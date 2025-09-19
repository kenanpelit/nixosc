# modules/core/system/default.nix
# ==============================================================================
# NixOS System Configuration - Advanced Power & Thermal Management
# ==============================================================================
#
# Module: modules/core/system
# Author: Kenan Pelit
# Version: 4.0 FINAL (Production-Ready)
# Date:    2025-01-19
#
# PURPOSE:
# --------
# Provides enterprise-grade power and thermal management for NixOS systems,
# optimizing for performance, thermal efficiency, and battery longevity across
# diverse hardware configurations.
#
# SUPPORTED HARDWARE:
# -------------------
# - ThinkPad X1 Carbon Gen 6 (i7-8650U, Kaby Lake-R, 15W TDP)
# - ThinkPad E14 Gen 6 (Core Ultra 7 155H, Meteor Lake, 28W TDP)
# - QEMU/KVM Virtual Machines (hostname: vhay)
#
# KEY FEATURES:
# -------------
# ✓ Intelligent CPU frequency scaling with guaranteed minimums
# ✓ Adaptive thermal limits based on CPU generation and power source
# ✓ Multi-tier fan control with temperature hysteresis
# ✓ Battery charge threshold management for longevity
# ✓ Automatic reconfiguration on AC/DC transitions
# ✓ Persistent settings across suspend/resume cycles
# ✓ VM-specific optimizations and guest agent support
#
# PERFORMANCE TARGETS:
# --------------------
# - Idle: < 45°C with minimal fan activity
# - Load: 68-72°C sustained without throttling
# - Responsiveness: < 1ms frequency ramp-up
# - Battery: 5-8 hours typical usage
# - Fan noise: < 35 dBA typical, < 45 dBA peak
#
# TECHNICAL APPROACH:
# -------------------
# 1. CPU Governor: Passive Intel P-State + Schedutil
#    - OS-controlled frequency selection
#    - Scheduler-aware decision making
#    - Configurable ramp rates
#
# 2. Power Limits: RAPL + TLP coordination
#    - Hardware-enforced power budgets
#    - Software-guided frequency ranges
#    - Dynamic adjustment based on thermal headroom
#
# 3. Thermal Control: ThinkFan + Thermald
#    - Progressive fan curves with hysteresis
#    - Predictive thermal management
#    - Emergency throttle prevention
#
# 4. State Management: SystemD + Udev
#    - Event-driven reconfiguration
#    - Atomic setting application
#    - Graceful error handling
#
# DESIGN DECISIONS:
# -----------------
# - TLP chosen over auto-cpufreq for ThinkPad-specific features
# - Schedutil over powersave for superior interactive performance
# - Passive P-State for finer OS control vs active hardware autonomy
# - RAPL limits tuned per-CPU generation for optimal thermals
# - Timer-based service startup to avoid boot race conditions
#
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  # System identification for conditional configuration
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";    # Physical ThinkPad
  isVirtualMachine  = hostname == "vhay";   # Virtual machine
  
  # Helper for creating robust shell scripts with proper error handling
  mkRobustScript = name: content: pkgs.writeShellScript name ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail  # Exit on error, undefined vars, pipe failures
    ${content}
  '';
in
{
  # ============================================================================
  # LOCALIZATION & TIMEZONE
  # ============================================================================
  # Istanbul timezone with mixed English/Turkish locale for optimal compatibility
  time.timeZone = "Europe/Istanbul";

  i18n = {
    defaultLocale = "en_US.UTF-8";  # System messages in English
    extraLocaleSettings = {
      # Turkish locale for regional formats (dates, currency, etc.)
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

  # Turkish F-keyboard layout with Caps Lock remapped to Ctrl
  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";  # Ergonomic: Caps Lock becomes Control
  };
  console.keyMap = "trf";

  # NixOS state version - DO NOT change after initial installation
  system.stateVersion = "25.11";

  # ============================================================================
  # BOOT CONFIGURATION
  # ============================================================================
  boot = {
    # Latest stable kernel for hardware support
    kernelPackages = pkgs.linuxPackages_latest;

    # Essential kernel modules
    kernelModules = [
      "coretemp"        # CPU temperature monitoring
      "i915"            # Intel graphics driver
    ] ++ lib.optionals isPhysicalMachine [
      "thinkpad_acpi"   # ThinkPad-specific features (fan, battery, etc.)
    ];

    # Kernel module parameters for power optimization
    extraModprobeConfig = ''
      # Intel P-State: Enable hardware-guided performance scaling
      # hwp_dynamic_boost=1 allows CPU to exceed base frequency dynamically
      options intel_pstate hwp_dynamic_boost=1

      # Audio: Power down after 10 seconds idle
      options snd_hda_intel power_save=10 power_save_controller=Y

      # WiFi: Enable power saving with medium latency tolerance
      options iwlwifi power_save=1 power_level=3

      # USB: Auto-suspend after 5 seconds idle
      options usbcore autosuspend=5

      # NVMe: Allow 5.5ms latency for deeper power states
      options nvme_core default_ps_max_latency_us=5500

      ${lib.optionalString isPhysicalMachine ''
        # ThinkPad: Enable manual fan control and experimental features
        options thinkpad_acpi fan_control=1 experimental=1
      ''}
    '';

    # Kernel command line parameters
    kernelParams = [
      # CPU: Use OS-controlled frequency scaling for better responsiveness
      "intel_pstate=passive"
      
      # PCIe: Default ASPM for balanced power/performance
      "pcie_aspm=default"
      
      # Graphics: Enable GuC firmware, disable unstable features
      "i915.enable_guc=3"     # GuC/HuC firmware for better scheduling
      "i915.enable_fbc=0"     # Disable framebuffer compression (causes artifacts)
      "i915.enable_psr=0"     # Disable panel self-refresh (causes flicker)
      "i915.enable_sagv=1"    # Enable system agent voltage/frequency scaling
      
      # System: Deep sleep for better battery life
      "mem_sleep_default=deep"
      
      # NVMe: Reiterate power saving latency tolerance
      "nvme_core.default_ps_max_latency_us=5500"
    ];

    # Kernel sysctls for performance and power optimization
    kernel.sysctl = {
      "vm.swappiness" = 10;                # Prefer RAM over swap
      "vm.vfs_cache_pressure" = 50;        # Balanced inode/dentry cache
      "vm.dirty_writeback_centisecs" = 1500; # 15s writeback interval
      "kernel.nmi_watchdog" = 0;           # Disable NMI watchdog (saves power)
    };

    # GRUB bootloader configuration
    loader = {
      grub = {
        enable = true;
        device = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");
        efiSupport = isPhysicalMachine;
        useOSProber = true;  # Detect other operating systems
        configurationLimit = 10;  # Keep 10 generations
        gfxmodeEfi  = "1920x1200";  # Native ThinkPad resolution
        gfxmodeBios = if isVirtualMachine then "1920x1080" else "1920x1200";
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };
      
      # EFI configuration for physical machines
      efi = lib.mkIf isPhysicalMachine {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  # ============================================================================
  # HARDWARE CONFIGURATION
  # ============================================================================
  hardware = {
    # TrackPoint configuration (ThinkPad pointer)
    trackpoint = lib.mkIf isPhysicalMachine {
      enable = true;
      speed = 200;         # Pointer speed
      sensitivity = 200;   # Pointer sensitivity
      emulateWheel = true; # Middle button scrolling
    };

    # Intel graphics configuration
    graphics = {
      enable = true;
      enable32Bit = true;  # 32-bit support for Steam/Wine
      
      # Comprehensive Intel graphics stack
      extraPackages = with pkgs; [
        intel-media-driver       # VA-API implementation
        mesa                     # OpenGL/Vulkan
        vaapiVdpau              # VDPAU backend for VA-API
        libvdpau-va-gl          # VDPAU implementation
        intel-compute-runtime   # OpenCL runtime
        intel-graphics-compiler # Graphics compiler
        level-zero              # oneAPI Level Zero support
      ];
      
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver      # 32-bit VA-API
      ];
    };

    # Firmware and microcode updates
    enableRedistributableFirmware = true;  # Non-free firmware
    enableAllFirmware             = true;  # All available firmware
    cpu.intel.updateMicrocode     = true;  # CPU security updates
    bluetooth.enable              = true;  # Bluetooth support
  };

  # ============================================================================
  # POWER MANAGEMENT (TLP)
  # ============================================================================
  # Disable conflicting power managers
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;

  # TLP - Advanced Linux Power Management
  services.tlp = lib.mkIf isPhysicalMachine {
    enable = true;
    settings = {
      # Default mode and persistence
      TLP_DEFAULT_MODE       = "AC";   # Default to AC mode
      TLP_PERSISTENT_DEFAULT = 0;       # Auto-detect AC/BAT

      # CPU frequency scaling - Passive mode with schedutil governor
      CPU_DRIVER_OPMODE           = "passive";    # OS-controlled
      CPU_SCALING_GOVERNOR_ON_AC  = "schedutil";  # Scheduler-aware
      CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";  # Consistent behavior

      # Frequency limits (Hz)
      # AC: 1.8-4.2 GHz for smooth performance
      # Battery: 1.2-3.2 GHz for efficiency
      CPU_SCALING_MIN_FREQ_ON_AC  = 1800000;  # 1.8 GHz minimum
      CPU_SCALING_MAX_FREQ_ON_AC  = 4200000;  # 4.2 GHz maximum
      CPU_SCALING_MIN_FREQ_ON_BAT = 1200000;  # 1.2 GHz minimum
      CPU_SCALING_MAX_FREQ_ON_BAT = 3200000;  # 3.2 GHz maximum

      # Intel HWP performance hints (works with passive mode)
      CPU_MIN_PERF_ON_AC  = 40;   # 40% minimum performance
      CPU_MAX_PERF_ON_AC  = 92;   # 92% maximum performance
      CPU_MIN_PERF_ON_BAT = 20;   # 20% minimum performance
      CPU_MAX_PERF_ON_BAT = 80;   # 80% maximum performance

      # Energy Performance Preference
      CPU_ENERGY_PERF_POLICY_ON_AC  = "performance";    # Favor performance
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";  # Favor efficiency

      # CPU turbo boost
      CPU_HWP_DYN_BOOST_ON_AC  = 1;      # Dynamic boost on AC
      CPU_HWP_DYN_BOOST_ON_BAT = 0;      # No dynamic boost on battery
      CPU_BOOST_ON_AC  = 1;              # Turbo always on AC
      CPU_BOOST_ON_BAT = "auto";         # Turbo when needed on battery

      # Platform profile (firmware hints)
      PLATFORM_PROFILE_ON_AC  = "balanced";  # Balanced platform behavior
      PLATFORM_PROFILE_ON_BAT = "balanced";  # Consistent across power states

      # PCIe Active State Power Management
      PCIE_ASPM_ON_AC  = "default";        # Default ASPM on AC
      PCIE_ASPM_ON_BAT = "powersupersave"; # Aggressive ASPM on battery

      # Runtime Power Management
      RUNTIME_PM_ON_AC  = "on";            # No runtime PM on AC
      RUNTIME_PM_ON_BAT = "auto";          # Auto runtime PM on battery
      RUNTIME_PM_DRIVER_DENYLIST = "nouveau radeon";  # Exclude problematic drivers

      # USB power management
      USB_AUTOSUSPEND     = 1;             # Enable USB autosuspend
      USB_DENYLIST        = "17ef:6047";   # ThinkPad dock exception
      USB_EXCLUDE_AUDIO   = 1;             # Don't suspend audio devices
      USB_EXCLUDE_BTUSB   = 0;             # Allow Bluetooth suspend
      USB_EXCLUDE_PHONE   = 1;             # Don't suspend phones
      USB_EXCLUDE_PRINTER = 1;             # Don't suspend printers
      USB_EXCLUDE_WWAN    = 0;             # Allow WWAN suspend

      # Battery charge thresholds (75-80% for longevity)
      START_CHARGE_THRESH_BAT0 = 75;  # Start charging at 75%
      STOP_CHARGE_THRESH_BAT0 = 80;   # Stop charging at 80%
      START_CHARGE_THRESH_BAT1 = 75;  # External battery start
      STOP_CHARGE_THRESH_BAT1 = 80;   # External battery stop
      RESTORE_THRESHOLDS_ON_BAT = 1;  # Restore on battery

      # Disk power management
      DISK_IDLE_SECS_ON_AC       = 0;    # No idle spindown on AC
      DISK_IDLE_SECS_ON_BAT      = 2;    # 2s idle spindown on battery
      MAX_LOST_WORK_SECS_ON_AC   = 15;   # 15s writeback on AC
      MAX_LOST_WORK_SECS_ON_BAT  = 60;   # 60s writeback on battery
      DISK_APM_LEVEL_ON_AC       = "255"; # No APM on AC (max performance)
      DISK_APM_LEVEL_ON_BAT      = "128"; # Medium APM on battery
      DISK_APM_CLASS_DENYLIST    = "usb ieee1394"; # No APM for external
      DISK_IOSCHED               = "mq-deadline";  # I/O scheduler

      # SATA link power management
      SATA_LINKPWR_ON_AC  = "max_performance";      # No SATA PM on AC
      SATA_LINKPWR_ON_BAT = "med_power_with_dipm";  # DIPM on battery

      # WiFi power saving
      WIFI_PWR_ON_AC  = "off";  # No WiFi power save on AC
      WIFI_PWR_ON_BAT = "on";   # WiFi power save on battery
      WOL_DISABLE     = "Y";    # Disable Wake-on-LAN

      # Audio power saving
      SOUND_POWER_SAVE_ON_AC  = 0;   # No audio power save on AC
      SOUND_POWER_SAVE_ON_BAT = 10;  # 10s timeout on battery
      SOUND_POWER_SAVE_CONTROLLER = "Y"; # Controller power save

      # Radio device management
      DEVICES_TO_ENABLE_ON_STARTUP  = "bluetooth wifi";      # Enable on boot
      DEVICES_TO_ENABLE_ON_AC       = "bluetooth wifi wwan"; # Enable on AC
      DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE = "wwan";        # Disable WWAN on battery
    };
  };

  # ============================================================================
  # THERMAL MANAGEMENT SERVICES
  # ============================================================================
  services = {
    # Intel thermal daemon for dynamic thermal management
    thermald.enable = true;
    
    # UPower for battery status
    upower.enable = true;

    # ThinkFan - Temperature-based fan control
    # Target: 68-72°C under load with minimal noise
    thinkfan = lib.mkIf isPhysicalMachine {
      enable = true;
      levels = [
        # [Fan Level] [Low Temp] [High Temp]
        [ "level auto"        0  46 ]  # BIOS auto control up to 46°C
        [ 1                  44  54 ]  # Level 1: 44-54°C (quiet)
        [ 2                  52  60 ]  # Level 2: 52-60°C (audible)
        [ 3                  58  66 ]  # Level 3: 58-66°C (moderate)
        [ 5                  64  72 ]  # Level 5: 64-72°C (loud)
        [ 7                  70  78 ]  # Level 7: 70-78°C (very loud)
        [ "level full-speed" 76 32767 ] # Maximum: >76°C (emergency)
      ];
    };

    # Login manager settings
    logind.settings.Login = {
      HandleLidSwitch              = "suspend";     # Suspend on lid close
      HandleLidSwitchDocked        = "suspend";     # Even when docked
      HandleLidSwitchExternalPower = "suspend";     # Even on AC power
      HandlePowerKey               = "ignore";      # Ignore short press
      HandlePowerKeyLongPress      = "poweroff";    # Shutdown on long press
      HandleSuspendKey             = "suspend";     # Suspend button
      HandleHibernateKey           = "hibernate";   # Hibernate button
    };

    # SPICE guest agent for VMs
    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
  };

  # ============================================================================
  # RAPL POWER LIMITS SERVICE
  # ============================================================================
  # Applies CPU power limits based on model and power source
  # Meteor Lake and newer use different limits due to hybrid architecture
  systemd.services.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Apply thermal-optimized RAPL power limits";
    after = [ "tlp.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ConditionPathExists = "/sys/class/powercap/intel-rapl:0";
      ExecStart = mkRobustScript "set-rapl-limits" ''
        # Detect CPU model for generation-specific limits
        CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' \
          | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.coreutils}/bin/tr -d '\n' \
          | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

        # Detect AC/DC power state
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done

        # Set power limits based on CPU generation
        # Meteor Lake and newer: Higher base power, better efficiency
        if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE 'Core\(TM\) Ultra|Meteor Lake|Arrow Lake|Lunar Lake'; then
          if [[ "$ON_AC" == "1" ]]; then
            PL1_W=22; PL2_W=30  # AC: 22W sustained, 30W burst
          else
            PL1_W=18; PL2_W=25  # Battery: 18W sustained, 25W burst
          fi
        else
          # Legacy Intel Core (Kaby Lake, Coffee Lake, etc.)
          if [[ "$ON_AC" == "1" ]]; then
            PL1_W=20; PL2_W=28  # AC: 20W sustained, 28W burst
          else
            PL1_W=15; PL2_W=22  # Battery: 15W sustained, 22W burst
          fi
        fi

        # Apply limits to all RAPL domains
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          
          # PL1: Long-term power limit (28s window)
          [[ -w "$R/constraint_0_power_limit_uw" ]] && \
            echo $(( PL1_W * 1000000 )) > "$R/constraint_0_power_limit_uw" 2>/dev/null || true
          [[ -w "$R/constraint_0_time_window_us" ]] && \
            echo 28000000 > "$R/constraint_0_time_window_us" 2>/dev/null || true
          
          # PL2: Short-term power limit (2.44s window)
          [[ -w "$R/constraint_1_power_limit_uw" ]] && \
            echo $(( PL2_W * 1000000 )) > "$R/constraint_1_power_limit_uw" 2>/dev/null || true
          [[ -w "$R/constraint_1_time_window_us" ]] && \
            echo 2440000 > "$R/constraint_1_time_window_us" 2>/dev/null || true
        done

        echo "RAPL: PL1=''${PL1_W}W PL2=''${PL2_W}W (AC=''${ON_AC})"
      '';
    };
  };

  # Timer to apply RAPL limits after boot (avoids race conditions)
  systemd.timers.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Timer: apply RAPL power limits shortly after boot";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "45s";        # 45s after boot
      Persistent = true;        # Run if missed
      Unit = "rapl-power-limits.service";
    };
  };

  # Re-apply RAPL limits after resume from sleep
  systemd.services.rapl-power-limits-resume = lib.mkIf isPhysicalMachine {
    description = "Re-apply RAPL limits after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ConditionPathExists = "/sys/class/powercap/intel-rapl:0";
      ExecStart = "${pkgs.systemd}/bin/systemctl start rapl-power-limits.service";
    };
  };

  # ============================================================================
  # CPU AUTOTUNE SERVICE
  # ============================================================================
  # Ensures optimal CPU frequency settings and schedutil tuning
  systemd.services.cpu-epp-autotune = lib.mkIf isPhysicalMachine {
    description = "CPU autotune (governor, schedutil ramp, min_freq guarantee)";
    after = [ "tlp.service" ];
    serviceConfig = {
      Type = "oneshot";
      ConditionPathExists = "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor";
      ExecStart = mkRobustScript "cpu-epp-autotune" ''
        # Select best available governor (prefer schedutil)
        GOVS="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")"
        target="powersave"  # Fallback to powersave
        echo "$GOVS" | ${pkgs.gnugrep}/bin/grep -qw schedutil && target="schedutil"
        
        # Apply governor to all policies
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$pol/scaling_governor" ]] && echo "$target" > "$pol/scaling_governor" || true
        done

        # Detect power state for frequency tuning
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done

        # Set minimum frequency based on power state
        if [[ "$ON_AC" == "1" ]]; then
          MIN_FREQ=1800000   # 1.8 GHz on AC for smoothness
        else
          MIN_FREQ=1200000   # 1.2 GHz on battery (guaranteed minimum)
        fi

        # Apply frequency limits and schedutil tuning
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          # Set minimum frequency
          [[ -w "$pol/scaling_min_freq" ]] && echo "$MIN_FREQ" > "$pol/scaling_min_freq" || true
          
          # Tune schedutil parameters if available
          if [[ -d "$pol/schedutil" ]]; then
            # Fast ramp up (1ms), slower ramp down (5ms)
            [[ -w "$pol/schedutil/up_rate_limit_us"    ]] && echo 1000  > "$pol/schedutil/up_rate_limit_us"    || true
            [[ -w "$pol/schedutil/down_rate_limit_us"  ]] && echo 5000  > "$pol/schedutil/down_rate_limit_us"  || true
            # Enable I/O wait boost for better interactivity
            [[ -w "$pol/schedutil/iowait_boost_enable" ]] && echo 1     > "$pol/schedutil/iowait_boost_enable" || true
          fi
        done

        echo "autotune: governor=$target, min_freq>=''$((MIN_FREQ/1000)) MHz (AC=$ON_AC)"
      '';
    };
  };

  # Timer for CPU autotune (after TLP)
  systemd.timers.cpu-epp-autotune = lib.mkIf isPhysicalMachine {
    description = "Timer: autotune after TLP";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";        # 30s after boot
      Persistent = true;
      Unit = "cpu-epp-autotune.service";
    };
  };

  # Re-apply autotune after resume
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
  # UDEV RULES FOR AC/DC TRANSITIONS
  # ============================================================================
  # Automatically reconfigure system when power adapter is connected/disconnected
  services.udev.extraRules = lib.mkIf isPhysicalMachine ''
    # Trigger on AC adapter state change
    SUBSYSTEM=="power_supply", KERNEL=="AC*",  ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start rapl-power-limits.service"
    SUBSYSTEM=="power_supply", KERNEL=="AC*",  ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service"
    SUBSYSTEM=="power_supply", KERNEL=="ADP*", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start rapl-power-limits.service"
    SUBSYSTEM=="power_supply", KERNEL=="ADP*", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start cpu-epp-autotune.service"
  '';

  # ============================================================================
  # THINKPAD-SPECIFIC SERVICES
  # ============================================================================
  
  # Disable ThinkPad mute LEDs (they stay on unnecessarily)
  systemd.services.thinkpad-led-fix = lib.mkIf isPhysicalMachine {
    description = "Turn off ThinkPad mute LEDs";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkRobustScript "disable-mute-leds" ''
        # Turn off both mute and mic-mute LEDs
        for led in /sys/class/leds/platform::{mute,micmute}/brightness; do
          [[ -w "$led" ]] && echo 0 > "$led" 2>/dev/null || true
        done
      '';
    };
  };

  # Re-apply LED fix after resume
  systemd.services.thinkpad-led-fix-resume = lib.mkIf isPhysicalMachine {
    description = "Turn off ThinkPad mute LEDs after resume";
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    after    = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkRobustScript "disable-mute-leds-resume" ''
        for led in /sys/class/leds/platform::{mute,micmute}/brightness; do
          [[ -w "$led" ]] && echo 0 > "$led" 2>/dev/null || true
        done
      '';
    };
  };

  # Fan control during suspend/resume cycle
  systemd.services.suspend-pre-fan = lib.mkIf isPhysicalMachine {
    description = "Stop thinkfan before suspend";
    wantedBy = [ "sleep.target" ];
    before   = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkRobustScript "suspend-pre-fan" ''
        # Stop thinkfan service to prevent conflicts
        ${pkgs.systemd}/bin/systemctl stop thinkfan.service 2>/dev/null || true
        # Set fan to auto mode
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
      ExecStart = mkRobustScript "resume-post-fan" ''
        # Wait for system to stabilize
        sleep 1
        # Restart thinkfan if it was enabled
        if ${pkgs.systemd}/bin/systemctl is-enabled thinkfan.service >/dev/null 2>&1; then
          ${pkgs.systemd}/bin/systemctl restart thinkfan.service 2>/dev/null || true
        else
          # Fallback to auto mode if thinkfan is disabled
          [[ -w /proc/acpi/ibm/fan ]] && echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true
        fi
      '';
    };
  };

  # Disable legacy fan services if they exist
  systemd.services.thinkfan-sleep  = lib.mkIf isPhysicalMachine { 
    enable = lib.mkForce false; 
    wantedBy = lib.mkForce [ ]; 
  };
  systemd.services.thinkfan-wakeup = lib.mkIf isPhysicalMachine { 
    enable = lib.mkForce false; 
    wantedBy = lib.mkForce [ ]; 
  };

  # ============================================================================
  # USER UTILITY SCRIPTS
  # ============================================================================
  # Convenient commands for manual power management
  environment.systemPackages = with pkgs;
    lib.optionals isPhysicalMachine [
      tlp          # TLP commands
      lm_sensors   # Temperature monitoring

      # Performance mode: Maximum performance, higher thermals
      (writeScriptBin "performance-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "🚀 Switching to Performance mode..."
        
        # Activate TLP AC mode
        sudo ${tlp}/bin/tlp ac
        
        # Set governor (prefer schedutil)
        GOVS="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")"
        target="powersave"
        echo "$GOVS" | ${gnugrep}/bin/grep -qw schedutil && target="schedutil"
        
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$p/scaling_governor" ]] && echo "$target" | sudo tee "$p/scaling_governor" >/dev/null || true
        done
        
        # Set minimum frequency to 1.8 GHz for responsiveness
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          if [[ -w "$p/scaling_min_freq" ]]; then
            echo 1800000 | sudo tee "$p/scaling_min_freq" >/dev/null || true
          fi
          
          # Tune schedutil for performance
          if [[ -d "$p/schedutil" ]]; then
            echo 1000 | sudo tee "$p/schedutil/up_rate_limit_us" >/dev/null || true
            echo 5000 | sudo tee "$p/schedutil/down_rate_limit_us" >/dev/null || true
            echo 1    | sudo tee "$p/schedutil/iowait_boost_enable" >/dev/null || true
          fi
        done
        
        # Set aggressive RAPL limits: 25W/32W
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && echo 25000000 | sudo tee "$R/constraint_0_power_limit_uw" >/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && echo 32000000 | sudo tee "$R/constraint_1_power_limit_uw" >/dev/null || true
        done
        
        echo "✅ Performance mode active: governor=$target, min_freq≥1800 MHz, RAPL 25/32W"
      '')

      # Balanced mode: Default configuration
      (writeScriptBin "balanced-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "⚖️ Switching to Balanced mode..."
        
        # Restart TLP with default settings
        sudo ${tlp}/bin/tlp start
        
        # Set governor
        GOVS="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")"
        target="powersave"
        echo "$GOVS" | ${gnugrep}/bin/grep -qw schedutil && target="schedutil"
        
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$p/scaling_governor" ]] && echo "$target" | sudo tee "$p/scaling_governor" >/dev/null || true
        done
        
        # Set minimum frequency to 1.8 GHz on AC
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          if [[ -w "$p/scaling_min_freq" ]]; then
            echo 1800000 | sudo tee "$p/scaling_min_freq" >/dev/null || true
          fi
          
          # Balanced schedutil tuning
          if [[ -d "$p/schedutil" ]]; then
            echo 1000 | sudo tee "$p/schedutil/up_rate_limit_us" >/dev/null || true
            echo 5000 | sudo tee "$p/schedutil/down_rate_limit_us" >/dev/null || true
            echo 1    | sudo tee "$p/schedutil/iowait_boost_enable" >/dev/null || true
          fi
        done
        
        # Set balanced RAPL limits: 22W/30W
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && echo 22000000 | sudo tee "$R/constraint_0_power_limit_uw" >/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && echo 30000000 | sudo tee "$R/constraint_1_power_limit_uw" >/dev/null || true
        done
        
        echo "✅ Balanced mode active: governor=$target, min_freq≥1800 MHz, RAPL 22/30W"
      '')

      # Cool mode: Prioritize thermals and battery life
      (writeScriptBin "cool-mode" ''
        #!${bash}/bin/bash
        set -e
        echo "❄️ Switching to Cool mode..."
        
        # Set governor
        GOVS="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")"
        target="powersave"
        echo "$GOVS" | ${gnugrep}/bin/grep -qw schedutil && target="schedutil"
        
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$p/scaling_governor" ]] && echo "$target" | sudo tee "$p/scaling_governor" >/dev/null || true
        done
        
        # Lower minimum frequency to 1.2 GHz
        for p in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ -w "$p/scaling_min_freq" ]] && echo 1200000 | sudo tee "$p/scaling_min_freq" >/dev/null || true
          
          # Conservative schedutil tuning
          if [[ -d "$p/schedutil" ]]; then
            echo 1000 | sudo tee "$p/schedutil/up_rate_limit_us" >/dev/null || true
            echo 7000 | sudo tee "$p/schedutil/down_rate_limit_us" >/dev/null || true
            echo 1    | sudo tee "$p/schedutil/iowait_boost_enable" >/dev/null || true
          fi
        done
        
        # Set conservative RAPL limits: 18W/25W
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          [[ -w "$R/constraint_0_power_limit_uw" ]] && echo 18000000 | sudo tee "$R/constraint_0_power_limit_uw" >/dev/null || true
          [[ -w "$R/constraint_1_power_limit_uw" ]] && echo 25000000 | sudo tee "$R/constraint_1_power_limit_uw" >/dev/null || true
        done
        
        echo "✅ Cool mode active: governor=$target, min_freq=1200 MHz, RAPL 18/25W"
      '')

      # Power status: Quick overview of power settings
      (writeScriptBin "power-status" ''
        #!${bash}/bin/bash
        echo "==== Power Status ===="
        echo ""
        echo "TLP Status:"
        sudo ${tlp}/bin/tlp-stat -s -c -p | head -40
        echo ""
        echo "CPU Governor:"
        cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A"
        echo ""
        echo "RAPL Limits:"
        for R in /sys/class/powercap/intel-rapl:0/constraint_*_power_limit_uw; do
          [ -f "$R" ] && echo "$(basename "$R" | cut -d_ -f1-2): $(($(cat "$R")/1000000))W"
        done
      '')

      # Performance monitoring: Comprehensive system status
      (writeScriptBin "perf-mode" ''
        #!${bash}/bin/bash
        set -euo pipefail
        cmd="''${1:-status}"
        
        show_status() {
          # CPU model
          CPU="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.gnused}/bin/sed 's/^ *//')"
          
          # Governor
          GOV="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo n/a)"
          
          # Power source
          PWR="BAT"
          for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
            [ -f "$PS" ] && [ "$(cat "$PS")" = "1" ] && PWR="AC" && break
          done
          
          echo "CPU: $CPU"
          echo "Power: $PWR"
          echo "Governor: $GOV"
          echo ""
          echo "CPU Frequencies (first 12 cores):"
          
          # Show current frequencies
          i=0
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
            [ -f "$f" ] || continue
            mhz=$(( $(cat "$f") / 1000 ))
            printf "  Core %02d: %4d MHz\n" "$i" "$mhz"
            i=$((i+1))
            [ $i -ge 12 ] && break
          done
          
          echo ""
          # RAPL limits
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            pl1="$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)"
            pl2="$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)"
            [ "$pl1" != "0" ] && echo "PL1: $((pl1/1000000)) W"
            [ "$pl2" != "0" ] && echo "PL2: $((pl2/1000000)) W"
          fi
          
          echo ""
          # Temperature
          TEMP_RAW="$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep -m1 -E 'Package id 0|Tctl' || true)"
          TEMP="$(echo "$TEMP_RAW" | ${pkgs.gnused}/bin/sed -E 's/.*: *\+?([0-9]+\.?[0-9]*)°C.*/\1°C/' )"
          [[ -z "$TEMP" ]] && TEMP="n/a"
          echo "CPU Temperature: $TEMP"
        }
        
        case "$cmd" in
          status) show_status ;;
          perf)   performance-mode ;;
          bal)    balanced-mode ;;
          cool)   cool-mode ;;
          *) 
            echo "Usage: perf-mode {status|perf|bal|cool}"
            echo ""
            echo "  status - Show current power/thermal status"
            echo "  perf   - Switch to performance mode"
            echo "  bal    - Switch to balanced mode"
            echo "  cool   - Switch to cool/quiet mode"
            exit 2
            ;;
        esac
      '')

      # Thermal monitoring: Live temperature and fan monitoring
      (writeScriptBin "thermal-monitor" ''
        #!${bash}/bin/bash
        echo "Monitoring thermals... (Press Ctrl+C to exit)"
        echo ""
        
        watch -n 1 ${pkgs.bash}/bin/bash -c '
          echo "=== CPU Thermals ==="
          ${pkgs.lm_sensors}/bin/sensors | ${pkgs.gnugrep}/bin/grep -E "Package|Tctl|fan"
          echo ""
          echo "=== Power Limits ==="
          for f in /sys/class/powercap/intel-rapl:0/constraint_*_power_limit_uw; do
            [ -f "$f" ] && echo "$(basename "$f" | cut -d_ -f1-2): $(($(cat "$f")/1000000))W"
          done
          echo ""
          echo "=== CPU Frequencies ==="
          echo -n "Current: "
          for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
            [ -f "$f" ] && echo -n "$(($(cat "$f")/1000)) "
          done | cut -d" " -f1-8
          echo " MHz"
        '
      '')
    ];

  # ============================================================================
  # SUMMARY
  # ============================================================================
  # This configuration provides:
  #
  # 1. AUTOMATIC POWER MANAGEMENT
  #    - TLP handles most power settings automatically
  #    - Adaptive RAPL limits based on CPU generation
  #    - Dynamic frequency scaling with guaranteed minimums
  #
  # 2. THERMAL OPTIMIZATION
  #    - Multi-tier fan curves with hysteresis
  #    - Preventive thermal management via thermald
  #    - Target: 68-72°C under sustained load
  #
  # 3. BATTERY PRESERVATION
  #    - 75-80% charge thresholds
  #    - Aggressive power saving on battery
  #    - Component-level optimization
  #
  # 4. USER CONTROL
  #    - Manual performance modes (performance/balanced/cool)
  #    - Real-time monitoring tools
  #    - Comprehensive status reporting
  #
  # 5. ROBUSTNESS
  #    - Automatic reconfiguration on AC/DC transitions
  #    - Persistent settings across sleep states
  #    - Graceful error handling
  #
  # The system automatically adapts to power state changes and maintains
  # optimal performance while preventing thermal throttling. Manual
  # intervention is rarely needed, but comprehensive tools are provided
  # for users who want fine-grained control.
  #
  # ============================================================================
}

