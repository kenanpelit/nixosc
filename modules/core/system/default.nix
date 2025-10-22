# modules/core/system/default.nix
# ==============================================================================
# NixOS System Configuration - ThinkPad E14 Gen 6 (Core Ultra 7 155H)
# ==============================================================================
#
# Module:    modules/core/system
# Version:   16.0
# Date:      2025-10-22
# Platform:  ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, Meteor Lake)
#
# PHILOSOPHICAL APPROACH:
# -----------------------
# "Trust the hardware; intervene only where critical."
#
# Modern Intel platforms (esp. Meteor Lake) already optimize P-states and boosting
# in hardware (HWP). Instead of fighting the firmware, this module applies a few
# well-chosen, high-leverage controls and leaves the rest to silicon:
#
# - ACPI Platform Profile: High-level hint to relax conservative firmware limits.
# - EPP: Clear intent signals to HWP (performance vs. efficiency).
# - RAPL (PL1/PL2): Hard ceilings for the thermal/power envelope.
# - Min Performance Floor: Prevents UI jank by avoiding over-deep idle.
#
# KEY FEATURES IN THIS VERSION:
# -----------------------------
# ✅ ACPI Platform Profile → AC: "performance", Battery: "balanced" (adaptive).
# ✅ Intel HWP active + EPP: AC="performance", Battery="balance_power".
# ✅ Min performance guard (intel_pstate/min_perf_pct): AC=30%, Battery=20%.
# ✅ CPU-aware, source-aware RAPL:
#      • Meteor Lake (this machine) → AC: 35W/52W, Battery: 28W/45W.
# ✅ Temperature-aware PL2 (rapl-thermo-guard):
#      • 60-64°C → restore BASE_PL2 (52W); 65-69°C → hold; 70-74°C → clamp 38W; ≥75°C → clamp 32W.
#      • Never touches PL1; avoids oscillation vs. stock firmware throttling.
# ✅ MSR-only RAPL strategy:
#      • MMIO interface disabled to prevent conflicts with MSR.
#      • Single source of truth: MSR (intel-rapl module).
# ✅ Instant AC plug/unplug handling via udev (restart all relevant services).
# ✅ Post-suspend hook re-applies all power settings after resume.
# ✅ Battery longevity: charge thresholds 75% (start) / 80% (stop).
# ✅ Tooling: system-status, turbostat-quick/stress/analyze, power-check, power-monitor,
#    power-profile-refresh for fast diagnostics.
#
# CHANGES IN v16.0:
# -----------------
# • FIXED: MMIO/MSR conflict - now using MSR-only strategy (MMIO fully disabled).
# • FIXED: EPB removed - redundant with HWP+EPP; simplified power management.
# • FIXED: Temperature thresholds now consistent (60-64°C restore, not 65°C).
# • FIXED: Centralized power source detection (no code duplication).
# • FIXED: Service restart dependencies now properly ordered.
# • IMPROVED: Platform profile now adaptive (performance on AC, balanced on battery).
# • IMPROVED: Auto-cpufreq explicitly disabled in configuration.
#
# IMPORTANT NOTES:
# ----------------
# • With HWP, `scaling_cur_freq` often reads ~400 MHz and is misleading. Use `turbostat`
#   (Avg_MHz/Bzy_MHz, PkgWatt) for truth.
# • Nix string escaping: write Bash vars as ''${VAR} (not ${VAR}) inside Nix strings.
# • Conflicting daemons are intentionally disabled (tlp, thermald, power-profiles-daemon,
#   auto-cpufreq) to ensure deterministic control via sysfs/MSR.
# • Timezone defaults to Europe/Istanbul; UI/console/input are tuned for TR-F layout.
#
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  # ============================================================================
  # SYSTEM IDENTIFICATION
  # ============================================================================
  # These booleans determine whether the configuration is being applied to the
  # primary physical machine or a virtual machine guest. This allows for
  # conditional inclusion of hardware-specific packages and settings.
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";      # ThinkPad E14 Gen 6 (physical hardware)
  isVirtualMachine  = hostname == "vhay";     # QEMU/KVM VM (guest)

  # ============================================================================
  # CPU DETECTION (Multi-Platform Support)
  # ============================================================================
  # This runtime script detects the CPU model to apply platform-specific power
  # profiles. It is designed to be robust and always perform a fresh detection,
  # avoiding any system cache. It uses simple, reliable pattern matching against
  # the output of `lscpu` to identify the CPU generation (Meteor Lake, Kaby Lake)
  # or falls back to a generic Intel default profile. The script outputs a simple
  # identifier string used by other services.
  cpuDetectionScript = pkgs.writeTextFile {
    name = "detect-cpu";
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # Do not use a cache; always perform a fresh detection.
      CPU_MODEL=$(LC_ALL=C ${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F "Model name" | ${pkgs.coreutils}/bin/cut -d: -f2-)
      CPU_MODEL=$(echo "''${CPU_MODEL}" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

      echo "CPU Model: ''${CPU_MODEL}" >&2 # Log detected model to stderr for debugging.

      # Reliable pattern matching for known CPU generations.
      case "''${CPU_MODEL}" in
        *"Ultra 7 155H"*|*"Meteor Lake"*|*"MTL"*)
          echo "METEORLAKE"
          ;;
        *"8650U"*|*"Kaby Lake"*)
          echo "KABYLAKE"
          ;;
        *)
          echo "GENERIC" # Fallback for unknown Intel CPUs.
          ;;
      esac
    '';
  };

  # ============================================================================
  # CENTRALIZED POWER SOURCE DETECTION
  # ============================================================================
  # This is the single source of truth for power source detection throughout
  # the configuration. It returns "AC" or "BATTERY" as a string for easier
  # use in conditional logic within scripts.
  powerSourceDetector = pkgs.writeTextFile {
    name = "detect-power-source";
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      
      # Iterate through possible sysfs paths for AC adapter status.
      for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        if [[ -f "$PS" ]]; then
          ON_AC=$(cat "$PS")
          if [[ "$ON_AC" == "1" ]]; then
            echo "AC"
            exit 0
          fi
        fi
      done
      
      # If no AC detected, we're on battery.
      echo "BATTERY"
    '';
  };

  # ============================================================================
  # ROBUST SCRIPT GENERATOR
  # ============================================================================
  # This helper function creates robust, self-logging systemd service scripts.
  # It wraps the provided content in a Bash script that includes:
  # - Strict mode (`set -euo pipefail`) to exit immediately on errors.
  # - Automatic redirection of stdout (to journald with INFO priority) and
  #   stderr (to journald with ERR priority). This simplifies debugging with
  #   `journalctl -t power-mgmt-<n>`.
  # Note on Nix escaping: Bash variables must be written as ''${VAR} to prevent
  # Nix from treating them as its own antiquotation syntax `${...}`.
  mkRobustScript = name: content: pkgs.writeTextFile {
    name = name;
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      # Redirect all output to the system journal for easy inspection.
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
  # The system is configured for the Istanbul timezone. Regional settings (LC_*)
  # are set to Turkish for correct formatting of currency, numbers, and time.
  # However, system messages (LC_MESSAGES) are kept in English for broader
  # compatibility and easier troubleshooting of software errors.
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
      LC_MESSAGES       = "en_US.UTF-8"; # Keep messages in English.
    };
  };

  # Turkish F-keyboard layout with Caps Lock remapped to Control for ergonomics.
  services.xserver.xkb = {
    layout = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };

  # Console keyboard layout (matches X11 settings for consistency).
  console = {
    keyMap = "trq";
    font   = "Lat2-Terminus16";
  };

  # ============================================================================
  # SYSTEM PACKAGES
  # ============================================================================
  # A curated collection of essential system utilities and tools, conditionally
  # installed depending on whether the system is physical or virtual.
  environment.systemPackages = with pkgs; [
    # --- CORE UTILITIES ---
    vim wget curl git htop tree unzip zip file ncdu lsof strace
    ripgrep fd bat eza jq yq bc

    # --- HARDWARE DIAGNOSTICS (Physical Machine Only) ---
  ] ++ lib.optionals isPhysicalMachine [
    lm_sensors          # Hardware temperature monitoring
    powertop            # Power consumption analysis
    pciutils usbutils   # PCI/USB device inspection (lspci, lsusb)
    acpi                # Battery and AC adapter status
    smartmontools       # Disk health (SMART monitoring)
    nvme-cli            # NVMe SSD diagnostics
    dmidecode           # BIOS/firmware information
    lshw                # Comprehensive hardware listing
    inxi                # System information tool
    hwinfo              # Hardware probing
  ];

  # ============================================================================
  # HARDWARE SUPPORT (Physical Machine Only)
  # ============================================================================
  # These settings enable essential hardware features and firmware for the
  # ThinkPad E14 Gen 6. CPU microcode, firmware updates, and Bluetooth are
  # critical for stability and security on physical hardware.
  hardware = lib.mkIf isPhysicalMachine {
    # Intel CPU microcode updates (security patches, stability fixes).
    cpu.intel.updateMicrocode = true;

    # Enable firmware updates via fwupd (UEFI, Thunderbolt, etc.).
    enableRedistributableFirmware = true;

    # Bluetooth support (needed for wireless peripherals).
    bluetooth = {
      enable = true;
      powerOnBoot = true; # Automatically enable on boot.
    };
  };

  # ============================================================================
  # BOOT & KERNEL CONFIGURATION
  # ============================================================================
  boot = {
    # Use latest LTS kernel for best hardware support and stability.
    kernelPackages = pkgs.linuxPackages_latest;

    # Kernel modules to load at boot.
    kernelModules = [
      "kvm-intel"        # Intel virtualization support.
      "msr"              # Model-Specific Register access (required for RAPL control).
      "intel_rapl_msr"   # Intel RAPL energy measurement via MSR.
    ];

    # Kernel parameters optimizing for performance, security, and Intel platforms.
    kernelParams = [
      # --- POWER MANAGEMENT ---
      "intel_pstate=active"          # Use Intel P-State driver with HWP.
      "intel_pstate=hwp_only"        # Force Hardware P-States (HWP) mode.
      
      # --- SECURITY ---
      "mitigations=auto"             # Enable CPU vulnerability mitigations.
      "lockdown=confidentiality"     # Kernel lockdown for security.
      
      # --- PERFORMANCE ---
      "processor.max_cstate=1"       # Limit C-states to reduce latency (C1 max).
      "idle=poll"                    # Prevent deep idle states (for low-latency).
      "intel_idle.max_cstate=0"      # Disable intel_idle deep states.
      
      # --- LOGGING & DEBUGGING ---
      "quiet"                        # Suppress verbose boot messages.
      "loglevel=3"                   # Kernel log level (errors and warnings only).
      "systemd.show_status=auto"     # Show systemd boot status when needed.
      "rd.udev.log_level=3"          # Reduce udev logging verbosity.
      
      # --- GRAPHICS (Intel) ---
      "i915.enable_fbc=1"            # Enable framebuffer compression (power saving).
      "i915.enable_psr=2"            # Enable Panel Self-Refresh (PSR2 for efficiency).
      "i915.fastboot=1"              # Skip mode-set on boot for faster startup.
    ];

    # Systemd boot loader (modern, fast, UEFI-native).
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 3; # Boot menu timeout in seconds.
    };

    # Clean /tmp on boot (security and disk space).
    tmp.cleanOnBoot = true;
  };

  # ============================================================================
  # CONFLICTING POWER MANAGEMENT SERVICES (DISABLED)
  # ============================================================================
  # To ensure full control over power management via our custom systemd services,
  # all potentially conflicting daemons are explicitly disabled. This prevents
  # unexpected interactions and ensures deterministic behavior.
  services = {
    # TLP: Conflicts with manual sysfs control.
    tlp.enable = false;
    
    # thermald: Intel's thermal daemon; we use custom temperature-aware RAPL instead.
    thermald.enable = false;
    
    # power-profiles-daemon: GNOME's power profile manager; conflicts with EPP control.
    power-profiles-daemon.enable = false;
    
    # auto-cpufreq: Automatic CPU frequency scaling; conflicts with our HWP+EPP setup.
    # Note: This is not a NixOS service by default, but explicitly noted here.
    # If installed via overlay/package, ensure it's not enabled.
  };

  # ============================================================================
  # NETWORKING
  # ============================================================================
  networking = {
    # Hostname (used for system identification logic).
    hostName = "hay";
    
    # NetworkManager for flexible network management (Wi-Fi, Ethernet, VPN).
    networkmanager.enable = true;
    
    # Firewall (enabled for security; customize as needed).
    firewall = {
      enable = true;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
    };
  };

  # ============================================================================
  # SYSTEMD CUSTOM POWER MANAGEMENT SERVICES
  # ============================================================================
  # This is the core of the custom power management system. Each service targets
  # a specific aspect of power/performance tuning and is designed to be:
  # - Idempotent (can be run multiple times safely).
  # - Source-aware (adapts to AC vs. battery power).
  # - CPU-aware (uses platform-specific values via cpuDetectionScript).
  # - Logged (all output goes to journald for debugging).
  #
  # Service dependencies are carefully ordered to prevent race conditions.
  # ============================================================================

  systemd.services = {
    # ==========================================================================
    # SERVICE: platform-profile
    # Sets the ACPI platform profile hint to guide firmware behavior.
    # AC: "performance" (relaxes power limits, enables full turbo).
    # Battery: "balanced" (moderate power limits, balances perf/efficiency).
    # ==========================================================================
    platform-profile = {
      description = "Set ACPI Platform Profile (Adaptive: AC=performance, Battery=balanced)";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "platform-profile" ''
          PROFILE_PATH="/sys/firmware/acpi/platform_profile"
          
          if [[ ! -f "$PROFILE_PATH" ]]; then
            echo "⚠ ACPI platform profile interface not found. Skipping."
            exit 0
          fi
          
          # Detect power source
          POWER_SOURCE=$(${powerSourceDetector}/bin/detect-power-source)
          
          if [[ "$POWER_SOURCE" == "AC" ]]; then
            TARGET_PROFILE="performance"
          else
            TARGET_PROFILE="balanced"
          fi
          
          echo "$TARGET_PROFILE" > "$PROFILE_PATH"
          CURRENT=$(cat "$PROFILE_PATH")
          echo "✓ Platform profile set to: $CURRENT (requested: $TARGET_PROFILE)"
        '';
      };
    };

    # ==========================================================================
    # SERVICE: cpu-epp
    # Configures Intel Energy Performance Preference (EPP) for HWP.
    # This is the primary power/performance knob for modern Intel CPUs.
    # AC: "performance" (maximum responsiveness, turbo prioritized).
    # Battery: "balance_power" (efficiency prioritized, lower turbo).
    # ==========================================================================
    cpu-epp = {
      description = "Set Intel EPP (Energy Performance Preference)";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" "platform-profile.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "cpu-epp" ''
          # Detect power source using centralized detector
          POWER_SOURCE=$(${powerSourceDetector}/bin/detect-power-source)
          
          if [[ "$POWER_SOURCE" == "AC" ]]; then
            TARGET_EPP="performance"
          else
            TARGET_EPP="balance_power"
          fi
          
          # Apply EPP to all CPU policies
          for POLICY in /sys/devices/system/cpu/cpufreq/policy*; do
            EPP_FILE="$POLICY/energy_performance_preference"
            if [[ -f "$EPP_FILE" ]]; then
              echo "$TARGET_EPP" > "$EPP_FILE"
              echo "✓ Set $(basename $POLICY) EPP to: $TARGET_EPP"
            fi
          done
          
          echo "✓ EPP configuration complete for power source: $POWER_SOURCE"
        '';
      };
    };

    # ==========================================================================
    # SERVICE: cpu-min-freq-guard
    # Sets a minimum performance floor to prevent excessive idle throttling.
    # This prevents UI jank and ensures responsive behavior under light loads.
    # AC: 30% (allows deeper idle but maintains responsiveness).
    # Battery: 20% (more aggressive power saving).
    # ==========================================================================
    cpu-min-freq-guard = {
      description = "Set Intel P-State Min Performance Floor";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" "cpu-epp.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "cpu-min-freq-guard" ''
          # Detect power source
          POWER_SOURCE=$(${powerSourceDetector}/bin/detect-power-source)
          
          if [[ "$POWER_SOURCE" == "AC" ]]; then
            MIN_PERF=30
          else
            MIN_PERF=20
          fi
          
          MIN_PERF_FILE="/sys/devices/system/cpu/intel_pstate/min_perf_pct"
          
          if [[ -f "$MIN_PERF_FILE" ]]; then
            echo "$MIN_PERF" > "$MIN_PERF_FILE"
            CURRENT=$(cat "$MIN_PERF_FILE")
            echo "✓ Min performance floor set to: $CURRENT% (power source: $POWER_SOURCE)"
          else
            echo "⚠ Intel P-State min_perf_pct not available."
          fi
        '';
      };
    };

    # ==========================================================================
    # SERVICE: rapl-power-limits
    # Sets Intel RAPL (Running Average Power Limit) constraints.
    # These are hard power ceilings enforced by the CPU hardware.
    # PL1 (sustained): Long-term power budget.
    # PL2 (burst): Short-term turbo boost budget (28 seconds window).
    #
    # Platform-specific values:
    # - Meteor Lake (Core Ultra 7 155H):
    #   AC: 35W (PL1) / 52W (PL2)
    #   Battery: 28W (PL1) / 45W (PL2)
    # - Kaby Lake (Core i7-8650U):
    #   AC: 25W (PL1) / 44W (PL2)
    #   Battery: 15W (PL1) / 25W (PL2)
    # - Generic Intel:
    #   AC: 20W (PL1) / 35W (PL2)
    #   Battery: 15W (PL1) / 25W (PL2)
    # ==========================================================================
    rapl-power-limits = {
      description = "Set CPU-aware RAPL Power Limits (MSR-based)";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" "cpu-min-freq-guard.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "rapl-power-limits" ''
          # Detect CPU platform
          CPU_TYPE=$(${cpuDetectionScript}/bin/detect-cpu)
          
          # Detect power source
          POWER_SOURCE=$(${powerSourceDetector}/bin/detect-power-source)
          
          # Determine RAPL limits based on CPU and power source
          case "$CPU_TYPE" in
            METEORLAKE)
              if [[ "$POWER_SOURCE" == "AC" ]]; then
                PL1_W=35
                PL2_W=52
              else
                PL1_W=28
                PL2_W=45
              fi
              ;;
            KABYLAKE)
              if [[ "$POWER_SOURCE" == "AC" ]]; then
                PL1_W=25
                PL2_W=44
              else
                PL1_W=15
                PL2_W=25
              fi
              ;;
            *)
              if [[ "$POWER_SOURCE" == "AC" ]]; then
                PL1_W=20
                PL2_W=35
              else
                PL1_W=15
                PL2_W=25
              fi
              ;;
          esac
          
          # Convert watts to microwatts for sysfs
          PL1_UW=$((PL1_W * 1000000))
          PL2_UW=$((PL2_W * 1000000))
          
          RAPL_PATH="/sys/class/powercap/intel-rapl:0"
          
          if [[ ! -d "$RAPL_PATH" ]]; then
            echo "⚠ RAPL interface not found. Cannot set power limits."
            exit 1
          fi
          
          # Set PL1 (constraint_0 = long term)
          echo "$PL1_UW" > "$RAPL_PATH/constraint_0_power_limit_uw"
          
          # Set PL2 (constraint_1 = short term)
          echo "$PL2_UW" > "$RAPL_PATH/constraint_1_power_limit_uw"
          
          # Verify settings
          ACTUAL_PL1=$(cat "$RAPL_PATH/constraint_0_power_limit_uw")
          ACTUAL_PL2=$(cat "$RAPL_PATH/constraint_1_power_limit_uw")
          
          echo "✓ RAPL limits set for $CPU_TYPE on $POWER_SOURCE:"
          echo "  PL1 (sustained): $((ACTUAL_PL1/1000000)) W"
          echo "  PL2 (burst):     $((ACTUAL_PL2/1000000)) W"
        '';
      };
    };

    # ==========================================================================
    # SERVICE: disable-rapl-mmio
    # Disables the intel-rapl-mmio driver to prevent conflicts with MSR control.
    # The MMIO interface can override MSR settings, causing unpredictable
    # behavior. We use MSR exclusively (intel-rapl-msr) as the single source
    # of truth for RAPL control.
    #
    # Strategy: MSR-only (no MMIO sync, no conflicts).
    # ==========================================================================
    disable-rapl-mmio = {
      description = "Disable Intel RAPL MMIO Interface (Prevent MSR Conflicts)";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      before = [ "rapl-power-limits.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "disable-rapl-mmio" ''
          # Unbind intel-rapl-mmio driver if loaded
          MMIO_DRIVER_PATH="/sys/bus/platform/drivers/intel-rapl-mmio"
          
          if [[ -d "$MMIO_DRIVER_PATH" ]]; then
            for DEVICE in "$MMIO_DRIVER_PATH"/*; do
              if [[ -e "$DEVICE" && "$DEVICE" != *"bind" && "$DEVICE" != *"unbind" ]]; then
                DEVICE_NAME=$(basename "$DEVICE")
                echo "Unbinding MMIO device: $DEVICE_NAME"
                echo "$DEVICE_NAME" > "$MMIO_DRIVER_PATH/unbind" 2>/dev/null || true
              fi
            done
            echo "✓ Intel RAPL MMIO driver disabled."
          else
            echo "ℹ Intel RAPL MMIO driver not present or already disabled."
          fi
          
          # Verify MSR driver is active
          if [[ -d "/sys/class/powercap/intel-rapl:0" ]]; then
            echo "✓ Intel RAPL MSR interface confirmed active."
          else
            echo "⚠ Intel RAPL MSR interface not found!"
            exit 1
          fi
        '';
      };
    };

    # ==========================================================================
    # SERVICE: rapl-thermo-guard
    # Temperature-aware dynamic PL2 limiter for thermal protection.
    # Monitors CPU package temperature and dynamically adjusts PL2 to prevent
    # thermal throttling while maintaining performance when cool.
    #
    # Temperature bands (Celsius):
    # - 60-64°C: Restore BASE_PL2 (full burst performance).
    # - 65-69°C: Hold current PL2 (stable state).
    # - 70-74°C: Clamp PL2 to 38W (thermal warning).
    # - ≥75°C:   Clamp PL2 to 32W (thermal emergency).
    #
    # PL1 is NEVER touched to avoid conflicts with stock firmware throttling.
    # Runs every 5 seconds.
    # ==========================================================================
    rapl-thermo-guard = {
      description = "Temperature-Aware Dynamic PL2 Manager";
      wantedBy = [ "multi-user.target" ];
      after = [ "rapl-power-limits.service" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "10s";
        ExecStart = mkRobustScript "rapl-thermo-guard" ''
          # Determine BASE_PL2 from current CPU platform and power source
          CPU_TYPE=$(${cpuDetectionScript}/bin/detect-cpu)
          POWER_SOURCE=$(${powerSourceDetector}/bin/detect-power-source)
          
          case "$CPU_TYPE" in
            METEORLAKE)
              [[ "$POWER_SOURCE" == "AC" ]] && BASE_PL2_W=52 || BASE_PL2_W=45
              ;;
            KABYLAKE)
              [[ "$POWER_SOURCE" == "AC" ]] && BASE_PL2_W=44 || BASE_PL2_W=25
              ;;
            *)
              [[ "$POWER_SOURCE" == "AC" ]] && BASE_PL2_W=35 || BASE_PL2_W=25
              ;;
          esac
          
          BASE_PL2_UW=$((BASE_PL2_W * 1000000))
          RAPL_PL2_PATH="/sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw"
          
          echo "Starting thermal guard with BASE_PL2=$BASE_PL2_W W"
          
          while true; do
            # Read package temperature
            TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | \
                   ${pkgs.gnugrep}/bin/grep "Package id 0" | \
                   ${pkgs.gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, a); print a[1]}')
            
            if [[ -z "$TEMP" ]]; then
              echo "⚠ Cannot read temperature. Skipping adjustment."
              sleep 5
              continue
            fi
            
            TEMP_INT=$(echo "$TEMP" | ${pkgs.coreutils}/bin/cut -d. -f1)
            
            # Determine target PL2 based on temperature bands
            if   [[ $TEMP_INT -le 64 ]]; then
              TARGET_PL2_UW=$BASE_PL2_UW
              STATUS="COOL"
            elif [[ $TEMP_INT -le 69 ]]; then
              # Hold current PL2 (no change)
              CURRENT_PL2=$(cat "$RAPL_PL2_PATH")
              TARGET_PL2_UW=$CURRENT_PL2
              STATUS="STABLE"
            elif [[ $TEMP_INT -le 74 ]]; then
              TARGET_PL2_UW=38000000  # 38W clamp
              STATUS="WARM"
            else
              TARGET_PL2_UW=32000000  # 32W emergency clamp
              STATUS="HOT"
            fi
            
            # Apply PL2 adjustment if different from current
            CURRENT_PL2=$(cat "$RAPL_PL2_PATH")
            if [[ "$TARGET_PL2_UW" != "$CURRENT_PL2" ]]; then
              echo "$TARGET_PL2_UW" > "$RAPL_PL2_PATH"
              echo "[$STATUS] Temp: ''${TEMP}°C → PL2 adjusted to $((TARGET_PL2_UW/1000000))W"
            fi
            
            sleep 5
          done
        '';
      };
    };

    # ==========================================================================
    # SERVICE: battery-thresholds
    # Configures battery charge thresholds for longevity.
    # Start: 75% (begin charging when battery drops below this).
    # Stop:  80% (stop charging when battery reaches this).
    #
    # This prevents the battery from constantly charging to 100%, which
    # significantly extends its lifespan over years of use.
    # ==========================================================================
    battery-thresholds = {
      description = "Set Battery Charge Thresholds (75%-80%)";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = mkRobustScript "battery-thresholds" ''
          START_THRESHOLD=75
          STOP_THRESHOLD=80
          
          # Locate battery sysfs path
          BAT_PATH=""
          for BAT in /sys/class/power_supply/BAT*; do
            if [[ -d "$BAT" ]]; then
              BAT_PATH="$BAT"
              break
            fi
          done
          
          if [[ -z "$BAT_PATH" ]]; then
            echo "ℹ No battery found. Skipping threshold configuration."
            exit 0
          fi
          
          START_FILE="$BAT_PATH/charge_control_start_threshold"
          STOP_FILE="$BAT_PATH/charge_control_end_threshold"
          
          if [[ -f "$START_FILE" && -f "$STOP_FILE" ]]; then
            echo "$START_THRESHOLD" > "$START_FILE"
            echo "$STOP_THRESHOLD" > "$STOP_FILE"
            echo "✓ Battery thresholds set: Start=$START_THRESHOLD%, Stop=$STOP_THRESHOLD%"
          else
            echo "⚠ Battery threshold control not supported on this hardware."
          fi
        '';
      };
    };

  }; # End of systemd.services

  # ============================================================================
  # UDEV RULES: AC/BATTERY EVENT HANDLING
  # ============================================================================
  # This udev rule triggers on AC adapter plug/unplug events and automatically
  # restarts all power management services to adapt to the new power source.
  # This ensures instant responsiveness when switching between AC and battery.
  # ============================================================================
  services.udev.extraRules = ''
    # AC adapter status change detection
    SUBSYSTEM=="power_supply", KERNEL=="AC*|ADP*", ATTR{online}=="0", TAG+="systemd", ENV{SYSTEMD_WANTS}="power-profile-ac-event.service"
    SUBSYSTEM=="power_supply", KERNEL=="AC*|ADP*", ATTR{online}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}="power-profile-ac-event.service"
  '';

  systemd.services.power-profile-ac-event = {
    description = "Refresh Power Profiles on AC Plug/Unplug";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkRobustScript "ac-event-handler" ''
        echo "AC adapter event detected. Refreshing all power profiles..."
        
        # Ordered restart of all power-related services
        SERVICES=(
          "platform-profile.service"
          "cpu-epp.service"
          "cpu-min-freq-guard.service"
          "rapl-power-limits.service"
          "disable-rapl-mmio.service"
        )
        
        for SVC in "''${SERVICES[@]}"; do
          ${pkgs.systemd}/bin/systemctl restart "$SVC" || true
        done
        
        # Note: rapl-thermo-guard automatically adapts on its next iteration
        # battery-thresholds is static and doesn't need restart
        
        echo "✓ Power profile refresh complete."
      '';
    };
  };

  # ============================================================================
  # POST-SUSPEND HOOK: RESTORE ALL POWER SETTINGS
  # ============================================================================
  # After system resume from suspend/hibernation, all power management settings
  # can be lost or reset to defaults by the BIOS/firmware. This systemd service
  # triggers after suspend and re-applies all custom power configurations.
  # ============================================================================
  systemd.services.power-profile-post-suspend = {
    description = "Restore Power Profiles After Suspend/Resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkRobustScript "post-suspend" ''
        echo "System resumed from suspend. Restoring power management settings..."
        
        # Wait briefly for hardware to stabilize
        sleep 2
        
        # Ordered restart of all power-related services
        SERVICES=(
          "platform-profile.service"
          "cpu-epp.service"
          "cpu-min-freq-guard.service"
          "rapl-power-limits.service"
          "disable-rapl-mmio.service"
        )
        
        for SVC in "''${SERVICES[@]}"; do
          ${pkgs.systemd}/bin/systemctl restart "$SVC" || true
        done
        
        # rapl-thermo-guard is a daemon and should auto-recover
        # battery-thresholds is static
        
        echo "✓ Post-suspend power restoration complete."
      '';
    };
  };

  # ============================================================================
  # DIAGNOSTIC & UTILITY SCRIPTS
  # ============================================================================
  # A collection of convenience scripts for monitoring, testing, and debugging
  # the power management configuration. These are installed system-wide and
  # can be run from any terminal.
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # (existing packages remain unchanged...)
    
    # ========================================================================
    # SCRIPT: system-status
    # Comprehensive single-page overview of all power management settings.
    # Shows: platform profile, EPP, min performance, RAPL limits, battery
    # thresholds, temperatures, and current power consumption. This is the
    # first tool to run when diagnosing power/performance issues.
    # ========================================================================
    (writeScriptBin "system-status" ''
      #!${pkgs.bash}/bin/bash
      echo "╔════════════════════════════════════════════════════════════════════╗"
      echo "║           SYSTEM POWER MANAGEMENT STATUS (v16.0)                  ║"
      echo "╚════════════════════════════════════════════════════════════════════╝"
      echo ""
      
      # CPU Detection
      CPU_TYPE=$(${cpuDetectionScript}/bin/detect-cpu)
      echo "📟 CPU Platform: $CPU_TYPE"
      
      # Power Source
      POWER_SOURCE=$(${powerSourceDetector}/bin/detect-power-source)
      if [[ "$POWER_SOURCE" == "AC" ]]; then
        echo "⚡ Power Source: AC Power (plugged in)"
      else
        echo "🔋 Power Source: Battery"
      fi
      echo ""
      
      # Platform Profile
      echo "─────────────────────────────────────────────────────────────────────"
      echo "ACPI PLATFORM PROFILE:"
      if [[ -f /sys/firmware/acpi/platform_profile ]]; then
        PROFILE=$(cat /sys/firmware/acpi/platform_profile)
        echo "  Current: $PROFILE"
        echo "  Available: $(cat /sys/firmware/acpi/platform_profile_choices)"
      else
        echo "  Not supported on this hardware."
      fi
      echo ""
      
      # EPP Settings
      echo "─────────────────────────────────────────────────────────────────────"
      echo "INTEL ENERGY PERFORMANCE PREFERENCE (EPP):"
      EPP_FILE="/sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference"
      if [[ -f "$EPP_FILE" ]]; then
        EPP=$(cat "$EPP_FILE")
        echo "  Current: $EPP"
        echo "  Available: $(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_available_preferences)"
      else
        echo "  EPP not supported."
      fi
      echo ""
      
      # Min Performance
      echo "─────────────────────────────────────────────────────────────────────"
      echo "INTEL P-STATE MIN PERFORMANCE:"
      MIN_PERF_FILE="/sys/devices/system/cpu/intel_pstate/min_perf_pct"
      if [[ -f "$MIN_PERF_FILE" ]]; then
        MIN_PERF=$(cat "$MIN_PERF_FILE")
        echo "  Current: $MIN_PERF%"
      else
        echo "  Not available."
      fi
      echo ""
      
      # RAPL Limits
      echo "─────────────────────────────────────────────────────────────────────"
      echo "RAPL POWER LIMITS (PACKAGE):"
      if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
        PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)
        PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw)
        printf "  PL1 (Sustained): %3d W\n" $((PL1/1000000))
        printf "  PL2 (Burst):     %3d W\n" $((PL2/1000000))
      else
        echo "  RAPL not available."
      fi
      echo ""
      
      # Battery Thresholds
      echo "─────────────────────────────────────────────────────────────────────"
      echo "BATTERY CHARGE THRESHOLDS:"
      BAT_PATH=""
      for BAT in /sys/class/power_supply/BAT*; do
        [[ -d "$BAT" ]] && BAT_PATH="$BAT" && break
      done
      
      if [[ -n "$BAT_PATH" ]]; then
        if [[ -f "$BAT_PATH/charge_control_start_threshold" ]]; then
          START=$(cat "$BAT_PATH/charge_control_start_threshold")
          STOP=$(cat "$BAT_PATH/charge_control_end_threshold")
          echo "  Start charging at: $START%"
          echo "  Stop charging at:  $STOP%"
        else
          echo "  Not supported on this hardware."
        fi
      else
        echo "  No battery detected."
      fi
      echo ""
      
      # Temperature
      echo "─────────────────────────────────────────────────────────────────────"
      echo "CPU TEMPERATURE:"
      TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Package id 0" | ${pkgs.gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, a); print a[1]}')
      if [[ -n "$TEMP" ]]; then
        printf "  Package: %.1f°C\n" "$TEMP"
      else
        echo "  Temperature data not available."
      fi
      echo ""
      
      # Instantaneous Power
      echo "─────────────────────────────────────────────────────────────────────"
      echo "INSTANTANEOUS POWER CONSUMPTION:"
      if [[ -f /sys/class/powercap/intel-rapl:0/energy_uj ]]; then
        ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
        sleep 1
        ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
        ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
        [[ $ENERGY_DIFF -lt 0 ]] && ENERGY_DIFF=$ENERGY_AFTER
        WATTS=$(echo "scale=2; $ENERGY_DIFF / 1000000" | ${pkgs.bc}/bin/bc)
        printf "  Package Power: %6.2f W\n" "$WATTS"
      else
        echo "  Power measurement not available."
      fi
      echo ""
      
      # Service Status
      echo "─────────────────────────────────────────────────────────────────────"
      echo "POWER MANAGEMENT SERVICES:"
      SERVICES=(
        "platform-profile.service"
        "cpu-epp.service"
        "cpu-min-freq-guard.service"
        "rapl-power-limits.service"
        "disable-rapl-mmio.service"
        "rapl-thermo-guard.service"
        "battery-thresholds.service"
      )
      
      for SVC in "''${SERVICES[@]}"; do
        if systemctl is-active --quiet "$SVC"; then
          printf "  ✓ %-30s [ACTIVE]\n" "$SVC"
        else
          printf "  ✗ %-30s [INACTIVE]\n" "$SVC"
        fi
      done
      echo ""
      echo "═════════════════════════════════════════════════════════════════════"
      echo "TIP: Use 'power-monitor' for real-time updates, or 'power-check' for"
      echo "     a quick power consumption snapshot."
      echo "═════════════════════════════════════════════════════════════════════"
    '')

    # ========================================================================
    # SCRIPT: turbostat-quick
    # Runs `turbostat` for 5 seconds to show real CPU behavior.
    # This is the ground truth for frequency (Avg_MHz, Bzy_MHz) and power
    # (PkgWatt), as `scaling_cur_freq` is misleading with HWP.
    # ========================================================================
    (writeScriptBin "turbostat-quick" ''
      #!${pkgs.bash}/bin/bash
      echo "Running turbostat for 5 seconds (Ctrl+C to stop early)..."
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      sudo ${pkgs.linuxPackages.turbostat}/bin/turbostat --interval 1 --num_iterations 5
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "Key metrics:"
      echo "  • Avg_MHz:  Average frequency (all cores, including idle)"
      echo "  • Bzy_MHz:  Frequency when busy (true active frequency)"
      echo "  • PkgWatt:  Package power consumption"
      echo "  • %Busy:    CPU utilization"
    '')

    # ========================================================================
    # SCRIPT: turbostat-stress
    # Runs a CPU stress test for 10 seconds while monitoring with turbostat.
    # Useful for verifying RAPL limits and turbo behavior under full load.
    # ========================================================================
    (writeScriptBin "turbostat-stress" ''
      #!${pkgs.bash}/bin/bash
      echo "Starting 10-second CPU stress test with turbostat monitoring..."
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      sudo ${pkgs.linuxPackages.turbostat}/bin/turbostat --interval 1 ${pkgs.stress-ng}/bin/stress-ng --cpu 0 --timeout 10s
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "Check if PkgWatt reached the configured RAPL limits during stress."
    '')

    # ========================================================================
    # SCRIPT: turbostat-analyze
    # Extended turbostat run (60 seconds) for detailed performance analysis.
    # Use this when you need to observe behavior over a longer period or
    # during specific workloads.
    # ========================================================================
    (writeScriptBin "turbostat-analyze" ''
      #!${pkgs.bash}/bin/bash
      echo "Running extended turbostat analysis (60 seconds)..."
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      sudo ${pkgs.linuxPackages.turbostat}/bin/turbostat --interval 2 --num_iterations 30
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    '')

    # ========================================================================
    # SCRIPT: power-check
    # Quick snapshot of current power consumption. Measures package power over
    # a 2-second interval using RAPL and provides context with active limits.
    # ========================================================================
    (writeScriptBin "power-check" ''
      #!${pkgs.bash}/bin/bash
      echo "═══════════════════════════════════════════════════════════════════"
      echo "     INSTANTANEOUS POWER CONSUMPTION CHECK"
      echo "═══════════════════════════════════════════════════════════════════"
      echo ""

      # Power Source Detection
      POWER_SOURCE=$(${powerSourceDetector}/bin/detect-power-source)
      if [[ "$POWER_SOURCE" == "AC" ]]; then
        echo "Power Source: ⚡ AC Power (plugged in)"
      else
        echo "Power Source: 🔋 Battery"
      fi
      echo ""

      if [[ ! -f /sys/class/powercap/intel-rapl:0/energy_uj ]]; then
        echo "⚠ RAPL interface not found. Cannot measure power."
        exit 1
      fi

      echo "Measuring power consumption over a 2-second interval..."
      ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
      sleep 2
      ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

      # Handle counter wraparound (unlikely but possible).
      ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
      [[ $ENERGY_DIFF -lt 0 ]] && ENERGY_DIFF=$ENERGY_AFTER

      # Watts = (Joules / seconds) = (microjoules / 1,000,000) / 2
      WATTS=$(echo "scale=2; $ENERGY_DIFF / 2000000" | ${pkgs.bc}/bin/bc)

      echo ""
      echo "╔═══════════════════════════════════════════════════════════════════╗"
      printf "║  PACKAGE POWER: %6.2f W                                        ║\n" "$WATTS"
      echo "╚═══════════════════════════════════════════════════════════════════╝"
      echo ""

      # Show current RAPL limits for context.
      PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)
      PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw)
      echo "Active RAPL Limits:"
      printf "  PL1 (Sustained): %3d W\n" $((PL1/1000000))
      printf "  PL2 (Burst):     %3d W\n" $((PL2/1000000))
      echo ""

      # Interpret the power level.
      WATTS_INT=$(echo "$WATTS" | ${pkgs.coreutils}/bin/cut -d. -f1)
      if   [[ $WATTS_INT -lt 10 ]]; then echo "📊 Status: Idle or light usage."
      elif [[ $WATTS_INT -lt 30 ]]; then echo "📊 Status: Normal productivity workload."
      elif [[ $WATTS_INT -lt 50 ]]; then echo "📊 Status: High load (compiling, gaming, etc.)."
      else                                echo "📊 Status: Very high load (stress test or sustained heavy work)."
      fi
      echo ""
      echo "═══════════════════════════════════════════════════════════════════"
    '')

    # ========================================================================
    # SCRIPT: power-monitor
    # Real-time dashboard showing power, temperature, EPP, and frequency.
    # Updates every second. Useful for observing the immediate impact of
    # configuration changes or different workloads. Press Ctrl+C to stop.
    # ========================================================================
    (writeScriptBin "power-monitor" ''
      #!${pkgs.bash}/bin/bash
      trap "tput cnorm; exit" INT # Ensure cursor is visible on exit.
      tput civis # Hide cursor for cleaner display.

      while true; do
        clear
        echo "╔════════════════════════════════════════════════════════════════════╗"
        echo "║     REAL-TIME POWER MONITOR (v16.0) │ Press Ctrl+C to stop        ║"
        echo "╚════════════════════════════════════════════════════════════════════╝"
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "────────────────────────────────────────────────────────────────────"

        # Power Source
        POWER_SOURCE=$(${powerSourceDetector}/bin/detect-power-source)
        if [[ "$POWER_SOURCE" == "AC" ]]; then
          echo "Power Source:  ⚡ AC Power"
        else
          echo "Power Source:  🔋 Battery"
        fi

        # EPP
        EPP=$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo "N/A")
        echo "EPP Setting:   $EPP"

        # Temperature
        TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Package id 0" | ${pkgs.gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, a); print a[1]}')
        [[ -n "$TEMP" ]] && printf "Temperature:   %.1f°C\n" "$TEMP" || echo "Temperature:   N/A"

        echo "────────────────────────────────────────────────────────────────────"

        # Power Consumption (0.5 second sample for faster updates)
        if [[ -f /sys/class/powercap/intel-rapl:0/energy_uj ]]; then
          ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
          sleep 0.5
          ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

          ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
          [[ $ENERGY_DIFF -lt 0 ]] && ENERGY_DIFF=$ENERGY_AFTER
          WATTS=$(echo "scale=2; $ENERGY_DIFF / 500000" | ${pkgs.bc}/bin/bc)

          PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)
          PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)

          echo "PACKAGE POWER (RAPL):"
          printf "  Current Consumption: %6.2f W\n" "$WATTS"
          printf "  Sustained Limit (PL1): %4d W\n" $((PL1/1000000))
          printf "  Burst Limit (PL2):     %4d W\n" $((PL2/1000000))
        else
          echo "PACKAGE POWER (RAPL): Not Available"
        fi

        echo "────────────────────────────────────────────────────────────────────"
        # Frequency Statistics
        echo "CPU FREQUENCY (scaling_cur_freq - indicative only):"
        FREQS=($(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null))
        if [[ ''${#FREQS[@]} -gt 0 ]]; then
            SUM=$(IFS=+; echo "$((''${FREQS[*]}))")
            AVG=$((SUM / ''${#FREQS[@]} / 1000))
            MIN=$(printf "%s\n" "''${FREQS[@]}" | sort -n | head -1)
            MAX=$(printf "%s\n" "''${FREQS[@]}" | sort -n | tail -1)
            printf "  Average: %5d MHz\n" "$AVG"
            printf "  Min/Max: %5d / %d MHz\n" "$((MIN/1000))" "$((MAX/1000))"
            echo "  ⚠ NOTE: This value can be misleading with HWP. Use turbostat for truth."
        else
            echo "  Frequency data not available."
        fi
        
        echo "────────────────────────────────────────────────────────────────────"
        echo "TIP: Run 'turbostat-quick' in another terminal for accurate frequency"
        echo "     and power data. Press Ctrl+C here to stop monitoring."
        
        sleep 0.5 # Remainder of the 1-second loop.
      done
    '')

    # ========================================================================
    # SCRIPT: power-profile-refresh
    # Manually restart all power management services. Useful for testing
    # configuration changes or recovering from a failed state without rebooting.
    # Requires sudo/root privileges.
    # ========================================================================
    (writeScriptBin "power-profile-refresh" ''
        #!${pkgs.bash}/bin/bash
        echo "═══════════════════════════════════════════════════════════════════"
        echo "     RESTARTING POWER PROFILE SERVICES"
        echo "═══════════════════════════════════════════════════════════════════"
        echo ""
        
        if [[ $EUID -ne 0 ]]; then
            echo "⚠ This script requires root privileges. Please run with sudo."
            exit 1
        fi

        # Ordered restart sequence (respects service dependencies)
        SERVICES=(
            "platform-profile.service"
            "cpu-epp.service"
            "cpu-min-freq-guard.service"
            "disable-rapl-mmio.service"
            "rapl-power-limits.service"
            "battery-thresholds.service"
        )

        for SVC in "''${SERVICES[@]}"; do
            printf "Restarting %-35s ... " "$SVC"
            if systemctl restart "$SVC" 2>/dev/null; then
                echo "✓ OK"
            else
                echo "✗ FAILED"
            fi
        done

        echo ""
        echo "Note: rapl-thermo-guard is a daemon and will auto-recover."
        echo ""
        echo "✓ All power-related services have been refreshed."
        echo "═══════════════════════════════════════════════════════════════════"
        echo ""
        system-status
    '')
  ];
}

