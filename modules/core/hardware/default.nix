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
    # Lenovo throttling fix with aggressive thermal management
    # NOTE: Thermald has been removed due to compatibility issues with Meteor Lake
    # and XML configuration errors. throttled + auto-cpufreq + thinkfan provides
    # superior thermal management for modern Intel processors.
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
    };

    # TLP disabled in favor of auto-cpufreq for modern CPU management
    tlp.enable = false;
    
    # Modern CPU frequency management with aggressive thermal controls
    # This replaces thermald for Meteor Lake processors with better compatibility
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          scaling_min_freq = 400000;   # 400 MHz minimum frequency
          scaling_max_freq = 2500000;  # 2.5 GHz maximum on battery (reduced for thermals)
          turbo = "never";             # Disable turbo boost on battery
        };
        charger = {
          governor = "powersave";      # Use powersave governor even on AC
          scaling_min_freq = 400000;   # 400 MHz minimum frequency
          scaling_max_freq = 3500000;  # 3.5 GHz maximum on AC (reduced from 4.8 GHz)
          turbo = "auto";              # Allow turbo but let thermal management control it
        };
      };
    };

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
  };
  
  # ==============================================================================
  # System Services
  # ==============================================================================
  systemd.services = {
    # CPU power limit service for additional thermal control
    # Sets RAPL (Running Average Power Limit) constraints for Intel CPUs
    cpu-power-limit = {
      description = "Set Intel RAPL power limits for thermal management";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
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
          fi
        '';
      };
    };
    
    # Fix LED state on boot for ThinkPad E14 Gen 6
    # Ensures microphone and mute LEDs work correctly with audio integration
    fix-led-state = {
      description = "Fix ThinkPad LED states on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "fix-leds" ''
          # Configure LED triggers for proper audio integration
          echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
          echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
          
          # Initialize LED states to off
          echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
        '';
        RemainAfterExit = true;
      };
    };
    
    # Thermal monitoring service for system health
    # Provides logging and awareness of temperature conditions
    thermal-monitor = {
      description = "Monitor system thermal status and log warnings";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "thermal-monitor" ''
          while true; do
            # Get highest temperature from all thermal zones
            TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
            TEMP_C=$((TEMP / 1000))
            
            # Log warning if temperature exceeds safe operating range
            if [ "$TEMP_C" -gt 90 ]; then
              echo "WARNING: High CPU temperature detected: $${TEMP_C}°C"
              logger -t thermal-monitor "High CPU temperature: $${TEMP_C}°C - Consider checking cooling system"
            fi
            
            # Sleep for 30 seconds between checks
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
    # Ensure user has write access to LED controls
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::micmute/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::mute/brightness"
    
    # Dynamic CPU governor switching based on power source
    # Use powersave governor for optimal battery life and thermal management
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
  '';
}

