# modules/core/power/default.nix
# ==============================================================================
# Kapsamlı Güç Yönetimi Konfigürasyonu (ThinkPad E14 Gen 6)
# ==============================================================================
# Bu konfigürasyon şu güç yönetimi ayarlarını içerir:
# - UPower ve sistem güç politikaları
# - Logind ile kullanıcı etkileşimi yönetimi (kapak, güç tuşu)
# - Akıllı WiFi güç tasarrufu optimizasyonları
# - Pil durumu izleme ve bildirimler
# - Sistem günlük yönetimi ve güç olayları
# - Bluetooth güç tasarrufu
# - USB cihaz güç yönetimi
# - Uykudan uyandırma optimizasyonları
#
# NOT: Donanım-spesifik termal yönetim (thermald, throttled, auto-cpufreq) 
# modules/core/hardware/ modülünde bulunur.
#
# Hedef Sistem: Lenovo ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, 64GB RAM)
# Yazar: Kenan Pelit
# Güncelleme: 2025-08-25 (Temiz ve hatasız versiyon)
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # Kullanıcı UID'sini dinamik al
  mainUser = builtins.head (builtins.attrNames config.users.users);
  userUid = toString config.users.users.${mainUser}.uid;
  userHome = config.users.users.${mainUser}.home;
in
{
  # ==============================================================================
  # Ana Güç Yönetimi Servisleri
  # ==============================================================================
  services = {
    # UPower konfigürasyonu - akıllı pil yönetimi
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
      percentageLow = 20;          # Düşük pil uyarısı %20'de
      percentageCritical = 5;      # Kritik seviye %5'te
      percentageAction = 3;        # Otomatik eylem %3'te
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
        HandleHibernateLock=ignore
        HandleSuspendLock=delay
        KillUserProcesses=no
        KillOnlyUsers=
        KillExcludeUsers=root
        RuntimeDirectorySize=10%
        RemoveIPC=yes
      '';
    };
    
    # Çakışan güç yönetimi servislerini devre dışı bırak
    tlp.enable = false;
    power-profiles-daemon.enable = false;
    
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
      MaxLevelStore=info
      MaxLevelWall=emerg
    '';
    
    # D-Bus güç yönetimi optimizasyonları
    dbus.implementation = "broker";
  };
  
  # ==============================================================================
  # Systemd Servisleri - Temiz ve Basit
  # ==============================================================================
  systemd = {
    services = {
      # WiFi güç yönetimi - AC/pil durumuna göre
      adaptive-wifi-power-save = {
        description = "Adaptive WiFi power management based on power source";
        after = [ "NetworkManager.service" "multi-user.target" ];
        wants = [ "NetworkManager.service" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ networkmanager iw coreutils util-linux ];
        
        script = ''
          # WiFi interface'ini bul
          WIFI_INTERFACE=$(ls /sys/class/net/ | grep -E '^(wl|wlan)' | head -1)
          if [ -z "$WIFI_INTERFACE" ]; then
            echo "WiFi interface bulunamadı"
            exit 0
          fi
          
          # Güç kaynağını tespit et
          ON_AC=0
          for ac_path in /sys/class/power_supply/A{C,DP}*; do
            [ -f "$ac_path/online" ] && [ "$(cat "$ac_path/online" 2>/dev/null)" = "1" ] && ON_AC=1 && break
          done
          
          if [ "$ON_AC" = "1" ]; then
            # AC Power: Performance mode - power save OFF
            ${pkgs.networkmanager}/bin/nmcli connection modify type wifi wifi.powersave 2 2>/dev/null || true
            ${pkgs.iw}/bin/iw dev "$WIFI_INTERFACE" set power_save off 2>/dev/null || true
            echo "AC Mode: WiFi power save disabled for performance"
          else
            # Battery: Efficiency mode - power save ON
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
      
      # ThinkPad pil eşikleri - inline script
      thinkpad-battery-thresholds = {
        description = "Set ThinkPad battery charge thresholds for longevity";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ coreutils util-linux ];
        
        script = ''
          # ThinkPad pil eşiklerini ayarla
          BATTERY_PATH="/sys/class/power_supply/BAT0"
          
          if [ -d "$BATTERY_PATH" ]; then
            # Dosyaların yazılabilir olup olmadığını kontrol et
            if [ -w "$BATTERY_PATH/charge_control_start_threshold" ]; then
              echo 60 > "$BATTERY_PATH/charge_control_start_threshold" 2>/dev/null || true
              echo "ThinkPad pil başlangıç eşiği: 60%"
            fi
            
            if [ -w "$BATTERY_PATH/charge_control_end_threshold" ]; then
              echo 80 > "$BATTERY_PATH/charge_control_end_threshold" 2>/dev/null || true  
              echo "ThinkPad pil bitiş eşiği: 80%"
            fi
            
            # Pil durumunu göster
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
      
      # USB güç yönetimi - basit ve güvenli
      usb-power-management = {
        description = "Enable USB auto-suspend for all devices";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ coreutils ];
        
        script = ''
          # Tüm USB cihazları için autosuspend etkinleştir
          for usb_device in /sys/bus/usb/devices/*/power/control; do
            if [ -w "$usb_device" ]; then
              echo "auto" > "$usb_device" 2>/dev/null || true
            fi
          done
          
          # USB autosuspend delay'i ayarla (2 saniye)
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
      
      # Güç kaynağı değişiklik izleyicisi - basitleştirilmiş
      power-source-monitor = {
        description = "Monitor power source changes and adjust system accordingly";
        after = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [ coreutils systemd ];
        
        script = ''
          # İlk durumu kaydet
          LAST_STATE=""
          
          while true; do
            # Güç durumunu kontrol et
            CURRENT_STATE="BATTERY"
            for ac_path in /sys/class/power_supply/A{C,DP}*; do
              if [ -f "$ac_path/online" ] && [ "$(cat "$ac_path/online" 2>/dev/null)" = "1" ]; then
                CURRENT_STATE="AC"
                break
              fi
            done
            
            # Durum değişmişse servisleri yeniden başlat
            if [ "$CURRENT_STATE" != "$LAST_STATE" ]; then
              echo "Power source changed: $LAST_STATE -> $CURRENT_STATE"
              
              # İlgili servisleri yeniden başlat
              systemctl restart adaptive-wifi-power-save.service 2>/dev/null || true
              
              LAST_STATE="$CURRENT_STATE"
            fi
            
            # 30 saniyede bir kontrol et
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
    
    # Kullanıcı servisleri - bildirimler
    user.services = {
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
          # Desktop environment'ın yüklenmesini bekle
          sleep 5
          
          # Pil durumu bilgisi
          if [ -f /sys/class/power_supply/BAT0/capacity ]; then
            BATTERY_LEVEL=$(cat /sys/class/power_supply/BAT0/capacity)
            BATTERY_STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Unknown")
            
            # AC/Battery durumu
            POWER_SOURCE="Pil"
            for ac_path in /sys/class/power_supply/A{C,DP}*; do
              if [ -f "$ac_path/online" ] && [ "$(cat "$ac_path/online" 2>/dev/null)" = "1" ]; then
                POWER_SOURCE="AC Adaptör"
                break
              fi
            done
            
            # WiFi güç tasarrufu durumu
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
            
            # Bildirim gönder
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
    
    # Sleep hooks - suspend/resume optimizasyonları
    sleep.extraConfig = ''
      [Sleep]
      AllowSuspend=yes
      AllowHibernation=yes
      AllowSuspendThenHibernate=yes
      AllowHybridSleep=no
      HibernateDelaySec=120min
      SuspendState=mem
      HibernateState=disk
      HybridSleepState=disk
    '';
  };
  
  # ==============================================================================
  # Udev Kuralları - Temiz ve Basit
  # ==============================================================================
  services.udev.extraRules = ''
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
 
  # Güç yönetimi scriptleri için sistem aliasları
  environment.shellAliases = {
    battery-status = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
    power-usage = "sudo powertop --html=power-report.html --time=10";
    thermal-status = "sensors && cat /sys/class/thermal/thermal_zone*/temp";
  };
  
  # Güç olayları için özel log rotasyonu
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

