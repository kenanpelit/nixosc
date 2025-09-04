# modules/core/system/default.nix
# ==============================================================================
# NixOS Sistem Yapılandırması - Temel Sistem, Boot, Donanım ve Güç Yönetimi
# ==============================================================================
#
# Bu modül, geleneksel olarak ayrı dosyalarda tutulan sistem bileşenlerini tek
# bir bütünleşik yapıda toplar. Temel sistem servisleri, önyükleme süreci,
# donanım desteği ve gelişmiş güç yönetimini kapsamlı şekilde yönetir.
#
# DESTEKLENEn DONANIM:
# - ThinkPad X1 Carbon 6th Gen (Intel Core i7-8650U, Kaby Lake-R, 15W TDP)
#   → Ultra-taşınabilir, ince tasarım, uzun batarya ömrü odaklı
# - ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, Meteor Lake, 28W TDP) 
#   → Yüksek performans, çok çekirdekli işlem gücü, modern mimarı
# - Sanal Makineler (hostname tespiti ile: vhay)
#
# ANA ÖZELLİKLER:
#
# 1. AKILLI GÜÇ YÖNETİMİ
#    - TLP tabanlı dinamik güç profilleri (AC/Batarya otomatik geçiş)
#    - CPU'ya özgü RAPL güç limitleri (eski nesil Intel için)
#    - Meteor Lake için native güç yönetimi (RAPL bypass)
#    - Platform profilleri ile işletim sistemi seviyesinde optimizasyon
#    - Intel HWP (Hardware P-States) ve EPP (Energy Performance Preference)
#
# 2. THINKPAD ÖZEL OPTİMİZASYONLARI
#    - ThinkFan ile gelişmiş termal yönetim (5 kademeli fan kontrolü)
#    - Batarya ömrünü uzatan şarj eşikleri (%75-80 döngüsü)
#    - TrackPoint hassasiyet ve hız ayarları
#    - Mute/MicMute LED düzeltmeleri (boot ve resume sonrası)
#    - ACPI tabanlı fan kontrolü ve suspend/resume yönetimi
#
# 3. KERNEL VE BOOT OPTİMİZASYONLARI
#    - En güncel stable kernel (linuxPackages_latest)
#    - Intel mikroişlemci mikrocode güncellemeleri
#    - i915 GPU sürücüsü stabilite ayarları (PSR/FBC/SAGV kapalı)
#    - GRUB tema desteği ve çoklu işletim sistemi tespiti
#    - Hibernate/Suspend optimizasyonları
#
# 4. DONANIM DESTEĞİ
#    - Intel Graphics (Iris Xe / Arc) tam donanım hızlandırması
#    - VA-API/VDPAU video decode/encode desteği
#    - OpenCL ve Level Zero compute desteği
#    - Bluetooth, WiFi, WWAN modül yönetimi
#    - NVMe güç tasarrufu optimizasyonları
#
# 5. SERVİS VE UDEV KURALLARI
#    - AC/DC geçişlerinde otomatik profil değişimi
#    - Suspend öncesi/sonrası servis yönetimi
#    - Dinamik RAPL limit güncellemeleri
#    - Sistem durumu raporlama araçları
#
# KULLANIM:
# - performance-mode: Maksimum performans profili
# - balanced-mode: Dengeli kullanım (varsayılan)
# - eco-mode: Maksimum batarya tasarrufu
# - power-status: Anlık güç durumu raporu
#
# NOTLAR:
# - TLP, auto-cpufreq ve power-profiles-daemon ile çakışır (devre dışı bırakıldı)
# - RAPL limitleri CPU modeline göre otomatik belirlenir
# - Sanal makinelerde ThinkPad özellikleri otomatik devre dışı kalır
#
# Author: Kenan Pelit
# Version: 2.0
# Last Updated: 2024
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  hostname = config.networking.hostName or "";
  # hay = fiziksel ThinkPad, vhay = sanal makine
  isPhysicalMachine = hostname == "hay";
  isVirtualMachine = hostname == "vhay";
in
{
  # =============================================================================
  # BASE SYSTEM
  # =============================================================================

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

  # Türkçe F klavye düzeni ve Caps Lock -> Ctrl dönüşümü
  services.xserver.xkb = {
    layout = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };
  console.keyMap = "trf";

  system.stateVersion = "25.11";

  # =============================================================================
  # BOOT (GRUB + Kernel)
  # =============================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    # Kernel modülleri
    kernelModules = [ "coretemp" "intel_rapl" "i915" ] 
      ++ lib.optionals isPhysicalMachine [ "thinkpad_acpi" ];

    extraModprobeConfig = ''
      # Intel P-State hardware-managed P-states
      options intel_pstate hwp_dynamic_boost=1
      
      # Audio güç tasarrufu
      options snd_hda_intel power_save=10 power_save_controller=Y
      
      # WiFi güç optimizasyonu
      options iwlwifi power_save=1 power_level=3
      
      # USB otomatik suspend
      options usbcore autosuspend=5
      
      # NVMe güç yönetimi
      options nvme_core default_ps_max_latency_us=5500
      
      ${lib.optionalString isPhysicalMachine ''
        # ThinkPad ACPI - fan kontrolü ve batarya yönetimi
        options thinkpad_acpi fan_control=1 experimental=1
      ''}
    '';

    # Kernel parametreleri
    kernelParams = [
      "intel_pstate=active"
      "intel_pstate.hwp_dynamic_boost=1"
      "pcie_aspm=default"
      "i915.enable_guc=3"
      "i915.enable_fbc=0"
      "i915.enable_psr=0"
      "i915.enable_sagv=0"
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
        device = lib.mkForce (
          if isPhysicalMachine then "nodev"
          else if isVirtualMachine then "/dev/vda"
          else "nodev"
        );
        efiSupport = isPhysicalMachine;
        useOSProber = true;
        configurationLimit = 10;
        gfxmodeEfi = "1920x1200";
        gfxmodeBios = if isVirtualMachine then "1920x1080" else "1920x1200";
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };

      efi = lib.mkIf isPhysicalMachine {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  # =============================================================================
  # HARDWARE CONFIGURATION
  # =============================================================================
  
  hardware = {
    trackpoint = lib.mkIf isPhysicalMachine {
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
      extraPackages32 = with pkgs.pkgsi686Linux; [ 
        intel-media-driver 
      ];
    };

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
    bluetooth.enable = true;
  };

  # =============================================================================
  # POWER MANAGEMENT (TLP)
  # =============================================================================
  
  services.auto-cpufreq.enable = false;
  services.power-profiles-daemon.enable = false;

  services.tlp = lib.mkIf isPhysicalMachine {
    enable = true;
    settings = {
      TLP_DEFAULT_MODE = "AC";
      TLP_PERSISTENT_DEFAULT = 0;
      
      # CPU Configuration
      CPU_DRIVER_OPMODE = "active";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_MIN_FREQ_ON_AC = 1200000;
      CPU_SCALING_MAX_FREQ_ON_AC = 4800000;
      #CPU_SCALING_MIN_FREQ_ON_BAT = 800000;
      CPU_SCALING_MAX_FREQ_ON_BAT = 3500000;
      CPU_MIN_PERF_ON_AC = 25;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 10;
      CPU_MAX_PERF_ON_BAT = 80;
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = "auto";
      
      # Platform Profile
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";
      
      # GPU Configuration
      INTEL_GPU_MIN_FREQ_ON_AC = 500;
      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_MAX_FREQ_ON_AC = 1200;
      INTEL_GPU_MAX_FREQ_ON_BAT = 800;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1200;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 1000;
      
      # PCIe Power Management
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
      
      # Runtime PM
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_DRIVER_DENYLIST = "nouveau radeon";
      
      # USB Power Management
      USB_AUTOSUSPEND = 1;
      USB_DENYLIST = "17ef:6047";
      USB_EXCLUDE_AUDIO = 1;
      USB_EXCLUDE_BTUSB = 0;
      USB_EXCLUDE_PHONE = 1;
      USB_EXCLUDE_PRINTER = 1;
      USB_EXCLUDE_WWAN = 0;
      
      # ThinkPad Battery
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;
      RESTORE_THRESHOLDS_ON_BAT = 1;
      
      # Disk Power Management
      DISK_IDLE_SECS_ON_AC = 0;
      DISK_IDLE_SECS_ON_BAT = 2;
      MAX_LOST_WORK_SECS_ON_AC = 15;
      MAX_LOST_WORK_SECS_ON_BAT = 60;
      DISK_APM_LEVEL_ON_AC = "255";
      DISK_APM_LEVEL_ON_BAT = "128";
      DISK_APM_CLASS_DENYLIST = "usb ieee1394";
      DISK_IOSCHED = "mq-deadline";
      
      # SATA Power Management
      SATA_LINKPWR_ON_AC = "max_performance";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
      
      # WiFi Power Management
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
      WOL_DISABLE = "Y";
      
      # Audio Power Management
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 10;
      SOUND_POWER_SAVE_CONTROLLER = "Y";
      
      # Radio Devices
      DEVICES_TO_DISABLE_ON_STARTUP = "";
      DEVICES_TO_ENABLE_ON_STARTUP = "bluetooth wifi";
      DEVICES_TO_DISABLE_ON_SHUTDOWN = "";
      DEVICES_TO_ENABLE_ON_AC = "bluetooth wifi wwan";
      DEVICES_TO_DISABLE_ON_BAT = "";
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "wwan";
    };
  };

  # =============================================================================
  # SYSTEM SERVICES
  # =============================================================================
  
  services = {
    thermald.enable = true;
    upower.enable = true;

    # ThinkFan
    thinkfan = lib.mkIf isPhysicalMachine {
      enable = true;
      levels = [
        [ "level auto" 0 55 ]
        [ 1 55 65 ]
        [ 3 65 75 ]
        [ 7 75 85 ]
        [ "level full-speed" 85 32767 ]
      ];
    };

    # Laptop lid switch behaviors (yeni format)
    logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey = "ignore";
      HandlePowerKeyLongPress = "poweroff";
      HandleSuspendKey = "suspend";
      HandleHibernateKey = "hibernate";
    };
  };

  # =============================================================================
  # RAPL POWER LIMITS
  # =============================================================================
  
  systemd.services.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Apply RAPL power limits for Intel CPUs";
    wantedBy = [ "multi-user.target" ];
    after = [ "tlp.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "set-rapl-limits" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.coreutils}/bin/tr -d '\n')"
        
        # Skip RAPL for Meteor Lake and newer
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core Ultra|Meteor Lake|Arrow Lake|Lunar Lake'; then
          echo "Modern Intel CPU detected - using native power management"
          exit 0
        fi
        
        # Apply RAPL for older Intel CPUs
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '8650U|8550U|8350U|8250U|Kaby|Whiskey|Coffee'; then
          ON_AC=0
          for PS in /sys/class/power_supply/A{C,DP}*/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
          done

          if [[ "$ON_AC" == "1" ]]; then
            PL1_W=25
            PL2_W=35
          else
            PL1_W=15
            PL2_W=25
          fi

          for R in /sys/class/powercap/intel-rapl:*; do
            [[ -d "$R" ]] || continue
            
            if [[ -w "$R/constraint_0_power_limit_uw" ]]; then
              echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw" 2>/dev/null || true
              echo 28000000 > "$R/constraint_0_time_window_us" 2>/dev/null || true
            fi
            
            if [[ -w "$R/constraint_1_power_limit_uw" ]]; then
              echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw" 2>/dev/null || true
              echo 2440000 > "$R/constraint_1_time_window_us" 2>/dev/null || true
            fi
          done

          echo "RAPL limits applied: PL1=''${PL1_W}W PL2=''${PL2_W}W (AC=$ON_AC)"
        fi
      '';
    };
  };

  systemd.services.rapl-power-limits-resume = lib.mkIf isPhysicalMachine {
    description = "Re-apply RAPL limits after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl restart rapl-power-limits.service";
    };
  };

  # =============================================================================
  # THINKPAD HELPERS
  # =============================================================================
  
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
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
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
    before = [ "sleep.target" ];
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
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
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

  systemd.services.thinkfan-sleep = lib.mkIf isPhysicalMachine {
    enable = lib.mkForce false;
    wantedBy = lib.mkForce [ ];
  };
  
  systemd.services.thinkfan-wakeup = lib.mkIf isPhysicalMachine {
    enable = lib.mkForce false;
    wantedBy = lib.mkForce [ ];
  };

  # =============================================================================
  # UDEV RULES
  # =============================================================================
  
  services.udev.extraRules = lib.mkIf isPhysicalMachine ''
    SUBSYSTEM=="power_supply", KERNEL=="A{C,DP}*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl restart rapl-power-limits.service"
  '';

  # =============================================================================
  # USER PACKAGES
  # =============================================================================
  
  environment.systemPackages = with pkgs; 
    lib.optionals isPhysicalMachine [
      tlp
      
      (writeScriptBin "performance-mode" ''
        #!${bash}/bin/bash
        echo "🚀 Performance mode..."
        sudo ${tlp}/bin/tlp ac
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
          echo performance | sudo tee $cpu/scaling_governor >/dev/null 2>&1
        done
        echo "✅ Done!"
      '')
      
      (writeScriptBin "balanced-mode" ''
        #!${bash}/bin/bash
        echo "⚖️ Balanced mode..."
        sudo ${tlp}/bin/tlp start
        echo "✅ Done!"
      '')
      
      (writeScriptBin "eco-mode" ''
        #!${bash}/bin/bash
        echo "🍃 Eco mode..."
        sudo ${tlp}/bin/tlp bat
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
          echo powersave | sudo tee $cpu/scaling_governor >/dev/null 2>&1
        done
        echo "✅ Done!"
      '')
      
      (writeScriptBin "power-status" ''
        #!${bash}/bin/bash
        echo "==== Power Status ===="
        sudo ${tlp}/bin/tlp-stat -s -c -p | head -20
      '')
    ];
}

