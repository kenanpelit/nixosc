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
# Versiyon: 3.4.0
# Yazar:    Kenan Pelit
# Tarih:    2025-08-27
# ==============================================================================

{ config, lib, pkgs, ... }:

let
  # ----------------------------------------------------------------------------
  # CPU algılama: lscpu çıktısından model adına göre sınıflandır.
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
      echo "kabylaker"
    fi
  '';

  # CPU profilleri (Watt cinsinden)
  meteorLake = {
    battery = { pl1 = 28; pl2 = 40; maxFreq = 3200000; minFreq = 600000; };
    ac      = { pl1 = 40; pl2 = 55; maxFreq = 4200000; minFreq = 800000; };
    thermal = { trip = 85; tripAc = 90; warning = 92; critical = 100; };
    battery_threshold = { start = 60; stop = 80; };
    undervolt = { core = 0; gpu = 0; cache = 0; uncore = 0; analogio = 0; };
  };

  kabyLakeR = {
    battery = { pl1 = 15; pl2 = 25; maxFreq = 2400000; minFreq = 400000; };
    ac      = { pl1 = 25; pl2 = 35; maxFreq = 3800000; minFreq = 400000; };
    thermal = { trip = 78; tripAc = 82; warning = 85; critical = 90; };
    battery_threshold = { start = 75; stop = 80; };
    undervolt = { core = -80; gpu = -60; cache = -80; uncore = -40; analogio = -25; };
  };

  systemctl = "${pkgs.systemd}/bin/systemctl";
in
{
  # =============================================================================
  # Donanım
  # =============================================================================
  hardware = {
    trackpoint = {
      enable = true;
      speed = 200;
      sensitivity = 200;
      emulateWheel = true;
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
  # Servisler (Güç & Termal)
  # =============================================================================
  services = {
    # CPU freq otomasyonu (schedutil + passive P-state ile uyumlu)
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "schedutil";
          scaling_min_freq = 800000;
          scaling_max_freq = 3200000;
          turbo = "auto";
          energy_performance_preference = "power";
        };
        charger = {
          governor = "schedutil";
          scaling_min_freq = 1200000;
          scaling_max_freq = 4800000;
          turbo = "always";
          energy_performance_preference = "balance_performance";
        };
      };
    };

    # Isıl yönetim (PL, DVFS vb. için – fan kontrolünü thinkfan yapacak)
    thermald.enable = true;

    # ThinkFan – güvenilir fan kontrolü (ThinkPad)
    thinkfan = {
      enable = true;
      # smart* sensörlerini de kullanabilsin (NVMe, disk vb.)
      smartSupport = true;

      # Sessizlik odaklı fakat yüksüz-kısa yüklerde de reaktif kademeler.
      # [fan_level  lower°C  upper°C]
      # 0 en sessiz; 7 en hızlı. Son satır "level auto" Acpi’nin acil durum mantığını devreye sokar.
      levels = [
        [0  0   50]   # fan kapalı, 50°C’ye kadar pasif
        [1  48  55]
        [2  53  60]
        [3  58  65]
        [4  63  70]
        [5  68  75]
        [6  73  80]
        [7  78  32767]  # tam devir
      ];
    };

    power-profiles-daemon.enable = false;
    tlp.enable = false;

    # UPower – kritik eşikler
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      usePercentageForPolicy = true;
    };

    # logind – kapak ve güç tuşu davranışları
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

    # journald – log hacmini sınırlı tut
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

    # DBus – broker
    dbus = {
      implementation = "broker";
      packages = [ pkgs.dconf ];
    };
  };

  # =============================================================================
  # Boot & Kernel
  # =============================================================================
  boot = {
    kernelModules = [ "thinkpad_acpi" "coretemp" "intel_rapl" "msr" "kvm-intel" "i915" ];

    extraModprobeConfig = ''
      # ThinkPad ACPI – fan kontrolünü user space’e bırak
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
      "intel_iommu=on" "iommu=pt"
      "intel_pstate=passive"
      "nvme_core.default_ps_max_latency_us=5500"
      "i915.enable_guc=3" "i915.enable_fbc=1" "i915.enable_psr=1" "i915.fastboot=1" "i915.enable_sagv=1"
      "pcie_aspm=default"
      "iwlwifi.debug=0x0"
    ];

    # Sysctl ayarları
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_ratio" = 10;
      "vm.laptop_mode" = 5;
      "vm.page-cluster" = 0;
      "vm.compact_unevictable_allowed" = 1;
      "kernel.nmi_watchdog" = 0;
      "kernel.sched_autogroup_enabled" = 1;
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
    };
  };

  # =============================================================================
  # systemd servisleri
  # =============================================================================
  systemd.services = {
    # RAPL güç limitleri (AC/Battery durumuna göre)
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
          sleep 2
          CPU_TYPE="$(${detectCpuScript})"
          echo "Detected CPU: $CPU_TYPE"
          RAPL="/sys/class/powercap/intel-rapl:0"
          if [[ ! -d "$RAPL" ]]; then
            echo "RAPL not available; skipping."
            exit 0
          fi
          ON_AC=0
          for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/AC/online /sys/class/power_supply/AC0/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
          done
          apply_limits () {
            local PL1_W="$1"; local PL2_W="$2"; local TW1_US="$3"; local TW2_US="$4"
            echo $(( PL1_W * 1000000 )) > "$RAPL/constraint_0_power_limit_uw"
            echo $(( PL2_W * 1000000 )) > "$RAPL/constraint_1_power_limit_uw"
            echo "$TW1_US" > "$RAPL/constraint_0_time_window_us"
            echo "$TW2_US" > "$RAPL/constraint_1_time_window_us"
            echo "Applied: PL1=$PL1_W W PL2=$PL2_W W TW1=$TW1_US us TW2=$TW2_US us"
          }
          if [[ "$CPU_TYPE" == "meteorlake" ]]; then
            if [[ "$ON_AC" == "1" ]]; then
              apply_limits ${toString meteorLake.ac.pl1} ${toString meteorLake.ac.pl2} 28000000 10000
            else
              apply_limits ${toString meteorLake.battery.pl1} ${toString meteorLake.battery.pl2} 28000000 10000
            fi
          else
            if [[ "$ON_AC" == "1" ]]; then
              apply_limits ${toString kabyLakeR.ac.pl1} ${toString kabyLakeR.ac.pl2} 28000000 10000
            else
              apply_limits ${toString kabyLakeR.battery.pl1} ${toString kabyLakeR.battery.pl2} 28000000 10000
            fi
          fi
        '';
      };
    };

    # ThinkPad LED durumları
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

    # Pil şarj eşiği yönetimi
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
          [[ -d "$BAT" ]] || { echo "Battery not found."; exit 0; }
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
          if [[ "$CUR_START" != "$START" ]]; then
            echo "$START" > "$BAT/charge_control_start_threshold" || true
            echo "Updated start threshold: $START%"
          fi
          if [[ "$CUR_STOP" != "$STOP" ]]; then
            echo "$STOP" > "$BAT/charge_control_end_threshold" || true
            echo "Updated stop  threshold: $STOP%"
          fi
          echo "Battery thresholds → Start=$START% Stop=$STOP%"
        '';
      };
    };
  };

  # =============================================================================
  # Udev kuralları
  # =============================================================================
  services.udev.extraRules = lib.mkAfter ''
    # LED parlaklığı izinleri
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/class/leds/%k/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute",    ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 664 /sys/class/leds/%k/brightness"

    # USB autosuspend – bazı cihazları hariç tut
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTR{power/control}="on"

    # AC değişiminde RAPL limitlerini yeniden uygula
    SUBSYSTEM=="power_supply", KERNEL=="AC*", ACTION=="change", RUN+="${systemctl} start cpu-power-limit.service"
  '';

  # =============================================================================
  # Ortam / yardımcı araçlar
  # =============================================================================
  environment = {
    systemPackages = with pkgs; [
      lm_sensors
    ];

    shellAliases = {
      battery-status = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
      battery-info = ''
        echo "=== Battery Status ===" && \
        upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|percentage|time to|capacity" && \
        echo -e "\n=== Charge Thresholds ===" && \
        echo "Start: $(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null || echo 'N/A')%" && \
        echo "Stop:  $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold   2>/dev/null || echo 'N/A')%"
      '';
      power-report = "sudo powertop --html=power-report.html --time=10 && echo 'Report saved to power-report.html'";
      power-usage  = "sudo powertop";
      thermal-status = ''
        echo "=== Thermal Status ==="
        sensors 2>/dev/null || echo "lm-sensors not installed"
        echo
        echo "=== Thermal Zones ==="
        for z in /sys/class/thermal/thermal_zone*/temp; do
          [[ -r "$z" ]] || continue
          t=$(cat "$z"); printf "%s: %s°C\n" "$(basename "$(dirname "$z")")" "$((t/1000))"
        done
      '';
      cpu-freq = ''echo "=== CPU Frequency ==="; grep "cpu MHz" /proc/cpuinfo | awk '{print "Core " NR-1 ": " $4 " MHz"}' '';
      cpu-type = "${detectCpuScript}";

      # thinkfan yardımcıları
      thinkfan-status = "systemctl status thinkfan --no-pager";
      thinkfan-restart = "sudo systemctl restart thinkfan";
      thinkfan-log = "journalctl -u thinkfan -b --no-pager";
    };

    variables = {
      VDPAU_DRIVER = "va_gl";
      LIBVA_DRIVER_NAME = "iHD";
    };

    # fancontrol ile ilgili /etc kaydı tutmuyoruz
    etc.fancontrol.enable = false;
  };

  # =============================================================================
  # Zram
  # =============================================================================
  zramSwap = {
    enable = true;
    priority = 5000;
    algorithm = "zstd";
    memoryPercent = lib.mkDefault 30;
  };
}
