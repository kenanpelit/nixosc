# modules/core/hardware/default.nix
# ==============================================================================
# Hardware Configuration for ThinkPad X1 Carbon 6th
# ==============================================================================
# This configuration manages hardware settings including:
# - ThinkPad-specific ACPI and advanced thermal management
# - Intel UHD Graphics 620 drivers and hardware acceleration
# - NVMe storage optimizations
# - Intel Core i7-8650U CPU thermal and power management
# - LED control and function key management
# - TrackPoint and touchpad configuration
#
# Target Hardware:
# - ThinkPad X1 Carbon 6th (20KHS0XR00)
# - Intel Core i7-8650U (4-core, 8-thread)
# - Intel UHD Graphics 620
# - 16GB RAM
# - Samsung 1TB NVMe SSD
#
# Author: Kenan Pelit
# Modified: 2025-08-23 (X1 Carbon 6th için optimize edildi)
# ==============================================================================
{ pkgs, ... }:
{
  # ==============================================================================
  # Hardware Configuration
  # ==============================================================================
  hardware = {
    # Enable TrackPoint for ThinkPad
    trackpoint.enable = true;
    
    # Intel UHD Graphics 620 configuration
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver      # VA-API implementation
        vaapiVdpau             # VDPAU backend for VA-API
        libvdpau-va-gl         # VDPAU driver with OpenGL/VAAPI backend
        mesa                   # OpenGL implementation
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
    # Lenovo throttling fix with thermal management
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
        # Long-term power limit (Watts) - optimized for battery
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
        # Long-term power limit (Watts) - optimized for performance
        PL1_Tdp_W: 25
        PL1_Duration_s: 28
        # Short-term power limit (Watts)
        PL2_Tdp_W: 35
        PL2_Duration_S: 0.002
        # Temperature threshold for throttling (Celsius)
        Trip_Temp_C: 80

        [UNDERVOLT.BATTERY]
        # Kaby Lake R supports undervolting
        CORE: -100
        GPU: -80
        CACHE: -100
        UNCORE: 0
        ANALOGIO: 0

        [UNDERVOLT.AC]
        # Kaby Lake R supports undervolting
        CORE: -120
        GPU: -100
        CACHE: -120
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
          governor = "performance";    # Use performance on AC
          scaling_min_freq = 400000;   # 400 MHz minimum
          scaling_max_freq = 4200000;  # 4.2 GHz maximum on AC
          turbo = "auto";              # Allow turbo boost
        };
      };
    };

    # ThinkPad fan control - X1 Carbon için optimize edilmiş
    thinkfan = {
      enable = true;
      smartSupport = true;
      
      # X1 Carbon 6th için optimize edilmiş fan eğrisi
      levels = [
        # [fan_level temp_low temp_high]
        [ 0  0   55 ]          # Fan off below 55°C (sessiz çalışma)
        [ 1  53  60 ]          # Level 1: 53-60°C
        [ 2  58  65 ]          # Level 2: 58-65°C
        [ 3  63  70 ]          # Level 3: 63-70°C
        [ 4  68  75 ]          # Level 4: 68-75°C
        [ 5  73  80 ]          # Level 5: 73-80°C
        [ 6  78  85 ]          # Level 6: 78-85°C
        [ 7  83  90 ]          # Level 7: 83-90°C
        [ "level full-speed"  88  32767 ]  # Maximum fan speed above 88°C
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
      options intel_pstate hwp_dynamic_boost=1
    '';
    
    # Kernel parameters for thermal and power optimization
    kernelParams = [
      # CPU power management
      "intel_pstate=active"        # Active mode for better performance
      "processor.max_cstate=5"     # Allow deeper C-states for better battery
      "intel_idle.max_cstate=5"    # Allow deeper idle states
      
      # Intel Graphics power saving
      "i915.enable_fbc=1"           # Frame buffer compression
      "i915.enable_psr=1"           # Panel self refresh
      "i915.enable_dc=2"            # Display C-states
      "i915.fastboot=1"             # Faster boot
      
      # Thermal management
      "thermal.off=0"               # Ensure thermal management is enabled
      "thermal.act=-1"              # ACPI thermal control
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
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          # Check if RAPL is available
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            # Set long-term power limit (PL1) to 25W
            echo 25000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
            
            # Set short-term power limit (PL2) to 35W
            echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
            
            # Set time windows
            echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us
            echo 2500 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us
            
            echo "Intel RAPL power limits set: PL1=25W, PL2=35W"
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
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g performance"
  '';
}
