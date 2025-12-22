# modules/nixos/power/default.nix
# ==============================================================================
# NixOS power management: CPU scaling, TLP/auto-cpufreq, laptop policies.
# Set power profiles and battery-friendly defaults in one place.
# Keep power behaviour consistent by editing this module.
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  hostname          = config.my.host.name;
  isPhysicalMachine = config.my.host.isPhysicalHost;
  isVirtualMachine  = config.my.host.isVirtualHost;

  enablePowerTuning     = isPhysicalMachine;
  enableRaplThermoGuard = isPhysicalMachine;

  cpuDetectionScript = pkgs.writeTextFile {
    name = "detect-cpu";
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      CPU_MODEL=$(LC_ALL=C ${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F "Model name" | ${pkgs.coreutils}/bin/cut -d: -f2-)
      CPU_MODEL=$(echo "''${CPU_MODEL}" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

      case "''${CPU_MODEL}" in
        *"Ultra 7 155H"*|*"Meteor Lake"*|*"MTL"*) echo "METEORLAKE" ;; 
        *"8650U"*|*"Kaby Lake"*)                   echo "KABYLAKE" ;; 
        *)                                        echo "GENERIC" ;; 
      esac
    '';
  };

  detectPowerSourceFunc = ''
    detect_power_source() {
      local on_ac=0
      for ps in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [[ -f "$ps" ]] && on_ac="$(cat "$ps")" && break
      done
      if [[ "''${on_ac}" == "1" ]]; then echo "AC"; else echo "BATTERY"; fi
    }
  '';

  writeSysfsFunc = ''
    write_sysfs() {
      local path="$1"
      local value="$2"
      for ((i=0;i<40;i++)); do
        if echo "$value" >"$path" 2>/dev/null; then
          return 0
        fi
        sleep 0.05
      done
      return 1
    }
  '';

  persistPowerStateFunc = ''
    state_dir="/run/osc-power"
    ensure_state_dirs() {
      install -d -m 0755 "$state_dir" "$state_dir/desired" "$state_dir/actual"
    }
    write_state() {
      local rel="$1"
      local value="$2"
      ensure_state_dirs
      echo "$value" >"$state_dir/$rel"
    }
    read_state() {
      local rel="$1"
      cat "$state_dir/$rel" 2>/dev/null || true
    }
  '';

  mkRobustScript = name: content: pkgs.writeTextFile {
    name = name;
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      exec 1> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.info)
      exec 2> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.err)

      ${content}
    '';
  };
in
{
  # Avoid conflicts with our custom power stack. power-profiles-daemon can
  # override platform_profile / EPP / governor settings after boot.
  services.power-profiles-daemon.enable = lib.mkForce false;

  # ============================================================================ 
  # CUSTOM POWER MANAGEMENT SERVICES
  # ============================================================================ 
  systemd.services = {
    # -------------------------------------------------------------------------- 
    # 1) ACPI PLATFORM PROFILE (AC / BATTERY)
    # -------------------------------------------------------------------------- 
    platform-profile = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Set ACPI Platform Profile (power-aware)";
      wantedBy    = [ "multi-user.target" ];
      after       = [
        "systemd-udev-settle.service"
        "power-profiles-daemon.service"
        "auto-cpufreq.service"
        "tlp.service"
        "thermald.service"
      ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = mkRobustScript "platform-profile" ''
          ${detectPowerSourceFunc}
          ${writeSysfsFunc}
          ${persistPowerStateFunc}

          PROFILE_PATH="/sys/firmware/acpi/platform_profile"
          CHOICES_PATH="/sys/firmware/acpi/platform_profile_choices"

          if [[ ! -f "''${PROFILE_PATH}" ]]; then
            echo "Platform profile interface not available"
            exit 0
          fi

          POWER_SRC=$(detect_power_source)
          if [[ "''${POWER_SRC}" == "AC" ]]; then
            TARGET="performance"
          else
            TARGET="low-power"
          fi

          # Respect low_power vs low-power spelling
          if [[ -f "''${CHOICES_PATH}" ]]; then
            CHOICES="$(cat "''${CHOICES_PATH}")"
            echo "Available platform profiles: ''${CHOICES}"
            # If the desired target isn't available, fall back to something sane.
            if [[ "''${TARGET}" != "low-power" && "''${TARGET}" != "low_power" ]] && ! grep -qw "''${TARGET}" "''${CHOICES_PATH}"; then
              if grep -qw "balanced" "''${CHOICES_PATH}"; then
                TARGET="balanced"
              elif grep -qw "balanced-performance" "''${CHOICES_PATH}"; then
                TARGET="balanced-performance"
              elif grep -qw "performance" "''${CHOICES_PATH}"; then
                TARGET="performance"
              fi
            fi
            if [[ "''${TARGET}" == "low-power" && "''${CHOICES}" == *low_power* ]]; then
              TARGET="low_power"
            fi
          fi

          write_state "desired/platform_profile" "''${TARGET}"

          CURRENT="$(cat "''${PROFILE_PATH}" 2>/dev/null || echo "unknown")"
          if [[ "''${CURRENT}" != "''${TARGET}" ]]; then
            if write_sysfs "''${PROFILE_PATH}" "''${TARGET}"; then
              echo "Platform profile set to: ''${TARGET} (was: ''${CURRENT})"
            else
              echo "WARN: failed to set platform profile to: ''${TARGET} (busy?)"
            fi
          else
            echo "Platform profile already: ''${TARGET}"
          fi

          # Read back (some firmware/services can revert this after boot).
          sleep 0.1
          FINAL="$(cat "''${PROFILE_PATH}" 2>/dev/null || echo "unknown")"
          write_state "actual/platform_profile" "''${FINAL}"
          if [[ "''${FINAL}" != "''${TARGET}" ]]; then
            echo "WARN: platform profile drift detected: wanted=''${TARGET}' actual=''${FINAL}'"
          else
            echo "Platform profile verified: ''${FINAL}"
          fi
        '';
      };
    };

    # --------------------------------------------------------------------------
    # 1b) CPU GOVERNOR + HWP DYNAMIC BOOST (intel_pstate)
    # --------------------------------------------------------------------------
    cpu-governor = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Configure CPU governor and Intel HWP dynamic boost (power-aware)";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "systemd-udev-settle.service" "platform-profile.service" ];
      wants       = [ "platform-profile.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = mkRobustScript "cpu-governor" ''
          ${detectPowerSourceFunc}
          ${persistPowerStateFunc}

          POWER_SRC=$(detect_power_source)
          if [[ "''${POWER_SRC}" == "AC" ]]; then
            TARGET_GOV="performance"
            TARGET_BOOST="1"
          else
            TARGET_GOV="powersave"
            TARGET_BOOST="0"
          fi

          # Wait briefly for cpufreq policies to appear (early boot race).
          for ((i=0;i<50;i++)); do
            [[ -d /sys/devices/system/cpu/cpufreq/policy0 ]] && break
            sleep 0.1
          done

          ${writeSysfsFunc}

          write_state "desired/governor" "''${TARGET_GOV}"
          write_state "desired/hwp_dynamic_boost" "''${TARGET_BOOST}"

          # Prefer policy-level knobs; fall back to per-cpu.
          wrote_any="0"
          for GOV in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor; do
            [[ -f "''${GOV}" ]] || continue
            wrote_any="1"
            cur="$(cat "''${GOV}" 2>/dev/null || echo "")"
            [[ "''${cur}" == "''${TARGET_GOV}" ]] && continue
            avail="$(cat "$(dirname "''${GOV}")/scaling_available_governors" 2>/dev/null || echo "")"
            if [[ -n "''${avail}" ]] && ! echo "''${avail}" | ${pkgs.gnugrep}/bin/grep -qw "''${TARGET_GOV}"; then
              echo "WARN: governor ''${TARGET_GOV}' not available for $(dirname "''${GOV}") (available: ''${avail})"
              continue
            fi
            if write_sysfs "''${GOV}" "''${TARGET_GOV}"; then
              echo "Governor set to ''${TARGET_GOV} for $(dirname "''${GOV}")"
            else
              echo "WARN: failed to set governor for $(dirname "''${GOV}") (busy?)"
            fi
          done

          if [[ "''${wrote_any}" == "0" ]]; then
            for GOV in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
              [[ -f "''${GOV}" ]] || continue
              cur="$(cat "''${GOV}" 2>/dev/null || echo "")"
              [[ "''${cur}" == "''${TARGET_GOV}" ]] && continue
              if write_sysfs "''${GOV}" "''${TARGET_GOV}"; then
                echo "Governor set to ''${TARGET_GOV} for $(dirname "''${GOV}")"
              else
                echo "WARN: failed to set governor for $(dirname "''${GOV}") (busy?)"
              fi
            done
          fi

          BOOST_PATH="/sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost"
          if [[ -f "''${BOOST_PATH}" ]]; then
            write_sysfs "''${BOOST_PATH}" "''${TARGET_BOOST}" || true
            echo "HWP dynamic boost set to: ''${TARGET_BOOST} (power source: ''${POWER_SRC})"
          else
            echo "HWP dynamic boost interface not available"
          fi
        '';
      };
    };

    # -------------------------------------------------------------------------- 
    # 2) CPU EPP (HWP ENERGY PERFORMANCE PREFERENCE)
    # -------------------------------------------------------------------------- 
    cpu-epp = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Configure Intel HWP Energy Performance Preference";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "systemd-udev-settle.service" "cpu-governor.service" ];
      wants       = [ "cpu-governor.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = mkRobustScript "cpu-epp" ''
          ${detectPowerSourceFunc}
          ${persistPowerStateFunc}

          # Wait briefly for cpufreq policies to appear (early boot race).
          for ((i=0;i<50;i++)); do
            [[ -d /sys/devices/system/cpu/cpufreq/policy0 ]] && break
            sleep 0.1
          done

          ${writeSysfsFunc}

          POWER_SRC=$(detect_power_source)
          if [[ "''${POWER_SRC}" == "AC" ]]; then
            TARGET_EPP="performance"
          else
            TARGET_EPP="balance_power"
          fi

          write_state "desired/epp" "''${TARGET_EPP}"
          echo "Setting EPP to: ''${TARGET_EPP} (power source: ''${POWER_SRC})"

          # Prefer policy-level knobs (one per cpufreq policy); they behave more
          # consistently on hybrid CPUs than per-cpu files.
          wrote_any="0"
          for POL in /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference; do
            [[ -f "''${POL}" ]] || continue
            wrote_any="1"
            cur="$(cat "''${POL}" 2>/dev/null || echo "")"
            [[ "''${cur}" == "''${TARGET_EPP}" ]] && continue
            avail="$(cat "$(dirname "''${POL}")/energy_performance_available_preferences" 2>/dev/null || echo "")"
            if [[ -n "''${avail}" ]] && ! echo "''${avail}" | ${pkgs.gnugrep}/bin/grep -qw "''${TARGET_EPP}"; then
              echo "  WARN: EPP ''${TARGET_EPP}' not available for $(dirname "''${POL}") (available: ''${avail})"
              continue
            fi
            if write_sysfs "''${POL}" "''${TARGET_EPP}"; then
              echo "  updated $(dirname "''${POL}")"
            else
              # Some kernels/drivers return EBUSY transiently; don't fail the unit.
              echo "  WARN: failed to update $(dirname "''${POL}") (busy?)"
            fi
          done

          if [[ "''${wrote_any}" == "0" ]]; then
            for CPU in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
              [[ -f "''${CPU}" ]] || continue
              cur="$(cat "''${CPU}" 2>/dev/null || echo "")"
              [[ "''${cur}" == "''${TARGET_EPP}" ]] && continue
              if write_sysfs "''${CPU}" "''${TARGET_EPP}"; then
                echo "  updated $(dirname "''${CPU}")"
              else
                echo "  WARN: failed to update $(dirname "''${CPU}") (busy?)"
              fi
            done
          fi

          # Snapshot one policy for status UIs
          write_state "actual/epp_policy0" "$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo unknown)"
        '';
      };
    };

    # -------------------------------------------------------------------------- 
    # 3) MINIMUM PERFORMANCE FLOOR (intel_pstate)
    # -------------------------------------------------------------------------- 
    cpu-min-freq-guard = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Set minimum CPU performance floor (intel_pstate)";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "systemd-udev-settle.service" "cpu-epp.service" ];
      wants       = [ "cpu-epp.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = mkRobustScript "cpu-min-freq-guard" ''
          ${detectPowerSourceFunc}
          ${writeSysfsFunc}
          ${persistPowerStateFunc}

          MIN_PERF_PATH="/sys/devices/system/cpu/intel_pstate/min_perf_pct"

          if [[ ! -f "''${MIN_PERF_PATH}" ]]; then
            echo "intel_pstate min_perf_pct not available"
            exit 0
          fi

          POWER_SRC=$(detect_power_source)
          if [[ "''${POWER_SRC}" == "AC" ]]; then
            TARGET_MIN=60
          else
            TARGET_MIN=30
          fi

          write_state "desired/min_perf_pct" "''${TARGET_MIN}"
          if write_sysfs "''${MIN_PERF_PATH}" "''${TARGET_MIN}"; then
            echo "Min performance floor set to ''${TARGET_MIN}% (power source: ''${POWER_SRC})"
          else
            echo "WARN: failed to set min_perf_pct to ''${TARGET_MIN}% (busy?)"
          fi
          write_state "actual/min_perf_pct" "$(cat "''${MIN_PERF_PATH}" 2>/dev/null || echo unknown)"
        '';
      };
    };

    # -------------------------------------------------------------------------- 
    # 4) RAPL POWER LIMITS (MSR, CPU + POWER SOURCE AWARE)
    # -------------------------------------------------------------------------- 
    rapl-power-limits = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Set RAPL power limits (MSR, CPU-aware)";
      wantedBy    = [ "multi-user.target" ];
      after = [
        "systemd-udev-settle.service"
        "platform-profile.service"
        "cpu-epp.service"
        "cpu-min-freq-guard.service"
      ];
      wants    = [ "disable-rapl-mmio.service" "rapl-thermo-guard.service" ];
      requires = [ "disable-rapl-mmio.service" ];
      unitConfig = {
        ConditionPathExists = "/sys/class/powercap/intel-rapl:0";
      };
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = mkRobustScript "rapl-power-limits" ''
          ${detectPowerSourceFunc}
          ${writeSysfsFunc}
          ${persistPowerStateFunc}

          CPU_TYPE=$(${cpuDetectionScript})
          POWER_SRC=$(detect_power_source)

          echo "Detected CPU: ''${CPU_TYPE}, power source: ''${POWER_SRC}"

          case "''${CPU_TYPE}" in
            METEORLAKE)
              if [[ "''${POWER_SRC}" == "AC" ]]; then
                PL1_WATTS=40
                PL2_WATTS=55
              else
                PL1_WATTS=28
                PL2_WATTS=40
              fi
              ;; 
            KABYLAKE)
              if [[ "''${POWER_SRC}" == "AC" ]]; then
                PL1_WATTS=25
                PL2_WATTS=44
              else
                PL1_WATTS=20
                PL2_WATTS=35
              fi
              ;; 
            *)
              if [[ "''${POWER_SRC}" == "AC" ]]; then
                PL1_WATTS=25
                PL2_WATTS=40
              else
                PL1_WATTS=20
                PL2_WATTS=30
              fi
              ;; 
          esac

          PL1_UW=$((PL1_WATTS * 1000000))
          PL2_UW=$((PL2_WATTS * 1000000))

          RAPL_BASE="/sys/class/powercap/intel-rapl:0"

          if [[ ! -d "''${RAPL_BASE}" ]]; then
            echo "RAPL interface not available"
            exit 1
          fi

          write_state "desired/rapl_pl1_w" "''${PL1_WATTS}"
          write_state "desired/rapl_pl2_w" "''${PL2_WATTS}"

          if write_sysfs "''${RAPL_BASE}/constraint_0_power_limit_uw" "''${PL1_UW}"; then
            echo "PL1 set to ''${PL1_WATTS} W"
          else
            echo "WARN: failed to set PL1 (busy?)"
          fi

          if write_sysfs "''${RAPL_BASE}/constraint_1_power_limit_uw" "''${PL2_UW}"; then
            echo "PL2 set to ''${PL2_WATTS} W"
          else
            echo "WARN: failed to set PL2 (busy?)"
          fi

          write_state "actual/rapl_pl1_w" "$(( $(cat "''${RAPL_BASE}/constraint_0_power_limit_uw" 2>/dev/null || echo 0) / 1000000 ))"
          write_state "actual/rapl_pl2_w" "$(( $(cat "''${RAPL_BASE}/constraint_1_power_limit_uw" 2>/dev/null || echo 0) / 1000000 ))"

          install -d -m 0755 /var/run
          echo "''${PL2_WATTS}" > /var/run/rapl-base-pl2
        '';
      };
    };

    # --------------------------------------------------------------------------
    # 4b) SHORT-LIVED GUARD (detect + mitigate firmware/service drift)
    # --------------------------------------------------------------------------
    power-policy-guard = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Guard power settings against drift (short-lived)";
      wantedBy    = [ "multi-user.target" ];
      after       = [
        "platform-profile.service"
        "cpu-governor.service"
        "cpu-epp.service"
        "cpu-min-freq-guard.service"
        "rapl-power-limits.service"
      ];
      serviceConfig = {
        Type = "simple";
        ExecStart = mkRobustScript "power-policy-guard" ''
          ${writeSysfsFunc}
          ${persistPowerStateFunc}

          DURATION_SEC=60
          INTERVAL_SEC=2

          desired_platform="$(read_state desired/platform_profile)"
          desired_gov="$(read_state desired/governor)"
          desired_epp="$(read_state desired/epp)"
          desired_min_perf="$(read_state desired/min_perf_pct)"

          PROFILE_PATH="/sys/firmware/acpi/platform_profile"
          MIN_PERF_PATH="/sys/devices/system/cpu/intel_pstate/min_perf_pct"

          echo "Guard starting (duration=''${DURATION_SEC}s, interval=''${INTERVAL_SEC}s)"
          echo "Desired: platform_profile=''${desired_platform:-unknown}', governor=''${desired_gov:-unknown}', epp=''${desired_epp:-unknown}', min_perf_pct=''${desired_min_perf:-unknown}'"

          end=$((SECONDS + DURATION_SEC))
          while (( SECONDS < end )); do
            if [[ -n "''${desired_platform}" && -w "''${PROFILE_PATH}" ]]; then
              cur="$(cat "''${PROFILE_PATH}" 2>/dev/null || echo unknown)"
              if [[ "''${cur}" != "''${desired_platform}" ]]; then
                echo "Drift: platform_profile actual=''${cur}' wanted=''${desired_platform}' → reapply"
                write_sysfs "''${PROFILE_PATH}" "''${desired_platform}" || true
              fi
              write_state "actual/platform_profile" "$(cat "''${PROFILE_PATH}" 2>/dev/null || echo unknown)"
            fi

            if [[ -n "''${desired_min_perf}" && -w "''${MIN_PERF_PATH}" ]]; then
              cur="$(cat "''${MIN_PERF_PATH}" 2>/dev/null || echo unknown)"
              if [[ "''${cur}" != "''${desired_min_perf}" ]]; then
                echo "Drift: min_perf_pct actual=''${cur}' wanted=''${desired_min_perf}' → reapply"
                write_sysfs "''${MIN_PERF_PATH}" "''${desired_min_perf}" || true
              fi
              write_state "actual/min_perf_pct" "$(cat "''${MIN_PERF_PATH}" 2>/dev/null || echo unknown)"
            fi

            if [[ -n "''${desired_gov}" ]]; then
              for govp in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor; do
                [[ -w "''${govp}" ]] || continue
                cur="$(cat "''${govp}" 2>/dev/null || echo "")"
                [[ "''${cur}" == "''${desired_gov}" ]] && continue
                avail="$(cat "$(dirname "''${govp}")/scaling_available_governors" 2>/dev/null || echo "")"
                if [[ -n "''${avail}" ]] && ! echo "''${avail}" | ${pkgs.gnugrep}/bin/grep -qw "''${desired_gov}"; then
                  continue
                fi
                echo "Drift: $(dirname "''${govp}") governor ''${cur}' → ''${desired_gov}'"
                write_sysfs "''${govp}" "''${desired_gov}" || true
              done
            fi

            if [[ -n "''${desired_epp}" ]]; then
              for eppp in /sys/devices/system/cpu/cpufreq/policy*/energy_performance_preference; do
                [[ -w "''${eppp}" ]] || continue
                cur="$(cat "''${eppp}" 2>/dev/null || echo "")"
                [[ "''${cur}" == "''${desired_epp}" ]] && continue
                avail="$(cat "$(dirname "''${eppp}")/energy_performance_available_preferences" 2>/dev/null || echo "")"
                if [[ -n "''${avail}" ]] && ! echo "''${avail}" | ${pkgs.gnugrep}/bin/grep -qw "''${desired_epp}"; then
                  continue
                fi
                echo "Drift: $(dirname "''${eppp}") epp ''${cur}' → ''${desired_epp}'"
                write_sysfs "''${eppp}" "''${desired_epp}" || true
              done
              write_state "actual/epp_policy0" "$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo unknown)"
            fi

            sleep "''${INTERVAL_SEC}"
          done

          echo "Guard finished"
        '';
      };
    };

    # -------------------------------------------------------------------------- 
    # 5) RAPL MMIO DISABLE (SAFETY NET)
    # -------------------------------------------------------------------------- 
    disable-rapl-mmio = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Disable intel_rapl_mmio to prevent conflicts";
      before      = [ "rapl-power-limits.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = mkRobustScript "disable-rapl-mmio" ''
          if ${pkgs.kmod}/bin/lsmod | ${pkgs.gnugrep}/bin/grep -q "^intel_rapl_mmio"; then
            echo "Disabling intel_rapl_mmio (rmmod)..."
            ${pkgs.kmod}/bin/rmmod intel_rapl_mmio 2>/dev/null || true
            echo "intel_rapl_mmio removed"
          else
            echo "intel_rapl_mmio not loaded"
          fi
        '';
      };
    };

    # -------------------------------------------------------------------------- 
    # 6) RAPL THERMAL GUARD (TEMP-AWARE PL2 ADJUSTMENT)
    # -------------------------------------------------------------------------- 
    rapl-thermo-guard = lib.mkIf (enablePowerTuning && enableRaplThermoGuard && isPhysicalMachine) {
      description = "Temperature-aware RAPL PL2 guard";
      after       = [ "rapl-power-limits.service" ];
      partOf      = [ "rapl-power-limits.service" ];
      serviceConfig = {
        Type       = "simple";
        Restart    = "always";
        RestartSec = "5s";
        ExecStart  = mkRobustScript "rapl-thermo-guard" ''
          RAPL_BASE="/sys/class/powercap/intel-rapl:0"
          PL1_PATH="''${RAPL_BASE}/constraint_0_power_limit_uw"
          PL2_PATH="''${RAPL_BASE}/constraint_1_power_limit_uw"
          BASE_PL2_FILE="/var/run/rapl-base-pl2"

          if [[ ! -f "''${BASE_PL2_FILE}" || ! -f "''${PL1_PATH}" || ! -f "''${PL2_PATH}" ]]; then
            echo "RAPL not ready; skipping thermal guard"
            exit 0
          fi

          BASE_PL2=$(cat "''${BASE_PL2_FILE}")
          BASE_PL2_UW=$((BASE_PL2 * 1000000))

          # Read the actual current PL1 from sysfs as our restore target. On some
          # systems the platform/firmware may cap PL1 below what we request.
          BASE_PL1_UW="$(cat "''${PL1_PATH}")"
          BASE_PL1_W=$((BASE_PL1_UW / 1000000))

          # Clamp relative to base PL2 so we never *increase* PL2 when hot.
          # (Fixed clamps like 60 W can accidentally raise PL2 on lower-TDP CPUs.)
          # Stronger clamps to target cooler sustained temps. This will reduce
          # all-core throughput under sustained load, but should keep interactive
          # performance largely intact.
          CLAMP_WARM_W=$(( (BASE_PL2 * 75) / 100 )) # ~75% at warm temps
          CLAMP_HOT_W=$(( (BASE_PL2 * 50) / 100 ))  # ~50% at hot temps

          # Mild PL1 clamps (sustained). This has the biggest impact on long,
          # all-core loads and is the most effective lever for sustained temps.
          # Keep it gentle to preserve responsiveness.
          CLAMP_PL1_WARM_W=$(( (BASE_PL1_W * 93) / 100 ))
          CLAMP_PL1_HOT_W=$(( (BASE_PL1_W * 85) / 100 ))

          # Keep sane minimums (avoid clamping too low on already-low base PL2).
          [[ ''${CLAMP_WARM_W} -lt 15 ]] && CLAMP_WARM_W=15
          [[ ''${CLAMP_HOT_W} -lt 15 ]] && CLAMP_HOT_W=15
          [[ ''${CLAMP_PL1_WARM_W} -lt 10 ]] && CLAMP_PL1_WARM_W=10
          [[ ''${CLAMP_PL1_HOT_W} -lt 10 ]] && CLAMP_PL1_HOT_W=10

          if [[ ''${CLAMP_PL1_HOT_W} -gt ''${CLAMP_PL1_WARM_W} ]]; then
            CLAMP_PL1_HOT_W="''${CLAMP_PL1_WARM_W}"
          fi

          CLAMP_WARM_UW=$((CLAMP_WARM_W * 1000000))
          CLAMP_HOT_UW=$((CLAMP_HOT_W * 1000000))
          CLAMP_PL1_WARM_UW=$((CLAMP_PL1_WARM_W * 1000000))
          CLAMP_PL1_HOT_UW=$((CLAMP_PL1_HOT_W * 1000000))

          # Earlier clamp thresholds to keep package temps closer to ~70°C on AC.
          RESTORE_C=66
          WARM_C=70
          HOT_C=74

          echo "Starting thermal guard (PL1 base: ''${BASE_PL1_W} W, PL2 base: ''${BASE_PL2} W, warm: PL1 ''${CLAMP_PL1_WARM_W} W + PL2 ''${CLAMP_WARM_W} W @ ''${WARM_C}°C, hot: PL1 ''${CLAMP_PL1_HOT_W} W + PL2 ''${CLAMP_HOT_W} W @ ''${HOT_C}°C, restore @ <= ''${RESTORE_C}°C)"

          read_pkgtemp() {
            for tz in /sys/class/thermal/thermal_zone*; do
              [[ -r "''${tz}/type" && -r "''${tz}/temp" ]] || continue
              if ${pkgs.gnugrep}/bin/grep -qi "x86_pkg_temp" "''${tz}/type"; then
                ${pkgs.gawk}/bin/awk '{printf("%d\n",$1/1000)}' "''${tz}/temp"
                return
              fi
            done
            ${pkgs.lm_sensors}/bin/sensors 2>/dev/null \
              | ${pkgs.gnugrep}/bin/grep -m1 "Package id 0" \
              | ${pkgs.gawk}/bin/awk '{match($0,/([0-9]+)\\. /,a); print a[1]}'
          }

          while true; do
            TEMP_INT="$(read_pkgtemp)"
            [[ -z "''${TEMP_INT}" ]] && { sleep 3; continue; }

            CURRENT_PL1_UW="$(cat "''${PL1_PATH}")"
            CURRENT_PL1_W=$((CURRENT_PL1_UW / 1000000))
            CURRENT_PL2_UW=$(cat "''${PL2_PATH}")
            CURRENT_PL2_W=$((CURRENT_PL2_UW / 1000000))

            if [[ ''${TEMP_INT} -le ''${RESTORE_C} ]]; then
              if [[ ''${CURRENT_PL1_UW} -ne ''${BASE_PL1_UW} ]]; then
                echo "''${BASE_PL1_UW}" > "''${PL1_PATH}"
                echo "[ ''${TEMP_INT}°C ] PL1 restored to ''${BASE_PL1_W} W"
              fi
              if [[ ''${CURRENT_PL2_W} -ne ''${BASE_PL2} ]]; then
                echo "''${BASE_PL2_UW}" > "''${PL2_PATH}"
                echo "[ ''${TEMP_INT}°C ] PL2 restored to ''${BASE_PL2} W"
              fi
            elif [[ ''${TEMP_INT} -ge ''${HOT_C} ]]; then
              if [[ ''${CURRENT_PL1_UW} -ne ''${CLAMP_PL1_HOT_UW} ]]; then
                echo "''${CLAMP_PL1_HOT_UW}" > "''${PL1_PATH}"
                echo "[ ''${TEMP_INT}°C ] PL1 clamped to ''${CLAMP_PL1_HOT_W} W"
              fi
              if [[ ''${CURRENT_PL2_UW} -ne ''${CLAMP_HOT_UW} ]]; then
                echo "''${CLAMP_HOT_UW}" > "''${PL2_PATH}"
                echo "[ ''${TEMP_INT}°C ] PL2 clamped to ''${CLAMP_HOT_W} W"
              fi
            elif [[ ''${TEMP_INT} -ge ''${WARM_C} ]]; then
              if [[ ''${CURRENT_PL1_UW} -ne ''${CLAMP_PL1_WARM_UW} ]]; then
                echo "''${CLAMP_PL1_WARM_UW}" > "''${PL1_PATH}"
                echo "[ ''${TEMP_INT}°C ] PL1 clamped to ''${CLAMP_PL1_WARM_W} W"
              fi
              if [[ ''${CURRENT_PL2_UW} -ne ''${CLAMP_WARM_UW} ]]; then
                echo "''${CLAMP_WARM_UW}" > "''${PL2_PATH}"
                echo "[ ''${TEMP_INT}°C ] PL2 clamped to ''${CLAMP_WARM_W} W"
              fi
            fi
            sleep 3
          done
        '';
      };
    };

    # -------------------------------------------------------------------------- 
    # 7) BATTERY CHARGE THRESHOLDS (75–80%)
    # -------------------------------------------------------------------------- 
    battery-thresholds = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Set battery charge thresholds (75–80%)";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "systemd-udev-settle.service" "rapl-power-limits.service" ];
      wants       = [ "rapl-power-limits.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = mkRobustScript "battery-thresholds" ''
          BAT_BASE="/sys/class/power_supply/BAT0"

          if [[ ! -d "''${BAT_BASE}" ]]; then
            echo "Battery interface not found"
            exit 0
          fi

          if [[ -f "''${BAT_BASE}/charge_control_start_threshold" ]]; then
            echo 75 > "''${BAT_BASE}/charge_control_start_threshold"
            echo "Charge start threshold set to 75%"
          fi

          if [[ -f "''${BAT_BASE}/charge_control_end_threshold" ]]; then
            echo 80 > "''${BAT_BASE}/charge_control_end_threshold"
            echo "Charge stop threshold set to 80%"
          fi
        '';
      };
    };

    # -------------------------------------------------------------------------- 
    # 8) AC CHANGE HANDLER (udev → restart core services)
    # -------------------------------------------------------------------------- 
    power-source-change = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Handle AC power source changes (restart power services)";
      serviceConfig = {
        Type      = "oneshot";
        ExecStart = mkRobustScript "power-source-change" ''
          ${detectPowerSourceFunc}

          POWER_SRC=$(detect_power_source)
          echo "Power source changed to: ''${POWER_SRC}"

          SERVICES=(
            "platform-profile.service"
            "cpu-governor.service"
            "cpu-epp.service"
            "cpu-min-freq-guard.service"
            "rapl-power-limits.service"
            "rapl-thermo-guard.service"
            "battery-thresholds.service"
            "power-policy-guard.service"
          )

          for SVC in "''${SERVICES[@]}"; do
            echo "Restarting ''${SVC}..."
            ${pkgs.systemd}/bin/systemctl restart "''${SVC}" || \
              echo "Failed to restart ''${SVC}"
          done

          echo "Power profile refresh complete"
        '';
      };
    };

    # -------------------------------------------------------------------------- 
    # 9) POST-SUSPEND RESTORE (AFTER RESUME)
    # -------------------------------------------------------------------------- 
    post-suspend-restore = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Restore power settings after suspend/resume";
      wantedBy    = [ "sleep.target" ];
      after       = [ "sleep.target" ];
      serviceConfig = {
        Type      = "oneshot";
        ExecStart = mkRobustScript "post-suspend-restore" ''
          echo "Restoring power settings after resume..."

          SERVICES=(
            "disable-rapl-mmio.service"
            "platform-profile.service"
            "cpu-governor.service"
            "cpu-epp.service"
            "cpu-min-freq-guard.service"
            "rapl-power-limits.service"
            "rapl-thermo-guard.service"
            "battery-thresholds.service"
            "power-policy-guard.service"
          )

          for SVC in "''${SERVICES[@]}"; do
            ${pkgs.systemd}/bin/systemctl restart "''${SVC}" 2>/dev/null || \
              echo "Failed to restart ''${SVC}"
          done

          echo "Post-resume restoration complete"
        '';
      };
    };
  };

  # ============================================================================ 
  # UDEV RULES – AC POWER CHANGE TRIGGERS
  # ============================================================================ 
  services.udev.extraRules = lib.mkIf (enablePowerTuning && isPhysicalMachine) ''
    # On AC plug/unplug events, trigger power-source-change
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC*", ENV{POWER_SUPPLY_ONLINE}=="1", \
      TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-source-change.service"
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC*", ENV{POWER_SUPPLY_ONLINE}=="0", \
      TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-source-change.service"
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="ADP*", ENV{POWER_SUPPLY_ONLINE}=="1", \
      TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-source-change.service"
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="ADP*", ENV{POWER_SUPPLY_ONLINE}=="0", \
      TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-source-change.service"
  '';

  # ============================================================================ 
  # DIAGNOSTIC TOOLS (CLI ONLY – osc-system remains the primary status CLI)
  # ============================================================================ 
  environment.systemPackages = with pkgs; [
    lm_sensors
    htop
    powertop
    intel-gpu-tools
    (pkgs.linuxPackages_latest.turbostat)
    stress-ng
  ];
}
