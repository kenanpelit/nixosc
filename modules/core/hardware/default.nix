# modules/core/hardware/default.nix
# ==============================================================================
# Advanced Hardware and Power Management Configuration
# ==============================================================================
# Comprehensive hardware optimization for ThinkPad systems with intelligent
# runtime detection and adaptive power management strategies.
#
# Supported Systems:
# - ThinkPad X1 Carbon 6th (Intel Core i7-8650U, 16GB RAM)
# - ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, 64GB RAM)
#
# Version: 3.7.0
# Author:  Kenan Pelit
# Date:    2025-08-27
#
# Özet:
# - Fan kontrol: thinkfan (güvenilir & ThinkPad’e uygun)
# - CPU RAPL limitleri: model + güç kaynağına göre
# - Governor/EPP: AC’de agresif, bataryada dengeli
# - Termal, pil eşikleri ve günlükler optimize
# ==============================================================================

{ config, lib, pkgs, ... }:

let
  # ----------------------------------------------------------------------------
  # CPU ALGILAMA (güvenli, sade)
  # Dönüş: "meteorlake" | "kabylaker"
  # ----------------------------------------------------------------------------
  detectCpuScript = pkgs.writeShellScript "detect-cpu" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.coreutils}/bin/tr -s ' ' | ${pkgs.coreutils}/bin/tr -d '\n')"
    if echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core *Ultra|155H|Meteor *Lake'; then
      echo "meteorlake"
    elif echo "$MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '8650U|8550U|8350U|8250U|Kaby *Lake'; then
      echo "kabylaker"
    else
      echo "kabylaker"  # güvenli varsayılan
    fi
  '';

  # ----------------------------------------------------------------------------
  # CPU PROFİLLERİ (Watt cinsinden PL1/PL2 + pil eşikleri)
  # ----------------------------------------------------------------------------
  meteorLake = {
    battery = { pl1 = 28; pl2 = 40; };
    ac      = { pl1 = 40; pl2 = 55; };
    thermal = { trip = 85; tripAc = 90; warning = 92; critical = 100; };
    battery_threshold = { start = 60; stop = 80; };
  };

  kabyLakeR = {
    battery = { pl1 = 15; pl2 = 25; };
    ac      = { pl1 = 25; pl2 = 35; };
    thermal = { trip = 78; tripAc = 82; warning = 85; critical = 90; };
    battery_threshold = { start = 75; stop = 80; };
  };

  systemctl = "${pkgs.systemd}/bin/systemctl";
in
{
  # =============================================================================
  # DONANIM
  # =============================================================================
  hardware = {
    trackpoint = { enable = true; speed = 200; sensitivity = 200; emulateWheel = true; };

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
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings.General = {
        FastConnectable = false;
        ReconnectAttempts = 7;
        ReconnectIntervals = "1,2,4,8,16,32,64";
      };
    };
  };

  # =============================================================================
  # SERVİSLER (Güç & Termal)
  # =============================================================================
  services = {
    # Termal yönetim (fanı thinkfan yönetiyor)
    thermald.enable = true;

    # Çakışma önle: sadece thinkfan + thermald
    power-profiles-daemon.enable = false;
    tlp.enable = false;

    # ThinkFan – istikrarlı ThinkPad fan kontrolü
    thinkfan = {
      enable = true;
      smartSupport = true;  # NVMe/disk sensörlerini de kullanabilir
      # Dengeli & sessiz, ısı yükselince çevik
      levels = [
        # [fan_level  lower°C  upper°C]
        [0  0   45]
        [1  42  52]
        [2  48  58]
        [3  54  64]
        [4  60  70]
        [5  66  76]
        [6  72  82]
        [7  78  32767]
      ];
    };

    # Pil – güvenli eşikler
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      usePercentageForPolicy = true;
    };

    # logind – kapak/tuş davranışları
    logind.settings.Login = {
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "poweroff";
      HandleSuspendKey = "suspend";
      HandleHibernateKey = "hibernate";
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      IdleAction = "ignore";
      IdleActionSec = "30min";
      InhibitDelayMaxSec = "5";
      InhibitorsMax = "8192";
      UserTasksMax = "33%";
      RuntimeDirectorySize = "50%";
      RemoveIPC = "yes";
    };

    # journald – SSD dostu sınırlar
    journald.extraConfig = ''
      SystemMaxUse=2G
      SystemMaxFileSize=100M
      MaxRetentionSec=1week
      MaxFileSec=1day
      SyncIntervalSec=30
      RateLimitIntervalSec=30
      RateLimitBurst=1000
      Compress=yes
      ForwardToSyslog=no
    '';

    # Daha modern DBus
    dbus = { implementation = "broker"; packages = [ pkgs.dconf ]; };
  };

  # =============================================================================
  # BOOT & KERNEL
  # =============================================================================
  boot = {
    kernelModules = [ "thinkpad_acpi" "coretemp" "intel_rapl" "msr" "kvm-intel" "i915" ];

    extraModprobeConfig = ''
      # ThinkPad ACPI – kullanıcı alanı fan kontrolü
      options thinkpad_acpi fan_control=1 brightness_mode=1 volume_mode=1 experimental=1

      # Intel P-state
      options intel_pstate hwp_dynamic_boost=0

      # Ses güç tasarrufu
      options snd_hda_intel power_save=10 power_save_controller=Y

      # Wi-Fi güç tasarrufu
      options iwlwifi power_save=1 power_level=3
      options iwlmvm power_scheme=3

      # USB autosuspend
      options usbcore autosuspend=5
    '';

    kernelParams = [
      # IOMMU
      "intel_iommu=on" "iommu=pt"

      # intel_pstate = active → governor/EPP çalışır
      "intel_pstate=active"

      # NVMe dengesi
      "nvme_core.default_ps_max_latency_us=5500"

      # i915 iyileştirmeler
      "i915.enable_guc=3" "i915.enable_fbc=1" "i915.enable_psr=1" "i915.fastboot=1" "i915.enable_sagv=1"

      # PCIe güç
      "pcie_aspm=default"

      # Wi-Fi debug kapalı
      "iwlwifi.debug=0x0"
    ];

    kernel.sysctl = {
      # Bellek
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_ratio" = 10;
      "vm.laptop_mode" = 5;
      "vm.page-cluster" = 0;
      "vm.compact_unevictable_allowed" = 1;

      # Planlayıcı / genel
      "kernel.nmi_watchdog" = 0;
      "kernel.sched_autogroup_enabled" = 1;
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
    };
  };

  # =============================================================================
  # systemd SERVİSLER – RAPL + Governor/EPP + LED + Pil eşikleri
  # =============================================================================
  systemd.services = {
    # --------------------------------------------------------------------------
    # RAPL LIMIT + GOVERNOR/EPP AYARI
    # AC↔︎Batarya değişiminde udev tetikliyor (aşağıya bak)
    # --------------------------------------------------------------------------
    cpu-power-limit = {
      description = "Apply Intel RAPL power limits per CPU profile & power source";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          sleep 2  # sysfs sakinleşsin

          CPU_TYPE="$(${detectCpuScript})"
          RAPL="/sys/class/powercap/intel-rapl:0"
          [[ -d "$RAPL" ]] || { echo "RAPL not available"; exit 0; }

          # Güç kaynağı (AC=1 / Batarya=0)
          ON_AC=0
          for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/AC/online /sys/class/power_supply/AC0/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
          done

          # RAPL yazıcı
          apply_limits () {
            local PL1_W="$1" PL2_W="$2" TW1_US="$3" TW2_US="$4"
            echo $(( PL1_W * 1000000 )) > "$RAPL/constraint_0_power_limit_uw" || true
            echo $(( PL2_W * 1000000 )) > "$RAPL/constraint_1_power_limit_uw" || true
            echo "$TW1_US" > "$RAPL/constraint_0_time_window_us" || true
            echo "$TW2_US" > "$RAPL/constraint_1_time_window_us" || true
            echo "RAPL set: PL1=''${PL1_W}W PL2=''${PL2_W}W (AC=$ON_AC)"
          }

          # Governor & EPP (intel_pstate=active)
          set_governor_epp () {
            local GOV="$1" EPP="$2" MIN="$3"
            for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
              echo "$GOV" > "$g" 2>/dev/null || true
            done
            for p in /sys/devices/system/cpu/cpufreq/policy*; do
              echo "$EPP" > "$p/energy_performance_preference" 2>/dev/null || true
              if [[ -n "$MIN" ]]; then
                echo "$MIN" > "$p/scaling_min_freq" 2>/dev/null || true
              fi
              if [[ -f "$p/cpuinfo_max_freq" ]]; then
                cat "$p/cpuinfo_max_freq" > "$p/scaling_max_freq" 2>/dev/null || true
              fi
            done
            # Turbo açık (0 = turbo enabled)
            echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
          }

          # Model + güç kaynağına göre uygula
          if [[ "$CPU_TYPE" == "meteorlake" ]]; then
            if [[ "$ON_AC" == "1" ]]; then
              apply_limits ${toString meteorLake.ac.pl1} ${toString meteorLake.ac.pl2} 28000000 10000
              set_governor_epp performance balance_performance 1600000
            else
              apply_limits ${toString meteorLake.battery.pl1} ${toString meteorLake.battery.pl2} 28000000 10000
              set_governor_epp performance balance_power 800000
            fi
          else
            if [[ "$ON_AC" == "1" ]]; then
              apply_limits ${toString kabyLakeR.ac.pl1} ${toString kabyLakeR.ac.pl2} 28000000 10000
              set_governor_epp performance balance_performance 1400000
            else
              apply_limits ${toString kabyLakeR.battery.pl1} ${toString kabyLakeR.battery.pl2} 28000000 10000
              set_governor_epp powersave power 800000
            fi
          fi

          echo "Governor/EPP applied (AC=$ON_AC, CPU=$CPU_TYPE)"
        '';
      };
    };

    # LED durumları
    fix-led-state = {
      description = "Configure ThinkPad LED states";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "fix-leds" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          if [[ -d /sys/class/leds/platform::micmute ]]; then
            echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          fi
          if [[ -d /sys/class/leds/platform::mute ]]; then
            echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
          fi
          if [[ -d /sys/class/leds/tpacpi::lid_logo_dot ]]; then
            echo 0 > /sys/class/leds/tpacpi::lid_logo_dot/brightness 2>/dev/null || true
          fi
        '';
      };
    };

    # Pil şarj eşikleri
    battery-charge-threshold = {
      description = "Configure battery charge thresholds (BAT0)";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "battery-threshold" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          BAT="/sys/class/power_supply/BAT0"
          [[ -d "$BAT" ]] || { echo "Battery not found"; exit 0; }

          CPU_TYPE="$(${detectCpuScript})"
          if [[ "$CPU_TYPE" == "meteorlake" ]]; then
            START=${toString meteorLake.battery_threshold.start}
            STOP=${toString meteorLake.battery_threshold.stop}
          else
            START=${toString kabyLakeR.battery_threshold.start}
            STOP=${toString kabyLakeR.battery_threshold.stop}
          fi

          CUR_START="$(cat "$BAT/charge_control_start_threshold" 2>/dev/null || echo 0)"
          CUR_STOP="$(cat "$BAT/charge_control_end_threshold" 2>/dev/null || echo 100)"

          [[ "$CUR_START" = "$START" ]] || { echo "$START" > "$BAT/charge_control_start_threshold" || true; }
          [[ "$CUR_STOP"  = "$STOP"  ]] || { echo "$STOP"  > "$BAT/charge_control_end_threshold"  || true; }

          echo "Battery thresholds → Start=$START% Stop=$STOP%"
        '';
      };
    };
  };

  # =============================================================================
  # UDEV KURALLARI – AC değişiminde RAPL/governor’i uygula
  # =============================================================================
  services.udev.extraRules = lib.mkAfter ''
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/class/leds/%k/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute",    ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/class/leds/%k/brightness"

    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTR{power/control}="on"

    # AC adaptör online/offline → cpu-power-limit koşsun
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", RUN+="${systemctl} start cpu-power-limit.service"
  '';

  # =============================================================================
  # ORTAM & ARAÇLAR
  # =============================================================================
  environment = {
    systemPackages = with pkgs; [ lm_sensors powertop intel-gpu-tools ];

    shellAliases = {
      battery-status = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
      battery-info = ''
        echo "=== Battery Status ===" && \
        upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|percentage|time to|capacity" && \
        echo -e "\n=== Charge Thresholds ===" && \
        echo "Start: $(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null || echo 'N/A')%" && \
        echo "Stop:  $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold   2>/dev/null || echo 'N/A')%"
      '';

      power-report = "sudo powertop --html=power-report-$(date +%Y%m%d-%H%M).html --time=10 && echo 'Power report saved'";
      power-usage  = "sudo powertop";

      thermal-status = ''
        echo "=== Thermal Status ==="
        sensors 2>/dev/null || echo "lm-sensors not available"
        echo
        echo "=== ACPI Thermal ==="
        cat /proc/acpi/ibm/thermal 2>/dev/null || echo "ThinkPad ACPI thermal not available"
        echo
        echo "=== Thermal Zones ==="
        for z in /sys/class/thermal/thermal_zone*/temp; do
          [[ -r "$z" ]] || continue
          t=$(cat "$z"); printf "%s: %s°C\n" "$(basename "$(dirname "$z")")" "$((t/1000))"
        done
      '';

      cpu-freq = ''
        echo "=== CPU Frequency ==="
        grep "cpu MHz" /proc/cpuinfo | awk '{print "Core " NR-1 ": " $4 " MHz"}'
        echo
        echo "=== Governor ==="
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
      '';

      cpu-type = "${detectCpuScript}";

      perf-summary = ''
        echo "=== System Performance ==="
        echo "CPU: $(${detectCpuScript})"
        echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
        echo "Memory: $(free -h | awk "/^Mem:/ {print \$3 \" / \" \$2}")"
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
      '';
    };

    variables = {
      VDPAU_DRIVER = "va_gl";
      LIBVA_DRIVER_NAME = "iHD";
    };

    # fancontrol kullanılmıyor
    etc.fancontrol.enable = false;
  };

  # =============================================================================
  # ZRAM
  # =============================================================================
  zramSwap = {
    enable = true;
    priority = 5000;
    algorithm = "zstd";
    memoryPercent = lib.mkDefault 30;
  };
}
