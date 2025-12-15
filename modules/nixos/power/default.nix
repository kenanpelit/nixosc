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
      after       = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = mkRobustScript "platform-profile" ''
          ${detectPowerSourceFunc}

          PROFILE_PATH="/sys/firmware/acpi/platform_profile"
          CHOICES_PATH="/sys/firmware/acpi/platform_profile_choices"

          if [[ ! -f "''${PROFILE_PATH}" ]]; then
            echo "Platform profile interface not available"
            exit 0
          fi

          POWER_SRC=$(detect_power_source)
          TARGET="performance"
          [[ "''${POWER_SRC}" != "AC" ]] && TARGET="low-power"

          # Respect low_power vs low-power spelling
          if [[ -f "''${CHOICES_PATH}" ]]; then
            CHOICES="$(cat "''${CHOICES_PATH}")"
            if [[ "''${TARGET}" == "low-power" && "''${CHOICES}" == *low_power* ]]; then
              TARGET="low_power"
            fi
          fi

          CURRENT=$(cat "''${PROFILE_PATH}" 2>/dev/null || echo "unknown")
          if [[ "''${CURRENT}" != "''${TARGET}" ]]; then
            echo "''${TARGET}" > "''${PROFILE_PATH}"
            echo "Platform profile set to: ''${TARGET} (was: ''${CURRENT})"
          else
            echo "Platform profile already: ''${TARGET}"
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
      after       = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = mkRobustScript "cpu-epp" ''
          ${detectPowerSourceFunc}

          POWER_SRC=$(detect_power_source)
          if [[ "''${POWER_SRC}" == "AC" ]]; then
            TARGET_EPP="performance"
          else
            TARGET_EPP="balance_power"
          fi

          echo "Setting EPP to: ''${TARGET_EPP} (power source: ''${POWER_SRC})"

          for CPU in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            [[ -f "''${CPU}" ]] || continue
            echo "''${TARGET_EPP}" > "''${CPU}" && \
              echo "  updated $(dirname ''${CPU})"
          done
        '';
      };
    };

    # -------------------------------------------------------------------------- 
    # 3) MINIMUM PERFORMANCE FLOOR (intel_pstate)
    # -------------------------------------------------------------------------- 
    cpu-min-freq-guard = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Set minimum CPU performance floor (intel_pstate)";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = mkRobustScript "cpu-min-freq-guard" ''
          ${detectPowerSourceFunc}

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

          echo "''${TARGET_MIN}" > "''${MIN_PERF_PATH}"
          echo "Min performance floor set to ''${TARGET_MIN}% (power source: ''${POWER_SRC})"
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

          echo "''${PL1_UW}" > "''${RAPL_BASE}/constraint_0_power_limit_uw"
          echo "PL1 set to ''${PL1_WATTS} W"

          echo "''${PL2_UW}" > "''${RAPL_BASE}/constraint_1_power_limit_uw"
          echo "PL2 set to ''${PL2_WATTS} W"

          install -d -m 0755 /var/run
          echo "''${PL2_WATTS}" > /var/run/rapl-base-pl2
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
          PL2_PATH="''${RAPL_BASE}/constraint_1_power_limit_uw"
          BASE_PL2_FILE="/var/run/rapl-base-pl2"

          if [[ ! -f "''${BASE_PL2_FILE}" || ! -f "''${PL2_PATH}" ]]; then
            echo "RAPL not ready; skipping thermal guard"
            exit 0
          fi

          BASE_PL2=$(cat "''${BASE_PL2_FILE}")
          BASE_PL2_UW=$((BASE_PL2 * 1000000))
          echo "Starting thermal guard (base PL2: ''${BASE_PL2} W)"

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

            CURRENT_PL2_UW=$(cat "''${PL2_PATH}")
            CURRENT_PL2_W=$((CURRENT_PL2_UW / 1000000))

            if   [[ ''${TEMP_INT} -le 72 ]]; then
              if [[ ''${CURRENT_PL2_W} -ne ''${BASE_PL2} ]]; then
                echo "''${BASE_PL2_UW}" > "''${PL2_PATH}"
                echo "[ ''${TEMP_INT}°C ] PL2 restored to ''${BASE_PL2} W"
              fi
            elif [[ ''${TEMP_INT} -ge 82 ]]; then
              TARGET_UW=$((45 * 1000000))
              if [[ ''${CURRENT_PL2_UW} -ne ''${TARGET_UW} ]]; then
                echo "''${TARGET_UW}" > "''${PL2_PATH}"
                echo "[ ''${TEMP_INT}°C ] PL2 clamped to 45 W"
              fi
            elif [[ ''${TEMP_INT} -ge 77 ]]; then
              TARGET_UW=$((60 * 1000000))
              if [[ ''${CURRENT_PL2_UW} -ne ''${TARGET_UW} ]]; then
                echo "''${TARGET_UW}" > "''${PL2_PATH}"
                echo "[ ''${TEMP_INT}°C ] PL2 clamped to 60 W"
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
      after       = [ "systemd-udev-settle.service" ];
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
            "cpu-epp.service"
            "cpu-min-freq-guard.service"
            "rapl-power-limits.service"
            "rapl-thermo-guard.service"
            "battery-thresholds.service"
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
            "cpu-epp.service"
            "cpu-min-freq-guard.service"
            "rapl-power-limits.service"
            "rapl-thermo-guard.service"
            "battery-thresholds.service"
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
