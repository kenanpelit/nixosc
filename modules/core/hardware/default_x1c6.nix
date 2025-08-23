# modules/core/hardware/default.nix
# ==============================================================================
# Hardware Configuration for ThinkPad X1 Carbon 6th
# ==============================================================================
# This configuration manages hardware settings including:
# - ThinkPad-specific ACPI and thermal management
# - Intel UHD Graphics 620 drivers and hardware acceleration
# - NVMe storage optimizations
# - Intel Core i7-8650U CPU thermal and power management
# - LED control and function key management
# - TrackPoint and touchpad configuration
# - Conservative undervolting for stability
#
# Target Hardware:
# - ThinkPad X1 Carbon 6th (20KHS0XR00)
# - Intel Core i7-8650U (4-core, 8-thread, Kaby Lake R)
# - Intel UHD Graphics 620
# - 16GB LPDDR3 RAM
# - Samsung 1TB NVMe SSD
#
# Performance Targets:
# - CPU Temperature: 65-80°C under load
# - Fan Noise: Minimal (quiet operation priority)
# - Power Consumption: 15W sustained, 25W burst
# - Undervolt: Conservative -80mV for stability
#
# Author: Kenan Pelit
# Modified: 2025-08-23 (Final optimization for X1 Carbon 6th)
# ==============================================================================
{ pkgs, ... }:
{
  # ==============================================================================
  # Hardware Configuration
  # ==============================================================================
  hardware = {
    # Enable TrackPoint for ThinkPad
    trackpoint = {
      enable = true;
      speed = 200;        # Adjust TrackPoint sensitivity
      sensitivity = 200;  # Adjust TrackPoint sensitivity
    };
    
    # Intel UHD Graphics 620 configuration
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver      # VA-API implementation
        vaapiVdpau             # VDPAU backend for VA-API
        libvdpau-va-gl         # VDPAU driver with OpenGL/VAAPI backend
        mesa                   # OpenGL implementation
        intel-vaapi-driver     # Legacy VA-API driver (backup)
      ];
    };
    
    # Firmware configuration
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
  };
  
  # ==============================================================================
  # Thermal and Power Management Services
  # ==============================================================================
  services = {
    # Lenovo throttling fix with conservative undervolting
    throttled = {
      enable = true;
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
        # Long-term power limit (Watts) - optimized for battery life
        PL1_Tdp_W: 15
        PL1_Duration_s: 28
        # Short-term power limit (Watts)
        PL2_Tdp_W: 25
        PL2_Duration_S: 0.002
        # Temperature threshold for throttling (Celsius)
        Trip_Temp_C: 75

        [AC]
        # Update rate for AC mode (seconds)
        Update_Rate_s: 5
        # Long-term power limit (Watts) - balanced for quiet operation
        PL1_Tdp_W: 20
        PL1_Duration_s: 28
        # Short-term power limit (Watts)
        PL2_Tdp_W: 30
        PL2_Duration_S: 0.002
        # Temperature threshold for throttling (Celsius)
        Trip_Temp_C: 80

        [UNDERVOLT.BATTERY]
        # Conservative undervolting for Kaby Lake R (stability first)
        CORE: -60
        GPU: -40
        CACHE: -60
        UNCORE: 0
        ANALOGIO: 0

        [UNDERVOLT.AC]
        # Moderate undervolting on AC (better cooling available)
        CORE: -80
        GPU: -60
        CACHE: -80
        UNCORE: 0
        ANALOGIO: 0
      '';
    };

    # TLP disabled in favor of auto-cpufreq
    tlp.enable = false;
    
    # Modern CPU frequency management optimized for ultrabook
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          scaling_min_freq = 400000;   # 400 MHz minimum
          scaling_max_freq = 2200000;  # 2.2 GHz maximum on battery
          turbo = "never";             # Disable turbo for battery life
        };
        charger = {
          governor = "powersave";      # Powersave for quiet operation
          scaling_min_freq = 400000;   # 400 MHz minimum
          scaling_max_freq = 3500000;  # 3.5 GHz maximum on AC
          turbo = "auto";              # Allow turbo with limits
        };
      };
    };

    # ThinkPad fan control - optimized for quiet X1 Carbon operation
    thinkfan = {
      enable = true;
      smartSupport = true;
      
      # Conservative fan curve for quiet operation
      levels = [
        # [fan_level temp_low temp_high]
        [ 0  0   55 ]          # Fan off below 55°C (silent)
        [ 1  53  60 ]          # Level 1: 53-60°C (barely audible)
        [ 2  58  65 ]          # Level 2: 58-65°C (very quiet)
        [ 3  63  70 ]          # Level 3: 63-70°C (quiet)
        [ 4  68  75 ]          # Level 4: 68-75°C (audible)
        [ 5  73  80 ]          # Level 5: 73-80°C (moderate)
        [ 6  78  85 ]          # Level 6: 78-85°C (loud)
        [ 7  83  90 ]          # Level 7: 83-90°C (very loud)
        [ "level full-speed"  88  32767 ]  # Maximum above 88°C
      ];
    };

    # Intel thermal daemon for additional thermal management
    thermald = {
      enable = true;
      # Use default configuration for Kaby Lake R (well-supported)
    };

    # Disable power-profiles-daemon to avoid conflicts
    power-profiles-daemon.enable = false;
  };
  
  # ==============================================================================
  # Boot Configuration
  # ==============================================================================
  boot = {
    # Essential kernel modules
    kernelModules = [ 
      "thinkpad_acpi"  # ThinkPad ACPI extras
      "coretemp"       # Temperature monitoring
      "intel_rapl"     # Intel RAPL power capping
      "msr"            # Model-specific registers
    ];
    
    # Module options for ThinkPad features
    extraModprobeConfig = ''
      # ThinkPad ACPI configuration
      options thinkpad_acpi fan_control=1      # Enable fan control
      options thinkpad_acpi brightness_mode=1   # Better brightness control
      options thinkpad_acpi volume_mode=1       # Volume key handling
      options thinkpad_acpi experimental=1      # Experimental features
      
      # Intel P-state driver options
      options intel_pstate hwp_dynamic_boost=0  # Disable for consistency
    '';
    
    # Kernel parameters for thermal and power optimization
    kernelParams = [
      # NVMe optimization
      "nvme_core.default_ps_max_latency_us=0"  # Better NVMe performance
      
      # CPU power management
      "intel_pstate=active"         # Active mode for better efficiency
      "processor.max_cstate=7"      # Allow deep C-states for battery
      "intel_idle.max_cstate=7"     # Allow deep idle states
      
      # Intel Graphics power saving
      "i915.enable_guc=2"           # Enable GuC firmware
      "i915.enable_fbc=1"           # Frame buffer compression
      "i915.enable_psr=1"           # Panel self refresh
      "i915.enable_dc=2"            # Display C-states
      "i915.fastboot=1"             # Faster boot
      "i915.modeset=1"              # Enable kernel mode setting
      
      # Thermal management
      "thermal.off=0"               # Ensure thermal management enabled
      "thermal.act=-1"              # ACPI thermal control
      
      # Power saving
      "pcie_aspm=force"             # Force PCIe power management
      "snd_hda_intel.power_save=1"  # Audio power saving
      "iwlwifi.power_save=1"        # WiFi power saving
      "iwlwifi.power_level=3"       # WiFi power level
      
      # Memory and performance
      "transparent_hugepage=madvise" # Optimize memory
      "mitigations=auto"            # Keep security mitigations
    ];
  };
  
  # ==============================================================================
  # System Services
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
          #!/bin/sh
          # Wait for RAPL interface
          sleep 2
          
          # Check if RAPL is available
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            # Detect power source
            ON_AC=0
            if [ -f /sys/class/power_supply/AC/online ]; then
              ON_AC=$(cat /sys/class/power_supply/AC/online)
            elif [ -f /sys/class/power_supply/ADP1/online ]; then
              ON_AC=$(cat /sys/class/power_supply/ADP1/online)
            fi
            
            if [ "$ON_AC" = "1" ]; then
              # AC Power: Moderate limits for quiet operation
              echo 20000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo 30000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Intel RAPL power limits set (AC): PL1=20W, PL2=30W"
            else
              # Battery: Conservative limits for efficiency
              echo 15000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo 25000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Intel RAPL power limits set (Battery): PL1=15W, PL2=25W"
            fi
            
            # Set time windows
            echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us
            echo 2500 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us
          else
            echo "Intel RAPL not available"
          fi
        '';
      };
    };
    
    # Fix LED state on boot for ThinkPad X1 Carbon 6th
    fix-led-state = {
      description = "Fix ThinkPad LED states on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "fix-leds" ''
          #!/bin/sh
          # Set LED triggers for audio integration
          if [ -d /sys/class/leds/platform::micmute ]; then
            echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          fi
          
          if [ -d /sys/class/leds/platform::mute ]; then
            echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
          fi
          
          # ThinkPad LED (red dot)
          if [ -d /sys/class/leds/tpacpi::lid_logo_dot ]; then
            echo 0 > /sys/class/leds/tpacpi::lid_logo_dot/brightness 2>/dev/null || true
          fi
        '';
        RemainAfterExit = true;
      };
    };
    
    # Battery charge threshold service
    battery-charge-threshold = {
      description = "Set battery charge thresholds for longevity";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "battery-threshold" ''
          #!/bin/sh
          # Set battery charge thresholds (if supported)
          BAT_PATH="/sys/class/power_supply/BAT0"
          
          if [ -f "$BAT_PATH/charge_control_start_threshold" ]; then
            echo 75 > "$BAT_PATH/charge_control_start_threshold"
            echo "Battery start charge threshold set to 75%"
          fi
          
          if [ -f "$BAT_PATH/charge_control_end_threshold" ]; then
            echo 80 > "$BAT_PATH/charge_control_end_threshold"
            echo "Battery stop charge threshold set to 80%"
          fi
        '';
      };
    };
    
    # Thermal monitoring service
    thermal-monitor = {
      description = "Monitor system thermal status";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "thermal-monitor" ''
          #!/bin/sh
          WARNING_THRESHOLD=85
          CRITICAL_THRESHOLD=90
          
          while true; do
            # Get highest temperature from all thermal zones
            TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
            if [ -n "$TEMP" ]; then
              TEMP_C=$((TEMP / 1000))
              
              # Log based on temperature thresholds
              if [ "$TEMP_C" -gt "$CRITICAL_THRESHOLD" ]; then
                echo "CRITICAL: CPU temperature: ${TEMP_C}°C - System throttling active"
                logger -p user.crit -t thermal-monitor "Critical CPU temperature: ${TEMP_C}°C"
              elif [ "$TEMP_C" -gt "$WARNING_THRESHOLD" ]; then
                echo "WARNING: High CPU temperature: ${TEMP_C}°C"
                logger -p user.warning -t thermal-monitor "High CPU temperature: ${TEMP_C}°C"
              fi
            fi
            
            # Check every 30 seconds
            sleep 30
          done
        '';
        Restart = "always";
        RestartSec = 10;
      };

