# modules/core/power/default.nix
# ==============================================================================
# ThinkPad E14 Gen 6 Kapsamlı Donanım ve Güç Yönetimi
# ==============================================================================
# Bu modül ThinkPad E14 Gen 6 için optimize edilmiş donanım ve güç yönetimi sağlar:
#
# Donanım Özellikleri:
# - ThinkPad-spesifik ACPI ve termal yönetim
# - Intel Arc Graphics sürücüleri ve hardware acceleration
# - NVMe depolama optimizasyonları (dual-drive setup)
# - Intel Core Ultra 7 155H CPU termal ve güç yönetimi
# - LED kontrol ve fonksiyon tuş yönetimi
# - TrackPoint ve touchpad konfigürasyonu
#
# Güç Yönetimi Özellikleri:
# - Akıllı pil yönetimi ve şarj eşikleri (60-80%)
# - Adaptif WiFi güç tasarrufu (AC/battery modları)
# - USB auto-suspend ve güç optimizasyonu
# - Logind ile kullanıcı etkileşimi yönetimi
# - Sistem geneli güç politikaları
# - Bluetooth güç tasarrufu
#
# Hedef Donanım:
# - ThinkPad E14 Gen 6 (21M7006LTX)
# - Intel Core Ultra 7 155H (16-core hybrid architecture)
# - Intel Arc Graphics (Meteor Lake-P)
# - 64GB DDR5 RAM
# - Dual NVMe: Transcend TS2TMTE400S + Timetec 35TT2280GEN4E-2TB
#
# Performans Hedefleri:
# - CPU Sıcaklık: 75-85°C yük altında
# - Fan Gürültüsü: Dengeli (progressive curve)
# - Güç Tüketimi: 35W sürekli, 45W burst
#
# Yazar: Kenan Pelit
# Son Güncelleme: 2025-08-25 (Birleştirilmiş ve optimize edilmiş versiyon)
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # Kullanıcı UID'sini dinamik al
  mainUser = builtins.head (builtins.attrNames config.users.users);
  userUid = toString config.users.users.${mainUser}.uid;
in
{
  # ==============================================================================
  # Donanım Konfigürasyonu
  # ==============================================================================
  hardware = {
    # Enable TrackPoint for ThinkPad
    trackpoint.enable = true;
    
    # Intel Arc Graphics configuration for Meteor Lake
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver      # VA-API implementation
        vaapiVdpau             # VDPAU backend for VA-API
        libvdpau-va-gl         # VDPAU driver with OpenGL/VAAPI backend
        mesa                   # OpenGL implementation
        intel-compute-runtime  # OpenCL runtime for Intel GPUs
        intel-ocl             # OpenCL implementation
      ];
    };
    
    # Firmware configuration
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
  };
  
  # ==============================================================================
  # Termal ve Güç Yönetimi Servisleri
  # ==============================================================================
  services = {
    # Lenovo throttling fix with optimized thermal management
    throttled = {
      enable = true;
      extraConfig = ''
        [GENERAL]
        Enabled: True
        Sysfs_Power_Path: /sys/class/power_supply/AC*/online
        Autoreload: True

        [BATTERY]
        Update_Rate_s: 30
        PL1_Tdp_W: 25
        PL1_Duration_s: 28
        PL2_Tdp_W: 35
        PL2_Duration_S: 0.002
        Trip_Temp_C: 80

        [AC]
        Update_Rate_s: 5
        PL1_Tdp_W: 35
        PL1_Duration_s: 28
        PL2_Tdp_W: 45
        PL2_Duration_S: 0.002
        Trip_Temp_C: 85

        [UNDERVOLT.BATTERY]
        CORE: 0
        GPU: 0
        CACHE: 0
        UNCORE: 0
        ANALOGIO: 0

        [UNDERVOLT.AC]
        CORE: 0
        GPU: 0
        CACHE: 0
        UNCORE: 0
        ANALOGIO: 0
      '';
    };

    # Modern CPU frequency management with balanced thermal controls
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          scaling_min_freq = 400000;
          scaling_max_freq = 2800000;
          turbo = "never";
        };
        charger = {
          governor = "powersave";
          scaling_min_freq = 400000;
          scaling_max_freq = 3800000;
          turbo = "auto";
        };
      };
    };

    # ThinkPad fan control - disabled, using throttled + auto-cpufreq
    thinkfan.enable = false;
    
    # Intel thermal daemon - disabled due to Meteor Lake compatibility
    thermald.enable = false;

    # Power management services
    power-profiles-daemon.enable = false;
    tlp.enable = false;

    # UPower konfigürasyonu - akıllı pil yönetimi
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      usePercentageForPolicy = true;
    };
    
    # Logind - kullanıcı etkileşimi ve güç olayları yönetimi
    logind = {
      lidSwitch = "suspend";
      lidSwitchDocked = "suspend";  
      lidSwitchExternalPower = "suspend";
      
      extraConfig = ''
        HandlePowerKey=ignore
        HandleSuspendKey=suspend
        HandleHibernateKey=hibernate
        HandleLidSwitch=suspend
        HandleLidSwitchDocked=suspend
        HandleLidSwitchExternalPower=suspend
        IdleAction=ignore
        IdleActionSec=30min
        InhibitDelayMaxSec=5
        HandleSuspendLock=delay
        KillUserProcesses=no
        RemoveIPC=yes
      '';
    };
    
    # Bluetooth güç yönetimi
    blueman.enable = true;
    
    # Sistem günlük yönetimi - güç odaklı
    journald.extraConfig = ''
      SystemMaxUse=3G
      SystemMaxFileSize=200M
      MaxRetentionSec=2weeks
      SyncIntervalSec=60
      RateLimitIntervalSec=10
      RateLimitBurst=200
    '';
    
    # D-Bus optimizasyonları
    dbus.implementation = "broker";
  };
  
  # ==============================================================================
  # Boot Konfigürasyonu
  # ==============================================================================
  boot = {
    # Essential kernel modules for hardware monitoring and control
    kernelModules = [ 
      "thinkpad_acpi"
      "coretemp"
      "intel_rapl"
      "msr"
    ];
    
    # Module options for ThinkPad-specific features
    extraModprobeConfig = ''
      options thinkpad_acpi fan_control=1
      options thinkpad_acpi brightness_mode=1
      options thinkpad_acpi volume_mode=1
      options thinkpad_acpi experimental=1
      options intel_pstate hwp_dynamic_boost=0
    '';
    
    # Kernel parameters for optimized thermal and power management
    kernelParams = [
      "nvme.noacpi=1"
      "intel_iommu=on"
      "iommu=pt"
      "intel_pstate=passive"
      "processor.max_cstate=3"
      "intel_idle.max_cstate=3"
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
      "i915.enable_dc=2"
      "i915.fastboot=1"
      "thermal.off=0"
      "thermal.act=-1"
      "thermal.nocrt=0"
      "thermal.psv=-1"
      "transparent_hugepage=madvise"
      "mitigations=auto"
    ];
  };
  
  # ==============================================================================
  # Systemd Servisleri
  # ==============================================================================
  systemd.services = {
    # CPU power limit service for thermal control
    cpu-power-limit = {
      description = "Set Intel RAPL power limits for thermal management";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          #!/usr/bin/env sh
          sleep 2
          
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            ON_AC=0
            if [ -f /sys/class/power_supply/AC/online ]; then
              ON_AC=$(cat /sys/class/power_supply/AC/online)
            fi
            
            if [ "$ON_AC" = "1" ]; then
              echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo 45000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Intel RAPL power limits set (AC): PL1=35W, PL2=45W"
            else
              echo 25000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Intel RAPL power limits set (Battery): PL1=25W, PL2=35W"
            fi
            
            echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us
            echo 2500 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us
          else
            echo "Intel RAPL interface not available"
          fi
        '';
      };
    };
    
    # Fix LED state on boot for ThinkPad E14 Gen 6
    fix-led-state = {
      description = "Fix ThinkPad LED states on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "fix-leds" ''
          #!/usr/bin/env sh
          if [ -d /sys/class/leds/platform::micmute ]; then
            echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          fi
          
          if [ -d /sys/class/leds/platform::mute ]; then
            echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
          fi
        '';
        RemainAfterExit = true;
      };
    };
    
    # Thermal monitoring service with adaptive warnings
    thermal-monitor = {
      description = "Monitor system thermal status and log warnings";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "thermal-monitor" ''
          #!/usr/bin/env sh
          WARNING_THRESHOLD=88
          CRITICAL_THRESHOLD=95
          
          while true; do
            TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
            if [ -n "$TEMP" ]; then
              TEMP_C=$((TEMP / 1000))
              
              if [ "$TEMP_C" -gt "$CRITICAL_THRESHOLD" ]; then
                echo "CRITICAL: CPU temperature: $${TEMP_C}°C - System may throttle severely"
                logger -p user.crit -t thermal-monitor "Critical CPU temperature: $${TEMP_C}°C"
              elif [ "$TEMP_C" -gt "$WARNING_THRESHOLD" ]; then
                echo "WARNING: High CPU temperature: $${TEMP_C}°C - Performance may be reduced"
                logger -p user.warning -t thermal-monitor "High CPU temperature: $${TEMP_C}°C"
              fi
            fi
            
            sleep 30
          done
        '';
        Restart = "always";
        RestartSec = 10;
      };
    };

    # WiFi güç yönetimi - AC/pil durumuna göre
    adaptive-wifi-power-save = {
      description = "Adaptive WiFi power management based on power source";
      after = [ "NetworkManager.service" "multi-user.target" ];
      wants = [ "NetworkManager.service" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ networkmanager iw coreutils util-linux ];
      
      script = ''
        WIFI_INTERFACE=$(ls /sys/class/net/ | grep -E '^(wl|wlan)' | head -1)
        if [ -z "$WIFI_INTERFACE" ]; then
          echo "WiFi interface bulunamadı"
          exit 0
        fi
        
        ON_AC=0
        for ac_path in /sys/class/power_supply/A{C,DP}*; do
          [ -f "$ac_path/online" ] && [ "$(cat "$ac_path/online" 2>/dev/null)" = "1" ] && ON_AC=1 && break
        done
        
        if [ "$ON_AC" = "1" ]; then
          ${pkgs.networkmanager}/bin/nmcli connection modify type wifi wifi.powersave 2 2>/dev/null || true
          ${pkgs.iw}/bin/iw dev "$WIFI_INTERFACE" set power_save off 2>/dev/null || true
          echo "AC Mode: WiFi power save disabled for performance"
        else
          ${pkgs.networkmanager}/bin/nmcli connection modify type wifi wifi.powersave 3 2>/dev/null || true
          ${pkgs.iw}/bin/iw dev "$WIFI_INTERFACE" set power_save on 2>/dev/null || true
          echo "Battery Mode: WiFi power save enabled for efficiency"
        fi
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };
    
    # ThinkPad pil eşikleri
    thinkpad-battery-thresholds = {
      description = "Set ThinkPad battery charge thresholds for longevity";
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ coreutils util-linux ];
      
      script = ''
        BATTERY_PATH="/sys/class/power_supply/BAT0"
        
        if [ -d "$BATTERY_PATH" ]; then
          if [ -w "$BATTERY_PATH/charge_control_start_threshold" ]; then
            echo 60 > "$BATTERY_PATH/charge_control_start_threshold" 2>/dev/null || true
            echo "ThinkPad pil başlangıç eşiği: 60%"
          fi
          
          if [ -w "$BATTERY_PATH/charge_control_end_threshold" ]; then
            echo 80 > "$BATTERY_PATH/charge_control_end_threshold" 2>/dev/null || true  
            echo "ThinkPad pil bitiş eşiği: 80%"
          fi
          
          if [ -f "$BATTERY_PATH/capacity" ]; then
            BATTERY_LEVEL=$(cat "$BATTERY_PATH/capacity")
            BATTERY_STATUS=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")
            echo "Pil durumu: %$BATTERY_LEVEL ($BATTERY_STATUS)"
          fi
        else
          echo "ThinkPad pil yönetimi bulunamadı"
        fi
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
    };
    
    # USB güç yönetimi
    usb-power-management = {
      description = "Enable USB auto-suspend for all devices";
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ coreutils ];
      
      script = ''
        for usb_device in /sys/bus/usb/devices/*/power/control; do
          if [ -w "$usb_device" ]; then
            echo "auto" > "$usb_device" 2>/dev/null || true
          fi
        done
        
        for usb_device in /sys/bus/usb/devices/*/power/autosuspend_delay_ms; do
          if [ -w "$usb_device" ]; then
            echo "2000" > "$usb_device" 2>/dev/null || true
          fi
        done
        
        echo "USB auto-suspend enabled for all devices"
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
    };
    
    # Güç kaynağı değişiklik izleyicisi
    power-source-monitor = {
      description = "Monitor power source changes and adjust system accordingly";
      after = [ "multi-user.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ coreutils systemd ];
      
      script = ''
        LAST_STATE=""
        
        while true; do
          CURRENT_STATE="BATTERY"
          for ac_path in /sys/class/power_supply/A{C,DP}*; do
            if [ -f "$ac_path/online" ] && [ "$(cat "$ac_path/online" 2>/dev/null)" = "1" ]; then
              CURRENT_STATE="AC"
              break
            fi
          done
          
          if [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
            echo "Power source changed: $LAST_STATE -> $CURRENT_STATE"
            systemctl restart adaptive-wifi-power-save.service 2>/dev/null || true
            LAST_STATE="$CURRENT_STATE"
          fi
          
          sleep 30
        done
      '';
      
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10s";
        User = "root";
      };
    };
  };

  systemd.user.services = {
    # Kullanıcı servisleri - bildirimler
    power-status-notifications = {
      description = "Power status notifications for user";
      after = [ "graphical-session.target" ];
      bindsTo = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];
      
      environment = {
        WAYLAND_DISPLAY = "wayland-1";
        XDG_RUNTIME_DIR = "/run/user/${userUid}";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/${userUid}/bus";
      };
      
      path = with pkgs; [ libnotify coreutils ];
      
      script = ''
        sleep 5
        
        if [ -f /sys/class/power_supply/BAT0/capacity ]; then
          BATTERY_LEVEL=$(cat /sys/class/power_supply/BAT0/capacity)
          BATTERY_STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")
          
          POWER_SOURCE="Pil"
          for ac_path in /sys/class/power_supply/A{C,DP}*; do
            if [ -f "$ac_path/online" ] && [ "$(cat "$ac_path/online" 2>/dev/null)" = "1" ]; then
              POWER_SOURCE="AC Adaptör"
              break
            fi
          done
          
          WIFI_STATUS="Unknown"
          WIFI_INTERFACE=$(ls /sys/class/net/ 2>/dev/null | grep -E '^(wl|wlan)' | head -1)
          if [ -n "$WIFI_INTERFACE" ] && command -v iw >/dev/null 2>&1; then
            if iw dev "$WIFI_INTERFACE" get power_save 2>/dev/null | grep -q "Power save: on"; then
              WIFI_PS="Etkin"
            else
              WIFI_PS="Devre Dışı"
            fi
            WIFI_STATUS="WiFi güç tasarrufu: $WIFI_PS"
          fi
          
          notify-send -t 8000 -i battery "Güç Yönetimi Başlatıldı" \
            "🔋 Pil: %$BATTERY_LEVEL ($BATTERY_STATUS)
⚡ Kaynak: $POWER_SOURCE
📡 $WIFI_STATUS
🔧 Optimize güç profili aktif"
        fi
      '';
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
  
  # ==============================================================================
  # Udev Kuralları
  # ==============================================================================
  services.udev.extraRules = ''
    # Fix microphone LED permissions and initial state
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::micmute/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::mute/brightness"
    
    # Dynamic CPU governor switching based on power source
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
    
    # Adjust RAPL power limits on power source change
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service"
    
    # Pil eşiklerini güç kaynağı değişikliklerinde güncelle
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="0", RUN+="${pkgs.systemd}/bin/systemctl restart thinkpad-battery-thresholds.service"
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart thinkpad-battery-thresholds.service"
    
    # WiFi güç yönetimini güç kaynağı değişikliklerinde ayarla
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="0", RUN+="${pkgs.systemd}/bin/systemctl restart adaptive-wifi-power-save.service"
    SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart adaptive-wifi-power-save.service"
    
    # USB cihaz takıldığında otomatik power management
    ACTION=="add", SUBSYSTEM=="usb", RUN+="${pkgs.systemd}/bin/systemctl restart usb-power-management.service"
    
    # Bluetooth cihazlar için güç yönetimi
    ACTION=="add", SUBSYSTEM=="bluetooth", ATTR{power/control}="auto"
    
    # ThinkPad özel tuşlar için güç yönetimi
    ACTION=="add", SUBSYSTEM=="platform", DRIVER=="thinkpad_acpi", RUN+="${pkgs.systemd}/bin/systemctl restart thinkpad-battery-thresholds.service"
  '';
  
  # ==============================================================================
  # Ek Konfigürasyonlar
  # ==============================================================================
  environment.shellAliases = {
    battery-status = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
    power-usage = "sudo powertop --html=power-report.html --time=10";
    thermal-status = "sensors && cat /sys/class/thermal/thermal_zone*/temp";
  };
  
  services.logrotate.settings."power-management" = {
    files = [ "/var/log/power-*.log" ];
    frequency = "weekly";
    rotate = 4;
    compress = true;
    delaycompress = true;
    missingok = true;
    notifempty = true;
    create = "644 root root";
  };
}

