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
# Modified: 2025-08-23 (Thermal optimization for high temperature issues)
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

    # TLP disabled in favor of auto-cpufreq
    tlp.enable = false;
    
    # Modern CPU frequency management
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          scaling_min_freq = 400000;   # 400 MHz minimum
          scaling_max_freq = 2500000;  # 2.5 GHz maximum on battery
          turbo = "never";             # Disable turbo on battery
        };
        charger = {
          governor = "powersave";      # Use powersave even on AC for thermal management
          scaling_min_freq = 400000;   # 400 MHz minimum
          scaling_max_freq = 3500000;  # 3.5 GHz maximum on AC (reduced from 4.8 GHz)
          turbo = "auto";              # Allow turbo but let thermal management control it
        };
      };
    };

    # Intel thermal daemon with custom configuration
    thermald = {
      enable = true;
      configFile = pkgs.writeText "thermal-conf.xml" ''
        <?xml version="1.0"?>
        <ThermalConfiguration>
          <Platform>
            <Name>ThinkPad E14 Gen 6</Name>
            <ProductName>21M7006LTX</ProductName>
            <Preference>QUIET</Preference>
            <ThermalZones>
              <ThermalZone>
                <Type>cpu</Type>
                <TripPoints>
                  <TripPoint>
                    <Temperature>80000</Temperature>
                    <type>passive</type>
                    <CoolingDevice>
                      <type>rapl_controller</type>
                      <influence>30</influence>
                    </CoolingDevice>
                  </TripPoint>
                  <TripPoint>
                    <Temperature>85000</Temperature>
                    <type>passive</type>
                    <CoolingDevice>
                      <type>rapl_controller</type>
                      <influence>60</influence>
                    </CoolingDevice>
                  </TripPoint>
                  <TripPoint>
                    <Temperature>90000</Temperature>
                    <type>passive</type>
                    <CoolingDevice>
                      <type>rapl_controller</type>
                      <influence>100</influence>
                    </CoolingDevice>
                  </TripPoint>
                </TripPoints>
              </ThermalZone>
            </ThermalZones>
          </Platform>
        </ThermalConfiguration>
      '';
    };

    # ThinkPad fan control with aggressive cooling curve
    thinkfan = {
      enable = true;
      smartSupport = true;
      levels = [
        # [fan_level  temp_low  temp_high]
        [ 0  0   60 ]          # Fan off below 60°C
        [ 1  58  65 ]          # Level 1: 58-65°C
        [ 2  62  70 ]          # Level 2: 62-70°C
        [ 3  68  75 ]          # Level 3: 68-75°C
        [ 4  72  78 ]          # Level 4: 72-78°C
        [ 5  76  82 ]          # Level 5: 76-82°C
        [ 6  80  85 ]          # Level 6: 80-85°C
        [ 7  83  88 ]          # Level 7: 83-88°C
        [ "level full-speed"  86  32767 ]  # Maximum fan speed above 86°C
      ];
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
    ];
    
    # Module options for ThinkPad features
    extraModprobeConfig = ''
      # ThinkPad ACPI configuration
      options thinkpad_acpi fan_control=1
      options thinkpad_acpi brightness_mode=1
      options thinkpad_acpi volume_mode=1
      options thinkpad_acpi experimental=1
      
      # Intel P-state driver options
      options intel_pstate hwp_dynamic_boost=0
    '';
    
    # Kernel parameters for thermal and power optimization
    kernelParams = [
      # NVMe optimization
      "nvme.noacpi=1"
      
      # IOMMU for better device isolation
      "intel_iommu=on"
      
      # CPU power management
      "intel_pstate=passive"        # Passive mode for better governor control
      "processor.max_cstate=3"       # Limit deep C-states to reduce latency
      "intel_idle.max_cstate=3"      # Limit idle states
      
      # Intel Arc Graphics power saving
      "i915.enable_guc=3"           # Enable GuC and HuC firmware
      "i915.enable_fbc=1"           # Frame buffer compression
      "i915.enable_psr=2"           # Panel self refresh
      "i915.enable_dc=2"            # Display C-states
      "i915.fastboot=1"             # Faster boot
      
      # Thermal and power settings
      "thermal.off=0"               # Ensure thermal management is enabled
      "thermal.act=-1"              # ACPI thermal control
      "thermal.nocrt=0"             # Critical temperature actions enabled
      "thermal.psv=-1"              # Passive cooling temperature
      
      # Optional: Disable CPU vulnerability mitigations for better performance
      # WARNING: This reduces security. Only enable if you understand the risks.
      # "mitigations=off"
    ];
  };
  
  # ==============================================================================
  # System Services
  # ==============================================================================
  systemd.services = {
    # CPU power limit service for additional thermal control
    cpu-power-limit = {
      description = "Set Intel RAPL power limits for thermal management";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          # Check if RAPL is available
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            # Set long-term power limit (PL1) to 28W
            echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
            
            # Set short-term power limit (PL2) to 35W
            echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
            
            # Set time windows
            echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us
            echo 2500 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us
            
            echo "Intel RAPL power limits set: PL1=28W, PL2=35W"
          else
            echo "Intel RAPL not available"
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
          # Set LED triggers for proper audio integration
          echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
          echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
          
          # Reset LED states to off
          echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
        '';
        RemainAfterExit = true;
      };
    };
    
    # Monitor thermal status service
    thermal-monitor = {
      description = "Monitor system thermal status";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = pkgs.writeShellScript "thermal-monitor" ''
          while true; do
            # Get current package temperature
            TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
            TEMP_C=$((TEMP / 1000))
            
            # If temperature exceeds 90°C, log warning
            if [ "$TEMP_C" -gt 90 ]; then
              echo "WARNING: High CPU temperature detected: $${TEMP_C}°C"
              logger -t thermal-monitor "High CPU temperature: $${TEMP_C}°C"
            fi
            
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
    
    # Set CPU governor to powersave when on battery
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
  '';
  
}

