# modules/core/system/default.nix
# ==============================================================================
# NixOS System Configuration - Adaptive Power Management v8.3
# ==============================================================================
#
# Module:    modules/core/system
# Version:   8.3 - Optimized Hardware Edition
# Date:      2025-10-08
# Author:    NixOS Power Management Suite
#
# RELEASE NOTES v8.3:
# -------------------
# • OPTIMIZED C-state management - let hardware manage completely
# • IMPROVED NVMe power management for better battery life
# • FIXED syslog priority names (user.err instead of user.error)
# • REMOVED unnecessary sysctl and kernel parameters
# • ENHANCED graphics power management with conditional PSR
# • STREAMLINED thermal management (thermald only)
# • BETTER USB autosuspend timing
# • CORRECTED package references
#
# SUPPORTED HARDWARE:
# -------------------
# - ThinkPad E14 Gen 6 (Core Ultra 7 155H, Meteor Lake, 28W TDP)
# - ThinkPad X1 Carbon Gen 6 (i7-8650U, Kaby Lake-R, 15W TDP)
# - QEMU/KVM Virtual Machines (hostname: vhay)
# - Any Intel CPU with P-State driver support
#
# DESIGN PHILOSOPHY:
# ------------------
# "True hardware autonomy with optimized power efficiency"
# - Zero artificial C-state limits
# - Balanced NVMe power management
# - Hardware-managed thermal control
# - Universal compatibility
# - Maximum battery life
#
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  # ============================================================================
  # SYSTEM IDENTIFICATION & DETECTION
  # ============================================================================
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";    # All physical ThinkPads
  isVirtualMachine  = hostname == "vhay";   # QEMU/KVM virtual machine

  # CPU detection script - determines actual hardware capabilities
  cpuDetectionScript = pkgs.writeShellScript "detect-cpu" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    CPU_MODEL="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'Model name' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.gnused}/bin/sed 's/^ *//')"
    CPU_FAMILY="$(${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F 'CPU family' | ${pkgs.coreutils}/bin/cut -d: -f2- | ${pkgs.gnused}/bin/sed 's/^ *//')"
    
    echo "Detected CPU: $CPU_MODEL"
    echo "CPU Family: $CPU_FAMILY"
    
    # Detect specific CPU models
    if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE "Core.*Ultra.*155H|Meteor Lake"; then
      echo "METEORLAKE"
    elif echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -qiE "i7-8650U|Kaby Lake"; then
      echo "KABYLAKE" 
    else
      echo "GENERIC"
    fi
  '';

  # Robust script helper with CORRECTED syslog priorities
  mkRobustScript = name: content: pkgs.writeShellScript name ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    # FIXED: Correct syslog priority names (user.err instead of user.error)
    exec 1> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.info)
    exec 2> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.err)
    ${content}
  '';

in
{
  # ============================================================================
  # LOCALIZATION & TIMEZONE
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

  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };

  console = {
    keyMap = "trf";
    font = "ter-v20b";
    packages = [ pkgs.terminus_font ];
  };

  system.stateVersion = "25.11";

  # ============================================================================
  # BOOT CONFIGURATION - OPTIMIZED HARDWARE AUTONOMY
  # ============================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [
      "coretemp"        # CPU temperature monitoring
      "i915"            # Intel graphics driver
    ] ++ lib.optionals isPhysicalMachine [
      "thinkpad_acpi"   # ThinkPad-specific features
    ];

    # OPTIMIZED modprobe configuration for better power efficiency
    extraModprobeConfig = ''
      # Power optimization - balanced for all hardware
      options snd_hda_intel power_save=1 power_save_controller=Y
      options iwlwifi power_save=1
      # IMPROVED: Better USB autosuspend timing for dongle compatibility
      options usbcore autosuspend=5
      # REMOVED: NVMe setting moved to kernel params for consistency

      ${lib.optionalString isPhysicalMachine ''
        options thinkpad_acpi fan_control=1 experimental=1
      ''}
    '';

    # OPTIMIZED kernel parameters - true hardware autonomy
    kernelParams = [
      # ENABLE HWP - Hardware-managed frequencies for all
      "intel_pstate=active"
      "intel_pstate.hwp_only=1"
      
      # REMOVED: All C-state limits - let hardware manage completely
      # "processor.max_cstate=5"    # REMOVED - hardware knows best
      # "intel_idle.max_cstate=9"   # REMOVED - hardware knows best  
      # "idle=halt"                 # REMOVED - unnecessary on modern systems
      
      # Performance optimizations (compatible with all)
      "pcie_aspm.policy=default"
      "i915.enable_guc=3"
      # IMPROVED: Conditional graphics power management
      # Start with PSR/FBC enabled, disable if flickering occurs
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "i915.enable_sagv=1"
      "mem_sleep_default=s2idle"
      # OPTIMIZED: Better NVMe power management for battery life
      "nvme_core.default_ps_max_latency_us=5500"

      # FIX: Audit backlog
      "audit_backlog_limit=8192"
  
      # FIX: WiFi error log
      "iwlwifi.bt_coex_active=0"
    ];

    # System tuning for natural operation - REMOVED unnecessary settings
    kernel.sysctl = {
      "vm.swappiness" = 60;
      "vm.vfs_cache_pressure" = 100;
      "vm.dirty_writeback_centisecs" = 500;
      "kernel.nmi_watchdog" = 0;
      # REMOVED: dev.cpu_dma_latency - not a valid sysctl and hardware manages this better
    };

    # Bootloader configuration
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
  # HARDWARE CONFIGURATION - UNIVERSAL SUPPORT
  # ============================================================================
  hardware = {
    # ThinkPad TrackPoint configuration (all ThinkPads)
    trackpoint = lib.mkIf isPhysicalMachine {
      enable = true;
      speed = 200;
      sensitivity = 200;
      emulateWheel = true;
    };

    # Intel graphics configuration (universal Intel support)
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

    # Firmware and microcode (all Intel systems)
    enableRedistributableFirmware = true;
    enableAllFirmware             = true;
    cpu.intel.updateMicrocode     = true;
    bluetooth.enable              = true;
  };

  # ============================================================================
  # POWER MANAGEMENT - OPTIMIZED HARDWARE AUTONOMY
  # ============================================================================
  # Let hardware manage itself - disable conflicting services
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;
  services.tlp.enable                   = false;

  # OPTIMIZED: Use thermald only for thermal management (simplified)
  services.thermald.enable = lib.mkDefault isPhysicalMachine;
  # STREAMLINED: Disable thinkfan - let thermald handle everything
  services.thinkfan.enable = lib.mkForce false;

  # Battery charge thresholds for longevity (all ThinkPads)
  systemd.services.battery-thresholds = lib.mkIf isPhysicalMachine {
    description = "Set battery charge thresholds (75-80% for battery health)";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "set-battery-thresholds" ''
        echo "Configuring battery charge thresholds..."
        
        for bat in /sys/class/power_supply/BAT*; do
          [[ ! -d "$bat" ]] && continue
          
          [[ -w "$bat/charge_control_start_threshold" ]] && \
            echo 75 > "$bat/charge_control_start_threshold" 2>/dev/null && \
            echo "  $(basename $bat): start threshold = 75%" || true
            
          [[ -w "$bat/charge_control_end_threshold" ]] && \
            echo 80 > "$bat/charge_control_end_threshold" 2>/dev/null && \
            echo "  $(basename $bat): stop threshold = 80%" || true
        done
        
        echo "Battery thresholds configured: 75-80%"
      '';
    };
  };

  # ============================================================================
  # THERMAL MANAGEMENT - STREAMLINED (THERMALD ONLY)
  # ============================================================================
  services = {
    upower.enable = true;      # Power management monitoring

    # Login manager power actions (universal settings)
    logind.settings.Login = {
      HandleLidSwitch              = "suspend";
      HandleLidSwitchDocked        = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey               = "ignore";
      HandlePowerKeyLongPress      = "poweroff";
      HandleSuspendKey             = "suspend";
      HandleHibernateKey           = "hibernate";
    };

    # SPICE agent for virtual machines
    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
  };

  # ============================================================================
  # FIXED THERMALD SERVICE - OPTIMIZED FOR ALL HARDWARE
  # ============================================================================
  # Thermald
  systemd.services.thermald = lib.mkIf config.services.thermald.enable {
    wantedBy = [ "multi-user.target" ];  # Boot'ta kesin başlasın
    serviceConfig.ExecStart = lib.mkForce 
      "${pkgs.thermald}/bin/thermald --no-daemon --adaptive --dbus-enable --ignore-cpuid-check --poll-interval 4";
  };

  # ============================================================================
  # HARDWARE-ADAPTIVE SERVICES - OPTIMIZED
  # ============================================================================
  
  # CPU Profile Optimizer - Sets optimal EPP based on CPU capabilities
  systemd.services.cpu-profile-optimizer = lib.mkIf isPhysicalMachine {
    description = "Optimize CPU energy-performance profile based on hardware";
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-profile-optimizer" ''
        echo "=== CPU PROFILE OPTIMIZER - PERFORMANCE FIX ==="
      
        # Detect CPU type
        CPU_TYPE="$(${cpuDetectionScript})"
        echo "CPU Type: $CPU_TYPE"
      
        # Check power source
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && [[ "$ON_AC" == "1" ]] && break
        done

        echo "Power source: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")"
      
        # FIX: Always use performance-oriented settings on AC power
        if [[ "$ON_AC" == "1" ]]; then
          # AC Power - Use performance settings
          EPP_PROFILE="performance"
          GOVERNOR="performance"
        
          # Remove minimum frequency limits
          for pol in /sys/devices/system/cpu/cpufreq/policy*; do
            [[ ! -d "$pol" ]] && continue
            [[ -w "$pol/scaling_min_freq" ]] && echo 0 > "$pol/scaling_min_freq" 2>/dev/null || true
          done
        
          # Enable HWP boost if available
          [[ -w "/sys/devices/system/cpu/cpufreq/boost" ]] && echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
        
        else
          # Battery - Use balanced settings
            EPP_PROFILE="balance_performance"
          GOVERNOR="powersave"
        fi
      
        echo "Optimal Settings: EPP=$EPP_PROFILE, Governor=$GOVERNOR"
      
        # Apply governor settings
        for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
          [[ -w "$gov" ]] && echo "$GOVERNOR" > "$gov" 2>/dev/null || true
        done
      
        # Apply EPP settings to all policies
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ ! -d "$pol" ]] && continue
        
          if [[ -w "$pol/energy_performance_preference" ]]; then
            echo "$EPP_PROFILE" > "$pol/energy_performance_preference" 2>/dev/null || true
            echo "✓ Policy $(basename $pol): $EPP_PROFILE"
          fi
        done
      
        echo "✓ CPU profile optimization complete - Performance mode active"
      '';
    };
  };

  systemd.timers.cpu-profile-optimizer = lib.mkIf isPhysicalMachine {
    description = "Timer for CPU profile optimization";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "10min";  # Rarely needed - hardware manages itself
      Persistent = true;
      Unit = "cpu-profile-optimizer.service";
    };
  };

  # Platform Profile Service - Universal balanced profile (oneshot only)
  systemd.services.platform-profile = lib.mkIf isPhysicalMachine {
    description = "Set optimal ACPI platform profile";
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "platform-profile" ''
        echo "=== Platform Profile Configuration ==="
        
        # Set balanced profile - let hardware manage power/performance
        if [[ -w "/sys/firmware/acpi/platform_profile" ]]; then
          echo "balanced" > /sys/firmware/acpi/platform_profile
          echo "✓ Platform profile: balanced (hardware-managed)"
        else
          echo "⚠ Platform profile interface unavailable"
        fi
      '';
    };
  };

  # Hardware Monitor - Optimized version with robust error handling
  systemd.services.hardware-monitor = lib.mkIf isPhysicalMachine {
    description = "Monitor hardware status without intervention";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkRobustScript "hardware-monitor" ''
        echo "=== HARDWARE STATUS MONITOR ==="
        echo "Timestamp: $(date)"
        
        # CPU frequencies (observe only) - FIXED: Robust CPU number extraction
        echo "CPU Frequencies (current):"
        for cpu_path in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
          [[ -r "$cpu_path/scaling_cur_freq" ]] || continue
          CPU_NUM=$(basename "$cpu_path" | sed 's/cpu//')
          # Validate CPU number is numeric to prevent printf errors
          if [[ "$CPU_NUM" =~ ^[0-9]+$ ]]; then
            FREQ=$(( $(cat "$cpu_path/scaling_cur_freq") / 1000 ))
            GOV=$(cat "$cpu_path/scaling_governor" 2>/dev/null || echo "unknown")
            printf "  CPU %2d: %4d MHz [%s]\n" "$CPU_NUM" "$FREQ" "$GOV"
          fi
        done
        
        # Temperature (observe only) - FIXED: Better error handling
        TEMP_RAW="$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep -m1 -E 'Package id 0|Tctl' || echo "0")"
        TEMP="$(echo "$TEMP_RAW" | ${pkgs.gnused}/bin/sed -E 's/.*: *\+?([0-9]+)\.?[0-9]*°C.*/\1/' 2>/dev/null || echo "unknown")"
        echo "CPU Temperature: ''${TEMP}°C"
        
        # Power source
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Power Source: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")"
        
        echo "✓ Hardware status logged"
      '';
    };
  };

  # Min Frequency Guard Service - HWP ile birlikte çalışır
  systemd.services.cpu-min-freq-guard = lib.mkIf isPhysicalMachine {
    description = "Ensure minimum CPU frequency of 1400 MHz while keeping HWP active";
    after = [ "multi-user.target" ];
    wants = [ "cpu-profile-optimizer.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-min-freq-guard" ''
        echo "=== CPU MIN FREQUENCY GUARD ==="
      
        # Min frekansı 1400 MHz yap (HWP hala aktif)
        echo "Setting minimum frequency to 1400 MHz..."
        for minf in /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq; do
          if [[ -w "$minf" ]]; then
            echo 1400000 > "$minf" 2>/dev/null && \
            echo "✓ $(basename $(dirname $(dirname $minf))): min 1400 MHz" || true
          fi
        done
      
        # EPP'yi balance_performance yap (HWP ile uyumlu)
        echo "Setting EPP to balance_performance..."
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          [[ ! -d "$pol" ]] && continue
          if [[ -w "$pol/energy_performance_preference" ]]; then
            echo "balance_performance" > "$pol/energy_performance_preference" 2>/dev/null && \
            echo "✓ $(basename $pol): EPP=balance_performance" || true
          fi
        done
      
        echo "✓ Min frequency guard active (1400 MHz) - HWP remains enabled"
      '';
    };
  };

  systemd.timers.cpu-min-freq-guard = lib.mkIf isPhysicalMachine {
    description = "Timer for CPU min frequency guard";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "45s";
      OnUnitActiveSec = "2min";  # Her 2 dakikada bir kontrol
      Persistent = true;
      Unit = "cpu-min-freq-guard.service";
    };
  };

  systemd.timers.hardware-monitor = lib.mkIf isPhysicalMachine {
    description = "Timer for hardware status monitoring";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
      Persistent = true;
      Unit = "hardware-monitor.service";
    };
  };

  # UDEV rules for power source changes - universal support
  services.udev.extraRules = lib.mkIf isPhysicalMachine ''
    # Re-apply CPU profile on AC adapter change (all ThinkPads)
    SUBSYSTEM=="power_supply", KERNEL=="AC*",  ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start cpu-profile-optimizer.service"
    SUBSYSTEM=="power_supply", KERNEL=="ADP*", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start cpu-profile-optimizer.service"
  '';

  # ============================================================================
  # USER UTILITY SCRIPTS - OPTIMIZED WITH CORRECTED PACKAGES
  # ============================================================================
  environment.systemPackages = with pkgs;
    lib.optionals isPhysicalMachine [
      lm_sensors
      linuxPackages.x86_energy_perf_policy

      # System Status - Universal observation tool
      (writeScriptBin "system-status" ''
        #!${bash}/bin/bash
        echo "=== SYSTEM STATUS - OPTIMIZED HARDWARE MANAGED ==="
        echo ""
        
        # CPU detection
        CPU_TYPE="$(${cpuDetectionScript})"
        echo "CPU Type: $CPU_TYPE"
        
        # Power source
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Power Source: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")"
        
        # CPU frequencies
        echo ""
        echo "CPU FREQUENCIES (Hardware Managed):"
        i=0
        for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
          [[ -f "$f" ]] || continue
          mhz=$(( $(cat "$f") / 1000 ))
          printf "  Core %2d: %4d MHz\n" "$i" "$mhz"
          i=$((i+1))
        done
        
        # Governor status
        echo ""
        echo "CPU GOVERNOR: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "unknown")"
        
        # EPP status
        EPP="$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null || echo "unknown")"
        echo "ENERGY PERFORMANCE: $EPP"
        
        # Temperature
        echo ""
        echo "TEMPERATURE:"
        ${lm_sensors}/bin/sensors 2>/dev/null | ${gnugrep}/bin/grep -E 'Package|Core|Tctl' | head -3 || \
          echo "  Temperature data unavailable"
        
        # Service status
        echo ""
        echo "SERVICE STATUS:"
        for service in cpu-profile-optimizer platform-profile thermald; do
          if ${systemd}/bin/systemctl is-active "$service.service" >/dev/null 2>&1; then
            echo "  ✅ $service: ACTIVE"
          else
            echo "  ❌ $service: INACTIVE"
          fi
        done
        
        echo ""
        echo "NOTE: System is fully hardware-managed. Optimized for power efficiency."
      '')

      # Hardware Info - Universal hardware detection
      (writeScriptBin "hardware-info" ''
        #!${bash}/bin/bash
        echo "=== OPTIMIZED HARDWARE INFORMATION ==="
        echo ""
        
        # CPU info
        echo "CPU:"
        ${util-linux}/bin/lscpu | ${gnugrep}/bin/grep -E "Model name|CPU MHz|CPU max MHz|CPU min MHz" | head -4
        echo ""
        
        # Memory
        echo "MEMORY:"
        ${procps}/bin/free -h
        echo ""
        
        # Battery info
        echo "BATTERY:"
        for bat in /sys/class/power_supply/BAT*; do
          [[ -d "$bat" ]] || continue
          echo "  $(basename $bat):"
          [[ -r "$bat/capacity" ]] && echo "    Capacity: $(cat "$bat/capacity")%"
          [[ -r "$bat/status" ]] && echo "    Status: $(cat "$bat/status")"
          [[ -r "$bat/charge_control_start_threshold" ]] && echo "    Start Threshold: $(cat "$bat/charge_control_start_threshold")%"
          [[ -r "$bat/charge_control_end_threshold" ]] && echo "    Stop Threshold: $(cat "$bat/charge_control_end_threshold")%"
        done
        echo ""
        
        # Thermal zones
        echo "THERMAL ZONES:"
        for zone in /sys/class/thermal/thermal_zone*; do
          [[ -d "$zone" ]] || continue
          if [[ -r "$zone/temp" ]]; then
            TEMP=$(( $(cat "$zone/temp") / 1000 ))
            TYPE=$(cat "$zone/type" 2>/dev/null || echo "unknown")
            echo "  $TYPE: ''${TEMP}°C"
          fi
        done
      '')

      # Real-time Monitor - Optimized observation
      (writeScriptBin "hw-monitor" ''
        #!${bash}/bin/bash
        echo "REAL-TIME OPTIMIZED HARDWARE MONITOR (Ctrl+C to stop)"
        echo "System is fully hardware-managed - observation only"
        echo "==================================================="
        
        while true; do
          CLEAR="\033c"
          echo -e "$CLEAR"
          echo "REAL-TIME HARDWARE MONITOR ($(date))"
          echo "==================================================="
          
          # CPU frequencies
          echo "CPU FREQUENCIES:"
          i=0
          for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
            [[ -f "$f" ]] || continue
            MHZ=$(( $(cat "$f") / 1000 ))
            printf "  Core %2d: %4d MHz\n" "$i" "$MHZ"
            i=$((i+1))
            [[ $i -eq 4 ]] && break  # Show first 4 cores only
          done
          [[ $i -gt 4 ]] && echo "  ... and $((i-4)) more cores"
          echo ""
          
          # Temperature
          echo "TEMPERATURE:"
          ${lm_sensors}/bin/sensors 2>/dev/null | ${gnugrep}/bin/grep -E 'Package|Tctl' | head -1 || \
            echo "  Temperature data unavailable"
          echo ""
          
          # Power source
          ON_AC=0
          for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
          done
          echo "POWER: $([ "$ON_AC" = "1" ] && echo "AC" || echo "Battery")"
          
          sleep 2
        done
      '')

      # Service Control - Optimized management
      (writeScriptBin "power-services" ''
        #!${bash}/bin/bash
        cmd="''${1:-status}"
        
        case "$cmd" in
          status)
            echo "=== OPTIMIZED HARDWARE MANAGEMENT SERVICES ==="
            echo ""
            for service in cpu-profile-optimizer platform-profile thermald hardware-monitor; do
              ${systemd}/bin/systemctl status "$service.service" --no-pager -l | head -10
              echo "---"
            done
            ;;
          restart)
            echo "Restarting optimized hardware management services..."
            ${systemd}/bin/systemctl restart cpu-profile-optimizer.service
            ${systemd}/bin/systemctl restart platform-profile.service
            ${systemd}/bin/systemctl restart thermald.service
            echo "Services restarted"
            ;;
          log)
            echo "=== OPTIMIZED SERVICE LOGS ==="
            ${pkgs.systemd}/bin/journalctl -u cpu-profile-optimizer -u platform-profile -u thermald --since "1 hour ago" | tail -20
            ;;
          *)
            echo "Usage: power-services {status|restart|log}"
            echo ""
            echo "Commands:"
            echo "  status  - Show service status"
            echo "  restart - Restart management services"
            echo "  log     - Show recent logs"
            ;;
        esac
      '')
    ];
}
