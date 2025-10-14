# ==============================================================================
# NixOS System Configuration - ThinkPad E14 Gen 6 (Core Ultra 7 155H)
# ==============================================================================
#
# Module:    modules/core/system
# Version:   15.0
# Date:      2025-10-13
# Platform:  ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, Meteor Lake)
#
# PHILOSOPHICAL APPROACH:
# -----------------------
# "Trust the hardware; intervene only where critical."
#
# This configuration philosophy recognizes that modern Intel processors have
# sophisticated self-management capabilities. Rather than micromanaging every
# parameter, we make strategic adjustments at key control points:
# - Platform profile (ACPI layer governance)
# - Energy Performance Preference (workload characteristic hints)
# - Power limits (thermal envelope boundaries)
# - Minimum performance floor (responsiveness guarantee)
#
# KEY FEATURES IN THIS VERSION:
# ------------------------------
# ✅ ACPI Platform Profile → "performance" (bypass aggressive throttling)
# ✅ Intel HWP active + EPP (AC=performance, Battery=balance_power)
# ✅ Min Performance (intel_pstate/min_perf_pct) → 30%
# ✅ RAPL limits adaptive to CPU type + power source:
#      - AC: 45W (PL1, sustainable) / 80W (PL2, burst)
#      - Battery: 28W / 45W
# ✅ Auto-reapplication after suspend/hibernate (systemd-sleep hook)
# ✅ Instant profile refresh on AC plug/unplug (udev rule with /bin/sh -c)
# ✅ Battery thresholds → 75% start / 80% stop
# ✅ Diagnostic tools: turbostat-quick, turbostat-stress, power-check, power-monitor
#
# IMPORTANT NOTES:
# ----------------
# • scaling_cur_freq sometimes shows 400 MHz; under HWP this is **misleading**.
#   Check turbostat's Avg_MHz / Bzy_MHz metrics for real behavior.
# • Bash environment variables (e.g. ${WATTS}) are escaped as ''${WATTS} in Nix.
#   (Otherwise Nix treats them as its own interpolation and causes build-time errors.)
# • Timezone is set to Istanbul as per original configuration.
#
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  # ============================================================================
  # SYSTEM IDENTIFICATION
  # ============================================================================
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";      # ThinkPad E14 Gen 6 (physical)
  isVirtualMachine  = hostname == "vhay";     # QEMU/KVM VM (guest)

  # ============================================================================
  # CPU DETECTION (Multi-Platform Support) - CORRECTED VERSION
  # ============================================================================
  # This script detects the CPU model without using any cache, ensuring fresh
  # detection on every invocation. It uses robust pattern matching to identify
  # specific CPU generations (Meteor Lake, Kaby Lake) or falls back to generic
  # Intel defaults. The output is a simple identifier string used to select
  # appropriate power profiles.
  cpuDetectionScript = pkgs.writeTextFile {
    name = "detect-cpu";
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # NO cache usage - always fresh detection
      CPU_MODEL=$(LC_ALL=C ${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F "Model name" | ${pkgs.coreutils}/bin/cut -d: -f2-)
      CPU_MODEL=$(echo "''${CPU_MODEL}" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    
      echo "CPU Model: ''${CPU_MODEL}" >&2

      # Simple and reliable matching pattern
      case "''${CPU_MODEL}" in
        *"Ultra 7 155H"*|*"Meteor Lake"*|*"MTL"*)
          echo "METEORLAKE"
          ;;
        *"8650U"*|*"Kaby Lake"*)
          echo "KABYLAKE" 
          ;;
        *)
          echo "GENERIC"
          ;;
      esac
    '';
  };
   
  # ============================================================================
  # POWER SOURCE DETECTION (AC/Battery) - Shell snippet
  # ============================================================================
  # This inline shell code snippet detects whether the system is running on AC
  # power or battery. It's designed to be embedded within service ExecStart
  # scripts using $(${detectPowerSource}) substitution. Returns "1" for AC
  # power, "0" for battery.
  detectPowerSource = ''
    ON_AC=0
    for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
      [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
    done
    echo "''${ON_AC}"
  '';

  # ============================================================================
  # ROBUST SCRIPT GENERATOR
  # ============================================================================
  # Creates systemd service scripts with built-in logging and error handling.
  # All stdout is redirected to journald with INFO priority, stderr with ERR
  # priority, allowing easy debugging via journalctl. The scripts use bash's
  # strict mode (set -euo pipefail) to catch errors early.
  #
  # Note on Nix escaping: Bash variables must be written as ''${VAR} to prevent
  # Nix from treating them as its own antiquotation syntax ${...}.
  mkRobustScript = name: content: pkgs.writeTextFile {
    name = name;
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      exec 1> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.info)
      exec 2> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.err)
      ${content}
    '';
  };

in
{
  # ============================================================================
  # LOCALIZATION & TIMEZONE
  # ============================================================================
  # System is configured for Istanbul timezone with Turkish regional settings
  # but English system messages for better software compatibility.
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
      LC_MESSAGES       = "en_US.UTF-8";
    };
  };
  
  # Turkish F-keyboard layout with Caps Lock remapped to Control
  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };
  
  # Console configuration with large, readable font
  console = {
    keyMap   = "trf";
    font     = "ter-v20b";
    packages = [ pkgs.terminus_font ];
  };

  system.stateVersion = "25.11";

  # ============================================================================
  # BOOT & KERNEL CONFIGURATION
  # ============================================================================
  boot = {
    # Use latest kernel for best hardware support on new platform
    kernelPackages = pkgs.linuxPackages_latest;
    
    # Essential kernel modules for thermal monitoring and graphics
    kernelModules = [
      "coretemp"  # Intel CPU temperature monitoring
      "i915"      # Intel integrated graphics
    ] ++ lib.optionals isPhysicalMachine [
      "thinkpad_acpi"  # ThinkPad-specific ACPI extensions
    ];
    
    # Enable experimental ThinkPad ACPI features (battery thresholds, etc.)
    extraModprobeConfig = lib.optionalString isPhysicalMachine ''
      options thinkpad_acpi experimental=1
    '';
    
    # Kernel boot parameters for optimal Intel graphics and power management
    kernelParams = [
      "i915.enable_guc=3"      # Enable GuC firmware for graphics scheduling
      "i915.enable_fbc=1"      # Frame Buffer Compression for power savings
      "mem_sleep_default=s2idle"  # Modern standby (s2idle) for faster wake
    ];
    
    # Runtime kernel tuning
    kernel.sysctl = {
      "vm.swappiness"       = 60;  # Moderate swap usage (default: 60)
      "kernel.nmi_watchdog" = 0;   # Disable NMI watchdog to save ~1W
    };
    
    # Bootloader configuration with dual-boot support
    loader = {
      grub = {
        enable = true;
        device = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");
        efiSupport = isPhysicalMachine;
        useOSProber = true;  # Detect other operating systems
        configurationLimit = 10;  # Keep last 10 generations
        gfxmodeEfi  = "1920x1200";  # Native resolution for ThinkPad E14 Gen 6
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
  # HARDWARE CONFIGURATION
  # ============================================================================
  hardware = {
    # TrackPoint configuration for ThinkPad pointing stick
    trackpoint = lib.mkIf isPhysicalMachine {
      enable       = true;
      speed        = 200;
      sensitivity  = 200;
      emulateWheel = true;  # Middle button for scrolling
    };
    
    # Intel graphics acceleration with full codec support
    graphics = {
      enable     = true;
      enable32Bit = true;  # For 32-bit applications/games
      extraPackages = with pkgs; [
        intel-media-driver    # VAAPI driver for Meteor Lake
        mesa                  # OpenGL support
        vaapiVdpau           # VDPAU wrapper for VAAPI
        libvdpau-va-gl       # VDPAU backend using VAAPI
        intel-compute-runtime # OpenCL support
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
      ];
    };
    
    # Firmware and microcode updates
    enableRedistributableFirmware = true;
    enableAllFirmware             = true;
    cpu.intel.updateMicrocode     = true;
    
    bluetooth.enable = true;
  };

  # ============================================================================
  # DISABLE CONFLICTING POWER MANAGEMENT DAEMONS
  # ============================================================================
  # We implement our own power management strategy, so disable all automatic
  # power management daemons that might conflict with our configuration.
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;
  services.tlp.enable                   = false;
  services.thermald.enable              = false;
  services.thinkfan.enable              = false;

  # ============================================================================
  # PLATFORM PROFILE - PERFORMANCE
  # ============================================================================
  # Sets the ACPI platform profile to "performance" mode. This is the first
  # line of defense against aggressive throttling. The platform profile is a
  # high-level hint to the firmware about the desired behavior:
  #
  # - "performance": Prioritize performance over power savings
  # - "balanced": Default balanced behavior
  # - "low-power": Maximize battery life
  #
  # On ThinkPads, this affects ACPI-level power management decisions made by
  # the embedded controller and BIOS, independent of OS-level CPU governors.
  systemd.services.platform-profile = lib.mkIf isPhysicalMachine {
    description = "Set ACPI platform profile to performance";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "multi-user.target" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "platform-profile" ''
        echo "=== Platform Profile Configuration ==="
        if [[ -w "/sys/firmware/acpi/platform_profile" ]]; then
          CURRENT=$(cat /sys/firmware/acpi/platform_profile)
          echo "Current profile: ''${CURRENT}"
          echo "performance" > /sys/firmware/acpi/platform_profile 2>/dev/null
          NEW=$(cat /sys/firmware/acpi/platform_profile)
          if [[ "''${NEW}" == "performance" ]]; then
            echo "✓ Platform profile: performance"
          else
            echo "⚠ Failed to set performance profile (current: ''${NEW})" >&2
          fi
        else
          echo "⚠ Platform profile interface not found"
        fi
      '';
    };
  };

  # ============================================================================
  # EPP (Energy Performance Preference)
  # ============================================================================
  # Configures Intel's Energy Performance Preference (EPP), which is a hint to
  # Hardware P-States (HWP) about workload characteristics. EPP values guide
  # the processor's internal power management algorithms:
  #
  # - "performance": Favor maximum performance, even at cost of power
  # - "balance_performance": Lean toward performance with some power awareness
  # - "balance_power": Lean toward power savings with acceptable performance
  # - "power": Maximize power savings, accept lower performance
  #
  # We dynamically switch EPP based on power source:
  # - AC power: "performance" for desktop-class responsiveness
  # - Battery: "balance_power" for reasonable battery life
  #
  # This service is restarted by udev rules when AC state changes, providing
  # instant adaptation to power source changes.
  systemd.services.cpu-epp = lib.mkIf isPhysicalMachine {
    description = "Set Intel EPP (AC=performance, Battery=balance_power)";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "multi-user.target" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-epp" ''
        echo "=== EPP (Energy Performance Preference) ==="

        ON_AC=$(${detectPowerSource})
        if [[ "''${ON_AC}" = "1" ]]; then
          EPP="performance";
          SOURCE="AC"
        else
          EPP="balance_power";
          SOURCE="Battery"
        fi
        echo "Power source: ''${SOURCE} → EPP: ''${EPP}"

        SUCCESS=0
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          if [[ -w "$pol/energy_performance_preference" ]]; then
            echo "''${EPP}" > "$pol/energy_performance_preference" 2>/dev/null && SUCCESS=1
          fi
        done
        if [[ "''${SUCCESS}" == "1" ]]; then
          echo "✓ EPP configured: ''${EPP}"
        else
          echo "⚠ EPP interface not found" >&2
        fi

        # Enable HWP Dynamic Boost if available (Meteor Lake feature)
        if [[ -w /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost ]]; then
          echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null
          BOOST=$(cat /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost)
          [[ "''${BOOST}" == "1" ]] && echo "✓ HWP Dynamic Boost: active"
        fi
      '';
    };
  };

  # ============================================================================
  # CPU PERFORMANCE CONFIGURATION (min_perf_pct)
  # ============================================================================
  # Sets the minimum performance percentage for intel_pstate. This establishes
  # a performance floor that prevents the CPU from idling too aggressively,
  # which can cause perceived lag in desktop responsiveness.
  #
  # Setting min_perf_pct to 30% means the CPU will operate at least at 30% of
  # its maximum frequency even under light load. This trades a small amount of
  # idle power for significantly better interactive responsiveness.
  #
  # Why 30%?
  # - Below 20%: Noticeable input lag in GUI applications
  # - 30-40%: Sweet spot for responsive desktop with reasonable idle power
  # - Above 50%: Diminishing returns, higher idle power consumption
  #
  # Note: This is a *minimum* - the CPU can and will boost higher when needed.
  # With HWP enabled, actual frequency selection is still hardware-managed.
  systemd.services.cpu-min-freq-guard = lib.mkIf isPhysicalMachine {
    description = "Configure CPU for responsive performance (30% minimum)";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "multi-user.target" "platform-profile.service" ];
    wants       = [ "platform-profile.service" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-min-freq-guard" ''
        echo "=== CPU PERFORMANCE CONFIGURATION ==="
        sleep 2  # Brief delay to ensure platform profile has been applied

        if [[ -w "/sys/devices/system/cpu/intel_pstate/min_perf_pct" ]]; then
          echo 30 > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null
          WRITTEN=$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct)
          echo "✓ Minimum performance: ''${WRITTEN}%"

          # Calculate approximate minimum frequency for user information
          CPUINFO_MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 5000000)
          MAX_FREQ_MHZ=$((CPUINFO_MAX / 1000))
          MIN_FREQ_APPROX=$((MAX_FREQ_MHZ * WRITTEN / 100))
          echo "  Approximate minimum frequency: ~''${MIN_FREQ_APPROX} MHz"
        else
          echo "⚠ min_perf_pct cannot be configured" >&2
          exit 1
        fi

        # Ensure maximum performance is not capped
        if [[ -w "/sys/devices/system/cpu/intel_pstate/max_perf_pct" ]]; then
          CURRENT_MAX=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct)
          if [[ "''${CURRENT_MAX}" -lt 100 ]]; then
            echo 100 > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null
            echo "✓ Maximum performance: 100%"
          fi
        fi

        # Ensure turbo boost is enabled
        if [[ -w "/sys/devices/system/cpu/intel_pstate/no_turbo" ]]; then
          echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null
          NO_TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
          [[ "''${NO_TURBO}" == "0" ]] && echo "✓ Turbo boost: active"
        fi

        echo "✓ CPU configured for responsive performance"
      '';
    };
  };

  # ============================================================================
  # RAPL POWER LIMITS - CPU type + AC/Battery adaptive
  # ============================================================================
  # Configures Running Average Power Limit (RAPL) constraints, which are the
  # final arbiter of CPU power consumption. RAPL operates at the hardware level
  # and cannot be circumvented by software.
  #
  # Two power limits are configured:
  # - PL1 (Power Limit 1): Sustained power limit for continuous operation
  # - PL2 (Power Limit 2): Short-duration burst power limit
  #
  # Power profiles by CPU and power source:
  #
  # Meteor Lake (Core Ultra 7 155H):
  #   AC:      PL1=45W (sustainable desktop performance) / PL2=80W (turbo bursts)
  #   Battery: PL1=28W (balanced mobile usage)         / PL2=45W (moderate bursts)
  #
  # Kaby Lake R (8th gen U-series):
  #   AC:      PL1=35W / PL2=55W (lower TDP platform)
  #   Battery: PL1=20W / PL2=35W
  #
  # Generic Intel (unknown/fallback):
  #   AC:      PL1=40W / PL2=65W
  #   Battery: PL1=22W / PL2=40W
  #
  # These values balance:
  # - Thermal headroom (staying within cooling capacity)
  # - Performance (allowing full-core turbo when needed)
  # - Battery life (reasonable limits on battery power)
  # - Sustained workload capability (PL1 sustainable indefinitely)
  #
  # The service automatically restarts via udev rules when power source changes,
  # providing instant adaptation between AC and battery power limits.
  systemd.services.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Set RAPL power limits (adaptive: CPU type + AC/Battery)";
    wantedBy    = [ "multi-user.target" ];
  
    # Robust dependency ordering to ensure stable boot
    after = [ 
      "multi-user.target" 
      "systemd-udev-settle.service"  # Wait for device enumeration
      "platform-profile.service" 
      "cpu-epp.service"
    ];
  
    wants = [ "platform-profile.service" "cpu-epp.service" ];
  
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      Restart         = "on-failure";
      RestartSec      = "3s";
    
      ExecStart = mkRobustScript "rapl-power-limits" ''
        echo "=== RAPL POWER LIMITS (AC/BATTERY ADAPTIVE) ==="

        # Detect CPU type freshly (no caching)
        CPU_TYPE="$(${cpuDetectionScript})"
        echo "CPU Type: ''${CPU_TYPE}"

        # Determine power source
        ON_AC=$(${detectPowerSource})
        
        # Select appropriate power profile based on CPU type
        case "''${CPU_TYPE}" in
          METEORLAKE)
            PL1_AC=45; PL2_AC=80
            PL1_BAT=28; PL2_BAT=45
            echo "  → Meteor Lake profile selected"
            ;;
          KABYLAKE)
            PL1_AC=35; PL2_AC=55
            PL1_BAT=20; PL2_BAT=35
            echo "  → Kaby Lake profile selected"
            ;;
          *)
            PL1_AC=40; PL2_AC=65
            PL1_BAT=22; PL2_BAT=40
            echo "  → Generic Intel profile selected"
            ;;
        esac

        # Apply AC or battery profile (with adaptive PL2 boost for Meteor Lake)
        if [[ "''${ON_AC}" = "1" ]]; then
          PL1="''${PL1_AC}"; PL2="''${PL2_AC}"; SOURCE="AC (Performance)"
          if [[ "''${CPU_TYPE}" = "METEORLAKE" ]]; then
            # If package temp < 80°C, allow short PL2=90W burst; else keep 80W
            TEMP="$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null \
              | ${pkgs.gnugrep}/bin/grep -m1 "Package id 0" \
              | ${pkgs.gawk}/bin/awk '{match($0, /[+]?([0-9]+(\.[0-9]+)?)/, a); print a[1]}')"
            if [[ -n "''${TEMP}" && $(printf '%.0f' "''${TEMP}") -lt 80 ]]; then
              echo "Temp ''${TEMP}°C < 80°C → enabling short PL2=90W burst"
              PL2=90
            else
              echo "Temp ''${TEMP:-N/A}°C ≥ 80°C or unknown → keeping PL2=''${PL2}W"
            fi
          fi
        else
          PL1="''${PL1_BAT}"; PL2="''${PL2_BAT}"; SOURCE="Battery (Efficiency)"
        fi

        echo "Power Source: ''${SOURCE}"
        echo "Target: PL1=''${PL1}W (sustained), PL2=''${PL2}W (burst)"
  
        # Verify RAPL interface availability
        if [[ ! -d "/sys/class/powercap/intel-rapl:0" ]]; then
          echo "⚠ RAPL interface not found" >&2
          exit 1
        fi

        # Apply power limits to all RAPL domains
        SUCCESS=0
        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          
          # PL1 (constraint_0): Sustained power limit
          if [[ -w "$R/constraint_0_power_limit_uw" ]]; then
            echo $((PL1 * 1000000)) > "$R/constraint_0_power_limit_uw" 2>/dev/null && SUCCESS=1
          fi
          
          # PL2 (constraint_1): Burst power limit
          if [[ -w "$R/constraint_1_power_limit_uw" ]]; then
            echo $((PL2 * 1000000)) > "$R/constraint_1_power_limit_uw" 2>/dev/null && SUCCESS=1
          fi
        done

        if [[ "''${SUCCESS}" == "1" ]]; then
          echo "✓ RAPL limits applied: PL1=''${PL1}W, PL2=''${PL2}W"
        else
          echo "⚠ Failed to apply RAPL limits" >&2
          exit 1
        fi
      '';
    };
  };

  # ============================================================================
  # BATTERY HEALTH MANAGEMENT (75–80%)
  # ============================================================================
  # Configures battery charge thresholds to extend battery lifespan. Modern
  # lithium batteries degrade faster when maintained at 100% charge. By limiting
  # the maximum charge to 80% and only starting charging when below 75%, we
  # significantly extend battery longevity with minimal practical impact.
  #
  # Science behind the 75-80% range:
  # - Li-ion degradation accelerates above 80% state of charge
  # - Keeping battery at 100% causes elevated cell voltage stress
  # - 75-80% range provides optimal balance of capacity vs. longevity
  # - For laptops that are frequently plugged in, this can double battery life
  #
  # ThinkPad implementation:
  # - charge_control_start_threshold: Begin charging when capacity drops below this
  # - charge_control_end_threshold: Stop charging when capacity reaches this
  #
  # If threshold files are not available (non-ThinkPad or older model), the
  # service exits gracefully without error.
  systemd.services.battery-thresholds = lib.mkIf isPhysicalMachine {
    description = "Set battery charge thresholds (75-80%)";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "multi-user.target" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      Restart         = "on-failure";
      RestartSec      = "30s";
      StartLimitBurst = 3;
      ExecStart = mkRobustScript "battery-thresholds" ''
        echo "=== BATTERY CHARGE THRESHOLDS ==="

        SUCCESS=0
        for bat in /sys/class/power_supply/BAT*; do
          [[ -d "$bat" ]] || continue

          if [[ -w "$bat/charge_control_start_threshold" ]]; then
            echo 75 > "$bat/charge_control_start_threshold" 2>/dev/null && SUCCESS=1
            echo "✓ $(basename "''${bat}"): start threshold = 75%"
          fi
          if [[ -w "$bat/charge_control_end_threshold" ]]; then
            echo 80 > "$bat/charge_control_end_threshold" 2>/dev/null && SUCCESS=1
            echo "✓ $(basename "''${bat}"): stop threshold = 80%"
          fi
        done

        if [[ "''${SUCCESS}" == "1" ]]; then
          echo "✓ Battery thresholds: 75–80% applied"
        else
          echo "⚠ Battery threshold interface not found" >&2
          exit 0  # Not an error - some systems don't support this
        fi
      '';
    };
  };

  # ============================================================================
  # SYSTEM SERVICES (logind configuration)
  # ============================================================================
  services = {
    # Enable UPower for battery monitoring and power state management
    upower.enable = true;
    
    # Logind handles lid switch, power button, and sleep behavior
    # Configuration uses the new nested settings structure
    logind.settings = {
      Login = {
        HandleLidSwitch = "suspend";              # Suspend when lid closes
        HandleLidSwitchDocked = "suspend";        # Suspend even when docked
        HandleLidSwitchExternalPower = "suspend"; # Suspend even on AC power
        HandlePowerKey = "ignore";                # Short press does nothing (accidental press protection)
        HandlePowerKeyLongPress = "poweroff";     # Long press powers off
        HandleSuspendKey = "suspend";             # Dedicated suspend key
        HandleHibernateKey = "hibernate";         # Dedicated hibernate key
      };
    };

    # Enable SPICE guest agent for VM environments
    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
  };

  # ============================================================================
  # POST-SLEEP AUTOMATIC RESTORATION (systemd-sleep hook)
  # ============================================================================
  # This hook ensures that power management settings are reapplied after
  # suspend or hibernate. Some power states reset hardware registers or
  # firmware settings, so we proactively restore our configuration.
  #
  # The hook runs during the "post" phase of sleep, which occurs after the
  # system has fully resumed and all devices are reinitialized.
  #
  # Why this is necessary:
  # - Suspend may reset RAPL limits to BIOS defaults
  # - Platform profile can revert to "balanced"
  # - EPP settings may be cleared
  # - CPU frequency policy might reset
  #
  # We restart the services rather than calling the scripts directly to
  # maintain proper systemd state tracking and logging.
  environment.etc."systemd/system-sleep/10-power-restore" = {
    mode = "0755";
    text = ''
      #!${pkgs.bash}/bin/bash
      case "''${1}" in
        post)
          # Restart power management services after wake
          /run/current-system/sw/bin/systemctl restart cpu-epp.service || true
          /run/current-system/sw/bin/systemctl restart rapl-power-limits.service || true
          /run/current-system/sw/bin/systemctl restart cpu-min-freq-guard.service || true
          /run/current-system/sw/bin/systemctl restart platform-profile.service || true
          ;;
      esac
    '';
  };

  # ============================================================================
  # AC PLUG/UNPLUG EVENT INSTANT PROFILE REFRESH (udev rule)
  # ============================================================================
  # This udev rule provides instant responsiveness to power source changes.
  # When AC power is connected or disconnected, the system immediately updates
  # EPP and RAPL settings to match the new power state.
  #
  # Without this rule:
  # - Power profile changes would only occur at next reboot/sleep
  # - System might run with inappropriate settings (battery limits on AC, etc.)
  #
  # Implementation note:
  # - Uses ${pkgs.runtimeShell} -c to execute multiple systemctl commands
  # - Semicolon separates commands within the shell invocation
  # - Both services restart regardless of individual success/failure
  #
  # The rule triggers on:
  # - ACTION=="change": Device state change events
  # - SUBSYSTEM=="power_supply": Power supply subsystem
  # - KERNEL=="AC*": AC adapter devices
  # - POWER_SUPPLY_ONLINE: Online status (1=connected, 0=disconnected)
  services.udev.extraRules = lib.mkIf isPhysicalMachine ''
    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC*", ENV{POWER_SUPPLY_ONLINE}=="1", \
      RUN+="${pkgs.runtimeShell} -c '/run/current-system/sw/bin/systemctl restart cpu-epp.service; /run/current-system/sw/bin/systemctl restart rapl-power-limits.service'"

    ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC*", ENV{POWER_SUPPLY_ONLINE}=="0", \
      RUN+="${pkgs.runtimeShell} -c '/run/current-system/sw/bin/systemctl restart cpu-epp.service; /run/current-system/sw/bin/systemctl restart rapl-power-limits.service'"
  '';

  # ============================================================================
  # MONITORING & DIAGNOSTIC TOOLS (convenience utilities)
  # ============================================================================
  # These custom scripts provide user-friendly interfaces for monitoring and
  # diagnosing power management behavior. They're designed to be run from the
  # command line and provide actionable information about system state.
  #
  # Available commands:
  # - system-status: Comprehensive overview of power management state
  # - turbostat-quick: Real frequency analysis (requires root)
  # - turbostat-stress: Performance testing under load
  # - power-check: Instantaneous power consumption measurement
  # - power-monitor: Real-time power monitoring dashboard
  # - power-profile-refresh: Manual service restart trigger
  #
  # Note on Nix escaping:
  # - pkgs.* references use Nix interpolation (${pkgs.bash})
  # - Shell variables use escaped form (''${VARIABLE}) to avoid Nix parsing
  environment.systemPackages = with pkgs; lib.optionals isPhysicalMachine [
    lm_sensors                    # Hardware monitoring (sensors command)
    stress-ng                     # CPU stress testing
    powertop                      # Power consumption analysis
    bc                            # Calculator for power math
    linuxPackages_latest.turbostat # Intel CPU frequency/power analysis

    # ========================================================================
    # SYSTEM-STATUS: Comprehensive power management status display
    # ========================================================================
    # Provides a complete snapshot of:
    # - Power source (AC/Battery)
    # - Intel P-State configuration (min/max perf, turbo status)
    # - Platform profile
    # - EPP settings per-policy
    # - Current CPU frequencies (sampling)
    # - RAPL power limits
    # - Battery status and charge thresholds
    # - Service health status
    #
    # This is the first tool to run when diagnosing power management issues.
    (writeScriptBin "system-status" ''
      #!${pkgs.bash}/bin/bash
      echo "=== SYSTEM STATUS (v15.0.0) ==="
      echo ""

      # Detect power source
      ON_AC=0
      for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
      done
      echo "Power Source: $([ "''${ON_AC}" = "1" ] && echo "⚡ AC" || echo "🔋 Battery")"

      # Intel P-State status
      if [[ -f "/sys/devices/system/cpu/intel_pstate/status" ]]; then
        PSTATE=$(cat /sys/devices/system/cpu/intel_pstate/status)
        echo "P-State Mode: ''${PSTATE}"

        if [[ -r "/sys/devices/system/cpu/intel_pstate/min_perf_pct" ]]; then
          MIN_PERF=$(cat /sys/devices/system/cpu/intel_pstate/min_perf_pct)
          MAX_PERF=$(cat /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || echo "?")
          echo "  Min/Max Performance: ''${MIN_PERF}% / ''${MAX_PERF}%"
        fi

        if [[ -r "/sys/devices/system/cpu/intel_pstate/no_turbo" ]]; then
          NO_TURBO=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)
          echo "  Turbo Boost: $([ "''${NO_TURBO}" = "0" ] && echo "✓ Active" || echo "✗ Disabled")"
        fi

        if [[ -r "/sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost" ]]; then
          BOOST=$(cat /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost)
          echo "  HWP Dynamic Boost: $([ "''${BOOST}" = "1" ] && echo "✓ Active" || echo "✗ Disabled")"
        fi
      fi

      # Platform profile
      if [[ -r "/sys/firmware/acpi/platform_profile" ]]; then
        PROFILE=$(cat /sys/firmware/acpi/platform_profile)
        echo "Platform Profile: ''${PROFILE}"
      fi

      # EPP (Energy Performance Preference) - compact summary
      echo ""
      CPU_COUNT=$(${pkgs.coreutils}/bin/ls -d /sys/devices/system/cpu/cpu[0-9]* 2>/dev/null | ${pkgs.coreutils}/bin/wc -l | ${pkgs.coreutils}/bin/tr -d ' ')
      POLICY_DIRS=$(${pkgs.coreutils}/bin/ls -d /sys/devices/system/cpu/cpufreq/policy* 2>/dev/null | ${pkgs.coreutils}/bin/wc -l | ${pkgs.coreutils}/bin/tr -d ' ')

      declare -A EPP_MAP
      for pol in /sys/devices/system/cpu/cpufreq/policy*; do
        [[ -r "$pol/energy_performance_preference" ]] || continue
        epp=$(${pkgs.coreutils}/bin/cat "$pol/energy_performance_preference")
        epp=$(${pkgs.coreutils}/bin/echo "''${epp}" | ${pkgs.gnused}/bin/sed 's/[[:space:]]\+//g')
        ((EPP_MAP["$epp"]++)) || true
      done

      echo "EPP:"
      if [[ "''${#EPP_MAP[@]}" -eq 1 ]]; then
        for k in "''${!EPP_MAP[@]}"; do
          echo "  ''${CPU_COUNT} CPUs → ''${k}"
        done
        if [[ "''${ON_AC}" = "1" ]]; then
          echo "  (On battery, expected: balance_power)"
        fi
      elif [[ "''${#EPP_MAP[@]}" -gt 1 ]]; then
        printf "  mixed (%d policies): " "''${POLICY_DIRS}"
        first=1
        for k in $(${pkgs.coreutils}/bin/printf "%s\n" "''${!EPP_MAP[@]}" | ${pkgs.coreutils}/bin/sort); do
          count="''${EPP_MAP[$k]}"
          if [[ $first -eq 1 ]]; then
            printf "%s=%d" "''${k}" "''${count}"
            first=0
          else
            printf ", %s=%d" "''${k}" "''${count}"
          fi
        done
        printf "\n"
        if [[ "''${POLICY_DIRS}" -ne "''${CPU_COUNT}" ]]; then
          echo "  (Note: ''${POLICY_DIRS} policies, ''${CPU_COUNT} CPUs)"
        fi
      else
        echo "  (no EPP interface found)"
      fi

      # CPU frequencies (sample cores)
      echo ""
      echo "CPU FREQUENCIES (sample cores):"
      for i in 0 4 8 12 16 20; do
        if [[ -r "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" ]]; then
          FREQ=$(cat "/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq" 2>/dev/null || echo 0)
          printf "  CPU %2d: %4d MHz\n" "$i" "$((FREQ/1000))"
        fi
      done

      # Frequencies summary (avg/min/max over all CPUs)
      F_SUM=0; F_CNT=0; F_MIN=999999999; F_MAX=0
      for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
        [[ -f "$f" ]] || continue
        v=$(cat "$f")
        F_SUM=$((F_SUM + v)); F_CNT=$((F_CNT + 1))
        [[ "''${v}" -lt "''${F_MIN}" ]] && F_MIN="''${v}"
        [[ "''${v}" -gt "''${F_MAX}" ]] && F_MAX="''${v}"
      done
      if [[ "''${F_CNT}" -gt 0 ]]; then
        printf "  All-CPU Avg/Min/Max: %4d / %4d / %4d MHz\n" $((F_SUM/F_CNT/1000)) $((F_MIN/1000)) $((F_MAX/1000))
      fi

      # RAPL power limits (nice time formatting; hide zero)
      echo ""
      echo "RAPL POWER LIMITS:"
      if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
        fmt_us() {
          local us="$1"
          if [[ "$us" -le 0 ]]; then
            echo ""   # nothing
          elif [[ "$us" -ge 1000000 ]]; then
            # seconds with 2 decimals
            ${pkgs.coreutils}/bin/printf "(τ≈%.2fs)" "$(${pkgs.bc}/bin/bc -l <<< "scale=4; $us/1000000")"
          elif [[ "$us" -ge 1000 ]]; then
            # milliseconds integer
            echo "(τ≈$((us/1000))ms)"
          else
            # microseconds integer
            echo "(τ≈''${us}µs)"
          fi
        }

        for R in /sys/class/powercap/intel-rapl:*; do
          [[ -d "$R" ]] || continue
          NAME=$(basename "$R")
          LABEL=$(cat "$R/name" 2>/dev/null || echo "$NAME")

          PL1=$(cat "$R/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
          TW1=$(cat "$R/constraint_0_time_window_us" 2>/dev/null || echo 0)

          PL2=$(cat "$R/constraint_1_power_limit_uw" 2>/dev/null || echo 0)
          TW2=$(cat "$R/constraint_1_time_window_us" 2>/dev/null || echo 0)

          echo "  Domain: ''${LABEL}"
  
          # PL1
          printf "    PL1: %3d W" $((PL1/1000000))
          F1=$(fmt_us "$TW1")
          [[ -n "$F1" ]] && printf "  %s" "$F1"
          echo

          # PL2 (only if present and >0)
          if [[ "$PL2" -gt 0 ]]; then
            printf "    PL2: %3d W" $((PL2/1000000))
            F2=$(fmt_us "$TW2")
            [[ -n "$F2" ]] && printf "  %s" "$F2"
            echo
          fi
        done
      else
        echo "  (RAPL interface not available)"
      fi

      # Battery status
      echo ""
      echo "BATTERY STATUS:"
      for bat in /sys/class/power_supply/BAT*; do
        [[ -d "$bat" ]] || continue
        NAME=$(basename "$bat")
        CAPACITY=$(cat "$bat/capacity" 2>/dev/null || echo "N/A")
        STATUS=$(cat "$bat/status" 2>/dev/null || echo "N/A")
        START=$(cat "$bat/charge_control_start_threshold" 2>/dev/null || echo "N/A")
        STOP=$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo "N/A")
        echo "  ''${NAME}: ''${CAPACITY}% (''${STATUS}) [Thresholds: ''${START}-''${STOP}%]"
      done

      # Service status
      echo ""
      echo "SERVICE STATUS:"
      for svc in battery-thresholds platform-profile cpu-epp cpu-min-freq-guard rapl-power-limits; do
        STATE=$(${pkgs.systemd}/bin/systemctl show -p ActiveState --value "$svc.service" 2>/dev/null)
        RESULT=$(${pkgs.systemd}/bin/systemctl show -p Result --value "$svc.service" 2>/dev/null)
        if [[ ( "''${STATE}" == "inactive" && "''${RESULT}" == "success" ) || "''${STATE}" == "active" ]]; then
          echo "  ✅ $svc"
        else
          echo "  ⚠️  $svc (''${STATE})"
        fi
      done

      echo ""
      echo "💡 Tip: Use 'turbostat-quick' for real frequency analysis"
      echo "💡 Use 'power-check' or 'power-monitor' for power consumption"
    '')

    # ========================================================================
    # TURBOSTAT-QUICK: Real CPU frequency analysis
    # ========================================================================
    # Uses Intel's turbostat utility to show ACTUAL CPU behavior, not the
    # often-misleading scaling_cur_freq values. Key metrics:
    #
    # - Avg_MHz: Average frequency across measurement period (includes idle)
    # - Bzy_MHz: Average frequency when CPU is busy (excludes idle time)
    # - %Busy: Percentage of time CPU was not idle
    # - PkgWatt: Package power consumption
    # - Package Temperature
    #
    # Why turbostat vs sysfs frequencies?
    # - scaling_cur_freq shows last requested frequency, not actual
    # - Under HWP, hardware manages frequency independently of OS requests
    # - turbostat reads hardware counters for ground truth
    #
    # Requires root privileges to access MSR (Model-Specific Registers).
    (writeScriptBin "turbostat-quick" ''
      #!${pkgs.bash}/bin/bash
      echo "=== TURBOSTAT QUICK ANALYSIS ==="
      echo "Monitoring CPU behavior for 5 seconds..."
      echo ""
      echo "NOTE: 'Avg_MHz' is real average; 'Bzy_MHz' is busy-core frequency."
      echo "      scaling_cur_freq showing 400 MHz may be misleading."
      echo ""

      if ! command -v turbostat &>/dev/null; then
        echo "⚠ turbostat not found"
        exit 1
      fi

      sudo ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat --interval 5 --num_iterations 1
    '')

    # ========================================================================
    # TURBOSTAT-STRESS: Performance testing under load
    # ========================================================================
    # Combines CPU stress testing with turbostat monitoring to verify that
    # the system can actually achieve high performance when needed.
    #
    # Test sequence:
    # 1. Baseline measurement (idle state)
    # 2. Start stress-ng CPU load
    # 3. Monitor under full load
    # 4. Compare results
    #
    # What to look for:
    # - Avg_MHz should reach 2000+ MHz under load
    # - Package temperature should stay below 85°C
    # - Power consumption should approach RAPL limits
    # - No throttling events (check turbostat output)
    #
    # If performance is poor, possible causes:
    # - RAPL limits too restrictive
    # - Thermal throttling (cooling issue)
    # - Platform profile not set to performance
    # - EPP set too conservatively
    (writeScriptBin "turbostat-stress" ''
      #!${pkgs.bash}/bin/bash
      echo "=== CPU PERFORMANCE TEST ==="
      echo "10 second stress + turbostat analysis"
      echo ""

      if ! command -v ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat &>/dev/null || ! command -v ${pkgs.stress-ng}/bin/stress-ng &>/dev/null; then
        echo "⚠ Required tools not found"
        exit 1
      fi

      echo "Initial state (idle):"
      sudo ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat --interval 2 --num_iterations 1

      echo ""
      echo "Starting stress test..."
      ${pkgs.stress-ng}/bin/stress-ng --cpu 0 --timeout 10s &
      STRESS_PID=$!
      sleep 1
      echo "Analysis under load:"
      sudo ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat --interval 8 --num_iterations 1

      wait "''${STRESS_PID}" 2>/dev/null

      echo ""
      echo "Stress test completed"
      echo ""
      echo "📊 Evaluation criteria:"
      echo "   - Avg_MHz >= 2000 is good"
      echo "   - Package temperature <= 85°C is ideal"
      echo "   - Compare Watt values with RAPL limits"
    '')

    # ========================================================================
    # POWER-CHECK: Instantaneous power consumption measurement
    # ========================================================================
    # Measures current CPU package power by sampling RAPL energy counters
    # over a 2-second interval. Provides context with:
    # - Current power source (AC/Battery)
    # - Active RAPL limits
    # - Interpretation of power level
    # - Average CPU frequency
    # - Package temperature
    #
    # RAPL energy counters are cumulative, so we take two readings and
    # calculate the difference to determine power consumption rate.
    #
    # Power interpretation guidelines:
    # - <10W: Idle/light usage (good for battery)
    # - 10-30W: Normal productivity workload
    # - 30-50W: Heavy computational work
    # - >50W: Sustained high performance or stress testing
    (writeScriptBin "power-check" ''
      #!${pkgs.bash}/bin/bash
      echo "=== POWER CONSUMPTION ANALYSIS (v15.0.0) ==="
      echo ""

      # Detect power source
      ON_AC=0
      for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
      done
      echo "Power Source: $([ "''${ON_AC}" = "1" ] && echo "⚡ AC" || echo "🔋 Battery")"
      echo ""

      if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
        echo "Measuring power consumption for 2 seconds..."
        ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
        sleep 2
        ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

        # Handle counter wraparound (rare but possible)
        ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
        [[ "''${ENERGY_DIFF}" -lt 0 ]] && ENERGY_DIFF="''${ENERGY_AFTER}"

        # Calculate watts (microjoules / 2 seconds / 1,000,000)
        WATTS=$(echo "scale=2; ''${ENERGY_DIFF} / 2000000" | ${pkgs.bc}/bin/bc)

        echo ""
        echo "INSTANTANEOUS PACKAGE POWER: ''${WATTS}W"
        echo ""

        # Show current RAPL limits for context
        PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)
        PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw)
        printf "Active RAPL Limits:\n  PL1 (sustained): %3d W\n  PL2 (burst):     %3d W\n\n" $((PL1/1000000)) $((PL2/1000000))

        # Interpret power level
        WATTS_INT=$(echo "''${WATTS}" | ${pkgs.coreutils}/bin/cut -d. -f1)
        if   [[ "''${WATTS_INT}" -lt 10 ]]; then echo "📊 Status: Ideal (low power)"
        elif [[ "''${WATTS_INT}" -lt 30 ]]; then echo "📊 Status: Normal (daily usage)"
        elif [[ "''${WATTS_INT}" -lt 50 ]]; then echo "📊 Status: High (intensive work)"
        else                                     echo "📊 Status: Very High (stress?)"
        fi

        # Additional context: average frequency
        FREQ_SUM=0; COUNT=0
        for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
          [[ -f "$f" ]] && FREQ_SUM=$((FREQ_SUM + $(cat "$f"))) && COUNT=$((COUNT + 1))
        done
        [[ "''${COUNT}" -gt 0 ]] && echo "Average scaling freq: $((FREQ_SUM / COUNT / 1000)) MHz"

        # Package temperature
        TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Package id 0" | ${pkgs.gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, a); print a[1]}')
        [[ -n "''${TEMP}" ]] && printf "Package temperature: %.1f°C\n" "''${TEMP}"

        echo ""
        echo "💡 Tip: 'turbostat-quick' shows real frequencies"
      else
        echo "⚠ RAPL interface not found"
      fi
    '')

    # ========================================================================
    # POWER-MONITOR: Real-time power consumption dashboard
    # ========================================================================
    # Continuous monitoring tool that updates every second, showing:
    # - Current power source
    # - Real-time package power consumption
    # - Active RAPL limits
    # - Current EPP setting
    # - CPU frequency statistics (min/max/avg)
    # - Package temperature
    #
    # Useful for:
    # - Observing power impact of applications
    # - Verifying power profile changes take effect
    # - Watching thermal behavior under sustained load
    # - Identifying power-hungry processes (use with top/htop)
    #
    # Press Ctrl+C to exit. The display refreshes continuously, providing
    # a live view of system power management behavior.
    (writeScriptBin "power-monitor" ''
      #!${pkgs.bash}/bin/bash
      echo "=== REAL-TIME POWER MONITOR (v15.0.0) ==="
      echo "Press Ctrl+C to stop"
      echo ""

      while true; do
        clear
        echo "=== POWER MONITOR ($(date '+%H:%M:%S')) ==="
        echo ""

        # Power source
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Power Source: $([ "''${ON_AC}" = "1" ] && echo "⚡ AC" || echo "🔋 Battery")"
        echo ""

        # Power consumption (0.5 second sample for faster updates)
        if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
          ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj 2>/dev/null || echo 0)
          sleep 0.5
          ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj 2>/dev/null || echo 0)

          ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
          [[ "''${ENERGY_DIFF}" -lt 0 ]] && ENERGY_DIFF="''${ENERGY_AFTER}"
          WATTS=$(echo "scale=2; ''${ENERGY_DIFF} / 500000" | ${pkgs.bc}/bin/bc)

          PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)
          PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)

          echo "PACKAGE POWER:"
          printf "  Current:   %6.2f W\n" "''${WATTS}"
          printf "  Limit 1:   %6d W (sustained)\n" $((PL1/1000000))
          printf "  Limit 2:   %6d W (burst)\n"   $((PL2/1000000))
          echo ""
        fi

        # EPP
        for pol in /sys/devices/system/cpu/cpufreq/policy0; do
          if [[ -r "$pol/energy_performance_preference" ]]; then
            EPP=$(cat "$pol/energy_performance_preference")
            echo "EPP: ''${EPP}"
            echo ""
            break
          fi
        done

        # CPU frequency statistics
        echo "CPU FREQUENCIES (scaling):"
        FREQ_SUM=0; FREQ_COUNT=0; FREQ_MIN=9999999; FREQ_MAX=0
        for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
          [[ -f "$f" ]] || continue
          FREQ=$(cat "$f")
          FREQ_SUM=$((FREQ_SUM + FREQ))
          FREQ_COUNT=$((FREQ_COUNT + 1))
          [[ "''${FREQ}" -lt "''${FREQ_MIN}" ]] && FREQ_MIN="''${FREQ}"
          [[ "''${FREQ}" -gt "''${FREQ_MAX}" ]] && FREQ_MAX="''${FREQ}"
        done
        if [[ "''${FREQ_COUNT}" -gt 0 ]]; then
          FREQ_AVG=$((FREQ_SUM / FREQ_COUNT))
          printf "  Average: %4d MHz\n" $((FREQ_AVG/1000))
          printf "  Minimum: %4d MHz\n" $((FREQ_MIN/1000))
          printf "  Maximum: %4d MHz\n" $((FREQ_MAX/1000))
        fi
        echo ""

        # Temperature
        echo "TEMPERATURE:"
        TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Package id 0" | ${pkgs.gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, a); print a[1]}')
        [[ -n "''${TEMP}" ]] && printf "  Package: %5.1f°C\n" "''${TEMP}" || echo "  N/A"

        echo ""
        echo "⚠ NOTE: scaling_cur_freq values may be misleading!"
        echo "   Use 'turbostat-quick' for real frequencies"

        sleep 1
      done
    '')

    # ========================================================================
    # POWER-PROFILE-REFRESH: Manual service restart utility
    # ========================================================================
    # Convenience command to manually trigger a complete refresh of all power
    # management services. Useful when:
    # - Testing configuration changes
    # - Recovering from service failures
    # - Forcing re-detection of power state
    # - Verifying that all services can start successfully
    #
    # This command requires sudo privileges as it restarts system services.
    # After restarting services, it displays the current system status to
    # verify that the refresh was successful.
    (writeScriptBin "power-profile-refresh" ''
      #!${pkgs.bash}/bin/bash
      echo "=== POWER PROFILE REFRESH ==="
      echo ""
      echo "Restarting EPP and RAPL services..."
      echo ""

      sudo ${pkgs.systemd}/bin/systemctl restart cpu-epp.service
      sudo ${pkgs.systemd}/bin/systemctl restart rapl-power-limits.service
      sudo ${pkgs.systemd}/bin/systemctl restart cpu-min-freq-guard.service
      sudo ${pkgs.systemd}/bin/systemctl restart platform-profile.service

      echo "✓ Services restarted"
      echo ""
      echo "New status:"
      system-status
    '')

  ];
}
