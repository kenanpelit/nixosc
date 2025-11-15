# modules/core/system/default.nix
# ==============================================================================
# NixOS System Configuration - ThinkPad E14 Gen 6 (Core Ultra 7 155H)
# ==============================================================================
#
# Module:    modules/core/system
# Version:   16.2 (Optimized, Declarative, Conflict-Resolved)
# Date:      2025-11-15
# Platform:  ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, Meteor Lake)
#
# PHILOSOPHY
# ----------
# "Trust the hardware; intervene only where critical."
#
# Modern Intel platforms (HWP) zaten P-state / boost işini kendi yapıyor.
# Sen sadece şu kaldıraçlara dokunuyorsun:
#   - ACPI Platform Profile (AC vs batarya)
#   - EPP (Energy Performance Preference)
#   - RAPL PL1/PL2 (MSR-based, hard limit)
#   - Min Perf Floor (UI jank’ı engellemek için)
#
# v16.2 ÖZETİ
# -----------
# ✅ MMIO RAPL modülü (intel_rapl_mmio) declarative blacklist
# ✅ RAPL, udev-settle + platform-profile + cpu-epp SONRASINA bağlandı
# ✅ Platform profile, low_power vs low-power varyantlarını otomatik seçiyor
# ✅ Thermal guard, önce sysfs x86_pkg_temp, yoksa sensors fallback
# ✅ AC değişiklikleri için temiz udev trigger + power-source-change servisi
# ✅ Uyku sonrası restore hook’u sleep.target üzerinden düzgün tetikleniyor
# ✅ turbostat & stress-ng sistem çapında
#
# NOTLAR
# ------
# • HWP altında scaling_cur_freq saçmalayabilir; turbostat’ı referans al.
# • intel_rapl_mmio tamamen devre dışı – sadece MSR tabanlı kontrol var.
# • tlp, thermald, power-profiles-daemon, auto-cpufreq bilerek devre dışı.
#
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  # ============================================================================
  # HOST TESPİTİ
  # ============================================================================
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";   # ThinkPad E14 Gen 6 (bare metal)
  isVirtualMachine  = hostname == "vhay";  # QEMU/KVM guest

  # ============================================================================
  # GLOBAL POWER FLAGS
  # ============================================================================
  # Debug mode: disable the entire custom power-management stack and
  # run as close to "stock Intel HWP" as possible.
  #
  # When you are happy with performance again, flip these to true.
  enablePowerTuning     = false;
  enableRaplThermoGuard = false;  # sub-feature, requires enablePowerTuning

  # ============================================================================
  # CPU TESPİTİ (profil seçimi için)
  # ============================================================================
  cpuDetectionScript = pkgs.writeTextFile {
    name = "detect-cpu";
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      CPU_MODEL=$(LC_ALL=C ${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F "Model name" | ${pkgs.coreutils}/bin/cut -d: -f2-)
      CPU_MODEL=$(echo "''${CPU_MODEL}" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

      echo "CPU Model: ''${CPU_MODEL}" >&2

      case "''${CPU_MODEL}" in
        *"Ultra 7 155H"*|*"Meteor Lake"*|*"MTL"*)
          echo "METEORLAKE"
          ;;
        *"8650U"*|*"Kaby Lake"*)
          echo "KABYLAKE"
          ;;
        *)
          echo "GENERIC"
          ;;
      esac
    '';
  };

  # ============================================================================
  # GÜÇ KAYNAĞI TESPİTİ (TEK KAYNAK)
  # ============================================================================
  detectPowerSourceFunc = ''
    detect_power_source() {
      local on_ac=0
      for ps in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [[ -f "$ps" ]] && on_ac="$(cat "$ps")" && break
      done
      if [[ "''${on_ac}" == "1" ]]; then
        echo "AC"
      else
        echo "BATTERY"
      fi
    }
  '';

  # ============================================================================
  # systemd-friendly SCRIPT WRAPPER (logları journala atar)
  # ============================================================================
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
  # LOKALİZASYON & KLAVYE
  # ============================================================================
  time.timeZone = "Europe/Istanbul";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS        = "tr_TR.UTF-8";
      LC_IDENTIFICATION = "tr_TR.UTF-8";
      LC_MEASUREMENT    = "tr_TR.UTF-8";
      LC_MONETARY       = "tr_TR.UTF-8";
      LC_NAME           = "tr_TR.UTF-8";
      LC_NUMERIC        = "tr_TR.UTF-8";
      LC_PAPER          = "tr_TR.UTF-8";
      LC_TELEPHONE      = "tr_TR.UTF-8";
      LC_TIME           = "tr_TR.UTF-8";
      LC_MESSAGES       = "en_US.UTF-8";
    };
  };

  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };

  console = {
    keyMap   = "trf";
    font     = "ter-v20b";
    packages = [ pkgs.terminus_font ];
  };

  # ============================================================================
  # BOOT & KERNEL
  # ============================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [
      "msr"           # RAPL MSR erişimi
      "coretemp"      # CPU sıcaklığı
      "i915"          # Intel iGPU
    ] ++ lib.optionals isPhysicalMachine [
      "thinkpad_acpi"
    ];

    extraModprobeConfig = lib.optionalString isPhysicalMachine ''
      options thinkpad_acpi experimental=1
    '';

    kernelParams = [
      # Intel HWP / power
      "intel_pstate=active"
      "intel_idle.max_cstate=7"
      "processor.ignore_ppc=1"

      # Intel iGPU
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_dc=2"
      "i915.enable_psr=1"
      "i915.fastboot=1"

      # Modern standby
      "mem_sleep_default=s2idle"
    ];

    kernel.sysctl = {
      "vm.swappiness"              = 60;
      "kernel.nmi_watchdog"        = 0;
      "kernel.audit_backlog_limit" = 8192;
    };

    # intel_rapl_mmio → declarative blacklist (MMIO çakışmalarını engelle)
    blacklistedKernelModules = [ "intel_rapl_mmio" ];

    loader = {
      grub = {
        enable  = true;
        device  = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");
        efiSupport = isPhysicalMachine;
        useOSProber = true;
        configurationLimit = 10;
        gfxmodeEfi  = "1920x1200";
        gfxmodeBios = if isVirtualMachine then "1920x1080" else "1920x1200";
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };

      efi = lib.mkIf isPhysicalMachine {
        canTouchEfiVariables = true;
        efiSysMountPoint     = "/boot";
      };
    };
  };

  # ============================================================================
  # NETWORKING
  # ============================================================================
  networking.networkmanager.enable = true;

  # ============================================================================
  # HARDWARE
  # ============================================================================
  hardware = {
    trackpoint = lib.mkIf isPhysicalMachine {
      enable       = true;
      speed        = 200;
      sensitivity  = 200;
      emulateWheel = true;
    };

    graphics = {
      enable      = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        mesa
        libva-vdpau-driver
        libvdpau-va-gl
        # intel-compute-runtime
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
      ];
    };

    enableRedistributableFirmware = true;
    enableAllFirmware             = true;
    cpu.intel.updateMicrocode     = true;
  };

  # ============================================================================
  # TEMEL SİSTEM SERVİSLERİ
  # ============================================================================
  services = {
    upower.enable = true;

    logind.settings = {
      Login = {
        HandleLidSwitch              = "suspend";
        HandleLidSwitchDocked        = "suspend";
        HandleLidSwitchExternalPower = "suspend";
        HandlePowerKey               = "ignore";
        HandlePowerKeyLongPress      = "poweroff";
        HandleSuspendKey             = "suspend";
        HandleHibernateKey           = "hibernate";
      };
    };

    # VM içi SPICE ajanı
    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;

    # Çakışan power daemons – kasıtlı olarak kapalı
    thermald.enable              = false;
    tlp.enable                   = false;
    power-profiles-daemon.enable = false;
  };

  # ============================================================================
  # ÖZEL POWER MANAGEMENT SERVİSLERİ
  # ============================================================================
  systemd.services = {
    # --------------------------------------------------------------------------
    # 1) PLATFORM PROFILE (AC / BATARYA)
    # --------------------------------------------------------------------------
    platform-profile = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Set ACPI Platform Profile (Power-Aware)";
      wantedBy = [ "multi-user.target" ];
      after    = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "platform-profile" ''
          ''${detectPowerSourceFunc}

          PROFILE_PATH="/sys/firmware/acpi/platform_profile"
          CHOICES_PATH="/sys/firmware/acpi/platform_profile_choices"

          if [[ ! -f "''${PROFILE_PATH}" ]]; then
            echo "⚠ Platform profile interface not available"
            exit 0
          fi

          POWER_SRC=$(detect_power_source)
          TARGET="performance"
          [[ "''${POWER_SRC}" != "AC" ]] && TARGET="low-power"

          # low_power vs low-power varyantına saygı göster
          if [[ -f "''${CHOICES_PATH}" ]]; then
            CHOICES="$(cat "''${CHOICES_PATH}")"
            if [[ "''${TARGET}" == "low-power" && "''${CHOICES}" == *low_power* ]]; then
              TARGET="low_power"
            fi
          fi

          CURRENT=$(cat "''${PROFILE_PATH}" 2>/dev/null || echo "unknown")
          if [[ "''${CURRENT}" != "''${TARGET}" ]]; then
            echo "''${TARGET}" > "''${PROFILE_PATH}"
            echo "✓ Platform profile set to: ''${TARGET} (was: ''${CURRENT})"
          else
            echo "✓ Platform profile already: ''${TARGET}"
          fi
        '';
      };
    };

    # --------------------------------------------------------------------------
    # 2) CPU EPP (HWP ENERGY PERFORMANCE PREFERENCE)
    # --------------------------------------------------------------------------
    cpu-epp = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Configure Intel HWP Energy Performance Preference";
      wantedBy = [ "multi-user.target" ];
      after    = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "cpu-epp" ''
          ''${detectPowerSourceFunc}

          POWER_SRC=$(detect_power_source)
          if [[ "''${POWER_SRC}" == "AC" ]]; then
            TARGET_EPP="performance"
          else
            TARGET_EPP="balance_power"
          fi

          echo "Setting EPP to: ''${TARGET_EPP} (Power: ''${POWER_SRC})"

          for CPU in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            [[ -f "''${CPU}" ]] || continue
            echo "''${TARGET_EPP}" > "''${CPU}" && echo "  ✓ $(dirname ''${CPU})"
          done
        '';
      };
    };

    # --------------------------------------------------------------------------
    # 3) MIN PERF FLOOR
    # --------------------------------------------------------------------------
    cpu-min-freq-guard = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Set Minimum CPU Performance Floor";
      wantedBy = [ "multi-user.target" ];
      after    = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "cpu-min-freq-guard" ''
          ''${detectPowerSourceFunc}

          MIN_PERF_PATH="/sys/devices/system/cpu/intel_pstate/min_perf_pct"

          if [[ ! -f "''${MIN_PERF_PATH}" ]]; then
            echo "⚠ intel_pstate min_perf_pct not available"
            exit 0
          fi

          POWER_SRC=$(detect_power_source)
          if [[ "''${POWER_SRC}" == "AC" ]]; then
            TARGET_MIN=40
          else
            TARGET_MIN=30
          fi

          echo "''${TARGET_MIN}" > "''${MIN_PERF_PATH}"
          echo "✓ Min performance set to ''${TARGET_MIN}% (Power: ''${POWER_SRC})"
        '';
      };
    };

    # --------------------------------------------------------------------------
    # 4) RAPL POWER LIMITS (MSR, CPU + POWER SOURCE AWARE)
    # --------------------------------------------------------------------------
    rapl-power-limits = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Set RAPL Power Limits (MSR, CPU-Aware)";
      wantedBy = [ "multi-user.target" ];
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
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "rapl-power-limits" ''
          ''${detectPowerSourceFunc}

          CPU_TYPE=$(${cpuDetectionScript})
          POWER_SRC=$(detect_power_source)

          echo "Detected CPU: ''${CPU_TYPE}, Power: ''${POWER_SRC}"

          case "''${CPU_TYPE}" in
            METEORLAKE)
              if [[ "''${POWER_SRC}" == "AC" ]]; then
                PL1_WATTS=50
                PL2_WATTS=85
              else
                PL1_WATTS=28
                PL2_WATTS=45
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
            echo "⚠ RAPL interface not available"
            exit 1
          fi

          echo "''${PL1_UW}" > "''${RAPL_BASE}/constraint_0_power_limit_uw"
          echo "✓ PL1 set to ''${PL1_WATTS}W"

          echo "''${PL2_UW}" > "''${RAPL_BASE}/constraint_1_power_limit_uw"
          echo "✓ PL2 set to ''${PL2_WATTS}W"

          install -d -m 0755 /var/run
          echo "''${PL2_WATTS}" > /var/run/rapl-base-pl2
        '';
      };
    };

    # --------------------------------------------------------------------------
    # 5) RAPL MMIO DISABLE (SAFETY NET)
    # --------------------------------------------------------------------------
    disable-rapl-mmio = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Disable intel_rapl_mmio to Prevent Conflicts";
      before = [ "rapl-power-limits.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "disable-rapl-mmio" ''
          if ${pkgs.kmod}/bin/lsmod | ${pkgs.gnugrep}/bin/grep -q "^intel_rapl_mmio"; then
            echo "Disabling intel_rapl_mmio (rmmod)..."
            ${pkgs.kmod}/bin/rmmod intel_rapl_mmio 2>/dev/null || true
            echo "✓ intel_rapl_mmio removed"
          else
            echo "✓ intel_rapl_mmio not loaded"
          fi
        '';
      };
    };

    # --------------------------------------------------------------------------
    # 6) RAPL THERMO GUARD (SICAKLIĞA GÖRE PL2 AYARI)
    # --------------------------------------------------------------------------
    rapl-thermo-guard = lib.mkIf (enablePowerTuning && enableRaplThermoGuard && isPhysicalMachine) {
      description = "Temperature-Aware RAPL PL2 Guard";
      after    = [ "rapl-power-limits.service" ];
      partOf   = [ "rapl-power-limits.service" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
        ExecStart = mkRobustScript "rapl-thermo-guard" ''
          RAPL_BASE="/sys/class/powercap/intel-rapl:0"
          PL2_PATH="''${RAPL_BASE}/constraint_1_power_limit_uw"
          BASE_PL2_FILE="/var/run/rapl-base-pl2"

          if [[ ! -f "''${BASE_PL2_FILE}" || ! -f "''${PL2_PATH}" ]]; then
            echo "⚠ RAPL not ready; skipping thermal guard"
            exit 0
          fi

          BASE_PL2=$(cat "''${BASE_PL2_FILE}")
          BASE_PL2_UW=$((BASE_PL2 * 1000000))
          echo "Starting thermal guard (BASE_PL2: ''${BASE_PL2}W)"

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
              | ${pkgs.gawk}/bin/awk '{match($0,/([0-9]+)\./,a); print a[1]}'
          }

          while true; do
            TEMP_INT="$(read_pkgtemp)"
            [[ -z "''${TEMP_INT}" ]] && { sleep 3; continue; }

            CURRENT_PL2_UW=$(cat "''${PL2_PATH}")
            CURRENT_PL2_W=$((CURRENT_PL2_UW / 1000000))

            if   [[ ''${TEMP_INT} -le 72 ]]; then
              if [[ ''${CURRENT_PL2_W} -ne ''${BASE_PL2} ]]; then
                echo "''${BASE_PL2_UW}" > "''${PL2_PATH}"
                echo "✓ [''${TEMP_INT}°C] PL2 restored to ''${BASE_PL2}W"
              fi
            elif [[ ''${TEMP_INT} -ge 82 ]]; then
              TARGET_UW=$((45 * 1000000))
              if [[ ''${CURRENT_PL2_UW} -ne ''${TARGET_UW} ]]; then
                echo "''${TARGET_UW}" > "''${PL2_PATH}"
                echo "⚠ [''${TEMP_INT}°C] PL2 clamped to 45W"
              fi
            elif [[ ''${TEMP_INT} -ge 77 ]]; then
              TARGET_UW=$((60 * 1000000))
              if [[ ''${CURRENT_PL2_UW} -ne ''${TARGET_UW} ]]; then
                echo "''${TARGET_UW}" > "''${PL2_PATH}"
                echo "⚠ [''${TEMP_INT}°C] PL2 clamped to 60W"
              fi
            fi
            sleep 3
          done
        '';
      };
    };

    # --------------------------------------------------------------------------
    # 7) BATARYA THRESHOLDS (75–80%)
    # --------------------------------------------------------------------------
    battery-thresholds = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Set Battery Charge Thresholds (75-80%)";
      wantedBy = [ "multi-user.target" ];
      after    = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "battery-thresholds" ''
          BAT_BASE="/sys/class/power_supply/BAT0"

          if [[ ! -d "''${BAT_BASE}" ]]; then
            echo "⚠ Battery interface not found"
            exit 0
          fi

          if [[ -f "''${BAT_BASE}/charge_control_start_threshold" ]]; then
            echo 75 > "''${BAT_BASE}/charge_control_start_threshold"
            echo "✓ Charge start threshold: 75%"
          fi

          if [[ -f "''${BAT_BASE}/charge_control_end_threshold" ]]; then
            echo 80 > "''${BAT_BASE}/charge_control_end_threshold"
            echo "✓ Charge stop  threshold: 80%"
          fi
        '';
      };
    };

    # --------------------------------------------------------------------------
    # 8) AC DEĞİŞİMİ HANDLER (udev → servis restart)
    # --------------------------------------------------------------------------
    power-source-change = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Handle AC Power Source Changes";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = mkRobustScript "power-source-change" ''
          ''${detectPowerSourceFunc}

          POWER_SRC=$(detect_power_source)
          echo "Power source changed to: ''${POWER_SRC}"

          SERVICES=(
            "platform-profile.service"
            "cpu-epp.service"
            "cpu-min-freq-guard.service"
            "rapl-power-limits.service"
            "rapl-thermo-guard.service"
          )

          for SVC in "''${SERVICES[@]}"; do
            echo "Restarting ''${SVC}..."
            ${pkgs.systemd}/bin/systemctl restart "''${SVC}" || \
              echo "⚠ Failed to restart ''${SVC}"
          done

          echo "✓ Power profile refresh complete"
        '';
      };
    };

    # --------------------------------------------------------------------------
    # 9) POST-SUSPEND RESTORE (UYKU SONRASI HOOK)
    # --------------------------------------------------------------------------
    post-suspend-restore = lib.mkIf (enablePowerTuning && isPhysicalMachine) {
      description = "Restore Power Settings After Suspend/Resume";
      wantedBy = [ "sleep.target" ];
      after    = [ "sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
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
              echo "⚠ Failed to restart ''${SVC}"
          done

          echo "✓ Post-resume restoration complete"
        '';
      };
    };
  };

  # ============================================================================
  # UDEV RULES – AC DEĞİŞİMİ
  # ============================================================================
  services.udev.extraRules = lib.mkIf (enablePowerTuning && isPhysicalMachine) ''
    # AC tak/çıkar olaylarında power-source-change’i tetikle
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC*", ENV{POWER_SUPPLY_ONLINE}=="1", \
      TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-source-change.service"
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC*", ENV{POWER_SUPPLY_ONLINE}=="0", \
      TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-source-change.service"

    # intel_rapl_mmio burada unbind edilmiyor; modül zaten blacklist’te.
  '';

  # ============================================================================
  # DİYAGNOSTİK ARAÇLAR & SCRIPT’LER
  # ============================================================================
  environment.systemPackages = with pkgs; let
    writeScriptBin = pkgs.writeScriptBin;
  in [
    lm_sensors
    htop
    powertop
    intel-gpu-tools
    (pkgs.linuxPackages_latest.turbostat)
    stress-ng

    # system-status: power stack’in snapshot’ı
    (writeScriptBin "system-status" ''
      #!${pkgs.bash}/bin/bash
      echo "╔════════════════════════════════════════════════════════════════╗"
      echo "║          POWER MANAGEMENT STATUS (v16.2)                      ║"
      echo "╚════════════════════════════════════════════════════════════════╝"
      echo ""

      ''${detectPowerSourceFunc}
      POWER_SRC=$(detect_power_source)
      echo "💡 Power Source: ''${POWER_SRC}"
      echo ""

      echo "━━━ CPU INFORMATION ━━━"
      CPU_MODEL=$(lscpu | grep "Model name" | cut -d: -f2- | sed 's/^[[:space:]]*//')
      echo "Model: ''${CPU_MODEL}"

      if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver ]]; then
        DRIVER=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver)
        echo "Driver: ''${DRIVER}"
      fi

      if [[ -f /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost ]]; then
        HWP=$(cat /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost)
        echo "HWP Dynamic Boost: ''${HWP}"
      fi
      echo ""

      echo "━━━ ACPI PLATFORM PROFILE ━━━"
      if [[ -f /sys/firmware/acpi/platform_profile ]]; then
        PROFILE=$(cat /sys/firmware/acpi/platform_profile)
        echo "Current: ''${PROFILE}"
        echo "Available: $(cat /sys/firmware/acpi/platform_profile_choices 2>/dev/null || echo 'N/A')"
      else
        echo "Not available on this platform"
      fi
      echo ""

      echo "━━━ ENERGY PERFORMANCE PREFERENCE (EPP) ━━━"
      if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]]; then
        EPP=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)
        echo "Current: ''${EPP}"
        EPP_AVAIL=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences 2>/dev/null || echo "N/A")
        echo "Available: ''${EPP_AVAIL}"
      else
        echo "EPP not available (HWP may be disabled)"
      fi
      echo ""

      echo "━━━ MINIMUM PERFORMANCE ━━━"
      if [[ -f /sys/devices/system/cpu/intel_pstate/min_perf_pct ]]; then
        MIN_PERF=$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct)
        echo "Min Performance Floor: ''${MIN_PERF}%"
      fi
      echo ""

      echo "━━━ RAPL POWER LIMITS ━━━"
      if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
        PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)
        PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw)
        printf "PL1 (Sustained): %3d W\n" $((PL1 / 1000000))
        printf "PL2 (Burst):     %3d W\n" $((PL2 / 1000000))

        if [[ -f /var/run/rapl-base-pl2 ]]; then
          BASE_PL2=$(cat /var/run/rapl-base-pl2)
          echo "Base PL2:        ''${BASE_PL2} W (thermal guard reference)"
        fi
      else
        echo "RAPL interface not available"
      fi
      echo ""

      echo "━━━ TEMPERATURE ━━━"
      if command -v sensors &>/dev/null; then
        TEMP=$(sensors 2>/dev/null | grep "Package id 0" | awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, a); print a[1]}')
        if [[ -n "''${TEMP}" ]]; then
          printf "Package: %.1f°C\n" "''${TEMP}"
        else
          echo "Temperature data not available"
        fi
      fi
      echo ""

      echo "━━━ BATTERY STATUS ━━━"
      if [[ -d /sys/class/power_supply/BAT0 ]]; then
        if [[ -f /sys/class/power_supply/BAT0/capacity ]]; then
          BAT_CAP=$(cat /sys/class/power_supply/BAT0/capacity)
          echo "Capacity: ''${BAT_CAP}%"
        fi
        if [[ -f /sys/class/power_supply/BAT0/status ]]; then
          BAT_STATUS=$(cat /sys/class/power_supply/BAT0/status)
          echo "Status: ''${BAT_STATUS}"
        fi
        if [[ -f /sys/class/power_supply/BAT0/charge_control_start_threshold ]]; then
          START=$(cat /sys/class/power_supply/BAT0/charge_control_start_threshold)
          STOP=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold)
          echo "Charge Thresholds: ''${START}% - ''${STOP}%"
        fi
      else
        echo "No battery detected (desktop or AC-only)"
      fi
      echo ""

      echo "━━━ SERVICE STATUS ━━━"
      SERVICES=(
        "platform-profile.service"
        "cpu-epp.service"
        "cpu-min-freq-guard.service"
        "rapl-power-limits.service"
        "disable-rapl-mmio.service"
        "rapl-thermo-guard.service"
        "battery-thresholds.service"
      )

      for SVC in "''${SERVICES[@]}"; do
        STATUS=$(systemctl is-active "''${SVC}" 2>/dev/null || echo "inactive")
        if [[ "''${STATUS}" == "active" ]]; then
          printf "✓ %-35s [ACTIVE]\n" "''${SVC}"
        else
          printf "✗ %-35s [''${STATUS}]\n" "''${SVC}"
        fi
      done
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "💡 Tip: Use 'power-monitor' for real-time monitoring"
      echo "💡 Tip: Use 'turbostat-quick' for CPU frequency verification"
    '')

    (writeScriptBin "turbostat-quick" ''
      #!${pkgs.bash}/bin/bash
      echo "=== TURBOSTAT QUICK CHECK (3 sec sample) ==="
      echo "This shows REAL CPU frequencies (not scaling_cur_freq)"
      echo ""
      sudo ''${pkgs.linuxPackages_latest.turbostat}/bin/turbostat \
        --quiet --show PkgWatt,Avg_MHz,Busy%,Bzy_MHz \
        --interval 3 --num_iterations 1
    '')

    (writeScriptBin "turbostat-stress" ''
      #!${pkgs.bash}/bin/bash
      echo "=== TURBOSTAT STRESS TEST ==="
      echo "Running stress-ng (10 sec) with turbostat monitoring..."
      echo ""
      sudo ''${pkgs.linuxPackages_latest.turbostat}/bin/turbostat \
        --quiet --show PkgWatt,Avg_MHz,Busy%,Bzy_MHz --interval 1 \
        ${pkgs.stress-ng}/bin/stress-ng --cpu $(nproc) --timeout 10s --metrics-brief
    '')

    (writeScriptBin "turbostat-analyze" ''
      #!${pkgs.bash}/bin/bash
      echo "=== TURBOSTAT DETAILED ANALYSIS (30 sec) ==="
      echo "Collecting comprehensive CPU metrics..."
      echo ""
      sudo ''${pkgs.linuxPackages_latest.turbostat}/bin/turbostat \
        --quiet --show Core,CPU,Avg_MHz,Busy%,Bzy_MHz,PkgWatt,PkgTmp,IRQ \
        --interval 2 --num_iterations 15
    '')

    (writeScriptBin "power-check" ''
      #!${pkgs.bash}/bin/bash
      echo "=== INSTANTANEOUS POWER CONSUMPTION CHECK ==="
      echo ""

      ''${detectPowerSourceFunc}
      POWER_SRC=$(detect_power_source)
      echo "Power Source: $([ "''${POWER_SRC}" = "AC" ] && echo "⚡ AC Power" || echo "🔋 Battery")"
      echo ""

      if [[ ! -f /sys/class/powercap/intel-rapl:0/energy_uj ]]; then
        echo "⚠ RAPL interface not found. Cannot measure power."
        exit 1
      fi

      echo "Measuring power consumption over a 2-second interval..."
      ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
      sleep 2
      ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

      ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
      [[ "''${ENERGY_DIFF}" -lt 0 ]] && ENERGY_DIFF="''${ENERGY_AFTER}"

      WATTS=$(echo "scale=2; ''${ENERGY_DIFF} / 2000000" | ${pkgs.bc}/bin/bc)

      echo ""
      echo ">> INSTANTANEOUS PACKAGE POWER: ''${WATTS} W"
      echo ""

      PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)
      PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw)
      printf "Active RAPL Limits:\n  PL1 (Sustained): %3d W\n  PL2 (Burst):     %3d W\n\n" $((PL1/1000000)) $((PL2/1000000))

      WATTS_INT=$(echo "''${WATTS}" | cut -d. -f1)
      if   [[ "''${WATTS_INT}" -lt 10 ]]; then echo "📊 Status: Idle or light usage."
      elif [[ "''${WATTS_INT}" -lt 30 ]]; then echo "📊 Status: Normal productivity workload."
      elif [[ "''${WATTS_INT}" -lt 50 ]]; then echo "📊 Status: High load (compiling, gaming)."
      else                                  echo "📊 Status: Very high load (stress test)."
      fi
    '')

    (writeScriptBin "power-monitor" ''
      #!${pkgs.bash}/bin/bash
      trap "tput cnorm; exit" INT
      tput civis

      while true; do
        clear
        echo "=== REAL-TIME POWER MONITOR (v16.2) | Press Ctrl+C to stop ==="
        echo "Timestamp: $(date '+%H:%M:%S')"
        echo "------------------------------------------------------------"

        ''${detectPowerSourceFunc}
        POWER_SRC=$(detect_power_source)
        echo "Power Source:  $([ "''${POWER_SRC}" = "AC" ] && echo "⚡ AC Power" || echo "🔋 Battery")"

        EPP=$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo "N/A")
        echo "EPP Setting:   ''${EPP}"

        TEMP=$(sensors 2>/dev/null | grep "Package id 0" | awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, a); print a[1]}')
        [[ -n "''${TEMP}" ]] && printf "Temperature:   %.1f°C\n" "''${TEMP}" || echo "Temperature:   N/A"

        echo "------------------------------------------------------------"

        if [[ -f /sys/class/powercap/intel-rapl:0/energy_uj ]]; then
          ENERGY_BEFORE=$(cat /sys/class/powercap:intel-rapl:0/energy_uj 2>/dev/null || cat /sys/class/powercap/intel-rapl:0/energy_uj)
          sleep 0.5
          ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

          ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
          [[ "''${ENERGY_DIFF}" -lt 0 ]] && ENERGY_DIFF="''${ENERGY_AFTER}"
          WATTS=$(echo "scale=2; ''${ENERGY_DIFF} / 500000" | bc)

          PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)
          PL2=$(cat /sys/class/powercap:intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)

          echo "PACKAGE POWER (RAPL):"
          printf "  Current Consumption: %6.2f W\n" "''${WATTS}"
          printf "  Sustained Limit (PL1): %4d W\n" $((PL1/1000000))
          printf "  Burst    Limit (PL2): %4d W\n" $((PL2/1000000))
        else
          echo "PACKAGE POWER (RAPL): Not Available"
        fi

        echo "------------------------------------------------------------"
        echo "CPU FREQUENCY (scaling_cur_freq):"
        FREQS=($(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null))
        if [[ ''${#FREQS[@]} -gt 0 ]]; then
          SUM=$(IFS=+; echo "$((''${FREQS[*]}))")
          AVG=$((SUM / ''${#FREQS[@]} / 1000))
          MIN=$(printf "%s\n" "''${FREQS[@]}" | sort -n | head -1)
          MAX=$(printf "%s\n" "''${FREQS[@]}" | sort -n | tail -1)
          printf "  Average: %5d MHz\n" "$AVG"
          printf "  Min/Max: %5d / %d MHz\n" "$((MIN/1000))" "$((MAX/1000))"
          echo "  (NOTE: This value can be misleading; use turbostat for ground truth)"
        else
          echo "  Frequency data not available."
        fi
        sleep 0.5
      done
    '')

    (writeScriptBin "power-profile-refresh" ''
      #!${pkgs.bash}/bin/bash
      echo "=== RESTARTING POWER PROFILE SERVICES ==="
      echo ""
      if [[ $EUID -ne 0 ]]; then
        echo "⚠ This script requires root privileges. Please run with sudo."
        exit 1
      fi

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
        printf "Restarting %-35s ... " "''${SVC}"
        if systemctl restart "''${SVC}" 2>/dev/null; then
          echo "[ OK ]"
        else
          echo "[ FAILED ]"
        fi
      done

      echo ""
      echo "✓ All power-related services have been refreshed."
      echo "-------------------------------------------------"
      system-status
    '')
  ];

  # ============================================================================
  # SYSTEM STATE VERSION
  # ============================================================================
  system.stateVersion = "25.11";
}


