# modules/core/hardware/default.nix
# ==============================================================================
# Advanced Hardware and Power Management Configuration
# ==============================================================================
# Comprehensive hardware optimization for ThinkPad systems with intelligent
# runtime detection and adaptive power management strategies.
#
# Supported Systems:
# - ThinkPad X1 Carbon 6th (Intel Core i7-8650U, 16GB RAM)
# - ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, 64GB RAM)
#
# Version: 3.0.0
# Author: Kenan Pelit
# Last Updated: 2025-08-25
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # ==============================================================================
  # CPU Detection and Configuration
  # ==============================================================================
  
  # Runtime CPU detection script
  detectCpuScript = pkgs.writeShellScript "detect-cpu" ''
    #!/usr/bin/env bash
    # Read CPU information from /proc/cpuinfo
    CPU_INFO=$(cat /proc/cpuinfo 2>/dev/null || echo "")
    
    # Detect Meteor Lake (Intel Core Ultra series)
    if echo "$CPU_INFO" | grep -qE "155H|Ultra|Meteor Lake"; then
      echo "meteolake"
    # Detect Kaby Lake R (8th gen U series)
    elif echo "$CPU_INFO" | grep -qE "8650U|8550U|8250U|8350U|Kaby Lake"; then
      echo "kabylaker"
    else
      # Default to conservative settings for unknown CPUs
      echo "kabylaker"
    fi
  '';

  # Meteor Lake (Core Ultra) configuration profile
  meteorLakeConfig = {
    # Power limits in Watts - optimized for modern 28W TDP CPU
    battery = {
      pl1 = 28;          # Sustained power limit (increased from 25W)
      pl2 = 40;          # Burst power limit (increased from 35W)
      maxFreq = 3200000; # 3.2GHz max on battery (increased from 2.8GHz)
      minFreq = 600000;  # 600MHz minimum for better idle efficiency
    };
    ac = {
      pl1 = 40;          # Sustained power on AC (increased from 35W)
      pl2 = 55;          # Burst power on AC (increased from 45W)
      maxFreq = 4200000; # 4.2GHz max on AC (increased from 3.8GHz)
      minFreq = 800000;  # 800MHz minimum on AC
    };
    # Thermal thresholds in Celsius - adjusted for modern CPUs
    thermal = {
      trip = 85;         # Throttle start on battery (increased from 80°C)
      tripAc = 90;       # Throttle start on AC (increased from 85°C)
      warning = 92;      # Warning threshold (increased from 88°C)
      critical = 100;    # Critical shutdown (increased from 95°C - Intel spec)
    };
    # Battery charge thresholds for longevity
    battery_threshold = {
      start = 60;        # Start charging at 60%
      stop = 80;         # Stop charging at 80%
    };
    # Undervolt settings (Meteor Lake doesn't support undervolting)
    undervolt = {
      core = 0;
      gpu = 0;
      cache = 0;
      uncore = 0;
      analogio = 0;
    };
  };

  # Kaby Lake R (8th gen) configuration profile
  kabyLakeRConfig = {
    # Power limits in Watts - conservative for 15W TDP CPU
    battery = {
      pl1 = 15;          # Sustained power limit
      pl2 = 25;          # Burst power limit
      maxFreq = 2400000; # 2.4GHz max on battery (increased from 2.2GHz)
      minFreq = 400000;  # 400MHz minimum
    };
    ac = {
      pl1 = 25;          # Sustained power on AC (increased from 20W)
      pl2 = 35;          # Burst power on AC (increased from 30W)
      maxFreq = 3800000; # 3.8GHz max on AC (increased from 3.5GHz)
      minFreq = 400000;  # 400MHz minimum
    };
    # Thermal thresholds - more conservative for older architecture
    thermal = {
      trip = 78;         # Throttle start on battery (increased from 75°C)
      tripAc = 82;       # Throttle start on AC (increased from 80°C)
      warning = 85;      # Warning threshold
      critical = 90;     # Critical shutdown
    };
    # Battery thresholds - optimized for older battery technology
    battery_threshold = {
      start = 75;        # Start charging at 75%
      stop = 80;         # Stop charging at 80%
    };
    # Undervolt settings for better thermals (if stable)
    undervolt = {
      core = -80;        # Core voltage offset in mV
      gpu = -60;         # GPU voltage offset
      cache = -80;       # Cache voltage offset
      uncore = -40;      # System Agent offset
      analogio = -25;    # Analog I/O offset
    };
  };

in
{
  # ==============================================================================
  # Hardware Configuration
  # ==============================================================================
  
  hardware = {
    # TrackPoint configuration for ThinkPads
    trackpoint = {
      enable = true;
      speed = 200;        # Speed setting (0-255)
      sensitivity = 200;  # Sensitivity setting (0-255)
      emulateWheel = true; # Middle button scroll
    };
    
    # Intel graphics acceleration stack
    graphics = {
      enable = true;
      enable32Bit = true;  # 32-bit support for Steam/Wine
      extraPackages = with pkgs; [
        intel-media-driver      # VA-API driver for Broadwell+
        intel-vaapi-driver      # Legacy VA-API driver
        vaapiVdpau             # VA-API to VDPAU wrapper
        libvdpau-va-gl         # VDPAU backend for VA-API
        mesa                   # OpenGL/Vulkan implementation
        intel-compute-runtime  # OpenCL runtime
        intel-ocl             # OpenCL loader
        vaapiIntel            # Additional VA-API support
      ];
      # 32-bit packages for compatibility
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
        intel-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
    
    # Firmware configuration
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
    
    # Bluetooth configuration
    bluetooth = {
      enable = true;
      powerOnBoot = true;  # Don't power on at boot to save battery
      settings = {
        General = {
          FastConnectable = true;
          ReconnectAttempts = 7;
          ReconnectIntervals = "1,2,4,8,16,32,64";
        };
      };
    };
  };
  
  # ==============================================================================
  # Power Management Services
  # ==============================================================================
  
  services = {
    # CPU frequency and voltage management
    throttled = {
      enable = true;
      extraConfig = ''
        [GENERAL]
        Enabled: True
        Sysfs_Power_Path: /sys/class/power_supply/AC*/online
        Autoreload: True
        
        [BATTERY]
        Update_Rate_s: 30
        PL1_Tdp_W: ${toString kabyLakeRConfig.battery.pl1}
        PL1_Duration_s: 28
        PL2_Tdp_W: ${toString kabyLakeRConfig.battery.pl2}
        PL2_Duration_S: 0.002
        Trip_Temp_C: ${toString kabyLakeRConfig.thermal.trip}
        
        [AC]
        Update_Rate_s: 5
        PL1_Tdp_W: ${toString kabyLakeRConfig.ac.pl1}
        PL1_Duration_s: 28
        PL2_Tdp_W: ${toString kabyLakeRConfig.ac.pl2}
        PL2_Duration_S: 0.002
        Trip_Temp_C: ${toString kabyLakeRConfig.thermal.tripAc}
        
        [UNDERVOLT.BATTERY]
        CORE: ${toString kabyLakeRConfig.undervolt.core}
        GPU: ${toString kabyLakeRConfig.undervolt.gpu}
        CACHE: ${toString kabyLakeRConfig.undervolt.cache}
        UNCORE: ${toString kabyLakeRConfig.undervolt.uncore}
        ANALOGIO: ${toString kabyLakeRConfig.undervolt.analogio}
        
        [UNDERVOLT.AC]
        CORE: ${toString kabyLakeRConfig.undervolt.core}
        GPU: ${toString kabyLakeRConfig.undervolt.gpu}
        CACHE: ${toString kabyLakeRConfig.undervolt.cache}
        UNCORE: ${toString kabyLakeRConfig.undervolt.uncore}
        ANALOGIO: ${toString kabyLakeRConfig.undervolt.analogio}
      '';
    };

    # Automatic CPU frequency scaling
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "schedutil";           # Better than powersave for responsiveness
          scaling_min_freq = lib.mkDefault 400000;
          scaling_max_freq = lib.mkDefault 2400000;
          turbo = "auto";                   # Let system decide based on thermal
          energy_performance_preference = "power";  # Intel P-state preference
        };
        charger = {
          governor = "schedutil";           # Balanced performance
          scaling_min_freq = lib.mkDefault 400000;
          scaling_max_freq = lib.mkDefault 3800000;
          turbo = "auto";
          energy_performance_preference = "balance_performance";
        };
      };
    };

    # Thermal management
    thermald.enable = true;
    
    # ThinkPad fan control (disabled - thermald handles it)
    thinkfan.enable = false;
    
    # Power profiles daemon (disabled - conflicts with auto-cpufreq)
    power-profiles-daemon.enable = false;
    
    # TLP power management (disabled - conflicts with auto-cpufreq)
    tlp.enable = false;

    # Power management daemon
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      usePercentageForPolicy = true;
      noPollBatteries = false;  # Enable battery polling for accurate readings
    };
    
    # Login manager configuration
    logind = {
      settings = {
        Login = {
          HandlePowerKey = "ignore";
          HandlePowerKeyLongPress = "poweroff";
          HandleSuspendKey = "suspend";
          HandleHibernateKey = "hibernate";
          HandleLidSwitch = "suspend";           # Buraya taşındı
          HandleLidSwitchDocked = "suspend";     # Buraya taşındı
          HandleLidSwitchExternalPower = "suspend"; # Buraya taşındı
          IdleAction = "ignore";
          IdleActionSec = "30min";
          InhibitDelayMaxSec = "5";
          InhibitorsMax = "8192";
          UserTasksMax = "33%";
          RuntimeDirectorySize = "50%";
          RemoveIPC = "yes";
        };
      };
    };
   
    # System logging configuration
    journald.extraConfig = ''
      SystemMaxUse=2G
      SystemMaxFileSize=100M
      MaxRetentionSec=1week
      MaxFileSec=1day
      SyncIntervalSec=30
      RateLimitIntervalSec=30
      RateLimitBurst=1000
      Compress=yes
      ForwardToSyslog=no
    '';
    
    # DBus configuration
    dbus = {
      implementation = "broker";  # More efficient than dbus-daemon
      packages = [ pkgs.dconf ];
    };
  };
  
  # ==============================================================================
  # Boot Configuration
  # ==============================================================================
  
  boot = {
    # Essential kernel modules
    kernelModules = [ 
      "thinkpad_acpi"    # ThinkPad ACPI extras
      "coretemp"         # Temperature monitoring
      "intel_rapl"       # Power capping framework
      "msr"              # Model Specific Registers
      "kvm-intel"        # KVM virtualization
      "i915"             # Intel graphics
    ];
    
    # Module configuration
    extraModprobeConfig = ''
      # ThinkPad ACPI configuration
      options thinkpad_acpi fan_control=1 brightness_mode=1 volume_mode=1 experimental=1
      
      # Intel P-state configuration
      options intel_pstate hwp_dynamic_boost=0
      
      # Audio power saving (10 second timeout)
      options snd_hda_intel power_save=10 power_save_controller=Y
      
      # WiFi power saving
      options iwlwifi power_save=1 power_level=3
      options iwlmvm power_scheme=3
      
      # USB autosuspend
      options usbcore autosuspend=5
    '';
    
    # Kernel parameters optimized for laptops
    kernelParams = [
      # IOMMU configuration
      "intel_iommu=on"
      "iommu=pt"
      
      # CPU power management
      "processor.max_cstate=4"           # Allow deeper C-states (was 3)
      "intel_idle.max_cstate=4"          # Intel idle states (was 3)
      "intel_pstate=passive"             # Passive P-state for schedutil governor
      
      # Thermal management
      "thermal.off=0"
      "thermal.act=-1"
      "thermal.nocrt=0"
      "thermal.psv=-1"
      
      # Memory management
      "transparent_hugepage=madvise"
      "mitigations=auto"
      
      # NVMe power management
      "nvme_core.default_ps_max_latency_us=5500"  # 5.5ms latency (was 0)
      
      # Intel GPU optimizations
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_psr=3"                # PSR2 with selective update (was 2)
      "i915.enable_dc=2"
      "i915.fastboot=1"
      "i915.modeset=1"
      "i915.enable_sagv=1"              # System Agent Gelivolt (new)
      
      # PCIe power management
      "pcie_aspm=default"               # Default ASPM (was force)
      "pcie_port_pm=on"
      
      # Network optimizations
      "ipv6.disable=0"
      "net.ifnames=1"

      # Suppress iwlwifi firmware debug messages that appear as red warnings during boot
      # This doesn't affect WiFi functionality, only reduces console noise
      "iwlwifi.debug=0x00000000"        # WiFi hata mesajlarını gizle

    ];
    
    # I/O scheduler configuration
    kernel.sysctl = {
      # Memory management
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_ratio" = 10;
      "vm.laptop_mode" = 5;
      "vm.page-cluster" = 0;              # Better for SSD
      "vm.compact_unevictable_allowed" = 1;
      
      # Kernel behavior
      "kernel.nmi_watchdog" = 0;
      "kernel.sched_autogroup_enabled" = 1;
      "kernel.sched_cfs_bandwidth_slice_us" = 3000;
      
    };
  };
  
  # ==============================================================================
  # System Services
  # ==============================================================================
  
  systemd.services = {
    # Dynamic CPU power limit configuration
    cpu-power-limit = {
      description = "Configure Intel RAPL power limits based on CPU type";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          #!/usr/bin/env bash
          set -u
          
          # Wait for system initialization
          sleep 2
          
          # Detect CPU type
          CPU_TYPE=$(${detectCpuScript})
          echo "Detected CPU type: $CPU_TYPE"
          
          # Check for Intel RAPL interface
          if [ ! -d /sys/class/powercap/intel-rapl:0 ]; then
            echo "Intel RAPL interface not available"
            exit 0
          fi
          
          # Detect power source
          ON_AC=0
          for PS in /sys/class/power_supply/A{C,C0,DP1}/online; do
            [ -f "$PS" ] && ON_AC=$(cat "$PS") && break
          done
          
          # Apply CPU-specific power limits
          if [ "$CPU_TYPE" = "meteolake" ]; then
            if [ "$ON_AC" = "1" ]; then
              # Meteor Lake on AC
              echo ${toString (meteorLakeConfig.ac.pl1 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo ${toString (meteorLakeConfig.ac.pl2 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Meteor Lake AC: PL1=${toString meteorLakeConfig.ac.pl1}W, PL2=${toString meteorLakeConfig.ac.pl2}W"
            else
              # Meteor Lake on battery
              echo ${toString (meteorLakeConfig.battery.pl1 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo ${toString (meteorLakeConfig.battery.pl2 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Meteor Lake Battery: PL1=${toString meteorLakeConfig.battery.pl1}W, PL2=${toString meteorLakeConfig.battery.pl2}W"
            fi
          else
            if [ "$ON_AC" = "1" ]; then
              # Kaby Lake R on AC
              echo ${toString (kabyLakeRConfig.ac.pl1 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo ${toString (kabyLakeRConfig.ac.pl2 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Kaby Lake R AC: PL1=${toString kabyLakeRConfig.ac.pl1}W, PL2=${toString kabyLakeRConfig.ac.pl2}W"
            else
              # Kaby Lake R on battery
              echo ${toString (kabyLakeRConfig.battery.pl1 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
              echo ${toString (kabyLakeRConfig.battery.pl2 * 1000000)} > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
              echo "Kaby Lake R Battery: PL1=${toString kabyLakeRConfig.battery.pl1}W, PL2=${toString kabyLakeRConfig.battery.pl2}W"
            fi
          fi
          
          # Set time windows
          echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us
          echo 2500 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us
        '';
      };
    };
    
    # ThinkPad LED management
    fix-led-state = {
      description = "Configure ThinkPad LED states";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "fix-leds" ''
          #!/usr/bin/env bash
          
          # Configure microphone mute LED
          if [ -d /sys/class/leds/platform::micmute ]; then
            echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          fi
          
          # Configure audio mute LED
          if [ -d /sys/class/leds/platform::mute ]; then
            echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
          fi
          
          # Turn off logo LED to save power
          if [ -d /sys/class/leds/tpacpi::lid_logo_dot ]; then
            echo 0 > /sys/class/leds/tpacpi::lid_logo_dot/brightness 2>/dev/null || true
          fi
        '';
        RemainAfterExit = true;
      };
    };
    
    # Battery charge threshold management
    battery-charge-threshold = {
      description = "Configure battery charge thresholds";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "battery-threshold" ''
          #!/usr/bin/env bash
          set -euo pipefail
          
          # Detect CPU type
          CPU_TYPE=$(${detectCpuScript})
          echo "Setting battery thresholds for: $CPU_TYPE"
          
          BAT_PATH="/sys/class/power_supply/BAT0"
          
          # Check battery path
          [ ! -d "$BAT_PATH" ] && echo "Battery not found" && exit 0
          
          # Set charge start threshold
          if [ -f "$BAT_PATH/charge_control_start_threshold" ]; then
            if [ "$CPU_TYPE" = "meteolake" ]; then
              echo ${toString meteorLakeConfig.battery_threshold.start} > "$BAT_PATH/charge_control_start_threshold"
              echo "Start threshold: ${toString meteorLakeConfig.battery_threshold.start}%"
            else
              echo ${toString kabyLakeRConfig.battery_threshold.start} > "$BAT_PATH/charge_control_start_threshold"
              echo "Start threshold: ${toString kabyLakeRConfig.battery_threshold.start}%"
            fi
          fi
          
          # Set charge stop threshold
          if [ -f "$BAT_PATH/charge_control_end_threshold" ]; then
            echo 80 > "$BAT_PATH/charge_control_end_threshold"
            echo "Stop threshold: 80%"
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
          #!/usr/bin/env bash
          set -euo pipefail
          
          # Detect CPU type
          CPU_TYPE=$(${detectCpuScript})
          echo "Thermal monitor started for: $CPU_TYPE"
          
          # Set thresholds based on CPU type
          if [ "$CPU_TYPE" = "meteolake" ]; then
            WARNING=${toString meteorLakeConfig.thermal.warning}
            CRITICAL=${toString meteorLakeConfig.thermal.critical}
          else
            WARNING=${toString kabyLakeRConfig.thermal.warning}
            CRITICAL=${toString kabyLakeRConfig.thermal.critical}
          fi
          
          echo "Thresholds - Warning: $${WARNING}°C, Critical: $${CRITICAL}°C"
          
          # Monitor loop
          while true; do
            # Get highest temperature
            TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
            
            if [ -n "$TEMP" ]; then
              TEMP_C=$((TEMP / 1000))
              
              # Check temperature levels
              if [ "$TEMP_C" -gt "$CRITICAL" ]; then
                echo "CRITICAL: CPU temperature: $${TEMP_C}°C"
                logger -p user.crit -t thermal-monitor "Critical temperature: $${TEMP_C}°C"
              elif [ "$TEMP_C" -gt "$WARNING" ]; then
                echo "WARNING: CPU temperature: $${TEMP_C}°C"
                logger -p user.warning -t thermal-monitor "High temperature: $${TEMP_C}°C"
              fi
            fi
            
            sleep 30
          done
        '';
        Restart = "always";
        RestartSec = 10;
      };
    };
    
    # Dynamic auto-cpufreq configuration
    update-cpufreq-config = {
      description = "Configure auto-cpufreq based on CPU type";
      wantedBy = [ "default.target" ];
      before = [ "graphical-session.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "update-cpufreq" ''
          #!/usr/bin/env bash
          set -euo pipefail
          
          # Detect CPU type
          CPU_TYPE=$(${detectCpuScript})
          echo "Configuring auto-cpufreq for: $CPU_TYPE"
          
          CONFIG_FILE="/etc/auto-cpufreq.conf"
          
          # Generate CPU-specific configuration
          if [ "$CPU_TYPE" = "meteolake" ]; then
            cat > "$CONFIG_FILE" <<EOF
          [battery]
          governor = schedutil
          scaling_min_freq = ${toString meteorLakeConfig.battery.minFreq}
          scaling_max_freq = ${toString meteorLakeConfig.battery.maxFreq}
          turbo = auto
          
          [charger]
          governor = schedutil
          scaling_min_freq = ${toString meteorLakeConfig.ac.minFreq}
          scaling_max_freq = ${toString meteorLakeConfig.ac.maxFreq}
          turbo = auto
          EOF
          else
            cat > "$CONFIG_FILE" <<EOF
          [battery]
          governor = schedutil
          scaling_min_freq = ${toString kabyLakeRConfig.battery.minFreq}
          scaling_max_freq = ${toString kabyLakeRConfig.battery.maxFreq}
          turbo = auto
          
          [charger]
          governor = schedutil
          scaling_min_freq = ${toString kabyLakeRConfig.ac.minFreq}
          scaling_max_freq = ${toString kabyLakeRConfig.ac.maxFreq}
          turbo = auto
          EOF
          fi
          
          echo "Configuration updated"
        '';
      };
    };
  };
  
  # ==============================================================================
  # Udev Rules
  # ==============================================================================
  
  services.udev.extraRules = ''
    # LED permissions for user control
    SUBSYSTEM=="leds", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/%k/brightness"
    
    # Power supply change handling
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service"
    
    # I/O scheduler optimization
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="mq-deadline"
    
    # NVMe power management
    ACTION=="add", SUBSYSTEM=="nvme", ATTR{power/pm_qos_latency_tolerance_us}="5500"
    
    # PCI power management
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    
    # USB power management with exceptions
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTR{power/control}="on"
    
    # Audio power management
    ACTION=="add", SUBSYSTEM=="pci", DRIVER=="snd_hda_intel", ATTR{power/control}="auto"
    
    # Network power management
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="enp*", RUN+="${pkgs.ethtool}/bin/ethtool -s %k wol d"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlp*", RUN+="${pkgs.iw}/bin/iw dev %k set power_save on"
  '';
  
  # ==============================================================================
  # Environment Configuration
  # ==============================================================================
  
  environment = {
    # Shell aliases for system management
    shellAliases = {
      # Battery information
      battery-status = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
      battery-info = ''
        echo "=== Battery Status ===" && \
        upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep -E "state|percentage|time to|capacity" && \
        echo -e "\n=== Charge Thresholds ===" && \
        echo "Start: $(cat /sys/class/power_supply/BAT0/charge_control_start_threshold 2>/dev/null || echo 'N/A')%" && \
        echo "Stop: $(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || echo 'N/A')%"
      '';
      
      # Power management
      power-report = "sudo powertop --html=power-report.html --time=10 && echo 'Report saved to power-report.html'";
      power-usage = "sudo powertop";
      
      # Thermal monitoring
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
      
      # CPU information
      cpu-freq = ''
        echo "=== CPU Frequency ===" && \
        grep "cpu MHz" /proc/cpuinfo | awk '{print "Core " NR-1 ": " $4 " MHz"}'
      '';
      
      cpu-type = "${detectCpuScript}";
      
      # Performance summary
      perf-summary = ''
        echo "=== System Performance ===" && \
        echo -e "\nCPU: $(${detectCpuScript})" && \
        echo "Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)" && \
        echo "Memory: $(free -h | grep "^Mem:" | awk '{print $3 " / " $2}')" && \
        echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
      '';
    };
    
    # Environment variables
    variables = {
      VDPAU_DRIVER = "va_gl";
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
  
  # ==============================================================================
  # Zram Configuration
  # ==============================================================================
  
  zramSwap = {
    enable = true;
    priority = 5000;
    algorithm = "zstd";
    memoryPercent = lib.mkDefault 30;  # Can be overridden by host config
  };
}

