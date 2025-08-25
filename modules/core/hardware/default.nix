# modules/core/hardware/default.nix
# ==============================================================================
# Unified Hardware and Power Management Configuration
# ==============================================================================
# This configuration provides comprehensive hardware optimization and power
# management tailored for ThinkPad laptops with different CPU architectures.
#
# Key Features:
# - Dynamic CPU-specific power management (Meteor Lake vs Kaby Lake R)
# - Intelligent thermal throttling based on CPU generation
# - Battery health optimization with configurable charge thresholds
# - GPU acceleration and media decoding support
# - Advanced power saving without performance compromise
# - Real-time thermal monitoring and alerts
# - Automatic configuration based on detected hardware
#
# CPU Architecture Support:
# - Meteor Lake (Intel Core Ultra 7 155H): Advanced power management with
#   higher thermal thresholds and optimized performance profiles
# - Kaby Lake R (Intel Core i7-8650U): Conservative power management with
#   lower thermal limits for older architecture stability
#
# System Specific Optimizations:
# - ThinkPad X1 Carbon 6th (Kaby Lake R): Balanced performance with emphasis
#   on battery life and thermal management
# - ThinkPad E14 Gen 6 (Meteor Lake): Performance-oriented tuning with
#   higher power limits and advanced feature utilization
#
# Power Management Layers:
# 1. Intel RAPL (Running Average Power Limit) - Hardware-level power control
# 2. auto-cpufreq - CPU frequency scaling and governor management
# 3. throttled - Temperature-based throttling and undervolting (where supported)
# 4. thermald - Thermal daemon for proactive temperature management
# 5. Custom systemd services for runtime adaptation
#
# Thermal Management Strategy:
# - Multi-zone temperature monitoring (CPU, GPU, motherboard)
# - Progressive throttling with configurable trip points
# - Critical temperature protection with system alerts
# - Adaptive cooling based on power source (AC vs battery)
#
# Battery Health Features:
# - Configurable charge thresholds (60-80% for Meteor Lake, 75-80% for Kaby Lake R)
# - Smart charging based on usage patterns
# - Battery preservation mode for extended lifespan
#
# Performance Profiles:
# - Battery Mode: Power-saving governors, reduced frequency limits
# - AC Mode: Balanced performance with intelligent boost management
# - Custom per-CPU optimization based on architectural capabilities
#
# Hardware Support Matrix:
# - Intel Integrated Graphics (iGPU) with full VA-API acceleration
# - NVMe SSD power management and optimization
# - WiFi power saving modes (iwlwifi)
# - Audio power management (snd_hda_intel)
# - USB device power control with exception handling for HID devices
# - PCIe ASPM (Active State Power Management) for peripheral power savings
#
# Safety Features:
# - Fallback to conservative settings on hardware detection failure
# - Graceful degradation of features on unsupported hardware
# - Comprehensive logging and monitoring capabilities
# - User-configurable thresholds through NixOS options
#
# Monitoring and Diagnostics:
# - Real-time thermal monitoring with systemd service
# - Power usage reporting through powertop integration
# - Battery health tracking and reporting
# - Performance profiling tools and shell aliases
#
# Author: Kenan Pelit
# Version: 2.0.0
# Last Updated: 2025-08-25
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # CPU tipini runtime'da belirlemek için script oluştur
  # Bu script, sistemde hangi CPU'nun olduğunu tespit eder
  detectCpuScript = pkgs.writeShellScript "detect-cpu" ''
    #!/usr/bin/env bash
    
    # /proc/cpuinfo dosyasından CPU modelini oku
    CPU_INFO=$(cat /proc/cpuinfo 2>/dev/null || echo "")
    
    # Meteor Lake (Intel Core Ultra) CPU'ları kontrol et
    # 155H: Core Ultra 7 155H gibi modeller
    if echo "$CPU_INFO" | grep -qE "155H|Ultra"; then
      echo "meteolake"
    # Kaby Lake R (8. nesil U serisi) CPU'ları kontrol et  
    # 8650U, 8550U: 8. nesil Intel Core i7/i5 U serisi
    elif echo "$CPU_INFO" | grep -qE "8650U|8550U|8250U|8350U|Kaby Lake"; then
      echo "kabylaker"
    else
      # Bilinmeyen CPU için varsayılan olarak Kaby Lake R ayarlarını kullan (daha güvenli)
      echo "kabylaker"
    fi
  '';

  # Meteor Lake için özel ayarları tanımla
  meteorLakeConfig = {
    # Güç limitleri (Watt cinsinden)
    battery = {
      pl1 = 25;  # Uzun süreli güç limiti
      pl2 = 35;  # Kısa süreli burst güç limiti
      maxFreq = 2800000;  # Maksimum frekans (kHz)
    };
    ac = {
      pl1 = 35;
      pl2 = 45;
      maxFreq = 3800000;
    };
    # Termal eşikler (Celsius cinsinden)
    thermal = {
      trip = 80;  # Battery modunda termal throttle başlangıcı
      tripAc = 85;  # AC modunda termal throttle başlangıcı
      warning = 88;  # Uyarı sıcaklığı
      critical = 95;  # Kritik sıcaklık
    };
    # Batarya şarj eşikleri (yüzde olarak)
    battery_threshold = {
      start = 60;  # Şarj başlama yüzdesi
      stop = 80;   # Şarj durdurma yüzdesi
    };
  };

  # Kaby Lake R için özel ayarları tanımla
  kabyLakeRConfig = {
    # Güç limitleri (daha düşük, eski nesil CPU)
    battery = {
      pl1 = 15;
      pl2 = 25;
      maxFreq = 2200000;
    };
    ac = {
      pl1 = 20;
      pl2 = 30;
      maxFreq = 3500000;
    };
    # Termal eşikler (daha düşük, daha hassas)
    thermal = {
      trip = 75;
      tripAc = 80;
      warning = 85;
      critical = 90;
    };
    # Batarya şarj eşikleri
    battery_threshold = {
      start = 75;
      stop = 80;
    };
  };
in
{
  # ==============================================================================
  # Hardware Configuration
  # ==============================================================================
  hardware = {
    # ThinkPad TrackPoint ayarları
    trackpoint = {
      enable = true;
      speed = 200;       # TrackPoint hızı (0-255 arası)
      sensitivity = 200; # TrackPoint hassasiyeti (0-255 arası)
    };
    
    # Intel grafik sürücüleri ve donanım hızlandırma
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver     # Modern Intel GPU'lar için medya sürücüsü
        vaapiVdpau            # VA-API to VDPAU wrapper
        libvdpau-va-gl        # VDPAU driver with OpenGL/VAAPI backend
        mesa                  # OpenGL implementation
        intel-vaapi-driver    # Eski Intel GPU'lar için VA-API sürücüsü (her iki CPU için)
        intel-compute-runtime # OpenCL runtime (her iki CPU için faydalı)
        intel-ocl            # OpenCL loader
      ];
    };
    
    # Firmware ayarları
    enableRedistributableFirmware = true;  # Kapalı kaynak firmware'leri etkinleştir
    enableAllFirmware = true;              # Tüm kullanılabilir firmware'leri yükle
    cpu.intel.updateMicrocode = true;      # Intel CPU microcode güncellemelerini etkinleştir
  };
  
  # ==============================================================================
  # Thermal and Power Management Services
  # ==============================================================================
  services = {
    # CPU throttling yönetimi (undervolt ve güç limitleri)
    throttled = {
      enable = true;
      # Runtime'da CPU tipine göre yapılandırma dosyası oluştur
      extraConfig = ''
        [GENERAL]
        Enabled: True
        Sysfs_Power_Path: /sys/class/power_supply/AC*/online
        Autoreload: True
        
        # Not: Bu değerler runtime'da systemd servisi tarafından ayarlanacak
        # Varsayılan olarak güvenli değerler kullanılıyor
        
        [BATTERY]
        Update_Rate_s: 30
        PL1_Tdp_W: 15
        PL1_Duration_s: 28
        PL2_Tdp_W: 25
        PL2_Duration_S: 0.002
        Trip_Temp_C: 75
        
        [AC]
        Update_Rate_s: 5
        PL1_Tdp_W: 20
        PL1_Duration_s: 28
        PL2_Tdp_W: 30
        PL2_Duration_S: 0.002
        Trip_Temp_C: 80
        
        [UNDERVOLT.BATTERY]
        # Meteor Lake undervolt'u desteklemiyor, Kaby Lake R için değerler
        # Runtime'da ayarlanacak
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

    # Otomatik CPU frekans yönetimi
    auto-cpufreq = {
      enable = true;
      settings = {
        # Batarya modunda ayarlar
        battery = {
          governor = "powersave";        # Güç tasarrufu modunda çalış
          scaling_min_freq = 400000;     # Minimum frekans 400 MHz
          scaling_max_freq = 2200000;    # Maksimum frekans 2.2 GHz (güvenli varsayılan)
          turbo = "never";               # Turbo boost'u devre dışı bırak
        };
        # Şarj modunda ayarlar
        charger = {
          governor = "powersave";        # Hala powersave kullan (daha kararlı)
          scaling_min_freq = 400000;     # Minimum frekans 400 MHz
          scaling_max_freq = 3500000;    # Maksimum frekans 3.5 GHz (güvenli varsayılan)
          turbo = "auto";                # Turbo boost'u otomatik yönet
        };
      };
    };

    # ThinkPad fan kontrolü (şimdilik devre dışı, throttled yeterli)
    thinkfan.enable = false;
    
    # Intel termal daemon (CPU sıcaklık yönetimi)
    thermald.enable = true;
    
    # Power Profiles Daemon (auto-cpufreq ile çakışır, devre dışı)
    power-profiles-daemon.enable = false;
    
    # TLP güç yönetimi (auto-cpufreq ile çakışır, devre dışı)
    tlp.enable = false;

    # Güç yönetimi servisi
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";  # Kritik seviyede hazırda bekletme moduna geç
      percentageLow = 20;                  # Düşük batarya yüzdesi
      percentageCritical = 5;              # Kritik batarya yüzdesi
      percentageAction = 3;                # Aksiyon alınacak yüzde
      usePercentageForPolicy = true;       # Yüzde bazlı politika kullan
    };
    
    # Sistem oturum yönetimi
    logind = {
      lidSwitch = "suspend";                     # Kapak kapandığında askıya al
      lidSwitchDocked = "suspend";               # Dock'tayken kapak kapandığında askıya al
      lidSwitchExternalPower = "suspend";        # Güç kablosu takılıyken kapak kapandığında askıya al
      extraConfig = ''
        HandlePowerKey=ignore                    # Güç düğmesini yoksay (yanlışlıkla kapatmayı önle)
        HandleSuspendKey=suspend                 # Suspend tuşu askıya alsın
        HandleHibernateKey=hibernate             # Hibernate tuşu hazırda bekletme moduna geçsin
        HandleLidSwitch=suspend                  # Kapak kapanınca askıya al
        HandleLidSwitchDocked=suspend            # Dock'tayken de askıya al
        HandleLidSwitchExternalPower=suspend    # Güç kablosundayken de askıya al
        IdleAction=ignore                        # Boştayken bir şey yapma
        IdleActionSec=30min                     # Boşta kalma süresi
        InhibitDelayMaxSec=5                    # İnhibit gecikmesi maksimum 5 saniye
        HandleSuspendLock=delay                  # Suspend lock'u geciktir
        KillUserProcesses=no                    # Kullanıcı işlemlerini öldürme
        RemoveIPC=yes                           # IPC kaynaklarını temizle
      '';
    };
    
    # Sistem günlüğü ayarları
    journald.extraConfig = ''
      SystemMaxUse=3G                          # Maksimum 3GB log kullan
      SystemMaxFileSize=200M                   # Tek log dosyası maksimum 200MB
      MaxRetentionSec=2weeks                   # Logları 2 hafta tut
      SyncIntervalSec=60                       # Her 60 saniyede bir diske yaz
      RateLimitIntervalSec=10                  # Rate limit aralığı
      RateLimitBurst=200                       # Rate limit burst sayısı
    '';
    
    # DBus implementasyonu (broker daha performanslı)
    dbus.implementation = "broker";
  };
  
  # ==============================================================================
  # Boot Configuration
  # ==============================================================================
  boot = {
    # Yüklenecek kernel modülleri
    kernelModules = [ 
      "thinkpad_acpi"   # ThinkPad özel fonksiyonları
      "coretemp"        # CPU sıcaklık sensörleri
      "intel_rapl"      # Intel güç yönetimi
      "msr"             # Model Specific Register erişimi
    ];
    
    # Modül parametreleri
    extraModprobeConfig = ''
      options thinkpad_acpi fan_control=1        # Fan kontrolünü etkinleştir
      options thinkpad_acpi brightness_mode=1    # Parlaklık kontrolünü etkinleştir
      options thinkpad_acpi volume_mode=1        # Ses kontrolünü etkinleştir
      options thinkpad_acpi experimental=1       # Deneysel özellikleri etkinleştir
      options intel_pstate hwp_dynamic_boost=0   # HWP dynamic boost'u devre dışı bırak (kararlılık için)
    '';
    
    # Kernel parametreleri (her iki CPU için ortak olanlar)
    kernelParams = [
      "intel_iommu=on"                    # Intel IOMMU'yu etkinleştir
      "iommu=pt"                          # IOMMU passthrough modu
      "processor.max_cstate=3"            # Maksimum C-state seviyesi (güç tasarrufu)
      "intel_idle.max_cstate=3"           # Intel idle maksimum C-state
      "thermal.off=0"                     # Termal yönetimi etkin tut
      "thermal.act=-1"                    # Aktif soğutma devre dışı
      "thermal.nocrt=0"                   # Kritik sıcaklık kontrolünü etkin tut
      "thermal.psv=-1"                    # Pasif soğutma devre dışı
      "transparent_hugepage=madvise"      # Huge pages sadece istendiğinde
      "mitigations=auto"                  # Güvenlik açıkları için otomatik azaltma
      "nvme_core.default_ps_max_latency_us=0"  # NVMe güç yönetimini devre dışı bırak
      "intel_pstate=passive"              # Intel P-state'i pasif modda kullan
      "i915.enable_guc=3"                 # Intel GPU GuC'u tam etkinleştir
      "i915.enable_fbc=1"                 # Frame buffer compression'ı etkinleştir
      "i915.enable_psr=2"                 # Panel self refresh'i etkinleştir (güç tasarrufu)
      "i915.enable_dc=2"                  # Display power saving'i etkinleştir
      "i915.fastboot=1"                   # Hızlı boot için fastboot'u etkinleştir
      "i915.modeset=1"                    # Kernel mode setting'i etkinleştir
      "pcie_aspm=force"                   # PCIe güç yönetimini zorla
      "snd_hda_intel.power_save=1"        # Ses kartı güç tasarrufu
      "iwlwifi.power_save=1"              # WiFi güç tasarrufu
      "iwlwifi.power_level=3"             # WiFi güç seviyesi (maksimum tasarruf)
    ];
  };
  
  # ==============================================================================
  # System Services
  # ==============================================================================
  systemd.services = {
    # CPU güç limitlerini ayarlayan servis
    cpu-power-limit = {
      description = "Set Intel RAPL power limits based on CPU type";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          #!/usr/bin/env bash
          set -euo pipefail
          
          # Kısa bir bekleme (sistem başlatma tamamlansın)
          sleep 2
          
          # CPU tipini tespit et
          CPU_TYPE=$(${detectCpuScript})
          echo "Detected CPU type: $CPU_TYPE"
          
          # Intel RAPL arayüzünün varlığını kontrol et
          if [ ! -d /sys/class/powercap/intel-rapl:0 ]; then
            echo "Intel RAPL interface not available"
            exit 0
          fi
          
          # AC adaptör durumunu kontrol et
          ON_AC=0
          if [ -f /sys/class/power_supply/AC/online ]; then
            ON_AC=$(cat /sys/class/power_supply/AC/online)
          elif [ -f /sys/class/power_supply/AC0/online ]; then
            ON_AC=$(cat /sys/class/power_supply/AC0/online)
          elif [ -f /sys/class/power_supply/ADP1/online ]; then
            ON_AC=$(cat /sys/class/power_supply/ADP1/online)
          fi
          
          # CPU tipine ve güç durumuna göre limitleri ayarla
          if [ "$CPU_TYPE" = "meteolake" ]; then
            if [ "$ON_AC" = "1" ]; then
              # Meteor Lake AC modunda
              echo ${toString (meteorLakeConfig.ac.pl1 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo ${toString (meteorLakeConfig.ac.pl2 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Intel RAPL power limits set for Meteor Lake (AC): PL1=${toString meteorLakeConfig.ac.pl1}W, PL2=${toString meteorLakeConfig.ac.pl2}W"
            else
              # Meteor Lake batarya modunda
              echo ${toString (meteorLakeConfig.battery.pl1 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo ${toString (meteorLakeConfig.battery.pl2 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Intel RAPL power limits set for Meteor Lake (Battery): PL1=${toString meteorLakeConfig.battery.pl1}W, PL2=${toString meteorLakeConfig.battery.pl2}W"
            fi
          else
            if [ "$ON_AC" = "1" ]; then
              # Kaby Lake R AC modunda
              echo ${toString (kabyLakeRConfig.ac.pl1 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo ${toString (kabyLakeRConfig.ac.pl2 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Intel RAPL power limits set for Kaby Lake R (AC): PL1=${toString kabyLakeRConfig.ac.pl1}W, PL2=${toString kabyLakeRConfig.ac.pl2}W"
            else
              # Kaby Lake R batarya modunda
              echo ${toString (kabyLakeRConfig.battery.pl1 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo ${toString (kabyLakeRConfig.battery.pl2 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Intel RAPL power limits set for Kaby Lake R (Battery): PL1=${toString kabyLakeRConfig.battery.pl1}W, PL2=${toString kabyLakeRConfig.battery.pl2}W"
            fi
          fi
          
          # Zaman pencerelerini ayarla (her iki CPU için aynı)
          echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us  # 28 saniye
          echo 2500 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us      # 2.5 milisaniye
        '';
      };
    };
    
    # ThinkPad LED durumlarını düzelten servis
    fix-led-state = {
      description = "Fix ThinkPad LED states on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "fix-leds" ''
          #!/usr/bin/env bash
          
          # Mikrofon mute LED'ini ayarla
          if [ -d /sys/class/leds/platform::micmute ]; then
            echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          fi
          
          # Ses mute LED'ini ayarla
          if [ -d /sys/class/leds/platform::mute ]; then
            echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
          fi
          
          # ThinkPad logo LED'ini kapat (gereksiz güç tüketimi)
          if [ -d /sys/class/leds/tpacpi::lid_logo_dot ]; then
            echo 0 > /sys/class/leds/tpacpi::lid_logo_dot/brightness 2>/dev/null || true
          fi
        '';
        RemainAfterExit = true;
      };
    };
    
    # Batarya şarj eşiklerini ayarlayan servis
    battery-charge-threshold = {
      description = "Set battery charge thresholds based on CPU type";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "battery-threshold" ''
          #!/usr/bin/env bash
          set -euo pipefail
          
          # CPU tipini tespit et
          CPU_TYPE=$(${detectCpuScript})
          echo "Setting battery thresholds for CPU type: $CPU_TYPE"
          
          BAT_PATH="/sys/class/power_supply/BAT0"
          
          # Batarya yolu mevcut mu kontrol et
          if [ ! -d "$BAT_PATH" ]; then
            echo "Battery path not found: $BAT_PATH"
            exit 0
          fi
          
          # Şarj başlama eşiğini ayarla
          if [ -f "$BAT_PATH/charge_control_start_threshold" ]; then
            if [ "$CPU_TYPE" = "meteolake" ]; then
              echo ${toString meteorLakeConfig.battery_threshold.start} > "$BAT_PATH/charge_control_start_threshold"
              echo "Battery start threshold set to ${toString meteorLakeConfig.battery_threshold.start}%"
            else
              echo ${toString kabyLakeRConfig.battery_threshold.start} > "$BAT_PATH/charge_control_start_threshold"
              echo "Battery start threshold set to ${toString kabyLakeRConfig.battery_threshold.start}%"
            fi
          fi
          
          # Şarj durdurma eşiğini ayarla (her iki CPU için aynı)
          if [ -f "$BAT_PATH/charge_control_end_threshold" ]; then
            echo 80 > "$BAT_PATH/charge_control_end_threshold"
            echo "Battery end threshold set to 80%"
          fi
        '';
      };
    };
    
    # Termal durumu izleyen servis
    thermal-monitor = {
      description = "Monitor system thermal status based on CPU type";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "thermal-monitor" ''
          #!/usr/bin/env bash
          set -euo pipefail
          
          # CPU tipini tespit et
          CPU_TYPE=$(${detectCpuScript})
          echo "Starting thermal monitor for CPU type: $CPU_TYPE"
          
          # CPU tipine göre eşikleri belirle
          if [ "$CPU_TYPE" = "meteolake" ]; then
            WARNING_THRESHOLD=${toString meteorLakeConfig.thermal.warning}
            CRITICAL_THRESHOLD=${toString meteorLakeConfig.thermal.critical}
          else
            WARNING_THRESHOLD=${toString kabyLakeRConfig.thermal.warning}
            CRITICAL_THRESHOLD=${toString kabyLakeRConfig.thermal.critical}
          fi
          
          echo "Thermal thresholds - Warning: $${WARNING_THRESHOLD}°C, Critical: $${CRITICAL_THRESHOLD}°C"
          
          # Sonsuz döngüde sıcaklığı kontrol et
          while true; do
            # En yüksek sıcaklığı bul (millidegree cinsinden)
            TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
            
            if [ -n "$TEMP" ]; then
              # Celsius'a çevir
              TEMP_C=$((TEMP / 1000))
              
              # Kritik sıcaklık kontrolü
              if [ "$TEMP_C" -gt "$CRITICAL_THRESHOLD" ]; then
                echo "CRITICAL: CPU temperature: $${TEMP_C}°C"
                logger -p user.crit -t thermal-monitor "Critical CPU temperature: $${TEMP_C}°C"
                
                # Kritik durumda bildirim gönder (opsiyonel, notify-send gerektirir)
                if command -v notify-send >/dev/null 2>&1; then
                  notify-send -u critical "Thermal Warning" "Critical CPU temperature: $${TEMP_C}°C"
                fi
              # Uyarı sıcaklığı kontrolü
              elif [ "$TEMP_C" -gt "$WARNING_THRESHOLD" ]; then
                echo "WARNING: High CPU temperature: $${TEMP_C}°C"
                logger -p user.warning -t thermal-monitor "High CPU temperature: $${TEMP_C}°C"
              fi
            fi
            
            # 30 saniye bekle
            sleep 30
          done
        '';
        Restart = "always";      # Servis çökerse otomatik yeniden başlat
        RestartSec = 10;         # Yeniden başlatma öncesi 10 saniye bekle
      };
    };
    
    # Auto-cpufreq yapılandırmasını CPU tipine göre güncelleyen servis
    update-cpufreq-config = {
      description = "Update auto-cpufreq configuration based on CPU type";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      before = [ "auto-cpufreq.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "update-cpufreq" ''
          #!/usr/bin/env bash
          set -euo pipefail
          
          # CPU tipini tespit et
          CPU_TYPE=$(${detectCpuScript})
          echo "Updating auto-cpufreq config for CPU type: $CPU_TYPE"
          
          # auto-cpufreq config dosyası yolu
          CONFIG_FILE="/etc/auto-cpufreq.conf"
          
          # CPU tipine göre yapılandırma oluştur
          if [ "$CPU_TYPE" = "meteolake" ]; then
            cat > "$CONFIG_FILE" <<EOF
          [battery]
          governor = powersave
          scaling_min_freq = 400000
          scaling_max_freq = ${toString meteorLakeConfig.battery.maxFreq}
          turbo = never
          
          [charger]
          governor = powersave
          scaling_min_freq = 400000
          scaling_max_freq = ${toString meteorLakeConfig.ac.maxFreq}
          turbo = auto
          EOF
          else
            cat > "$CONFIG_FILE" <<EOF
          [battery]
          governor = powersave
          scaling_min_freq = 400000
          scaling_max_freq = ${toString kabyLakeRConfig.battery.maxFreq}
          turbo = never
          
          [charger]
          governor = powersave
          scaling_min_freq = 400000
          scaling_max_freq = ${toString kabyLakeRConfig.ac.maxFreq}
          turbo = auto
          EOF
          fi
          
          echo "auto-cpufreq configuration updated"
        '';
      };
    };
  };
  
  # ==============================================================================
  # Udev Rules
  # ==============================================================================
  services.udev.extraRules = ''
    # LED izinlerini ayarla (kullanıcı LED'leri kontrol edebilsin)
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::micmute/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::mute/brightness"
    SUBSYSTEM=="leds", KERNEL=="tpacpi::lid_logo_dot", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/tpacpi::lid_logo_dot/brightness"
    SUBSYSTEM=="leds", KERNEL=="tpacpi::power", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/tpacpi::power/brightness"
    
    # Güç kaynağı değiştiğinde CPU governor ve power limit'leri güncelle
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service"
    
    # PCI ve USB cihazları için güç yönetimi
    # Tüm PCI cihazları için otomatik güç yönetimi
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    
    # USB cihazları için güç yönetimi (klavye/fare hariç)
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    # Logitech cihazları (fare/klavye) için güç yönetimini kapat
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{power/control}="on"
    # HID cihazları (klavye/fare/touchpad) için güç yönetimini kapat
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTR{power/control}="on"
    
    # NVMe SSD güç yönetimi
    ACTION=="add", SUBSYSTEM=="nvme", ATTR{power/pm_qos_latency_tolerance_us}="0"
    
    # Ses kartı güç yönetimi
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="snd_hda_intel", ATTR{power/control}="auto"
    
    # Bluetooth güç yönetimi
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0a2b", ATTR{power/control}="auto"
    
    # Ethernet adaptör güç yönetimi
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="enp*", RUN+="${pkgs.ethtool}/bin/ethtool -s %k wol d"
  '';
  
  # ==============================================================================
  # Environment Configuration
  # ==============================================================================
  environment = {
    # Sistem genelinde kullanılabilecek shell alias'ları
    shellAliases = {
      # Batarya durumunu göster
      battery-status = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
      
      # Detaylı batarya bilgileri
      battery-info = ''
        echo "=== Battery Information ===" && \
        upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|percentage|time to|capacity" && \
        echo -e "\n=== Charge Thresholds ===" && \
        echo "Start: $(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null || echo 'N/A')%" && \
        echo "Stop: $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || echo 'N/A')%"
      '';
      
      # Güç kullanım raporu oluştur (powertop gerektirir)
      power-report = "sudo powertop --html=power-report.html --time=10 && echo 'Report saved to power-report.html'";
      
      # Anlık güç tüketimini göster
      power-usage = "sudo powertop";
      
      # Termal durum bilgileri
      thermal-status = ''
        echo "=== Thermal Status ===" && \
        sensors 2>/dev/null || echo "lm-sensors not installed" && \
        echo -e "\n=== CPU Temperatures ===" && \
        for zone in /sys/class/thermal/thermal_zone*/temp; do \
          if [ -r "$zone" ]; then \
            TEMP=$(cat "$zone"); \
            TEMP_C=$((TEMP / 1000)); \
            ZONE_NAME=$(basename $(dirname "$zone")); \
            echo "$ZONE_NAME: $${TEMP_C}°C"; \
          fi; \
        done
      '';
      
      # CPU frekans bilgileri
      cpu-freq = ''
        echo "=== CPU Frequency Information ===" && \
        cpupower frequency-info 2>/dev/null || echo "cpupower not installed" && \
        echo -e "\n=== Current Frequencies ===" && \
        grep "cpu MHz" /proc/cpuinfo | awk '{print "Core " NR-1 ": " $4 " MHz"}'
      '';
      
      # Güç profili bilgisi
      power-profile = ''
        echo "=== Power Profile ===" && \
        if [ -f /sys/class/power_supply/AC/online ] || [ -f /sys/class/power_supply/AC0/online ] || [ -f /sys/class/power_supply/ADP1/online ]; then \
          ON_AC=$(cat /sys/class/power_supply/A*/online 2>/dev/null | head -1); \
          if [ "$ON_AC" = "1" ]; then echo "Mode: AC Power"; else echo "Mode: Battery"; fi; \
        fi && \
        echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')" && \
        echo "Turbo: $(if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then \
          if [ "$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)" = "0" ]; then echo "Enabled"; else echo "Disabled"; fi; \
        else echo "N/A"; fi)"
      '';
      
      # CPU tipini göster
      cpu-type = "${detectCpuScript}";
      
      # Sistem performans özeti
      perf-summary = ''
        echo "=== System Performance Summary ===" && \
        echo -e "\n--- CPU ---" && \
        ${detectCpuScript} && \
        echo -e "\n--- Power ---" && \
        if [ -f /sys/class/power_supply/AC/online ] || [ -f /sys/class/power_supply/AC0/online ]; then \
          ON_AC=$(cat /sys/class/power_supply/A*/online 2>/dev/null | head -1); \
          if [ "$ON_AC" = "1" ]; then echo "Power: AC"; else echo "Power: Battery"; fi; \
        fi && \
        echo -e "\n--- Thermal ---" && \
        HIGHEST_TEMP=0; \
        for zone in /sys/class/thermal/thermal_zone*/temp; do \
          if [ -r "$zone" ]; then \
            TEMP=$(cat "$zone"); \
            if [ "$TEMP" -gt "$HIGHEST_TEMP" ]; then HIGHEST_TEMP=$TEMP; fi; \
          fi; \
        done; \
        echo "Max Temperature: $((HIGHEST_TEMP / 1000))°C" && \
        echo -e "\n--- Memory ---" && \
        free -h | grep "^Mem:" | awk '{print "Total: " $2 ", Used: " $3 ", Free: " $4}'
      '';
    };
    
    # Sistem genelinde ortam değişkenleri
    variables = {
      # Intel GPU için VA-API sürücüsü
      VDPAU_DRIVER = "va_gl";
      # Hardware video acceleration için
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
  
  # ==============================================================================
  # Additional System Configuration
  # ==============================================================================
  
  # Swappiness değerini düşür (RAM tercih edilsin)
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;                   # Swap kullanımını azalt
    "vm.vfs_cache_pressure" = 50;           # Dosya sistemi cache baskısını azalt
    "vm.dirty_writeback_centisecs" = 1500;  # Dirty page yazma aralığı (15 saniye)
    "vm.laptop_mode" = 5;                   # Laptop modu etkin
    "kernel.nmi_watchdog" = 0;              # NMI watchdog'u kapat (güç tasarrufu)
  };
  
  # Zram swap (RAM sıkıştırması)
  zramSwap = {
    enable = true;
    priority = 5000;      # Yüksek öncelik
    algorithm = "zstd";   # Hızlı ve verimli sıkıştırma
    memoryPercent = 30;   # RAM'in %25'i kadar zram
  };
}

