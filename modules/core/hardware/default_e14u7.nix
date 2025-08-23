# modules/core/hardware/default.nix
# ==============================================================================
# Hardware Configuration for ThinkPad E14 Gen 6
# ==============================================================================
# This configuration manages hardware settings including:
# - ThinkPad-specific ACPI and advanced thermal management
# - Intel Arc Graphics drivers and hardware acceleration
# - NVMe storage optimizations for dual-drive setup
# - Intel Core Ultra 7 155H CPU thermal and power management
# - LED control and function key management
# - TrackPoint and touchpad configuration
# - Optimized thermal throttling for stable operation
#
# Target Hardware:
# - ThinkPad E14 Gen 6 (21M7006LTX)
# - Intel Core Ultra 7 155H (16-core hybrid architecture)
# - Intel Arc Graphics (Meteor Lake-P)
# - 64GB DDR5 RAM
# - Dual NVMe setup: Transcend TS2TMTE400S + Timetec 35TT2280GEN4E-2TB
#
# Performance Targets:
# - CPU Temperature: 75-85°C under load
# - Fan Noise: Balanced (progressive curve)
# - Power Consumption: 35W sustained, 45W burst
#
# Author: Kenan Pelit
# Modified: 2025-08-23 (Final thermal optimization for E14 Gen 6)
# ==============================================================================
{ pkgs, ... }:
{
  # ==============================================================================
  # Hardware Configuration
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
  # Thermal and Power Management Services
  # ==============================================================================
  services = {
    # Lenovo throttling fix with optimized thermal management
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
        # Long-term power limit (Watts) - balanced for battery life
        PL1_Tdp_W: 25
        PL1_Duration_s: 28
        # Short-term power limit (Watts)
        PL2_Tdp_W: 35
        PL2_Duration_S: 0.002
        # Temperature threshold for throttling (Celsius)
        Trip_Temp_C: 80

        [AC]
        # Update rate for AC mode (seconds)
        Update_Rate_s: 5
        # Long-term power limit (Watts) - balanced performance
        PL1_Tdp_W: 35
        PL1_Duration_s: 28
        # Short-term power limit (Watts)
        PL2_Tdp_W: 45
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
    };

    # TLP disabled in favor of auto-cpufreq for modern CPU management
    tlp.enable = false;
    
    # Modern CPU frequency management with balanced thermal controls
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          scaling_min_freq = 400000;   # 400 MHz minimum frequency
          scaling_max_freq = 2800000;  # 2.8 GHz maximum on battery
          turbo = "never";             # Disable turbo boost on battery
        };
        charger = {
          governor = "powersave";      # Use powersave for thermal management
          scaling_min_freq = 400000;   # 400 MHz minimum frequency
          scaling_max_freq = 3800000;  # 3.8 GHz maximum on AC (balanced)
          turbo = "auto";              # Allow turbo with thermal limits
        };
      };
    };

    # ThinkPad fan control with optimized cooling curve
    thinkfan = {
      enable = true;  # IMPORTANT: Enable thinkfan for active cooling
      smartSupport = true;
      
      # Optimized fan curve for E14 Gen 6
      levels = [
        # [fan_level temp_low temp_high]
        [ 0  0   60 ]          # Fan off below 60°C (quiet operation)
        [ 1  58  65 ]          # Level 1: 58-65°C (barely audible)
        [ 2  63  70 ]          # Level 2: 63-70°C (quiet)
        [ 3  68  75 ]          # Level 3: 68-75°C (noticeable)
        [ 4  73  78 ]          # Level 4: 73-78°C (moderate)
        [ 5  77  82 ]          # Level 5: 77-82°C (loud)
        [ 6  81  85 ]          # Level 6: 81-85°C (very loud)
        [ 7  84  88 ]          # Level 7: 84-88°C (maximum normal)
        [ "level full-speed"  87  32767 ]  # Full speed above 87°C (emergency)
      ];
    };

    # Intel thermal daemon - disabled due to Meteor Lake compatibility issues
    thermald.enable = false;

    # Disable power-profiles-daemon to avoid conflicts with auto-cpufreq
    power-profiles-daemon.enable = false;
  };
  
  # ==============================================================================
  # Boot Configuration
  # ==============================================================================
  boot = {
    # Essential kernel modules for hardware monitoring and control
    kernelModules = [ 
      "thinkpad_acpi"  # ThinkPad ACPI extras (fan control, LEDs, etc.)
      "coretemp"       # CPU temperature monitoring
      "intel_rapl"     # Intel RAPL power capping interface
      "msr"            # Model-specific register access
    ];
    
    # Module options for ThinkPad-specific features
    extraModprobeConfig = ''
      # ThinkPad ACPI configuration
      options thinkpad_acpi fan_control=1      # Enable manual fan control
      options thinkpad_acpi brightness_mode=1   # Improved brightness control
      options thinkpad_acpi volume_mode=1       # Better volume key handling
      options thinkpad_acpi experimental=1      # Enable experimental features
      
      # Intel P-state driver options for better power management
      options intel_pstate hwp_dynamic_boost=0  # Disable dynamic boost for stability
    '';
    
    # Kernel parameters for optimized thermal and power management
    kernelParams = [
      # NVMe optimization - disable ACPI for better performance
      "nvme.noacpi=1"
      
      # IOMMU for better device isolation and security
      "intel_iommu=on"
      "iommu=pt"                    # Pass-through mode for better performance
      
      # CPU power management settings
      "intel_pstate=passive"        # Passive mode for governor-based control
      "processor.max_cstate=3"      # Limit deep C-states for responsiveness
      "intel_idle.max_cstate=3"     # Limit idle states
      
      # Intel Arc Graphics power saving and performance
      "i915.enable_guc=3"           # Enable GuC and HuC firmware
      "i915.enable_fbc=1"           # Frame buffer compression
      "i915.enable_psr=2"           # Panel self refresh v2
      "i915.enable_dc=2"            # Display C-states
      "i915.fastboot=1"             # Faster graphics initialization
      
      # Thermal management settings
      "thermal.off=0"               # Ensure thermal management is enabled
      "thermal.act=-1"              # ACPI thermal control (automatic)
      "thermal.nocrt=0"             # Enable critical temperature actions
      "thermal.psv=-1"              # Automatic passive cooling
      
      # Memory and performance
      "transparent_hugepage=madvise" # Optimize memory usage
      "mitigations=auto"            # Keep security mitigations enabled
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
          #!/usr/bin/env sh
          # Wait for RAPL interface to be available
          sleep 2
          
          # Check if RAPL interface is available
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            # Detect power source
            ON_AC=0
            if [ -f /sys/class/power_supply/AC/online ]; then
              ON_AC=$(cat /sys/class/power_supply/AC/online)
            fi
            
            if [ "$ON_AC" = "1" ]; then
              # AC Power: Higher limits for performance
              echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo 45000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Intel RAPL power limits set (AC): PL1=35W, PL2=45W"
            else
              # Battery: Lower limits for efficiency
              echo 25000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Intel RAPL power limits set (Battery): PL1=25W, PL2=35W"
            fi
            
            # Set time windows
            echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us
            echo 2500 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us
          else
            echo "Intel RAPL interface not available - skipping power limit configuration"
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
          # Configure LED triggers for proper audio integration
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
            # Get highest temperature from all thermal zones
            TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
            if [ -n "$TEMP" ]; then
              TEMP_C=$((TEMP / 1000))
              
              # Log based on temperature thresholds
              if [ "$TEMP_C" -gt "$CRITICAL_THRESHOLD" ]; then
                echo "CRITICAL: CPU temperature: $${TEMP_C}°C - System may throttle severely"
                logger -p user.crit -t thermal-monitor "Critical CPU temperature: $${TEMP_C}°C"
              elif [ "$TEMP_C" -gt "$WARNING_THRESHOLD" ]; then
                echo "WARNING: High CPU temperature: $${TEMP_C}°C - Performance may be reduced"
                logger -p user.warning -t thermal-monitor "High CPU temperature: $${TEMP_C}°C"
              fi
            fi
            
            # Check every 30 seconds
            sleep 30
          done
        '';
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
  
  # ==============================================================================
  # Udev Rules
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
  '';
}

