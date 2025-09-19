# modules/core/system/default.nix
# ==============================================================================
# NixOS System Configuration - Base System, Boot, Hardware & Power Management
# ==============================================================================
#
# Module: modules/core/system
# Author: Kenan Pelit
# Version: 3.0
# Date:    2025-01-18
#
# Purpose: Unified system configuration for ThinkPad laptops and VMs
#
# Supported Hardware:
#   - ThinkPad X1 Carbon 6th Gen (i7-8650U, Kaby Lake-R, 15W TDP)
#   - ThinkPad E14 Gen 6 (Core Ultra 7 155H, Meteor Lake, 28W TDP)
#   - Virtual Machine (hostname: vhay)
#
# Features:
#   - Intelligent power management (TLP + HWP/EPP)
#   - RAPL power limits optimized for thermal balance
#   - ThinkPad thermal/fan/battery threshold management
#   - Runtime CPU detection for dual-hardware single-hostname setup
#   - AC/DC and suspend/resume triggers
#   - VM-specific optimizations
#   - Aggressive fan curves for better cooling
#
# Design Notes:
#   - TLP conflicts with auto-cpufreq and power-profiles-daemon (disabled)
#   - i915 PSR/FBC disabled for stability (prevents tearing)
#   - iGPU frequencies not forced via TLP (causes errors on modern kernels)
#   - RAPL service uses timer to avoid boot ordering cycles
#   - EPP & min_perf auto-tuning based on CPU model detection
#   - Optimized for ~70°C target temperature under load
#
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";   # Both physical ThinkPads use "hay"
  isVirtualMachine  = hostname == "vhay";  # Virtual machine uses "vhay"
in
{
  # ============================================================================
  # Base System Configuration
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
  
  # Turkish F keyboard layout with CapsLock as Ctrl
  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };
  console.keyMap = "trf";
  
  # System state version for upgrade compatibility
  system.stateVersion = "25.11";

  # ============================================================================
  # Boot Configuration (GRUB + Kernel)
  # ============================================================================
  
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    
    # Kernel modules (intel_rapl built-in on most kernels, not loaded separately)
    kernelModules = 
      [ "coretemp" "i915" ]
      ++ lib.optionals isPhysicalMachine [ "thinkpad_acpi" ];
    
    # Module-specific parameters
    extraModprobeConfig = ''
      # Intel P-State HWP dynamic boost
      options intel_pstate hwp_dynamic_boost=1
      
      # Audio power saving (10s timeout)
      options snd_hda_intel power_save=10 power_save_controller=Y
      
      # Wi-Fi power management
      options iwlwifi power_save=1 power_level=3
      
      # USB autosuspend (5s timeout)
      options usbcore autosuspend=5
      
      # NVMe power management (max acceptable latency)
      options nvme_core default_ps_max_latency_us=5500
      
      ${lib.optionalString isPhysicalMachine ''
        # ThinkPad ACPI features
        options thinkpad_acpi fan_control=1 experimental=1
      ''}
    '';
    
    # Kernel parameters for stability and power management
    kernelParams = [
      "intel_pstate=active"
      "intel_pstate.hwp_dynamic_boost=1"
      "pcie_aspm=default"
      "i915.enable_guc=3"
      "i915.enable_fbc=0"       # Disabled for stability
      "i915.enable_psr=0"       # Disabled to prevent tearing
      "i915.enable_sagv=1"
      "mem_sleep_default=deep"  # Deep sleep if supported
      "nvme_core.default_ps_max_latency_us=5500"

      "intel_idle.max_cstate=1"   # Derin uyku modlarını kapat
      "processor.max_cstate=1"    # CPU C1'de kalsın
    ];
    
    # Sysctl optimizations for laptops
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_writeback_centisecs" = 1500;
      "kernel.nmi_watchdog" = 0;  # Save power
    };
    
    # GRUB bootloader configuration
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
  # Hardware Configuration
  # ============================================================================
  
  hardware = {
    # ThinkPad TrackPoint
    trackpoint = lib.mkIf isPhysicalMachine {
      enable = true;
      speed = 200;
      sensitivity = 200;
      emulateWheel = true;
    };
    
    # Intel Graphics
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
    
    # Firmware and microcode
    enableRedistributableFirmware = true;
    enableAllFirmware             = true;
    cpu.intel.updateMicrocode     = true;
    bluetooth.enable              = true;
  };

  # ============================================================================
  # Power Management (TLP + HWP/EPP) - OPTIMIZED FOR THERMAL BALANCE
  # ============================================================================
  
  # Disable conflicting services
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;
  
  # TLP power management - Optimized settings
  services.tlp = lib.mkIf isPhysicalMachine {
    enable = true;
    settings = {
      # Default mode (AC/BAT auto-switching enabled)
      TLP_DEFAULT_MODE       = "AC";
      TLP_PERSISTENT_DEFAULT = 0;
      
      # CPU driver and governor
      CPU_DRIVER_OPMODE           = "active";
      CPU_SCALING_GOVERNOR_ON_AC  = "performance";  # Quick response
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # CPU frequency limits - High minimum for responsiveness
      CPU_SCALING_MIN_FREQ_ON_AC  = 1800000;  # 1.8 GHz minimum - prevents lag
      CPU_SCALING_MAX_FREQ_ON_AC  = 4200000;  # 4.2 GHz max - thermal headroom
      CPU_SCALING_MIN_FREQ_ON_BAT = 1200000;  # 1.2 GHz battery mode
      CPU_SCALING_MAX_FREQ_ON_BAT = 3200000;  # 3.2 GHz max on battery
      
      # HWP performance percentages - Balanced for thermal
      CPU_MIN_PERF_ON_AC  = 40;   # 40% minimum - good responsiveness
      CPU_MAX_PERF_ON_AC  = 90;   # 90% maximum - thermal headroom
      CPU_MIN_PERF_ON_BAT = 20;
      CPU_MAX_PERF_ON_BAT = 75;
      
      # Energy Performance Preference - Balanced
      #CPU_ENERGY_PERF_POLICY_ON_AC  = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_AC  = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      
      # HWP dynamic boost
      CPU_HWP_DYN_BOOST_ON_AC  = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;
      
      # Turbo boost
      CPU_BOOST_ON_AC  = 1;
      CPU_BOOST_ON_BAT = "auto";
      
      # Platform profile - Balanced for thermal management
      PLATFORM_PROFILE_ON_AC  = "balanced";
      PLATFORM_PROFILE_ON_BAT = "balanced";
      
      # PCIe power management
      PCIE_ASPM_ON_AC  = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";
      
      # Runtime PM
      RUNTIME_PM_ON_AC  = "on";
      RUNTIME_PM_ON_BAT = "auto";
      RUNTIME_PM_DRIVER_DENYLIST = "nouveau radeon";
      
      # USB autosuspend
      USB_AUTOSUSPEND     = 1;
      USB_DENYLIST        = "17ef:6047";  # Example VID:PID
      USB_EXCLUDE_AUDIO   = 1;
      USB_EXCLUDE_BTUSB   = 0;
      USB_EXCLUDE_PHONE   = 1;
      USB_EXCLUDE_PRINTER = 1;
      USB_EXCLUDE_WWAN    = 0;
      
      # ThinkPad battery thresholds (75-80% for longevity)
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0  = 80;
      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1  = 80;
      RESTORE_THRESHOLDS_ON_BAT = 1;
      
      # Disk power management
      DISK_IDLE_SECS_ON_AC       = 0;
      DISK_IDLE_SECS_ON_BAT      = 2;
      MAX_LOST_WORK_SECS_ON_AC   = 15;
      MAX_LOST_WORK_SECS_ON_BAT  = 60;
      DISK_APM_LEVEL_ON_AC       = "255";
      DISK_APM_LEVEL_ON_BAT      = "128";
      DISK_APM_CLASS_DENYLIST    = "usb ieee1394";
      DISK_IOSCHED               = "mq-deadline";
      
      # SATA link power
      SATA_LINKPWR_ON_AC  = "max_performance";
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
      
      # Wi-Fi power
      WIFI_PWR_ON_AC  = "off";
      WIFI_PWR_ON_BAT = "on";
      WOL_DISABLE     = "Y";
      
      # Audio power saving
      SOUND_POWER_SAVE_ON_AC  = 0;
      SOUND_POWER_SAVE_ON_BAT = 10;
      SOUND_POWER_SAVE_CONTROLLER = "Y";
      
      # Radio devices
      DEVICES_TO_DISABLE_ON_STARTUP = "";
      DEVICES_TO_ENABLE_ON_STARTUP  = "bluetooth wifi";
      DEVICES_TO_DISABLE_ON_SHUTDOWN = "";
      DEVICES_TO_ENABLE_ON_AC = "bluetooth wifi wwan";
      DEVICES_TO_DISABLE_ON_BAT = "";
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "wwan";
    };
  };

  # ============================================================================
  # System Services
  # ============================================================================
  
  services = {
    thermald.enable = true;  # Intel thermal management
    upower.enable   = true;  # Battery/power reporting
    
    # ThinkFan - AGGRESSIVE COOLING for ~70°C target
    thinkfan = lib.mkIf isPhysicalMachine {
      enable = true;
      levels = [
        # More aggressive fan curve - starts earlier, ramps faster
        [ "level auto"        0  45 ]   # 45°C'ye kadar auto
        [ 1                  43  52 ]   # 43-52°C: Level 1 (quiet start)
        [ 2                  50  58 ]   # 50-58°C: Level 2 (light noise)
        [ 3                  56  63 ]   # 56-63°C: Level 3 (medium)
        [ 4                  61  67 ]   # 61-67°C: Level 4 (medium-high)
        [ 5                  65  71 ]   # 65-71°C: Level 5 (high)
        [ 7                  69  75 ]   # 69-75°C: Level 7 (very high)
        [ "level full-speed" 73 32767 ] # 73°C+: maximum speed
      ];
    };
    
    # Lid/button behavior
    logind.settings.Login = {
      HandleLidSwitch              = "suspend";
      HandleLidSwitchDocked        = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey               = "ignore";
      HandlePowerKeyLongPress      = "poweroff";
      HandleSuspendKey             = "suspend";
      HandleHibernateKey           = "hibernate";
    };
    
    # SPICE guest agent (VMs only)
    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
  };

  # ============================================================================
  # RAPL Power Limits Service - THERMAL OPTIMIZED
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
        
        # Detect CPU model
        CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu \
          | ${pkgs.gnugrep}/bin/grep -F 'Model name' \
          | ${pkgs.coreutils}/bin/cut -d: -f2- \
          | ${pkgs.coreutils}/bin/tr -d '\n' \
          | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        
        # Check AC power
        ON_AC=0
        for PS in /sys/class/power_supply/A{C,DP}*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done
        
        # Meteor Lake / Core Ultra - Thermal optimized values
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core\(TM\) Ultra|Meteor Lake|Arrow Lake|Lunar Lake'; then
          echo "RAPL: Meteor Lake detected, applying thermal-optimized limits"
          
          if [[ "$ON_AC" == "1" ]]; then
            PL1_W=22  # 22W sustained - balanced for ~70°C
            PL2_W=30  # 30W burst - controlled boost
          else
            PL1_W=18  # 18W on battery
            PL2_W=25  # 25W burst on battery
          fi
        else
          # Older CPUs (X1C6 etc)
          if [[ "$ON_AC" == "1" ]]; then
            PL1_W=20
            PL2_W=28
          else
            PL1_W=15
            PL2_W=22
          fi
        fi
        
        # Apply RAPL limits
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw" 2>/dev/null || true
          [[ -w "$R/constraint_0_time_window_us" ]] && echo 28000000 > "$R/constraint_0_time_window_us" 2>/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw" 2>/dev/null || true
          [[ -w "$R/constraint_1_time_window_us" ]] && echo 2440000 > "$R/constraint_1_time_window_us" 2>/dev/null || true
        done
        
        echo "RAPL: Applied PL1=''${PL1_W}W PL2=''${PL2_W}W (AC=''${ON_AC})"
      '';
    };
  };
  
  # Timer for RAPL (avoid boot ordering issues)
  systemd.timers.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Timer: apply RAPL power limits shortly after boot";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec  = "45s";
      Persistent = true;
    };
  };
  
  # Resume trigger for RAPL
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
  # CPU EPP/Min_Perf Auto-tuning Service - THERMAL BALANCED
  # ============================================================================
  
  systemd.services.cpu-epp-autotune = lib.mkIf isPhysicalMachine {
    description = "CPU EPP optimization for performance + thermal balance";
    after = [ "tlp.service" ];
    wantedBy = [ "multi-user.target" ];  # Timer yerine direkt başlat
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;  # Servis aktif kalsın
      ExecStart = pkgs.writeShellScript "cpu-epp-autotune" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        # Detect CPU model
        CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu \
          | ${pkgs.gnugrep}/bin/grep -F 'Model name' \
          | ${pkgs.coreutils}/bin/cut -d: -f2- \
          | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        
        # Check power source
        ON_AC=0
        for PS in /sys/class/power_supply/A{C,DP}*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done
        
        # Meteor Lake / Core Ultra - Balanced for thermal
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core\(TM\) Ultra|Meteor Lake|Lunar Lake|Arrow Lake'; then
          if [[ "$ON_AC" == "1" ]]; then
            EPP_ON_AC="performance"  # Balanced, not aggressive
            MIN_PERF=40  # 40% minimum for responsiveness
            MIN_FREQ=1800000  # 1.8 GHz minimum
          else
            EPP_ON_AC="balance_power"
            MIN_PERF=20
            MIN_FREQ=1200000  # 1.2 GHz on battery
          fi
        else
          # Other CPUs
          if [[ "$ON_AC" == "1" ]]; then
            EPP_ON_AC="performance"
            MIN_PERF=35
            MIN_FREQ=1800000
          else
            EPP_ON_AC="balance_power"
            MIN_PERF=15
            MIN_FREQ=1000000
          fi
        fi
        
        # Apply EPP to all CPU policies
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo "$EPP_ON_AC" > "$pol/energy_performance_preference" 2>/dev/null || true
        done
        
        # Apply min_perf_pct
        if [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]]; then
          echo "$MIN_PERF" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || true
        fi
        
        # Force minimum frequency on all cores
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/scaling_min_freq" ]] && \
            echo "$MIN_FREQ" > "$pol/scaling_min_freq" 2>/dev/null || true
        done
        
        echo "EPP: Applied EPP='$EPP_ON_AC', min_perf=$MIN_PERF%, min_freq=$((MIN_FREQ/1000))MHz"
      '';
    };
  };
  
  # Resume trigger for EPP
  systemd.services.cpu-epp-autotune-resume = lib.mkIf isPhysicalMachine {
    description = "Re-apply EPP/min_perf after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service";
    };
  };
 
  # ============================================================================
  # Udev Rules for AC/DC Switching
  # ============================================================================
  
  services.udev.extraRules = lib.mkIf isPhysicalMachine ''
    # Re-apply RAPL and CPU-EPP on AC/DC switch
    SUBSYSTEM=="power_supply", KERNEL=="A{C,DP}*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start rapl-power-limits.service"
    SUBSYSTEM=="power_supply", KERNEL=="A{C,DP}*", ACTION=="change", \
      RUN+="${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service"
  '';

  # ============================================================================
  # ThinkPad-specific Services
  # ============================================================================
  
  # Disable mute LEDs
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
  
  # ThinkFan suspend/resume handling
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

  # ============================================================================
  # User-facing Power Management Tools - THREE MODES
  # ============================================================================
  
  environment.systemPackages = with pkgs;
    lib.optionals isPhysicalMachine [
      tlp
      lm_sensors
      
      # Performance mode - Maximum performance (when needed)
      (writeScriptBin "performance-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "🚀 Performance mode (controlled thermal)…"
        sudo ${tlp}/bin/tlp ac
        
        # EPP and performance settings
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo balance_performance | sudo tee "$pol/energy_performance_preference" >/dev/null || true
        done
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && \
          echo 45 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct >/dev/null || true
        [[ -w /sys/devices/system/cpu/intel_pstate/max_perf_pct ]] && \
          echo 100 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null || true
        
        # RAPL: 25W/32W for short burst performance
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && \
            echo 25000000 | sudo tee "$R/constraint_0_power_limit_uw" >/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && \
            echo 32000000 | sudo tee "$R/constraint_1_power_limit_uw" >/dev/null || true
        done
        
        echo "✅ Performance mode active (PL1=25W, PL2=32W)"
      '')
      
      # Balanced mode - Daily use (default)
      (writeScriptBin "balanced-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "⚖️ Balanced mode (thermal optimized ~70°C)…"
        sudo ${tlp}/bin/tlp start
        
        # EPP and limits
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo balance_performance | sudo tee "$pol/energy_performance_preference" >/dev/null || true
        done
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && \
          echo 40 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct >/dev/null || true
        [[ -w /sys/devices/system/cpu/intel_pstate/max_perf_pct ]] && \
          echo 90 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null || true
        
        # RAPL: 22W/30W balanced
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && \
            echo 22000000 | sudo tee "$R/constraint_0_power_limit_uw" >/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && \
            echo 30000000 | sudo tee "$R/constraint_1_power_limit_uw" >/dev/null || true
        done
        
        echo "✅ Balanced mode active (PL1=22W, PL2=30W)"
      '')
      
      # Cool mode - Maximum cooling, quiet operation
      (writeScriptBin "cool-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "❄️ Cool mode (quiet & cool ~65°C)…"
        
        # EPP power saving
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo balance_power | sudo tee "$pol/energy_performance_preference" >/dev/null || true
        done
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && \
          echo 30 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct >/dev/null || true
        [[ -w /sys/devices/system/cpu/intel_pstate/max_perf_pct ]] && \
          echo 80 | sudo tee /sys/devices/system/cpu/intel_pstate/max_perf_pct >/dev/null || true
        
        # RAPL: 18W/25W low power
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && \
            echo 18000000 | sudo tee "$R/constraint_0_power_limit_uw" >/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && \
            echo 25000000 | sudo tee "$R/constraint_1_power_limit_uw" >/dev/null || true
        done
        
        echo "✅ Cool mode active (PL1=18W, PL2=25W)"
      '')
      
      # Power status script
      (writeScriptBin "power-status" ''
        #!${bash}/bin/bash
        echo "==== Power Status ===="
        sudo ${tlp}/bin/tlp-stat -s -c -p | head -40
      '')
      
      # Comprehensive performance status tool
      (writeScriptBin "perf-mode" ''
        #!${bash}/bin/bash
        set -euo pipefail
        
        if [ $# -ge 1 ]; then
          cmd="$1"
        else
          cmd="status"
        fi
        
        show_status() {
          CPU_MODEL="$(${util-linux}/bin/lscpu \
            | ${gnugrep}/bin/grep -F 'Model name' \
            | ${coreutils}/bin/cut -d: -f2- \
            | ${gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
          GOV="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo n/a)"
          EPP="$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo n/a)"
          MIN_PERF="$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null || echo n/a)"
          MAX_PERF="$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo n/a)"
          TURBO="$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null | tr '01' 'YesNo' || echo n/a)"
          PWR="BAT"; for PS in /sys/class/power_supply/A{C,DP}*/online; do
            [ -f "$PS" ] && [ "$(cat "$PS")" = "1" ] && PWR="AC" && break
          done
          
          echo "╭─────────────────────────────────────────╮"
          echo "│         System Power Status              │"
          echo "╰─────────────────────────────────────────╯"
          echo "CPU Model: $CPU_MODEL"
          echo "Power Source: $PWR"
          echo ""
          echo "┌─── CPU Configuration ───┐"
          echo "  Governor: $GOV"
          echo "  EPP: $EPP"
          echo "  Min Perf: ''${MIN_PERF}%"
          echo "  Max Perf: ''${MAX_PERF}%"
          echo "  Turbo: $TURBO"
          echo ""
          
          # Current frequencies
          echo "┌─── Current Frequencies ───┐"
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
            [ -f "$f" ] || continue
            cpu="$(basename "$(dirname "$(dirname "$f")")")"
            mhz="$(( $(cat "$f") / 1000 ))"
            printf "  %-5s: %4d MHz\n" "$cpu" "$mhz"
          done | head -n 9
          echo ""
          
          # Power limits
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            echo "┌─── Power Limits (RAPL) ───┐"
            pl1="$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)"
            pl2="$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)"
            [ "$pl1" != "0" ] && echo "  PL1 (Sustained): $((pl1/1000000))W"
            [ "$pl2" != "0" ] && echo "  PL2 (Burst): $((pl2/1000000))W"
            echo ""
          fi
          
          # Temperature
          echo "┌─── Thermal Status ───┐"
          TEMP="$(${lm_sensors}/bin/sensors 2>/dev/null | ${gnugrep}/bin/grep -m1 -E 'Package id 0|Tctl' | ${gawk}/bin/awk '{print $4}' || echo n/a)"
          FAN="$(${lm_sensors}/bin/sensors 2>/dev/null | ${gnugrep}/bin/grep -m1 'fan1' | ${gawk}/bin/awk '{print $2}' || echo n/a)"
          echo "  CPU Temp: $TEMP"
          echo "  Fan Speed: $FAN RPM"
          echo ""
          
          # Battery thresholds
          if [ -r /sys/class/power_supply/BAT0/charge_control_start_threshold ]; then
            echo "┌─── Battery Management ───┐"
            s=$(cat /sys/class/power_supply/BAT0/charge_control_start_threshold)
            e=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold)
            echo "  Start charging: ''${s}%"
            echo "  Stop charging: ''${e}%"
          fi
        }
        
        case "$cmd" in
          status) show_status ;;
          perf)   performance-mode ;;
          bal)    balanced-mode ;;
          cool)   cool-mode ;;
          *) 
            echo "Usage: perf-mode {status|perf|bal|cool}"
            echo ""
            echo "Modes:"
            echo "  status - Show current system status"
            echo "  perf   - Performance mode (~75°C, max performance)"
            echo "  bal    - Balanced mode (~70°C, daily use)"
            echo "  cool   - Cool mode (~65°C, quiet operation)"
            exit 2
            ;;
        esac
      '')
      
      # Thermal monitor script
      (writeScriptBin "thermal-monitor" ''
        #!${bash}/bin/bash
        echo "Monitoring thermals... (Ctrl+C to stop)"
        echo ""
        watch -n 1 '${lm_sensors}/bin/sensors | ${gnugrep}/bin/grep -E "Package|Core 0:|fan" && echo && \
          for f in /sys/class/powercap/intel-rapl:0/constraint_*_power_limit_uw; do \
            [ -f "$f" ] && echo "$(basename $f | cut -d_ -f1-2): $(($(cat $f)/1000000))W"; \
          done'
      '')
    ];
}

