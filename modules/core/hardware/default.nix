# modules/core/hardware/default.nix
# ==============================================================================
# Unified Hardware and Power Management Configuration
# ==============================================================================
# This configuration manages hardware and power settings including:
# - ThinkPad-specific ACPI and thermal management (X1 Carbon 6th + E14 Gen 6 support)
# - Intel Graphics drivers and hardware acceleration (UHD 620 + Arc Graphics)
# - NVMe storage optimizations
# - CPU thermal and power management (Intel i7-8650U + Core Ultra 7 155H)
# - LED control and function key management
# - TrackPoint and touchpad configuration
# - Comprehensive power management with lid suspend support
#
# Supported Hardware:
# - ThinkPad X1 Carbon 6th (20KHS0XR00) - Intel i7-8650U, UHD Graphics 620
# - ThinkPad E14 Gen 6 (21M7006LTX) - Intel Core Ultra 7 155H, Arc Graphics
#
# Performance Targets:
# - CPU Temperature: 65-85°C under load (model dependent)
# - Fan Noise: Minimal to balanced operation
# - Power Consumption: 15-35W sustained, 25-45W burst (model dependent)
#
# Author: Kenan Pelit
# Modified: 2025-08-25 (Unified configuration for multiple ThinkPad models)
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # Detect CPU architecture to apply appropriate settings
  isMeteorLake = lib.any (cpu: lib.hasInfix cpu config.hardware.cpu) ["155H" "ultra" "Ultra"];
  isKabyLakeR = lib.any (cpu: lib.hasInfix cpu config.hardware.cpu) ["8650U" "8550U" "Kaby"];
in
{
  # ==============================================================================
  # Hardware Configuration
  # ==============================================================================
  hardware = {
    # Enable TrackPoint for ThinkPad
    trackpoint = {
      enable = true;
      speed = 200;
      sensitivity = 200;
    };
    
    # Intel Graphics configuration (supports both UHD 620 and Arc Graphics)
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiVdpau
        libvdpau-va-gl
        mesa
      ] ++ lib.optionals isMeteorLake [
        intel-compute-runtime
        intel-ocl
      ] ++ lib.optionals isKabyLakeR [
        intel-vaapi-driver
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
    # Lenovo throttling fix with model-specific configurations
    throttled = {
      enable = true;
      extraConfig = 
        if isMeteorLake then ''
          [GENERAL]
          Enabled: True
          Sysfs_Power_Path: /sys/class/power_supply/AC*/online
          Autoreload: True

          [BATTERY]
          Update_Rate_s: 30
          PL1_Tdp_W: 25
          PL1_Duration_s: 28
          PL2_Tdp_W: 35
          PL2_Duration_S: 0.002
          Trip_Temp_C: 80

          [AC]
          Update_Rate_s: 5
          PL1_Tdp_W: 35
          PL1_Duration_s: 28
          PL2_Tdp_W: 45
          PL2_Duration_S: 0.002
          Trip_Temp_C: 85

          [UNDERVOLT.BATTERY]
          CORE: 0
          GPU: 0
          CACHE: 0
          UNCORE: 0
          ANALOGIO: 0

          [UNDERVOLT.AC]
          CORE: 0
          GPU: 0
          CACHE: 0
          UNCORE: 0
          ANALOGIO: 0
        '' else ''
          [GENERAL]
          Enabled: True
          Sysfs_Power_Path: /sys/class/power_supply/AC*/online
          Autoreload: True

          [BATTERY]
          Update_Rate_s: 30
          PL1_Tdp_W: 15
          PL1_Duration_s: 28
          PL2_Tdp_W: 25
          PL2_Duration_S: 0.002
          Trip_Temp_C: 75

          [AC]
          Update_Rate_s: 5
          PL1_Tdp_W: 20
          PL1_Duration_s: 28
          PL2_Tdp_W: 30
          PL2_Duration_S: 0.002
          Trip_Temp_C: 80

          [UNDERVOLT.BATTERY]
          CORE: -60
          GPU: -40
          CACHE: -60
          UNCORE: 0
          ANALOGIO: 0

          [UNDERVOLT.AC]
          CORE: -80
          GPU: -60
          CACHE: -80
          UNCORE: 0
          ANALOGIO: 0
        '';
    };

    # Modern CPU frequency management
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          scaling_min_freq = 400000;
          turbo = "never";
        };
        charger = {
          governor = "powersave";
          scaling_min_freq = 400000;
          turbo = "auto";
        };
      } // (if isMeteorLake then {
        battery.scaling_max_freq = 2800000;
        charger.scaling_max_freq = 3800000;
      } else {
        battery.scaling_max_freq = 2200000;
        charger.scaling_max_freq = 3500000;
      });
    };

    # ThinkPad fan control - disabled by default
    thinkfan.enable = false;

    # Intel thermal daemon
    thermald.enable = true;

    # Disable conflicting power services
    power-profiles-daemon.enable = false;
    tlp.enable = false;

    # UPower configuration
    upower = {
      enable = true;
      criticalPowerAction = "Hibernate";
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      usePercentageForPolicy = true;
    };
    
    # Logind configuration for lid suspend
    logind = {
      lidSwitch = "suspend";
      lidSwitchDocked = "suspend";  
      lidSwitchExternalPower = "suspend";
      extraConfig = ''
        HandlePowerKey=ignore
        HandleSuspendKey=suspend
        HandleHibernateKey=hibernate
        HandleLidSwitch=suspend
        HandleLidSwitchDocked=suspend
        HandleLidSwitchExternalPower=suspend
        IdleAction=ignore
        IdleActionSec=30min
        InhibitDelayMaxSec=5
        HandleSuspendLock=delay
        KillUserProcesses=no
        RemoveIPC=yes
      '';
    };
    
    # System logging
    journald.extraConfig = ''
      SystemMaxUse=3G
      SystemMaxFileSize=200M
      MaxRetentionSec=2weeks
      SyncIntervalSec=60
      RateLimitIntervalSec=10
      RateLimitBurst=200
    '';
    
    # D-Bus optimization
    dbus.implementation = "broker";
  };
  
  # ==============================================================================
  # Boot Configuration
  # ==============================================================================
  boot = {
    # Essential kernel modules
    kernelModules = [ 
      "thinkpad_acpi"
      "coretemp"
      "intel_rapl"
      "msr"
    ];
    
    # Module options for ThinkPad features
    extraModprobeConfig = ''
      options thinkpad_acpi fan_control=1
      options thinkpad_acpi brightness_mode=1
      options thinkpad_acpi volume_mode=1
      options thinkpad_acpi experimental=1
      options intel_pstate hwp_dynamic_boost=0
    '';
    
    # Kernel parameters with model-specific optimizations
    kernelParams = [
      # Common parameters
      "intel_iommu=on"
      "iommu=pt"
      "processor.max_cstate=3"
      "intel_idle.max_cstate=3"
      "thermal.off=0"
      "thermal.act=-1"
      "thermal.nocrt=0"
      "thermal.psv=-1"
      "transparent_hugepage=madvise"
      "mitigations=auto"
    ] ++ (if isMeteorLake then [
      # Meteor Lake specific
      "nvme.noacpi=1"
      "intel_pstate=passive"
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
      "i915.enable_dc=2"
      "i915.fastboot=1"
    ] else [
      # Kaby Lake R specific
      "nvme_core.default_ps_max_latency_us=0"
      "intel_pstate=active"
      "i915.enable_guc=2"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "i915.enable_dc=2"
      "i915.fastboot=1"
      "i915.modeset=1"
      "pcie_aspm=force"
      "snd_hda_intel.power_save=1"
      "iwlwifi.power_save=1"
      "iwlwifi.power_level=3"
    ]);
  };
  
  # ==============================================================================
  # System Services
  # ==============================================================================
  systemd.services = {
    # CPU power limit service
    cpu-power-limit = {
      description = "Set Intel RAPL power limits for thermal management";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpu-power-limit" ''
          #!/usr/bin/env sh
          sleep 2
          
          if [ -d /sys/class/powercap/intel-rapl:0 ]; then
            ON_AC=0
            if [ -f /sys/class/power_supply/AC/online ]; then
              ON_AC=$(cat /sys/class/power_supply/AC/online)
            elif [ -f /sys/class/power_supply/ADP1/online ]; then
              ON_AC=$(cat /sys/class/power_supply/ADP1/online)
            fi
            
            if [ "$ON_AC" = "1" ]; then
              ${if isMeteorLake then ''
                echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
                echo 45000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
                echo "Intel RAPL power limits set (AC): PL1=35W, PL2=45W"
              '' else ''
                echo 20000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
                echo 30000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
                echo "Intel RAPL power limits set (AC): PL1=20W, PL2=30W"
              ''}
            else
              ${if isMeteorLake then ''
                echo 25000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
                echo 35000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
                echo "Intel RAPL power limits set (Battery): PL1=25W, PL2=35W"
              '' else ''
                echo 15000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
                echo 25000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
                echo "Intel RAPL power limits set (Battery): PL1=15W, PL2=25W"
              ''}
            fi
            
            echo 28000000 > /sys/class/powercap/intel-rapl:0/constraint_0_time_window_us
            echo 2500 > /sys/class/powercap/intel-rapl:0/constraint_1_time_window_us
          else
            echo "Intel RAPL interface not available"
          fi
        '';
      };
    };
    
    # Fix LED state on boot
    fix-led-state = {
      description = "Fix ThinkPad LED states on boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "fix-leds" ''
          #!/usr/bin/env sh
          if [ -d /sys/class/leds/platform::micmute ]; then
            echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::micmute/brightness 2>/dev/null || true
          fi
          
          if [ -d /sys/class/leds/platform::mute ]; then
            echo "audio-mute" > /sys/class/leds/platform::mute/trigger 2>/dev/null || true
            echo 0 > /sys/class/leds/platform::mute/brightness 2>/dev/null || true
          fi
          
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
          #!/usr/bin/env sh
          BAT_PATH="/sys/class/power_supply/BAT0"
          
          if [ -f "$BAT_PATH/charge_control_start_threshold" ]; then
            ${if isMeteorLake then ''
              echo 60 > "$BAT_PATH/charge_control_start_threshold"
            '' else ''
              echo 75 > "$BAT_PATH/charge_control_start_threshold"
            ''}
          fi
          
          if [ -f "$BAT_PATH/charge_control_end_threshold" ]; then
            ${if isMeteorLake then ''
              echo 80 > "$BAT_PATH/charge_control_end_threshold"
            '' else ''
              echo 80 > "$BAT_PATH/charge_control_end_threshold"
            ''}
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
          #!/usr/bin/env sh
          ${if isMeteorLake then ''
            WARNING_THRESHOLD=88
            CRITICAL_THRESHOLD=95
          '' else ''
            WARNING_THRESHOLD=85
            CRITICAL_THRESHOLD=90
          ''}
          
          while true; do
            TEMP=$(cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1)
            if [ -n "$TEMP" ]; then
              TEMP_C=$((TEMP / 1000))
              
              if [ "$TEMP_C" -gt "$CRITICAL_THRESHOLD" ]; then
                echo "CRITICAL: CPU temperature: $${TEMP_C}°C"
                logger -p user.crit -t thermal-monitor "Critical CPU temperature: $${TEMP_C}°C"
              elif [ "$TEMP_C" -gt "$WARNING_THRESHOLD" ]; then
                echo "WARNING: High CPU temperature: $${TEMP_C}°C"
                logger -p user.warning -t thermal-monitor "High CPU temperature: $${TEMP_C}°C"
              fi
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
    # LED permissions
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::micmute/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::mute/brightness"
    SUBSYSTEM=="leds", KERNEL=="tpacpi::lid_logo_dot", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/tpacpi::lid_logo_dot/brightness"
    SUBSYSTEM=="leds", KERNEL=="tpacpi::power", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/tpacpi::power/brightness"
    
    # CPU governor and power management
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.linuxPackages.cpupower}/bin/cpupower frequency-set -g powersave"
    SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service"
    SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl restart cpu-power-limit.service"
    
    # PCI and USB power management
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTR{power/control}="on"
  '';
  
  # ==============================================================================
  # Environment Configuration
  # ==============================================================================
  environment.shellAliases = {
    battery-status = "upower -i /org/freedesktop/UPower/devices/battery_BAT0";
    power-usage = "sudo powertop --html=power-report.html --time=10";
    thermal-status = "sensors && cat /sys/class/thermal/thermal_zone*/temp";
  };
}

