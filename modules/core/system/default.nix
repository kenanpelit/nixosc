# modules/core/system/default.nix
# ==============================================================================
# NixOS System Configuration - Base System, Boot, Hardware & Power Management
# ==============================================================================
#
# Module: modules/core/system
# Author: Kenan Pelit
# Version: 3.4 FINAL (heredoc fix, passive+schedutil, 1200+ MHz garanti)
# Date:    2025-09-19
#
# Hedefler:
#   - Serin ve akıcı (idle düşük, yükte ~68–72 °C)
#   - Lag yok (schedutil ramp)
#   - CPU frekansı asla 1200 MHz altına düşmez
#   - Meteor Lake için termal optimize RAPL; X1C6 için güvenli limitler
#   - AC/DC ve suspend/resume tetiklemeleri; VM optimizasyonları
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";
  isVirtualMachine  = hostname == "vhay";
in
{
  # ============================================================================
  # Base System
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
    };
  };

  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };
  console.keyMap = "trf";

  system.stateVersion = "25.11";

  # ============================================================================
  # Boot (Kernel/GRUB)
  # ============================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules =
      [ "coretemp" "i915" ]
      ++ lib.optionals isPhysicalMachine [ "thinkpad_acpi" ];

    extraModprobeConfig = ''
      # Intel P-State HWP dynamic boost (passive modda zararsız)
      options intel_pstate hwp_dynamic_boost=1

      # Audio power saving (10s)
      options snd_hda_intel power_save=10 power_save_controller=Y

      # Wi-Fi power management
      options iwlwifi power_save=1 power_level=3

      # USB autosuspend (5s)
      options usbcore autosuspend=5

      # NVMe power (latency bütçesi)
      options nvme_core default_ps_max_latency_us=5500

      ${lib.optionalString isPhysicalMachine ''
        # ThinkPad ACPI
        options thinkpad_acpi fan_control=1 experimental=1
      ''}
    '';

    kernelParams = [
      # PASSIVE: cpufreq + scaling_min_freq uygulanır → 1200+ MHz garanti
      "intel_pstate=passive"

      "pcie_aspm=default"
      "i915.enable_guc=3"
      "i915.enable_fbc=0"
      "i915.enable_psr=0"
      "i915.enable_sagv=1"
      "mem_sleep_default=deep"
      "nvme_core.default_ps_max_latency_us=5500"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_writeback_centisecs" = 1500;
      "kernel.nmi_watchdog" = 0;
    };

    loader = {
      grub = {
        enable = true;
        device = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");
        efiSupport = isPhysicalMachine;
        useOSProber = true;
        configurationLimit = 10;
        gfxmodeEfi  = "1920x1200";
        gfxmodeBios = if isVirtualMachine then "1920x1080" else "1920x1200";
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };
      efi = lib.mkIf isPhysicalMachine {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  # ============================================================================
  # Hardware
  # ============================================================================
  hardware = {
    trackpoint = lib.mkIf isPhysicalMachine {
      enable = true; speed = 200; sensitivity = 200; emulateWheel = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        mesa
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime
        intel-graphics-compiler
        level-zero
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [ intel-media-driver ];
    };

    enableRedistributableFirmware = true;
    enableAllFirmware             = true;
    cpu.intel.updateMicrocode     = true;
    bluetooth.enable              = true;
  };

  # ============================================================================
  # Power (TLP + passive cpufreq) — Serin & Akıcı, Min 1200 MHz Garantisi
  # ============================================================================
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;

  services.tlp = lib.mkIf isPhysicalMachine {
    enable = true;
    settings = {
      TLP_DEFAULT_MODE       = "AC";
      TLP_PERSISTENT_DEFAULT = 0;

      CPU_DRIVER_OPMODE           = "passive";
      CPU_SCALING_GOVERNOR_ON_AC  = "schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";

      # Taban frekanslar
      CPU_SCALING_MIN_FREQ_ON_AC  = 1800000;
      CPU_SCALING_MAX_FREQ_ON_AC  = 4200000;
      CPU_SCALING_MIN_FREQ_ON_BAT = 1200000;
      CPU_SCALING_MAX_FREQ_ON_BAT = 3200000;

      # (Passive modda EPP yüzdeleri etkisiz ama zararsız)
      CPU_MIN_PERF_ON_AC  = 40;
      CPU_MAX_PERF_ON_AC  = 92;
      CPU_MIN_PERF_ON_BAT = 20;
      CPU_MAX_PERF_ON_BAT = 80;

      #CPU_ENERGY_PERF_POLICY_ON_AC  = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_AC  = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      CPU_HWP_DYN_BOOST_ON_AC  = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;
      CPU_BOOST_ON_AC  = 1;
      CPU_BOOST_ON_BAT = "auto";

      PLATFORM_PROFILE_ON_AC  = "balanced";
      PLATFORM_PROFILE_ON_BAT = "balanced";

      PCIE_ASPM_ON_AC  = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      RUNTIME_PM_ON_AC  = "on";
      RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_DRIVER_DENYLIST = "nouveau radeon";

      USB_AUTOSUSPEND     = 1;
      USB_DENYLIST        = "17ef:6047";
      USB_EXCLUDE_AUDIO   = 1;
      USB_EXCLUDE_BTUSB   = 0;
      USB_EXCLUDE_PHONE   = 1;
      USB_EXCLUDE_PRINTER = 1;
      USB_EXCLUDE_WWAN    = 0;

      START_CHARGE_THRESH_BAT0 = 75; STOP_CHARGE_THRESH_BAT0 = 80;
      START_CHARGE_THRESH_BAT1 = 75; STOP_CHARGE_THRESH_BAT1 = 80;
      RESTORE_THRESHOLDS_ON_BAT = 1;

      DISK_IDLE_SECS_ON_AC       = 0;
      DISK_IDLE_SECS_ON_BAT      = 2;
      MAX_LOST_WORK_SECS_ON_AC   = 15;
      MAX_LOST_WORK_SECS_ON_BAT  = 60;
      DISK_APM_LEVEL_ON_AC       = "255";
      DISK_APM_LEVEL_ON_BAT      = "128";
      DISK_APM_CLASS_DENYLIST    = "usb ieee1394";
      DISK_IOSCHED               = "mq-deadline";

      SATA_LINKPWR_ON_AC  = "max_performance";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";

      WIFI_PWR_ON_AC  = "off";
      WIFI_PWR_ON_BAT = "on";
      WOL_DISABLE     = "Y";

      SOUND_POWER_SAVE_ON_AC  = 0;
      SOUND_POWER_SAVE_ON_BAT = 10;
      SOUND_POWER_SAVE_CONTROLLER = "Y";

      DEVICES_TO_ENABLE_ON_STARTUP  = "bluetooth wifi";
      DEVICES_TO_ENABLE_ON_AC       = "bluetooth wifi wwan";
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "wwan";
    };
  };

  # ============================================================================
  # Services (Thermal / Fan / Login / VM)
  # ============================================================================
  services = {
    thermald.enable = true;
    upower.enable   = true;

    # hedef ~68–72 °C
    thinkfan = lib.mkIf isPhysicalMachine {
      enable = true;
      levels = [
        [ "level auto"        0  46 ]
        [ 1                  44  54 ]
        [ 2                  52  60 ]
        [ 3                  58  66 ]
        [ 5                  64  72 ]
        [ 7                  70  78 ]
        [ "level full-speed" 76 32767 ]
      ];
    };

    logind.settings.Login = {
      HandleLidSwitch              = "suspend";
      HandleLidSwitchDocked        = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey               = "ignore";
      HandlePowerKeyLongPress      = "poweroff";
      HandleSuspendKey             = "suspend";
      HandleHibernateKey           = "hibernate";
    };

    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
  };

  # ============================================================================
  # RAPL — Termal Optimize Limitler
  # ============================================================================
  systemd.services.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Apply thermal-optimized RAPL power limits";
    after = [ "tlp.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "set-rapl-limits" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' \
          | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.coreutils}/bin/tr -d '\n' \
          | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

        ON_AC=0
        for PS in /sys/class/power_supply/A{C,DP}*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done

        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core\(TM\) Ultra|Meteor Lake|Arrow Lake|Lunar Lake'; then
          if [[ "$ON_AC" == "1" ]]; then
            PL1_W=22; PL2_W=30
          else
            PL1_W=18; PL2_W=25
          fi
        else
          if [[ "$ON_AC" == "1" ]]; then
            PL1_W=20; PL2_W=28
          else
            PL1_W=15; PL2_W=22
          fi
        fi

        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw" 2>/dev/null || true
          [[ -w "$R/constraint_0_time_window_us" ]] && echo 28000000 > "$R/constraint_0_time_window_us" 2>/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw" 2>/dev/null || true
          [[ -w "$R/constraint_1_time_window_us" ]] && echo 2440000  > "$R/constraint_1_time_window_us" 2>/dev/null || true
        done

        echo "RAPL: PL1=''${PL1_W}W PL2=''${PL2_W}W (AC=''${ON_AC})"
      '';
    };
  };

  systemd.timers.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Timer: apply RAPL power limits shortly after boot";
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "45s"; Persistent = true; };
  };

  systemd.services.rapl-power-limits-resume = lib.mkIf isPhysicalMachine {
    description = "Re-apply RAPL limits after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl start rapl-power-limits.service";
    };
  };

  # ============================================================================
  # CPU autotune — governor + min_freq garantisi + schedutil ramp
  # ============================================================================
  systemd.services.cpu-epp-autotune = lib.mkIf isPhysicalMachine {
    description = "CPU autotune (governor, schedutil ramp, min_freq never < 1200 MHz)";
    after = [ "tlp.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "cpu-epp-autotune" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        # Governor: schedutil varsa onu, yoksa powersave
        GOVS="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")"
        target="powersave"
        echo "$GOVS" | ${pkgs.gnugrep}/bin/grep -qw schedutil && target="schedutil"
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/scaling_governor" ]] && echo "$target" > "$pol/scaling_governor" || true
        done

        # AC/BAT tespiti
        ON_AC=0
        for PS in /sys/class/power_supply/A{C,DP}*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done

        # Taban frekans hedefi
        if [[ "$ON_AC" == "1" ]]; then
          MIN_FREQ=1800000   # akıcı
        else
          MIN_FREQ=1200000   # garanti
        fi

        # scaling_min_freq ve schedutil tunables
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/scaling_min_freq" ]] && echo "$MIN_FREQ" > "$pol/scaling_min_freq" || true
          if [[ -d "$pol/schedutil" ]]; then
            [[ -w "$pol/schedutil/up_rate_limit_us"    ]] && echo 1000  > "$pol/schedutil/up_rate_limit_us"    || true
            [[ -w "$pol/schedutil/down_rate_limit_us"  ]] && echo 5000  > "$pol/schedutil/down_rate_limit_us"  || true
            [[ -w "$pol/schedutil/iowait_boost_enable" ]] && echo 1     > "$pol/schedutil/iowait_boost_enable" || true
          fi
        done

        echo "autotune: governor=$target, min_freq>=''$((MIN_FREQ/1000)) MHz (AC=$ON_AC)"
      '';
    };
  };

  systemd.timers.cpu-epp-autotune = lib.mkIf isPhysicalMachine {
    description = "Timer: autotune after TLP";
    wantedBy = [ "timers.target" ];
    timerConfig = { OnBootSec = "30s"; Persistent = true; Unit = "cpu-epp-autotune.service"; };
  };

  systemd.services.cpu-epp-autotune-resume = lib.mkIf isPhysicalMachine {
    description = "Re-apply autotune after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service";
    };
  };

  # ============================================================================
  # Udev — AC/DC Geçişlerinde Yeniden Uygula
  # ============================================================================
  services.udev.extraRules = lib.mkIf isPhysicalMachine ''
    SUBSYSTEM=="power_supply", KERNEL=="A{C,DP}*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start rapl-power-limits.service"
    SUBSYSTEM=="power_supply", KERNEL=="A{C,DP}*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service"
  '';

  # ============================================================================
  # ThinkPad LED/Fan Suspend-Resume Temizliği
  # ============================================================================
  systemd.services.thinkpad-led-fix = lib.mkIf isPhysicalMachine {
    description = "Turn off ThinkPad mute LEDs";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-mute-leds" ''
        #!${pkgs.bash}/bin/bash
        for led in /sys/class/leds/platform::{mute,micmute}/brightness; do
          [[ -w "$led" ]] && echo 0 > "$led" 2>/dev/null || true
        done
      '';
    };
  };

  systemd.services.thinkpad-led-fix-resume = lib.mkIf isPhysicalMachine {
    description = "Turn off ThinkPad mute LEDs after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "disable-mute-leds-resume" ''
        #!${pkgs.bash}/bin/bash
        for led in /sys/class/leds/platform::{mute,micmute}/brightness; do
          [[ -w "$led" ]] && echo 0 > "$led" 2>/dev/null || true
        done
      '';
    };
  };

  systemd.services.suspend-pre-fan = lib.mkIf isPhysicalMachine {
    description = "Stop thinkfan before suspend";
    wantedBy = [ "sleep.target" ];
    before   = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "suspend-pre-fan" ''
        #!${pkgs.bash}/bin/bash
        ${pkgs.systemd}/bin/systemctl stop thinkfan.service 2>/dev/null || true
        [[ -w /proc/acpi/ibm/fan ]] && echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
      '';
    };
  };

  systemd.services.resume-post-fan = lib.mkIf isPhysicalMachine {
    description = "Restart thinkfan after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "resume-post-fan" ''
        #!${pkgs.bash}/bin/bash
        sleep 1
        if ${pkgs.systemd}/bin/systemctl is-enabled thinkfan.service >/dev/null 2>&1; then
          ${pkgs.systemd}/bin/systemctl restart thinkfan.service 2>/dev/null || true
        else
          [[ -w /proc/acpi/ibm/fan ]] && echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
        fi
      '';
    };
  };

  # Eski ad-hoc servisleri kapat
  systemd.services.thinkfan-sleep  = lib.mkIf isPhysicalMachine { enable = lib.mkForce false; wantedBy = lib.mkForce [ ]; };
  systemd.services.thinkfan-wakeup = lib.mkIf isPhysicalMachine { enable = lib.mkForce false; wantedBy = lib.mkForce [ ]; };

  # ============================================================================
  # Kullanıcı Araçları
  # ============================================================================
  environment.systemPackages = with pkgs;
    lib.optionals isPhysicalMachine [
      tlp
      lm_sensors

      (writeScriptBin "performance-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "🚀 Performance mode…"
        sudo ${tlp}/bin/tlp ac
        # Governor (schedutil varsa)
        GOVS="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")"
        target="powersave"; echo "$GOVS" | ${gnugrep}/bin/grep -qw schedutil && target="schedutil"
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$p/scaling_governor" ]] && echo "$target" | sudo tee "$p/scaling_governor" >/dev/null || true
        done
        # Min freq: ≥ 1.8 GHz
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          if [[ -w "$p/scaling_min_freq" ]]; then
            echo 1800000 | sudo tee "$p/scaling_min_freq" >/dev/null || true
          fi
          # schedutil tunables
          if [[ -d "$p/schedutil" ]]; then
            echo 1000 | sudo tee "$p/schedutil/up_rate_limit_us" >/dev/null || true
            echo 5000 | sudo tee "$p/schedutil/down_rate_limit_us" >/dev/null || true
            echo 1    | sudo tee "$p/schedutil/iowait_boost_enable" >/dev/null || true
          fi
        done
        # RAPL: 25/32W
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && echo 25000000 | sudo tee "$R/constraint_0_power_limit_uw" >/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && echo 32000000 | sudo tee "$R/constraint_1_power_limit_uw" >/dev/null || true
        done
        echo "✅ Performance mode: governor=$target, min_freq≥1800 MHz, RAPL 25/32W"
      '')

      (writeScriptBin "balanced-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "⚖️ Balanced mode…"
        sudo ${tlp}/bin/tlp start
        GOVS="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")"
        target="powersave"; echo "$GOVS" | ${gnugrep}/bin/grep -qw schedutil && target="schedutil"
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$p/scaling_governor" ]] && echo "$target" | sudo tee "$p/scaling_governor" >/dev/null || true
        done
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          if [[ -w "$p/scaling_min_freq" ]]; then
            echo 1800000 | sudo tee "$p/scaling_min_freq" >/dev/null || true
          fi
          if [[ -d "$p/schedutil" ]]; then
            echo 1000 | sudo tee "$p/schedutil/up_rate_limit_us" >/dev/null || true
            echo 5000 | sudo tee "$p/schedutil/down_rate_limit_us" >/dev/null || true
            echo 1    | sudo tee "$p/schedutil/iowait_boost_enable" >/dev/null || true
          fi
        done
        # RAPL: 22/30W
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && echo 22000000 | sudo tee "$R/constraint_0_power_limit_uw" >/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && echo 30000000 | sudo tee "$R/constraint_1_power_limit_uw" >/dev/null || true
        done
        echo "✅ Balanced mode: governor=$target, min_freq≥1800 MHz, RAPL 22/30W"
      '')

      (writeScriptBin "cool-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "❄️ Cool mode…"
        GOVS="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")"
        target="powersave"; echo "$GOVS" | ${gnugrep}/bin/grep -qw schedutil && target="schedutil"
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$p/scaling_governor" ]] && echo "$target" | sudo tee "$p/scaling_governor" >/dev/null || true
        done
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$p/scaling_min_freq" ]] && echo 1200000 | sudo tee "$p/scaling_min_freq" >/dev/null || true
          if [[ -d "$p/schedutil" ]]; then
            echo 1000 | sudo tee "$p/schedutil/up_rate_limit_us" >/dev/null || true
            echo 7000 | sudo tee "$p/schedutil/down_rate_limit_us" >/dev/null || true
            echo 1    | sudo tee "$p/schedutil/iowait_boost_enable" >/dev/null || true
          fi
        done
        # RAPL: 18/25W
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && echo 18000000 | sudo tee "$R/constraint_0_power_limit_uw" >/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && echo 25000000 | sudo tee "$R/constraint_1_power_limit_uw" >/dev/null || true
        done
        echo "✅ Cool mode: governor=$target, min_freq=1200 MHz, RAPL 18/25W"
      '')

      (writeScriptBin "power-status" ''
        #!${bash}/bin/bash
        echo "==== Power Status ===="
        sudo ${tlp}/bin/tlp-stat -s -c -p | head -40
      '')

      (writeScriptBin "perf-mode" ''
        #!${bash}/bin/bash
        set -euo pipefail
        cmd="''${1:-status}"
        show_status() {
          CPU="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.gnused}/bin/sed 's/^ *//')"
          GOV="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo n/a)"
          PWR="BAT"; for PS in /sys/class/power_supply/A{C,DP}*/online; do [ -f "$PS" ] && [ "$(cat "$PS")" = "1" ] && PWR="AC" && break; done
          echo "CPU: $CPU"
          echo "Power: $PWR"
          echo "Governor: $GOV"
          echo "Frequencies (first 12 cores):"
          i=0
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
            [ -f "$f" ] || continue
            mhz=$(( $(cat "$f") / 1000 ))
            printf "  %02d: %4d MHz\n" "$i" "$mhz"
            i=$((i+1)); [ $i -ge 12 ] && break
          done
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            pl1="$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)"
            pl2="$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)"
            [ "$pl1" != "0" ] && echo "PL1: $((pl1/1000000)) W"
            [ "$pl2" != "0" ] && echo "PL2: $((pl2/1000000)) W"
          fi
          TEMP_RAW="$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep -m1 -E 'Package id 0|Tctl' || true)"
          TEMP="$(echo "$TEMP_RAW" | ${pkgs.gnused}/bin/sed -E 's/.*: *\+?([0-9]+\.?[0-9]*)°C.*/\1°C/' )"
          [[ -z "$TEMP" ]] && TEMP="n/a"
          echo "CPU Temp: $TEMP"
        }
        case "$cmd" in
          status) show_status ;;
          perf)   performance-mode ;;
          bal)    balanced-mode ;;
          cool)   cool-mode ;;
          *) echo "Usage: perf-mode {status|perf|bal|cool}"; exit 2;;
        esac
      '')

      (writeScriptBin "thermal-monitor" ''
        #!${bash}/bin/bash
        echo "Monitoring thermals… (Ctrl+C ile çık)"
        watch -n 1 bash -c "${pkgs.lm_sensors}/bin/sensors | ${pkgs.gnugrep}/bin/grep -E 'Package|Tctl|fan' && echo && \
          for f in /sys/class/powercap/intel-rapl:0/constraint_*_power_limit_uw; do \
            [ -f \"\$f\" ] && echo \"\$(basename \"\$f\" | cut -d_ -f1-2): \$((\$(cat \"\$f\")/1000000))W\"; \
          done"
      '')
    ];
}
