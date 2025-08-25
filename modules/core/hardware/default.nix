# modules/core/hardware/default.nix
# ==============================================================================
# Unified Hardware and Power Management Configuration
# ==============================================================================
<<<<<<< HEAD
# This configuration manages hardware and power settings including:
# - ThinkPad-specific ACPI and thermal management (X1 Carbon 6th + E14 Gen 6 support)
# - Intel Graphics drivers and hardware acceleration (UHD 620 + Arc Graphics)
# - NVMe storage optimizations
# - CPU thermal and power management (Intel i7-8650U + Core Ultra 7 155H)
# - LED control and function key management
# - TrackPoint and touchpad configuration
# - Comprehensive power management with lid suspend support
#
# Supported Hardware:
# - ThinkPad X1 Carbon 6th (20KHS0XR00) - Intel i7-8650U, UHD Graphics 620
# - ThinkPad E14 Gen 6 (21M7006LTX) - Intel Core Ultra 7 155H, Arc Graphics
#
# Performance Targets:
# - CPU Temperature: 65-85°C under load (model dependent)
# - Fan Noise: Minimal to balanced operation
# - Power Consumption: 15-35W sustained, 25-45W burst (model dependent)
#
# Author: Kenan Pelit
# Modified: 2025-08-25 (Unified configuration for multiple ThinkPad models)
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # Detect CPU architecture to apply appropriate settings
  isMeteorLake = lib.any (cpu: lib.hasInfix cpu config.hardware.cpu) ["155H" "ultra" "Ultra"];
  isKabyLakeR = lib.any (cpu: lib.hasInfix cpu config.hardware.cpu) ["8650U" "8550U" "Kaby"];
in
||||||| dec55af
# This configuration manages hardware settings including:
# - ThinkPad-specific ACPI and advanced thermal management
# - Intel Arc Graphics drivers and hardware acceleration
# - NVMe storage optimizations for dual-drive setup
# - Intel Core Ultra 7 155H CPU thermal and power management
# - LED control and function key management
# - TrackPoint and touchpad configuration
# - Aggressive thermal throttling to prevent overheating
#
# Target Hardware:
# - ThinkPad E14 Gen 6 (21M7006LTX)
# - Intel Core Ultra 7 155H (16-core hybrid architecture)
# - Intel Arc Graphics (Meteor Lake-P)
# - 64GB DDR5 RAM
# - Dual NVMe setup: Transcend TS2TMTE400S + Timetec 35TT2280GEN4E-2TB
#
# Author: Kenan Pelit
# Modified: 2025-08-23 (Thermal optimization - thermald removed due to compatibility issues)
# ==============================================================================
{ pkgs, ... }:
=======
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
>>>>>>> e14u7
{
  # ==============================================================================
  # Hardware Configuration
  # ==============================================================================
  hardware = {
<<<<<<< HEAD
    # Enable TrackPoint for ThinkPad
    trackpoint = {
      enable = true;
      speed = 200;
      sensitivity = 200;
    };
||||||| dec55af
    # Enable TrackPoint for ThinkPad
    trackpoint.enable = true;
=======
    # ThinkPad TrackPoint ayarları
    trackpoint = {
      enable = true;
      speed = 200;       # TrackPoint hızı (0-255 arası)
      sensitivity = 200; # TrackPoint hassasiyeti (0-255 arası)
    };
>>>>>>> e14u7
    
<<<<<<< HEAD
    # Intel Graphics configuration (supports both UHD 620 and Arc Graphics)
||||||| dec55af
    # Intel Arc Graphics configuration for Meteor Lake
=======
    # Intel grafik sürücüleri ve donanım hızlandırma
>>>>>>> e14u7
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
<<<<<<< HEAD
        intel-media-driver
        vaapiVdpau
        libvdpau-va-gl
        mesa
      ] ++ lib.optionals isMeteorLake [
        intel-compute-runtime
        intel-ocl
      ] ++ lib.optionals isKabyLakeR [
        intel-vaapi-driver
||||||| dec55af
        intel-media-driver      # VA-API implementation
        vaapiVdpau             # VDPAU backend for VA-API
        libvdpau-va-gl         # VDPAU driver with OpenGL/VAAPI backend
        mesa                   # OpenGL implementation
        intel-compute-runtime  # OpenCL runtime for Intel GPUs
        intel-ocl             # OpenCL implementation
=======
        intel-media-driver     # Modern Intel GPU'lar için medya sürücüsü
        vaapiVdpau            # VA-API to VDPAU wrapper
        libvdpau-va-gl        # VDPAU driver with OpenGL/VAAPI backend
        mesa                  # OpenGL implementation
        intel-vaapi-driver    # Eski Intel GPU'lar için VA-API sürücüsü (her iki CPU için)
        intel-compute-runtime # OpenCL runtime (her iki CPU için faydalı)
        intel-ocl            # OpenCL loader
>>>>>>> e14u7
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
<<<<<<< HEAD
    # Lenovo throttling fix with model-specific configurations
||||||| dec55af
    # Lenovo throttling fix with aggressive thermal management
    # NOTE: Thermald has been removed due to compatibility issues with Meteor Lake
    # and XML configuration errors. throttled + auto-cpufreq + thinkfan provides
    # superior thermal management for modern Intel processors.
=======
    # CPU throttling yönetimi (undervolt ve güç limitleri)
>>>>>>> e14u7
    throttled = {
      enable = true;
<<<<<<< HEAD
      extraConfig = 
        if isMeteorLake then ''
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
        '' else ''
          [GENERAL]
          Enabled: True
          Sysfs_Power_Path: /sys/class/power_supply/AC*/online
          Autoreload: True

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
          CORE: -60
          GPU: -40
          CACHE: -60
          UNCORE: 0
          ANALOGIO: 0

          [UNDERVOLT.AC]
          CORE: -80
          GPU: -60
          CACHE: -80
          UNCORE: 0
          ANALOGIO: 0
        '';
||||||| dec55af
      extraConfig = ''
        [GENERAL]
        # Enable throttling fix
        Enabled: True
        # Path to check AC power status
        Sysfs_Power_Path: /sys/class/power_supply/AC*/online
        # Auto-reload config on changes
        Autoreload: True

        [BATTERY]
        # Update rate for battery mode (seconds)
        Update_Rate_s: 30
        # Long-term power limit (Watts) - aggressive for battery
        PL1_Tdp_W: 20
        PL1_Duration_s: 28
        # Short-term power limit (Watts)
        PL2_Tdp_W: 28
        PL2_Duration_S: 0.002
        # Temperature threshold for throttling (Celsius)
        Trip_Temp_C: 80

        [AC]
        # Update rate for AC mode (seconds)
        Update_Rate_s: 5
        # Long-term power limit (Watts) - reduced from default
        PL1_Tdp_W: 30
        PL1_Duration_s: 28
        # Short-term power limit (Watts)
        PL2_Tdp_W: 40
        PL2_Duration_S: 0.002
        # Temperature threshold for throttling (Celsius)
        Trip_Temp_C: 85

        [UNDERVOLT.BATTERY]
        # Meteor Lake doesn't support undervolting
        CORE: 0
        GPU: 0
        CACHE: 0
        UNCORE: 0
        ANALOGIO: 0

        [UNDERVOLT.AC]
        # Meteor Lake doesn't support undervolting
        CORE: 0
        GPU: 0
        CACHE: 0
        UNCORE: 0
        ANALOGIO: 0
      '';
=======
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
>>>>>>> e14u7
    };

<<<<<<< HEAD
    # Modern CPU frequency management
||||||| dec55af
    # TLP disabled in favor of auto-cpufreq for modern CPU management
    tlp.enable = false;
    
    # Modern CPU frequency management with aggressive thermal controls
    # This replaces thermald for Meteor Lake processors with better compatibility
=======
    # Otomatik CPU frekans yönetimi
>>>>>>> e14u7
    auto-cpufreq = {
      enable = true;
      settings = {
        # Batarya modunda ayarlar
        battery = {
<<<<<<< HEAD
          governor = "powersave";
          scaling_min_freq = 400000;
          turbo = "never";
||||||| dec55af
          governor = "powersave";
          scaling_min_freq = 400000;   # 400 MHz minimum frequency
          scaling_max_freq = 2500000;  # 2.5 GHz maximum on battery (reduced for thermals)
          turbo = "never";             # Disable turbo boost on battery
=======
          governor = "powersave";        # Güç tasarrufu modunda çalış
          scaling_min_freq = 400000;     # Minimum frekans 400 MHz
          scaling_max_freq = 2200000;    # Maksimum frekans 2.2 GHz (güvenli varsayılan)
          turbo = "never";               # Turbo boost'u devre dışı bırak
>>>>>>> e14u7
        };
        # Şarj modunda ayarlar
        charger = {
<<<<<<< HEAD
          governor = "powersave";
          scaling_min_freq = 400000;
          turbo = "auto";
||||||| dec55af
          governor = "powersave";      # Use powersave governor even on AC
          scaling_min_freq = 400000;   # 400 MHz minimum frequency
          scaling_max_freq = 3500000;  # 3.5 GHz maximum on AC (reduced from 4.8 GHz)
          turbo = "auto";              # Allow turbo but let thermal management control it
=======
          governor = "powersave";        # Hala powersave kullan (daha kararlı)
          scaling_min_freq = 400000;     # Minimum frekans 400 MHz
          scaling_max_freq = 3500000;    # Maksimum frekans 3.5 GHz (güvenli varsayılan)
          turbo = "auto";                # Turbo boost'u otomatik yönet
>>>>>>> e14u7
        };
      } // (if isMeteorLake then {
        battery.scaling_max_freq = 2800000;
        charger.scaling_max_freq = 3800000;
      } else {
        battery.scaling_max_freq = 2200000;
        charger.scaling_max_freq = 3500000;
      });
    };

<<<<<<< HEAD
    # ThinkPad fan control - disabled by default
    thinkfan.enable = false;

    # Intel thermal daemon
    thermald.enable = true;

    # Disable conflicting power services
||||||| dec55af
    # ThinkPad fan control with aggressive cooling curve
    # Primary thermal management solution for temperature control
    thinkfan = {
      enable = false;
      smartSupport = true;
      
      # Yapılandırma dosyasını oluştur ve yolunu string olarak ver
      extraArgs = let
        configFile = pkgs.writeText "thinkfan.conf" ''
          # Thinkfan configuration for ThinkPad E14 Gen 6
          sensors:
            - hwmon: /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input
            - hwmon: /sys/devices/platform/thinkpad_hwmon/hwmon/hwmon*/temp1_input
          
          fans:
            - tpacpi: /proc/acpi/ibm/fan
          
          levels:
            - [0, 0, 60]          # Fan off below 60°C
            - [1, 58, 65]         # Level 1: 58-65°C
            - [2, 62, 70]         # Level 2: 62-70°C
            - [3, 68, 75]         # Level 3: 68-75°C
            - [4, 72, 78]         # Level 4: 72-78°C
            - [5, 76, 82]         # Level 5: 76-82°C
            - [6, 80, 85]         # Level 6: 80-85°C
            - [7, 83, 88]         # Level 7: 83-88°C
            - ["level full-speed", 86, 32767]  # Full speed above 86°C
        '';
      in [ "-c" "${configFile}" ];
    };

    # Disable power-profiles-daemon to avoid conflicts with auto-cpufreq
=======
    # ThinkPad fan kontrolü (şimdilik devre dışı, throttled yeterli)
    thinkfan.enable = false;
    
    # Intel termal daemon (CPU sıcaklık yönetimi)
    thermald.enable = true;
    
    # Power Profiles Daemon (auto-cpufreq ile çakışır, devre dışı)
>>>>>>> e14u7
    power-profiles-daemon.enable = false;
<<<<<<< HEAD
    tlp.enable = false;

    # UPower configuration
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      usePercentageForPolicy = true;
    };
    
    # Logind configuration for lid suspend
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
    
    # System logging
    journald.extraConfig = ''
      SystemMaxUse=3G
      SystemMaxFileSize=200M
      MaxRetentionSec=2weeks
      SyncIntervalSec=60
      RateLimitIntervalSec=10
      RateLimitBurst=200
    '';
    
    # D-Bus optimization
    dbus.implementation = "broker";
||||||| dec55af
=======
    
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
>>>>>>> e14u7
  };
  
  # ==============================================================================
  # Boot Configuration
  # ==============================================================================
  boot = {
<<<<<<< HEAD
    # Essential kernel modules
||||||| dec55af
    # Essential kernel modules for hardware monitoring and control
=======
    # Yüklenecek kernel modülleri
>>>>>>> e14u7
    kernelModules = [ 
<<<<<<< HEAD
      "thinkpad_acpi"
      "coretemp"
      "intel_rapl"
      "msr"
||||||| dec55af
      "thinkpad_acpi"  # ThinkPad ACPI extras (fan control, LEDs, etc.)
      "coretemp"       # CPU temperature monitoring
      "intel_rapl"     # Intel RAPL power capping interface
=======
      "thinkpad_acpi"   # ThinkPad özel fonksiyonları
      "coretemp"        # CPU sıcaklık sensörleri
      "intel_rapl"      # Intel güç yönetimi
      "msr"             # Model Specific Register erişimi
>>>>>>> e14u7
    ];
    
<<<<<<< HEAD
    # Module options for ThinkPad features
||||||| dec55af
    # Module options for ThinkPad-specific features
=======
    # Modül parametreleri
>>>>>>> e14u7
    extraModprobeConfig = ''
<<<<<<< HEAD
      options thinkpad_acpi fan_control=1
      options thinkpad_acpi brightness_mode=1
      options thinkpad_acpi volume_mode=1
      options thinkpad_acpi experimental=1
      options intel_pstate hwp_dynamic_boost=0
||||||| dec55af
      # ThinkPad ACPI configuration
      options thinkpad_acpi fan_control=1      # Enable manual fan control
      options thinkpad_acpi brightness_mode=1   # Improved brightness control
      options thinkpad_acpi volume_mode=1       # Better volume key handling
      options thinkpad_acpi experimental=1      # Enable experimental features
      
      # Intel P-state driver options for better power management
      options intel_pstate hwp_dynamic_boost=0  # Disable dynamic boost for stability
=======
      options thinkpad_acpi fan_control=1        # Fan kontrolünü etkinleştir
      options thinkpad_acpi brightness_mode=1    # Parlaklık kontrolünü etkinleştir
      options thinkpad_acpi volume_mode=1        # Ses kontrolünü etkinleştir
      options thinkpad_acpi experimental=1       # Deneysel özellikleri etkinleştir
      options intel_pstate hwp_dynamic_boost=0   # HWP dynamic boost'u devre dışı bırak (kararlılık için)
>>>>>>> e14u7
    '';
    
<<<<<<< HEAD
    # Kernel parameters with model-specific optimizations
||||||| dec55af
    # Kernel parameters for optimized thermal and power management
=======
    # Kernel parametreleri (her iki CPU için ortak olanlar)
>>>>>>> e14u7
    kernelParams = [
<<<<<<< HEAD
      # Common parameters
      "intel_iommu=on"
      "iommu=pt"
      "processor.max_cstate=3"
      "intel_idle.max_cstate=3"
      "thermal.off=0"
      "thermal.act=-1"
      "thermal.nocrt=0"
      "thermal.psv=-1"
      "transparent_hugepage=madvise"
      "mitigations=auto"
    ] ++ (if isMeteorLake then [
      # Meteor Lake specific
      "nvme.noacpi=1"
      "intel_pstate=passive"
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
      "i915.enable_dc=2"
      "i915.fastboot=1"
    ] else [
      # Kaby Lake R specific
      "nvme_core.default_ps_max_latency_us=0"
      "intel_pstate=active"
      "i915.enable_guc=2"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "i915.enable_dc=2"
      "i915.fastboot=1"
      "i915.modeset=1"
      "pcie_aspm=force"
      "snd_hda_intel.power_save=1"
      "iwlwifi.power_save=1"
      "iwlwifi.power_level=3"
    ]);
||||||| dec55af
      # NVMe optimization - disable ACPI for better performance
      "nvme.noacpi=1"
      
      # IOMMU for better device isolation and security
      "intel_iommu=on"
      
      # CPU power management settings
      "intel_pstate=passive"        # Passive mode for governor-based frequency control
      "processor.max_cstate=3"      # Limit deep C-states to reduce wake latency
      "intel_idle.max_cstate=3"     # Limit idle states for better responsiveness
      
      # Intel Arc Graphics power saving and performance options
      "i915.enable_guc=3"           # Enable GuC (Graphics microcontroller) and HuC firmware
      "i915.enable_fbc=1"           # Frame buffer compression for power savings
      "i915.enable_psr=2"           # Panel self refresh (reduced power consumption)
      "i915.enable_dc=2"            # Display C-states (power management)
      "i915.fastboot=1"             # Faster graphics initialization
      
      # Thermal management settings
      "thermal.off=0"               # Ensure thermal management is enabled
      "thermal.act=-1"              # ACPI thermal control (automatic)
      "thermal.nocrt=0"             # Enable critical temperature actions
      "thermal.psv=-1"              # Automatic passive cooling temperature
    ];
=======
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
>>>>>>> e14u7
  };
  
  # ==============================================================================
  # System Services
  # ==============================================================================
  systemd.services = {
<<<<<<< HEAD
    # CPU power limit service
||||||| dec55af
    # CPU power limit service for additional thermal control
    # Sets RAPL (Running Average Power Limit) constraints for Intel CPUs
=======
    # CPU güç limitlerini ayarlayan servis
>>>>>>> e14u7
    cpu-power-limit = {
      description = "Set Intel RAPL power limits based on CPU type";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
<<<<<<< HEAD
          #!/usr/bin/env sh
          sleep 2
          
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            ON_AC=0
            if [ -f /sys/class/power_supply/AC/online ]; then
              ON_AC=$(cat /sys/class/power_supply/AC/online)
            elif [ -f /sys/class/power_supply/ADP1/online ]; then
              ON_AC=$(cat /sys/class/power_supply/ADP1/online)
            fi
            
            if [ "$ON_AC" = "1" ]; then
              ${if isMeteorLake then ''
                echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
                echo 45000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
                echo "Intel RAPL power limits set (AC): PL1=35W, PL2=45W"
              '' else ''
                echo 20000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
                echo 30000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
                echo "Intel RAPL power limits set (AC): PL1=20W, PL2=30W"
              ''}
            else
              ${if isMeteorLake then ''
                echo 25000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
                echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
                echo "Intel RAPL power limits set (Battery): PL1=25W, PL2=35W"
              '' else ''
                echo 15000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
                echo 25000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
                echo "Intel RAPL power limits set (Battery): PL1=15W, PL2=25W"
              ''}
            fi
            
            echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us
            echo 2500 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us
          else
            echo "Intel RAPL interface not available"
||||||| dec55af
          # Check if RAPL interface is available
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            # Set long-term power limit (PL1) to 28W for sustained performance
            echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
            
            # Set short-term power limit (PL2) to 35W for burst performance
            echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
            
            # Set time windows for power limits
            echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us
            echo 2500 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us
            
            echo "Intel RAPL power limits configured: PL1=28W, PL2=35W"
          else
            echo "Intel RAPL interface not available - skipping power limit configuration"
=======
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
>>>>>>> e14u7
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
    
<<<<<<< HEAD
    # Fix LED state on boot
||||||| dec55af
    # Fix LED state on boot for ThinkPad E14 Gen 6
    # Ensures microphone and mute LEDs work correctly with audio integration
=======
    # ThinkPad LED durumlarını düzelten servis
>>>>>>> e14u7
    fix-led-state = {
      description = "Fix ThinkPad LED states on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "fix-leds" ''
<<<<<<< HEAD
          #!/usr/bin/env sh
          if [ -d /sys/class/leds/platform::micmute ]; then
            echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          fi
||||||| dec55af
          # Configure LED triggers for proper audio integration
          echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
          echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
=======
          #!/usr/bin/env bash
>>>>>>> e14u7
          
<<<<<<< HEAD
          if [ -d /sys/class/leds/platform::mute ]; then
            echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
          fi
          
          if [ -d /sys/class/leds/tpacpi::lid_logo_dot ]; then
            echo 0 > /sys/class/leds/tpacpi::lid_logo_dot/brightness 2>/dev/null || true
          fi
||||||| dec55af
          # Initialize LED states to off
          echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
=======
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
>>>>>>> e14u7
        '';
        RemainAfterExit = true;
      };
    };
    
<<<<<<< HEAD
    # Battery charge threshold service
    battery-charge-threshold = {
      description = "Set battery charge thresholds for longevity";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "battery-threshold" ''
          #!/usr/bin/env sh
          BAT_PATH="/sys/class/power_supply/BAT0"
          
          if [ -f "$BAT_PATH/charge_control_start_threshold" ]; then
            ${if isMeteorLake then ''
              echo 60 > "$BAT_PATH/charge_control_start_threshold"
            '' else ''
              echo 75 > "$BAT_PATH/charge_control_start_threshold"
            ''}
          fi
          
          if [ -f "$BAT_PATH/charge_control_end_threshold" ]; then
            ${if isMeteorLake then ''
              echo 80 > "$BAT_PATH/charge_control_end_threshold"
            '' else ''
              echo 80 > "$BAT_PATH/charge_control_end_threshold"
            ''}
          fi
        '';
      };
    };
    
    # Thermal monitoring service
||||||| dec55af
    # Thermal monitoring service for system health
    # Provides logging and awareness of temperature conditions
=======
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
>>>>>>> e14u7
    thermal-monitor = {
<<<<<<< HEAD
      description = "Monitor system thermal status";
||||||| dec55af
      description = "Monitor system thermal status and log warnings";
=======
      description = "Monitor system thermal status based on CPU type";
>>>>>>> e14u7
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "thermal-monitor" ''
<<<<<<< HEAD
          #!/usr/bin/env sh
          ${if isMeteorLake then ''
            WARNING_THRESHOLD=88
            CRITICAL_THRESHOLD=95
          '' else ''
            WARNING_THRESHOLD=85
            CRITICAL_THRESHOLD=90
          ''}
          
||||||| dec55af
=======
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
>>>>>>> e14u7
          while true; do
<<<<<<< HEAD
||||||| dec55af
            # Get highest temperature from all thermal zones
=======
            # En yüksek sıcaklığı bul (millidegree cinsinden)
>>>>>>> e14u7
            TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
<<<<<<< HEAD
            if [ -n "$TEMP" ]; then
              TEMP_C=$((TEMP / 1000))
              
              if [ "$TEMP_C" -gt "$CRITICAL_THRESHOLD" ]; then
                echo "CRITICAL: CPU temperature: $${TEMP_C}°C"
                logger -p user.crit -t thermal-monitor "Critical CPU temperature: $${TEMP_C}°C"
              elif [ "$TEMP_C" -gt "$WARNING_THRESHOLD" ]; then
                echo "WARNING: High CPU temperature: $${TEMP_C}°C"
                logger -p user.warning -t thermal-monitor "High CPU temperature: $${TEMP_C}°C"
              fi
||||||| dec55af
            TEMP_C=$((TEMP / 1000))
            
            # Log warning if temperature exceeds safe operating range
            if [ "$TEMP_C" -gt 90 ]; then
              echo "WARNING: High CPU temperature detected: $${TEMP_C}°C"
              logger -t thermal-monitor "High CPU temperature: $${TEMP_C}°C - Consider checking cooling system"
=======
            
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
>>>>>>> e14u7
            fi
            
<<<<<<< HEAD
||||||| dec55af
            # Sleep for 30 seconds between checks
=======
            # 30 saniye bekle
>>>>>>> e14u7
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
<<<<<<< HEAD
    # LED permissions
||||||| dec55af
    # Fix microphone LED permissions and initial state
    # Ensure user has write access to LED controls
=======
    # LED izinlerini ayarla (kullanıcı LED'leri kontrol edebilsin)
>>>>>>> e14u7
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::micmute/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::mute/brightness"
    SUBSYSTEM=="leds", KERNEL=="tpacpi::lid_logo_dot", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/tpacpi::lid_logo_dot/brightness"
    SUBSYSTEM=="leds", KERNEL=="tpacpi::power", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/tpacpi::power/brightness"
    
<<<<<<< HEAD
    # CPU governor and power management
||||||| dec55af
    # Dynamic CPU governor switching based on power source
    # Use powersave governor for optimal battery life and thermal management
=======
    # Güç kaynağı değiştiğinde CPU governor ve power limit'leri güncelle
>>>>>>> e14u7
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
<<<<<<< HEAD
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service"
    
    # PCI and USB power management
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTR{power/control}="on"
||||||| dec55af
=======
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
>>>>>>> e14u7
  '';
<<<<<<< HEAD
  
  # ==============================================================================
  # Environment Configuration
  # ==============================================================================
  environment.shellAliases = {
    battery-status = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
    power-usage = "sudo powertop --html=power-report.html --time=10";
    thermal-status = "sensors && cat /sys/class/thermal/thermal_zone*/temp";
  };
||||||| dec55af
=======
  
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
>>>>>>> e14u7
}

