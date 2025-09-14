# modules/core/system/default.nix
# ==============================================================================
# NixOS System Configuration - Base System, Boot, Hardware & Power Management
# ==============================================================================
#
# Module: modules/core/system
# Author: Kenan Pelit
# Version: 2.3
# Date:    2025-01-04
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
#   - RAPL power limits (legacy Intel CPUs, bypassed on Meteor Lake+)
#   - ThinkPad thermal/fan/battery threshold management
#   - Runtime CPU detection for dual-hardware single-hostname setup
#   - AC/DC and suspend/resume triggers
#   - VM-specific optimizations
#
# Design Notes:
#   - TLP conflicts with auto-cpufreq and power-profiles-daemon (disabled)
#   - i915 PSR/FBC disabled for stability (prevents tearing)
#   - iGPU frequencies not forced via TLP (causes errors on modern kernels)
#   - RAPL service uses timer to avoid boot ordering cycles
#   - EPP & min_perf auto-tuning based on CPU model detection
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
  # Power Management (TLP + HWP/EPP)
  # ============================================================================
  
  # Disable conflicting services
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;
  
  # TLP power management
  services.tlp = lib.mkIf isPhysicalMachine {
    enable = true;
    settings = {
      # Default mode (AC/BAT auto-switching enabled)
      TLP_DEFAULT_MODE       = "AC";
      TLP_PERSISTENT_DEFAULT = 0;
      
      # CPU driver and governor
      CPU_DRIVER_OPMODE           = "active";
      CPU_SCALING_GOVERNOR_ON_AC  = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # CPU frequency limits
      CPU_SCALING_MIN_FREQ_ON_AC  = 1000000;  # 1.0 GHz minimum for responsiveness
      CPU_SCALING_MAX_FREQ_ON_AC  = 4500000;  # 4.5 GHz max
      # Note: MIN_FREQ_ON_BAT not set - let HWP/EPP decide
      CPU_SCALING_MAX_FREQ_ON_BAT = 3500000;  # 3.5 GHz max on battery
      
      # HWP performance percentages
      CPU_MIN_PERF_ON_AC  = 35;
      CPU_MAX_PERF_ON_AC  = 100;
      CPU_MIN_PERF_ON_BAT = 10;
      CPU_MAX_PERF_ON_BAT = 80;
      
      # Energy Performance Preference
      CPU_ENERGY_PERF_POLICY_ON_AC  = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      
      # HWP dynamic boost
      CPU_HWP_DYN_BOOST_ON_AC  = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;
      
      # Turbo boost
      CPU_BOOST_ON_AC  = 1;
      CPU_BOOST_ON_BAT = "auto";
      
      # Platform profile (if firmware supports)
      PLATFORM_PROFILE_ON_AC  = "performance";
      PLATFORM_PROFILE_ON_BAT = "balanced";
      
      # Note: iGPU frequency control (INTEL_GPU_*) intentionally omitted
      # Modern i915 drivers handle this automatically
      
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
    
    # ThinkFan (5-level fan curve for ThinkPads)
    thinkfan = lib.mkIf isPhysicalMachine {
      enable = true;
      levels = [
        [ "level auto"        0  58 ]
        [ 1                  58  68 ]
        [ 3                  68  78 ]
        [ 7                  78  88 ]
        [ "level full-speed" 88 32767 ]
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
  # RAPL Power Limits Service
  # ============================================================================
  # Intel Running Average Power Limit configuration
  # - Meaningful for older CPUs (X1C6)
  # - Bypassed on Meteor Lake and newer
  
  systemd.services.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Apply RAPL power limits for Intel CPUs";
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
        
        # Modern Intel CPUs (Meteor Lake+)
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core\(TM\) Ultra|Meteor Lake|Arrow Lake|Lunar Lake'; then
          echo "RAPL: Meteor Lake detected, applying conservative limits for '$CPU_MODEL'"
          
          # Check AC power
          ON_AC=0
          for PS in /sys/class/power_supply/A{C,DP}*/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
          done
          
          if [[ "$ON_AC" == "1" ]]; then
            PL1_W=28; PL2_W=35  # E14 TDP-appropriate
          else
            PL1_W=20; PL2_W=28  # Conservative on battery
          fi
          
          # Apply RAPL and exit
          for R in /sys/class/powercap/intel-rapl:*; do
            [[ -d "$R" ]] || continue
            [[ -w "$R/constraint_0_power_limit_uw" ]] && echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw" 2>/dev/null || true
            [[ -w "$R/constraint_1_power_limit_uw" ]] && echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw" 2>/dev/null || true
          done
          
          echo "RAPL applied for Meteor Lake (PL1=''${PL1_W}W PL2=''${PL2_W}W; AC=''${ON_AC})."
          exit 0
        fi
        
        # Check for RAPL interface
        shopt -s nullglob
        have_rapl=0
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] && have_rapl=1 && break
        done
        if [[ "$have_rapl" -eq 0 ]]; then
          echo "RAPL: no powercap interface; skipping."
          exit 0
        fi
        
        # Check AC power (for older CPUs)
        ON_AC=0
        for PS in /sys/class/power_supply/A{C,DP}*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done
        
        if [[ "$ON_AC" == "1" ]]; then
          PL1_W=25; PL2_W=35  # X1C6-like older CPUs AC values
        else
          PL1_W=15; PL2_W=25  # X1C6-like older CPUs BAT values
        fi
        
        # Apply RAPL limits
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw"  ]] && echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw"  2>/dev/null || true
          [[ -w "$R/constraint_0_time_window_us"  ]] && echo 28000000 > "$R/constraint_0_time_window_us" 2>/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw"  ]] && echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw"  2>/dev/null || true
          [[ -w "$R/constraint_1_time_window_us"  ]] && echo 2440000  > "$R/constraint_1_time_window_us" 2>/dev/null || true
        done
        
        echo "RAPL applied (PL1=''${PL1_W}W PL2=''${PL2_W}W; AC=''${ON_AC})."
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
  # CPU EPP/Min_Perf Auto-tuning Service
  # ============================================================================
  # Detects CPU model and adjusts EPP and min_perf for optimal performance
  # - Meteor Lake: EPP=balance_performance, min_perf=20
  # - X1C6: EPP=performance, min_perf=25
  
  systemd.services.cpu-epp-autotune = lib.mkIf isPhysicalMachine {
    description = "CPU model-based EPP and min_perf adjustment";
    after = [ "tlp.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "cpu-epp-autotune" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        
        # Detect CPU model
        CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu \
          | ${pkgs.gnugrep}/bin/grep -F 'Model name' \
          | ${pkgs.coreutils}/bin/cut -d: -f2- \
          | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        
        # Defaults (for modern CPUs)
        EPP_ON_AC="balance_performance"
        MIN_PERF=25
        
        # Check power source
        ON_AC=0
        for PS in /sys/class/power_supply/A{C,DP}*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done
        
        if [[ "$ON_AC" == "1" ]]; then
          MIN_PERF=30
        else
          MIN_PERF=10
        fi
        
        # X1C6 / Kaby/Whiskey/Coffee U series - more aggressive on AC
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE '8650U|8550U|8350U|8250U|Kaby|Whiskey|Coffee'; then
          EPP_ON_AC="performance"
        fi
        
        # Meteor Lake / Core Ultra - full performance on AC with 35% floor
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core\(TM\) Ultra|Meteor Lake|Lunar Lake|Arrow Lake'; then
          if [[ "$ON_AC" == "1" ]]; then
            EPP_ON_AC="performance"
            MIN_PERF=35
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
        
        echo "cpu-epp-autotune: CPU='$CPU_MODEL' (AC=$ON_AC) -> EPP='$EPP_ON_AC', min_perf_pct='$MIN_PERF'"
      '';
    };
  };
  
  # Timer for EPP auto-tuning
  systemd.timers.cpu-epp-autotune = lib.mkIf isPhysicalMachine {
    description = "Timer: EPP/min_perf adjustment after TLP";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      Persistent = true;
      Unit = "cpu-epp-autotune.service";
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
  
  # Disable old ad-hoc services (cleanup)
  systemd.services.thinkfan-sleep  = lib.mkIf isPhysicalMachine { enable = lib.mkForce false; wantedBy = lib.mkForce [ ]; };
  systemd.services.thinkfan-wakeup = lib.mkIf isPhysicalMachine { enable = lib.mkForce false; wantedBy = lib.mkForce [ ]; };

  # ============================================================================
  # User-facing Power Management Tools
  # ============================================================================
  
  environment.systemPackages = with pkgs;
    lib.optionals isPhysicalMachine [
      tlp
      
      # Performance mode script
      (writeScriptBin "performance-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "🚀 Performance mode (HWP)…"
        sudo ${tlp}/bin/tlp ac
        
        # EPP=performance, min_perf_pct=30
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo performance | sudo tee "$pol/energy_performance_preference" >/dev/null || true
        done
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && \
          echo 30 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct >/dev/null || true
        
        # Enable turbo
        [[ -w /sys/devices/system/cpu/intel_pstate/no_turbo ]] && \
          echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null || true
        
        sudo ${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service || true
        echo "✅ Done!"
      '')
      
      # Balanced mode script
      (writeScriptBin "balanced-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "⚖️ Balanced mode (HWP)…"
        sudo ${tlp}/bin/tlp start
        
        # EPP=balance_performance, min_perf_pct=25
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo balance_performance | sudo tee "$pol/energy_performance_preference" >/dev/null || true
        done
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && \
          echo 25 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct >/dev/null || true
        
        sudo ${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service || true
        echo "✅ Done!"
      '')
      
      # Eco mode script
      (writeScriptBin "eco-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "🍃 Eco mode (HWP)…"
        sudo ${tlp}/bin/tlp bat
        
        # EPP=balance_power, min_perf_pct=10
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/energy_performance_preference" ]] && \
            echo balance_power | sudo tee "$pol/energy_performance_preference" >/dev/null || true
        done
        [[ -w /sys/devices/system/cpu/intel_pstate/min_perf_pct ]] && \
          echo 10 | sudo tee /sys/devices/system/cpu/intel_pstate/min_perf_pct >/dev/null || true
        
        echo "✅ Done!"
      '')
      
      # Power status script
      (writeScriptBin "power-status" ''
        #!${bash}/bin/bash
        echo "==== Power Status ===="
        sudo ${tlp}/bin/tlp-stat -s -c -p | head -40
      '')
      
      # Comprehensive performance mode tool
      (writeScriptBin "osc-perf-mode" ''
        #!${bash}/bin/bash
        set -euo pipefail
        
        if [ $# -ge 1 ]; then
          cmd="$1"
        else
          cmd="status"
        fi
        
        show_status() {
          CPU_TYPE="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
          GOV="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo n/a)"
          EPP="$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo n/a)"
          TURBO="$(cat /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null | ${pkgs.coreutils}/bin/tr '01' 'OnOff' || echo n/a)"
          MEMS="$(cat /sys/power/mem_sleep 2>/dev/null || echo n/a)"
          PWR="BAT"; for PS in /sys/class/power_supply/A{C,DP}*/online; do [ -f "$PS" ] && [ "$(cat "$PS")" = "1" ] && PWR="AC" && break; done
          TEMP="$( ${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep -m1 -E 'Package id 0|Tctl' | ${pkgs.gawk}/bin/awk '{print $3}' || echo n/a)"
          
          echo "=== Current System Status ==="
          echo "CPU: $CPU_TYPE"
          echo "Power Source: $PWR"
          echo "Governor: $GOV"
          echo "EPP: $EPP"
          echo "Turbo: $TURBO"
          echo "mem_sleep: $MEMS"
          echo
          echo "CPU Frequencies:"
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
            [ -f "$f" ] || continue
            cpu="$(basename "$(dirname "$(dirname "$f")")")"
            mhz="$(( $(cat "$f") / 1000 ))"
            printf "  %-5s: %s MHz\n" "$cpu" "$mhz"
          done | head -n 16
          echo
          
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            pl1="$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)"
            pl2="$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)"
            [ "$pl1" != "0" ] && echo "PL1: $((pl1/1000000))W"
            [ "$pl2" != "0" ] && echo "PL2: $((pl2/1000000))W"
          fi
          echo
          
          echo "CPU Temp: $TEMP"
          
          if [ -r /sys/class/power_supply/BAT0/charge_control_start_threshold ]; then
            s=$(cat /sys/class/power_supply/BAT0/charge_control_start_threshold)
            e=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold)
            echo "Battery Thresholds: Start: ''${s}% | Stop: ''${e}%"
          fi
        }
        
        case "$cmd" in
          status) show_status ;;
          perf)   performance-mode ;;
          bal)    balanced-mode ;;
          eco)    eco-mode ;;
          *) echo "usage: osc-perf-mode {status|perf|bal|eco}" ; exit 2 ;;
        esac
      '')
    ];
}
