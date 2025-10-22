# modules/core/system/default.nix
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
# Modern Intel platforms (esp. Meteor Lake) already optimize P-states and boosting
# in hardware (HWP). Instead of fighting the firmware, this module applies a few
# well-chosen, high-leverage controls and leaves the rest to silicon:
#
# - ACPI Platform Profile: High-level hint to relax conservative firmware limits.
# - EPP/EPB: Clear intent signals to HWP (performance vs. efficiency).
# - RAPL (PL1/PL2): Hard ceilings for the thermal/power envelope.
# - Min Performance Floor: Prevents UI jank by avoiding over-deep idle.
#
# KEY FEATURES IN THIS VERSION:
# -----------------------------
# ✅ ACPI Platform Profile → "performance" (reduces premature firmware throttling).
# ✅ Intel HWP active + EPP auto: AC="performance", Battery="balance_power".
# ✅ EPB tuned: AC=0 (max perf), Battery=6 (balanced) for better turbo behavior.
# ✅ Min performance guard (intel_pstate/min_perf_pct): AC=30%, Battery=20%.
# ✅ CPU-aware, source-aware RAPL:
#      • Meteor Lake (this machine) → AC: 35W/52W, Battery: 28W/45W.
# ✅ Temperature-aware PL2 (rapl-thermo-guard):
#      • ≤65 °C → restore BASE_PL2 (52W); 66–69 °C → hold; 70–74 °C → clamp 38W; ≥75 °C → clamp 32W.
#      • Never touches PL1; avoids oscillation vs. stock firmware throttling.
# ✅ MSR/MMIO parity & enforcement:
#      • Disable intel-rapl-mmio on udev add/change to prevent conflicts.
#      • Mirror/timer/keeper services keep MMIO synced to MSR limits.
# ✅ Instant AC plug/unplug handling via udev (restart all relevant services).
# ✅ Post-suspend hook re-applies all power settings after resume.
# ✅ Battery longevity: charge thresholds 75% (start) / 80% (stop).
# ✅ Tooling: system-status, turbostat-quick/stress/analyze, power-check, power-monitor,
#    power-profile-refresh for fast diagnostics.
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
  # POWER SOURCE DETECTION (AC/Battery) - Shell Snippet
  # ============================================================================
  # This inline shell code snippet provides a simple and portable way to detect
  # the current power source. It is designed to be embedded directly within
  # systemd `ExecStart` lines using shell substitution, like `$(${detectPowerSource})`.
  # It checks the standard sysfs paths and returns "1" for AC power or "0" for battery.
  detectPowerSource = ''
    ON_AC=0 # Default to battery power.
    # Iterate through possible sysfs paths for AC adapter status.
    for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
      # If the file exists and is readable, use its value and break the loop.
      [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
    done
    echo "''${ON_AC}"
  '';
  # ============================================================================
  # ROBUST SCRIPT GENERATOR
  # ============================================================================
  # This helper function creates robust, self-logging systemd service scripts.
  # It wraps the provided content in a Bash script that includes:
  # - Strict mode (`set -euo pipefail`) to exit immediately on errors.
  # - Automatic redirection of stdout (to journald with INFO priority) and
  #   stderr (to journald with ERR priority). This simplifies debugging with
  #   `journalctl -t power-mgmt-<name>`.
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
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };

  # Console configuration with a large, readable font for better visibility.
  console = {
    keyMap   = "trf";
    font     = "ter-v20b";
    packages = [ pkgs.terminus_font ];
  };

  # Set the NixOS state version to ensure compatibility with system updates.
  system.stateVersion = "25.11";
  # ============================================================================
  # BOOT & KERNEL CONFIGURATION
  # ============================================================================
  boot = {
    # Use the latest stable kernel for optimal hardware support, especially for
    # the new Meteor Lake platform and its integrated graphics.
    kernelPackages = pkgs.linuxPackages_latest;

    # Load essential kernel modules for thermal monitoring, graphics, and
    # platform-specific features on the ThinkPad.
    kernelModules = [
      "coretemp"      # Intel CPU core temperature monitoring.
      "i915"          # Driver for Intel integrated graphics.
    ] ++ lib.optionals isPhysicalMachine [
      "thinkpad_acpi" # Enables ThinkPad-specific ACPI features.
    ];

    # Enable experimental features in the thinkpad_acpi module, which is required
    # for advanced functionality like setting battery charge thresholds.
    extraModprobeConfig = lib.optionalString isPhysicalMachine ''
      options thinkpad_acpi experimental=1
    '';

    # Kernel boot parameters tuned for Intel graphics and modern power management.
    kernelParams = [
      # Enable GuC/HuC firmware for advanced graphics scheduling and power management.
      # Value 3 enables both GuC (scheduling) and HuC (media decoding).
      "i915.enable_guc=3"
      # Enable Frame Buffer Compression for reduced memory bandwidth and power savings.
      "i915.enable_fbc=1"
      # Set the default suspend mode to "s2idle" (modern standby) for faster
      # sleep and wake cycles, mimicking smartphone-like behavior.
      "mem_sleep_default=s2idle"
      # Enable Display C-states for GPU power management. Level 2 enables deeper
      # power saving states when the display is idle, reducing GPU power consumption.
      "i915.enable_dc=2"
      # Enable Panel Self Refresh (PSR) to allow the display panel to refresh itself
      # from its internal frame buffer without CPU/GPU intervention, saving power.
      "i915.enable_psr=1"
      # Enable fastboot to reuse BIOS/firmware-initialized display configuration,
      # reducing GPU initialization overhead during boot and resume.
      "i915.fastboot=1"
      # Limit Intel idle C-states to C7 maximum. This prevents entering very deep
      # sleep states (C8-C10) which can cause thermal spikes on exit. C7 provides
      # good power savings with more stable thermal behavior.
      "intel_idle.max_cstate=7"
    ];
   
    # Runtime kernel tuning via sysctl.
    kernel.sysctl = {
      "vm.swappiness"       = 60; # Default swappiness value, moderate swap usage.
      # Disable the NMI watchdog. This can save a small but consistent amount
      # of power (~1W) by preventing a periodic timer interrupt.
      "kernel.nmi_watchdog" = 0;
    };

    # Bootloader configuration (GRUB) with dual-boot support.
    loader = {
      grub = {
        enable = true;
        # Force the device path based on whether it's a VM or physical hardware.
        device = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");
        efiSupport = isPhysicalMachine;
        # Enable detection of other installed operating systems (e.g., Windows).
        useOSProber = true;
        # Keep the last 10 bootloader generations for easy rollbacks.
        configurationLimit = 10;
        # Set the framebuffer resolution to the native panel resolution.
        gfxmodeEfi  = "1920x1200"; # Native resolution for ThinkPad E14 Gen 6
        gfxmodeBios = if isVirtualMachine then "1920x1080" else "1920x1200";
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };
      # EFI configuration, only enabled on the physical machine.
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
    # Fine-tune the TrackPoint settings for optimal speed and sensitivity.
    trackpoint = lib.mkIf isPhysicalMachine {
      enable       = true;
      speed        = 200;
      sensitivity  = 200;
      # Enable middle-button scrolling with the TrackPoint.
      emulateWheel = true;
    };

    # Configure Intel graphics acceleration with full codec support.
    graphics = {
      enable      = true;
      enable32Bit = true; # Required for 32-bit applications and games (e.g., Steam).
      extraPackages = with pkgs; [
        intel-media-driver    # The modern VA-API driver for Broadwell+ and Meteor Lake.
        mesa                  # Core OpenGL support.
        vaapiVdpau            # VDPAU wrapper for VA-API.
        libvdpau-va-gl        # VDPAU backend using VA-API and OpenGL.
        intel-compute-runtime # OpenCL support for Intel GPUs.
      ];
      # Also provide the 32-bit version of the media driver.
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
      ];
    };

    # Ensure all necessary firmware and CPU microcode updates are available.
    enableRedistributableFirmware = true;
    enableAllFirmware             = true;
    cpu.intel.updateMicrocode     = true;

    # Enable Bluetooth support.
    bluetooth.enable = true;
  };

  # ============================================================================
  # DISABLE CONFLICTING POWER MANAGEMENT DAEMONS
  # ============================================================================
  # This configuration implements a custom, fine-grained power management
  # strategy. To prevent conflicts and ensure predictable behavior, standard
  # automated power management daemons are explicitly disabled. Our settings
  # directly manipulate sysfs and MSRs, and these daemons would interfere.
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;
  services.tlp.enable                   = false;
  services.thermald.enable              = false;
  services.thinkfan.enable              = false;

  # ============================================================================
  # PLATFORM PROFILE - PERFORMANCE
  # ============================================================================
  # This service sets the ACPI platform profile to "performance". This is the
  # first and highest-level control point, acting as a hint to the system
  # firmware (BIOS/EC) about the desired power/performance trade-off.
  #
  # Available Profiles:
  # - "performance": Prioritizes performance, relaxing firmware-level thermal
  #   and power constraints. This is our choice to prevent premature throttling.
  # - "balanced": The default, moderate setting.
  # - "low-power": Maximizes power savings at the cost of performance.
  #
  # Setting this to "performance" provides a less restrictive baseline for the
  # OS-level controls (EPP, RAPL) to operate within.
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
          echo "Attempting to set 'performance'..."
          echo "performance" > /sys/firmware/acpi/platform_profile 2>/dev/null
          NEW=$(cat /sys/firmware/acpi/platform_profile)
          if [[ "''${NEW}" == "performance" ]]; then
            echo "✓ Platform profile successfully set to: performance"
          else
            echo "⚠ Failed to set performance profile (current: ''${NEW})" >&2
          fi
        else
          echo "⚠ ACPI platform profile interface not found. Skipping."
        fi
      '';
    };
  };

  # ============================================================================
  # RAPL Energy Counter Permissions (for non-root power monitoring)
  # ============================================================================
  systemd.services.rapl-permissions = lib.mkIf isPhysicalMachine {
    description = "Set RAPL energy counter permissions for non-root users";
   wantedBy = [ "multi-user.target" ];
   after = [ "multi-user.target" ];
   serviceConfig = {
     Type = "oneshot";
     RemainAfterExit = true;
     ExecStart = pkgs.writeShellScript "rapl-permissions" ''
       # Make RAPL energy counters readable by all users
       for rapl in /sys/class/powercap/intel-rapl:*/energy_uj; do
         if [[ -f "$rapl" ]]; then
           chmod 644 "$rapl" || true
         fi
       done
       echo "RAPL energy counters made readable for non-root users"
     '';
   };
  };

  # ============================================================================
  # EPP (Energy Performance Preference)
  # ============================================================================
  # This service configures the Intel Energy Performance Preference (EPP), which
  # is a crucial hint to the Hardware P-States (HWP) governor. It tells the CPU
  # hardware how to balance performance and power saving for the current workload.
  #
  # EPP Values:
  # - "performance": Favors maximum frequency and responsiveness.
  # - "balance_performance": Leans towards performance but with some power awareness.
  # - "balance_power": Leans towards power savings with still-acceptable performance.
  # - "power": Maximizes power savings, allowing for lower performance.
  #
  # We dynamically switch the EPP value based on the power source, providing
  # instant adaptation. This service is restarted by a udev rule on AC state change.
  # - AC Power: "performance" for maximum desktop-class responsiveness.
  # - Battery:  "balance_power" for a good blend of performance and battery life.
  systemd.services.cpu-epp = lib.mkIf isPhysicalMachine {
    description = "Set Intel EPP (AC=performance, Battery=balance_power)";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "multi-user.target" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-epp" ''
        echo "=== EPP (Energy Performance Preference) Configuration ==="

        ON_AC=$(${detectPowerSource})
        if [[ "''${ON_AC}" = "1" ]]; then
          EPP="performance";
          SOURCE="AC"
        else
          EPP="balance_power";
          SOURCE="Battery"
        fi
        echo "Power source detected: ''${SOURCE}. Setting EPP to: ''${EPP}"

        SUCCESS=0
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
          if [[ -w "$pol/energy_performance_preference" ]]; then
            echo "''${EPP}" > "$pol/energy_performance_preference" 2>/dev/null && SUCCESS=1
          fi
        done
        if [[ "''${SUCCESS}" == "1" ]]; then
          echo "✓ EPP configured successfully."
        else
          echo "⚠ EPP interface not found or not writable." >&2
        fi

        # Enable HWP Dynamic Boost if available (a Meteor Lake feature). This allows
        # the CPU to be more opportunistic in its boosting behavior.
        if [[ -w /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost ]]; then
          echo 1 > /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost 2>/dev/null
          BOOST=$(cat /sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost)
          [[ "''${BOOST}" == "1" ]] && echo "✓ HWP Dynamic Boost enabled."
        fi
      '';
    };
  };

  # ============================================================================
  # EPB (Energy Performance Bias) Configuration
  # ============================================================================
  # This service sets the Intel Energy Performance Bias (EPB) register. EPB is
  # a lower-level hardware hint that works alongside EPP to influence the CPU's
  # internal power management decisions.
  #
  # EPB Scale (0-15):
  # - 0:  Maximum Performance. Instructs the hardware to ignore power-saving heuristics.
  # - 6:  Balanced (Default). A conservative setting that often prioritizes power saving.
  # - 15: Maximum Power Saving.
  #
  # On modern platforms like Meteor Lake, the default EPB of 6 can be overly
  # conservative, causing throttling even when EPP is set to "performance".
  # Setting EPB to 0 on AC power is critical for unlocking full turbo boost potential.
  systemd.services.cpu-epb = lib.mkIf isPhysicalMachine {
    description = "Set Intel EPB to Performance (AC=0, Battery=6)";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "multi-user.target" "cpu-epp.service" ];
    wants       = [ "cpu-epp.service" ]; # Run after EPP is configured.
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-epb" ''
        echo "=== EPB (Energy Performance Bias) Configuration ==="

        ON_AC=$(${detectPowerSource})
        if [[ "''${ON_AC}" = "1" ]]; then
          EPB_VALUE=0  # Max performance for AC power.
          SOURCE="AC"
        else
          EPB_VALUE=6  # Balanced default for battery.
          SOURCE="Battery"
        fi
        echo "Power source: ''${SOURCE}. Setting EPB to: ''${EPB_VALUE}"

        # Apply the EPB value to all CPUs using cpupower.
        # We ignore errors because some CPUs may have a read-only EPB.
        ${pkgs.linuxPackages_latest.cpupower}/bin/cpupower set -b ''${EPB_VALUE} &>/dev/null || true

        # Verify by reading the value back from the first CPU.
        RESULT=$(${pkgs.linuxPackages_latest.cpupower}/bin/cpupower -c 0 info -b 2>/dev/null | ${pkgs.gnugrep}/bin/grep -oP 'perf-bias: \K[0-9]+' | head -1)

        if [[ -n "''${RESULT}" ]]; then
          echo "✓ Verified EPB value on CPU0: ''${RESULT} (target was ''${EPB_VALUE})"
          # Note that the hardware can sometimes adjust the value slightly.
          if [[ "''${RESULT}" != "''${EPB_VALUE}" ]]; then
            echo "  Note: Hardware may have adjusted the final value."
          fi
        else
          echo "⚠ Could not read EPB value (this may not be supported on this CPU)."
        fi
        # This service should always be considered successful.
        exit 0
      '';
    };
  };

  # ============================================================================
  # CPU PERFORMANCE FLOOR (min_perf_pct)
  # ============================================================================
  # This service establishes a minimum performance floor for the `intel_pstate`
  # driver. This prevents the CPU from idling too aggressively, which can cause
  # perceptible lag in desktop UI interactions.
  #
  # Setting `min_perf_pct` to 30% on AC ensures the CPU operates at least at 30%
  # of its maximum non-turbo frequency, even under light load. This trades a
  # negligible amount of idle power for a significantly smoother and more
  # responsive interactive experience.
  #
  # Rationale for 30%:
  # - <20%: Can still exhibit noticeable input lag in GUI applications.
  # - 30-40%: The "sweet spot" for a responsive desktop with reasonable idle power.
  # - >50%: Diminishing returns on responsiveness with higher idle power consumption.
  #
  # This is only a *minimum* floor; the CPU is free to boost far higher as needed,
  # with the ceiling still managed by HWP and RAPL.
  systemd.services.cpu-min-freq-guard = lib.mkIf isPhysicalMachine {
    description = "Configure CPU for responsive performance (dynamic min_perf_pct: AC=30%, Battery=20%)";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "multi-user.target" "platform-profile.service" ];
    wants       = [ "platform-profile.service" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart = mkRobustScript "cpu-min-freq-guard" ''
        echo "=== CPU Performance Floor Configuration ==="
        sleep 2 # Small delay to ensure other services have settled.
        ON_AC=$(${detectPowerSource})
        if [[ "''${ON_AC}" = "1" ]]; then MIN=30; SRC="AC"; else MIN=20; SRC="Battery"; fi
        echo "Power source: ''${SRC} → Setting min_perf_pct to ''${MIN}%"

        if [[ -w "/sys/devices/system/cpu/intel_pstate/min_perf_pct" ]]; then
          echo "''${MIN}" > /sys/devices/system/cpu/intel_pstate/min_perf_pct 2>/dev/null
          # Ensure max performance and turbo are not artificially limited.
          echo 100 > /sys/devices/system/cpu/intel_pstate/max_perf_pct 2>/dev/null || true
          echo 0   > /sys/devices/system/cpu/intel_pstate/no_turbo     2>/dev/null || true
          echo "✓ Minimum performance floor configured."
        else
          echo "⚠ intel_pstate/min_perf_pct interface not writable. Cannot configure." >&2;
          exit 1
        fi
      '';
    };
  };

  # ============================================================================
  # DYNAMIC PROFILE REFRESH & MMIO MANAGEMENT (udev)
  # ============================================================================
  # These udev rules provide instant, event-driven responses to hardware changes.
  services.udev.extraRules = lib.concatStringsSep "\n" [
    ''
      # When the MMIO powercap zone appears or changes, trigger the disable service (writing is done in the service).
      ACTION=="add",    SUBSYSTEM=="powercap", KERNEL=="intel-rapl-mmio:*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="disable-rapl-mmio.service"
      ACTION=="change", SUBSYSTEM=="powercap", KERNEL=="intel-rapl-mmio:*", TAG+="systemd", ENV{SYSTEMD_WANTS}+="disable-rapl-mmio.service"

    ''
   (lib.optionalString isPhysicalMachine ''
      # AC adapter tak/çıkar → profilleri anında yenile
      ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC*", ENV{POWER_SUPPLY_ONLINE}=="1", RUN+="${pkgs.runtimeShell} -c '/run/current-system/sw/bin/systemctl restart platform-profile.service; /run/current-system/sw/bin/systemctl restart cpu-epp.service; /run/current-system/sw/bin/systemctl restart cpu-epb.service; /run/current-system/sw/bin/systemctl restart rapl-power-limits.service; /run/current-system/sw/bin/systemctl restart cpu-min-freq-guard.service; /run/current-system/sw/bin/systemctl start rapl-mmio-sync.service'"
      ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="AC*", ENV{POWER_SUPPLY_ONLINE}=="0", RUN+="${pkgs.runtimeShell} -c '/run/current-system/sw/bin/systemctl restart platform-profile.service; /run/current-system/sw/bin/systemctl restart cpu-epp.service; /run/current-system/sw/bin/systemctl restart cpu-epb.service; /run/current-system/sw/bin/systemctl restart rapl-power-limits.service; /run/current-system/sw/bin/systemctl restart cpu-min-freq-guard.service; /run/current-system/sw/bin/systemctl start rapl-mmio-sync.service'"
    '')
  ];

  # This service disables the intel-rapl-mmio powercap zone, which can sometimes
  # interfere with or override the primary MSR-based intel-rapl zone. We
  # prefer to manage limits via MSRs for consistency.
  systemd.services.disable-rapl-mmio = lib.mkIf isPhysicalMachine {
    description = "Disable intel-rapl-mmio powercap zone";
    wantedBy = [ "sysinit.target" ];
    after = [ "local-fs.target" ];

    # systemd rate-limitini kapat — udev birden fazla kez tetiklese bile sorun çıkarma
    unitConfig.StartLimitIntervalSec = 0;
    unitConfig.StartLimitBurst = 0;

    serviceConfig = {
      Type = "oneshot";
    };

    script = ''
      for d in /sys/class/powercap/intel-rapl-mmio:*; do
        [ -w "$d/enabled" ] && echo 0 > "$d/enabled" || true
      done
    '';
  };

  # ============================================================================
  # RAPL POWER LIMITS - Adaptive to CPU and Power Source
  # ============================================================================
  # This service configures the Running Average Power Limit (RAPL), which acts as
  # the final, hardware-enforced arbiter of CPU power consumption. These limits
  # cannot be circumvented by software and are critical for managing thermals
  # and performance under load.
  #
  # We configure two primary limits:
  # - PL1 (Power Limit 1): The sustained power limit for continuous, long-duration
  #   workloads. The CPU can maintain this power level indefinitely.
  # - PL2 (Power Limit 2): The short-duration burst power limit, allowing the CPU
  #   to exceed PL1 for brief periods to handle demanding tasks.
  #
  # Power profiles are tailored to the specific CPU and power source:
  #
  # Meteor Lake (Core Ultra 7 155H):
  #   AC:      PL1=32W / PL2=52W (High-performance desktop replacement)
  #   Battery: PL1=28W / PL2=45W (Balanced for mobile usage)
  #
  # Kaby Lake R (8th gen U-series):
  #   AC:      PL1=32W / PL2=52W (Respecting the lower TDP of this platform)
  #   Battery: PL1=20W / PL2=35W
  #
  # Generic Intel (Fallback):
  #   AC:      PL1=40W / PL2=65W
  #   Battery: PL1=22W / PL2=40W
  #
  # This service restarts automatically via udev rules when the power source changes.
  systemd.services.rapl-power-limits = lib.mkIf isPhysicalMachine {
    description = "Set RAPL power limits (MSR interface only)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "journal";
      StandardError = "journal";
      RemainAfterExit = true;
    };
    path = [ pkgs.coreutils pkgs.gawk ];
    script = ''
      #!/usr/bin/env bash
      set -euo pipefail

      SRC="/sys/class/powercap/intel-rapl:0"
      [[ -d "$SRC" ]] || { echo "MSR RAPL interface not found, exiting."; exit 0; }

      # Power source
      ON_AC=0
      for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
      done

      # CPU family (basit tespit, istersen ${cpuDetectionScript} çağırabilirsin)
      CPU_MODEL="$(LC_ALL=C ${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F "Model name" | ${pkgs.coreutils}/bin/cut -d: -f2-)"
      CPU_MODEL="$(echo "$CPU_MODEL" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"

      if echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -Eiq 'Ultra 7 155H|Meteor Lake|MTL'; then
        if [[ "$ON_AC" = "1" ]]; then PL1=32; PL2=52; else PL1=28; PL2=45; fi
      elif echo "$CPU_MODEL" | ${pkgs.gnugrep}/bin/grep -Eiq '8650U|Kaby Lake'; then
        if [[ "$ON_AC" = "1" ]]; then PL1=32; PL2=52; else PL1=20; PL2=35; fi
      else
        if [[ "$ON_AC" = "1" ]]; then PL1=40; PL2=65; else PL1=22; PL2=40; fi
      fi

      PL1_UW=$((PL1 * 1000000))
      PL2_UW=$((PL2 * 1000000))
      T1_US=20000000
      T2_US=1500000

      [[ -w "$SRC/constraint_0_power_limit_uw" ]] && echo "$PL1_UW" > "$SRC/constraint_0_power_limit_uw" || true
      [[ -w "$SRC/constraint_1_power_limit_uw" ]] && echo "$PL2_UW" > "$SRC/constraint_1_power_limit_uw" || true
      [[ -w "$SRC/constraint_0_time_window_us"  ]] && echo "$T1_US"  > "$SRC/constraint_0_time_window_us"  || true
      [[ -w "$SRC/constraint_1_time_window_us"  ]] && echo "$T2_US"  > "$SRC/constraint_1_time_window_us"  || true

      echo "rapl-power-limits: set PL1=''${PL1}W, PL2=''${PL2}W (AC=$ON_AC, CPU='$CPU_MODEL')"
    '';
  };

  # This service mirrors the power limits from the primary MSR RAPL interface
  # (`intel-rapl:0`) to the MMIO RAPL interface (`intel-rapl-mmio:0`) to ensure
  # consistency across the system.
  systemd.services.rapl-mmio-sync = lib.mkIf isPhysicalMachine {
    description = "Mirror MSR RAPL limits to MMIO RAPL interface";
    after = [ "rapl-power-limits.service" ];
    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "journal";
      StandardError = "journal";
    };
    path = [ pkgs.coreutils pkgs.gawk ];
    script = ''
      #!/usr/bin/env bash
      set -euo pipefail
      SRC="/sys/class/powercap/intel-rapl:0"
      DST="/sys/class/powercap/intel-rapl-mmio:0"
      [[ -d "$SRC" && -d "$DST" ]] || { echo "rapl-mmio-sync: One or both interfaces not found, skipping."; exit 0; }

      read_uw(){ cat "$1" 2>/dev/null || echo 0; }
      P1=$(read_uw "$SRC/constraint_0_power_limit_uw")
      P2=$(read_uw "$SRC/constraint_1_power_limit_uw")
      T1=$(read_uw "$SRC/constraint_0_time_window_us")
      T2=$(read_uw "$SRC/constraint_1_time_window_us")

      [[ -w "$DST/constraint_0_power_limit_uw" && "$P1" -gt 0 ]] && echo "$P1" > "$DST/constraint_0_power_limit_uw" || true
      [[ -w "$DST/constraint_1_power_limit_uw" && "$P2" -gt 0 ]] && echo "$P2" > "$DST/constraint_1_power_limit_uw" || true
      [[ -w "$DST/constraint_0_time_window_us"  && "$T1" -gt 0 ]] && echo "$T1" > "$DST/constraint_0_time_window_us"  || true
      [[ -w "$DST/constraint_1_time_window_us"  && "$T2" -gt 0 ]] && echo "$T2" > "$DST/constraint_1_time_window_us"  || true

      echo "rapl-mmio-sync: Mirrored MSR limits → PL1=''${P1}uW, PL2=''${P2}uW"
    '';
  };

  # A timer to periodically run the MMIO sync service, ensuring the limits
  # remain synchronized even if another process attempts to change them.
  systemd.timers.rapl-mmio-sync = lib.mkIf isPhysicalMachine {
    description = "Periodic RAPL MMIO mirror timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "60s";
      OnUnitActiveSec = "15s";
      AccuracySec = "2s";
      Unit = "rapl-mmio-sync.service";
    };
  };

  # ============================================================================
  # BATTERY HEALTH MANAGEMENT (75–80% Thresholds)
  # ============================================================================
  # This service configures battery charge thresholds to maximize battery
  # lifespan. Modern lithium-ion batteries degrade significantly faster when
  # kept at or near 100% charge for extended periods.
  #
  # By instructing the firmware to stop charging at 80% and only begin charging
  # again when the level drops below 75%, we keep the battery in its optimal
  # state of charge, drastically reducing cell voltage stress and chemical degradation.
  # For laptops that are frequently plugged in, this can double or triple the
  # usable lifespan of the battery pack.
  systemd.services.battery-thresholds = lib.mkIf isPhysicalMachine {
    description = "Set battery charge thresholds (75-80%) for longevity";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "multi-user.target" ];
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
      Restart         = "on-failure";
      RestartSec      = "30s";
      StartLimitBurst = 3;
      ExecStart = mkRobustScript "battery-thresholds" ''
        echo "=== Battery Charge Threshold Configuration ==="
        SUCCESS=0
        # Iterate over all power supplies prefixed with BAT.
        for bat in /sys/class/power_supply/BAT*; do
          [[ -d "$bat" ]] || continue

          # Set the start and stop charging thresholds.
          if [[ -w "$bat/charge_control_start_threshold" ]]; then
            echo 75 > "$bat/charge_control_start_threshold" 2>/dev/null && SUCCESS=1
            echo "✓ $(basename "''${bat}"): Set start threshold to 75%"
          fi
          if [[ -w "$bat/charge_control_end_threshold" ]]; then
            echo 80 > "$bat/charge_control_end_threshold" 2>/dev/null && SUCCESS=1
            echo "✓ $(basename "''${bat}"): Set stop threshold to 80%"
          fi
        done

        if [[ "''${SUCCESS}" == "1" ]]; then
          echo "✓ Battery charge thresholds successfully applied."
        else
          echo "⚠ Battery threshold control interface not found. (This is normal on non-ThinkPad systems)." >&2
          # Exit cleanly as this is not an error if the hardware doesn't support it.
          exit 0
        fi
      '';
    };
  };

  # ============================================================================
  # INTELLIGENT THERMAL PROTECTION - Temperature-Aware PL2 Management
  # ============================================================================
  # This service implements a temperature-aware PL2 control daemon that
  # dynamically adjusts the short-term power limit (PL2) based on CPU package
  # temperature. It prevents harsh firmware throttling and keeps performance
  # smooth without oscillations.
  #
  # Operation:
  #   • Monitors CPU package temperature every 2 seconds.
  #   • Adjusts PL2 (burst limit) according to temperature bands.
  #   • Restores full PL2 when cool, clamps it when hot.
  #   • Never modifies PL1 (sustained limit).
  #
  # Temperature Policy (AGGRESSIVE COOLING):
  #   ≤ 65°C : Cool  → restore full PL2 (BASE_PL2 = 52W)
  #   66–69°C: Hold  → keep current PL2 (hysteresis, no change)
  #   70–74°C: Warm  → clamp PL2 to 38W
  #   ≥ 75°C : Hot   → clamp PL2 to 32W
  #
  # Tunables (optimized for lower temperatures):
  #   HOT_C=75, WARM_C=70, COOL_C=65
  #   CLAMP_HOT_W=32, CLAMP_WARM_W=38
  #
  systemd.services.rapl-thermo-guard = lib.mkIf isPhysicalMachine {
    description = "Temperature-aware PL2 clamp on all RAPL interfaces (AGGRESSIVE)";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "multi-user.target" ];
    before      = [ "rapl-mmio-sync.service" ];
    serviceConfig = {
      Type       = "simple";
      Restart    = "always";      # Continuously running daemon
      RestartSec = "2s";
      ExecStart  = mkRobustScript "rapl-thermo-guard" ''
        echo "=== RAPL Thermo Guard Daemon Starting (AGGRESSIVE PROFILE) ==="

        # Ensure at least one RAPL interface is available.
        have_iface=0
        for R in /sys/class/powercap/intel-rapl:0 /sys/class/powercap/intel-rapl-mmio:0; do
          [[ -d "$R" ]] && have_iface=1
        done
        if [[ "''${have_iface}" -eq 0 ]]; then
          echo "⚠ No RAPL interface found. Exiting."
          exit 0
        fi

        # Read initial PL2 (base / maximum limit)
        read_base_pl2() {
          local P
          for P in /sys/class/powercap/intel-rapl:0 /sys/class/powercap/intel-rapl-mmio:0; do
            [[ -r "$P/constraint_1_power_limit_uw" ]] || continue
            echo $(( $(cat "$P/constraint_1_power_limit_uw") / 1000000 ))
            return
          done
          echo 52  # fallback if unreadable
        }

        BASE_PL2="$(read_base_pl2)"
        CURRENT_PL2="''${BASE_PL2}"
        echo "Base PL2 detected: ''${BASE_PL2} W"

        # -------------------- Tunables (AGGRESSIVE) --------------------
        HOT_C=73         # ≥ 75°C → aggressive clamp (was 78)
        WARM_C=68        # ≥ 70°C → moderate clamp (was 73)
        COOL_C=63        # ≤ 65°C → restore full PL2 (was 68)
        CLAMP_HOT_W=30   # PL2 when hot (was 35)
        CLAMP_WARM_W=36  # PL2 when warm (was 40)

        # -------------------- Helpers ---------------------
        read_temp() {
          ${pkgs.lm_sensors}/bin/sensors 2>/dev/null \
            | ${pkgs.gnugrep}/bin/grep -m1 "Package id 0" \
            | ${pkgs.gnugrep}/bin/grep -oP '\+\K[0-9]+' \
            | head -1
        }

        set_pl2_all() {
          local W="$1"
          for R in /sys/class/powercap/intel-rapl:* /sys/class/powercap/intel-rapl-mmio:*; do
            [[ -w "$R/constraint_1_power_limit_uw" ]] || continue
            echo $((W * 1000000)) > "$R/constraint_1_power_limit_uw" 2>/dev/null || true
          done
          echo "Thermal event: PL2 → ''${W} W (Temp: ''${TEMP}°C)"
        }

        # -------------------- Main loop -------------------
        while true; do
          TEMP="$(read_temp)"
          T_INT=$(printf '%.0f' "''${TEMP:-0}")  # round to int °C

          # Hysteresis bands (AGGRESSIVE):
          #   >= 75°C  → 32W (hot)
          #   >= 70°C  → 38W (warm)
          #   <= 65°C  → 52W (cool)
          #   otherwise → keep CURRENT_PL2 (hysteresis)
          if   [[ "''${T_INT}" -ge "''${HOT_C}" ]]; then
            TARGET_PL2="''${CLAMP_HOT_W}"
          elif [[ "''${T_INT}" -ge "''${WARM_C}" ]]; then
            TARGET_PL2="''${CLAMP_WARM_W}"
          elif [[ "''${T_INT}" -le "''${COOL_C}" ]]; then
            TARGET_PL2="''${BASE_PL2}"
          else
            TARGET_PL2="''${CURRENT_PL2}"
          fi

          # Apply only if changed
          if [[ "''${TARGET_PL2}" != "''${CURRENT_PL2}" ]]; then
            set_pl2_all "''${TARGET_PL2}"
            CURRENT_PL2="''${TARGET_PL2}"
          fi

          sleep 2
        done
      '';
    };
  };

  # ============================================================================
  # SYSTEM SERVICES (logind configuration)
  # ============================================================================
  services = {
    # Enable UPower for battery monitoring and power state information in desktop environments.
    upower.enable = true;

    # Configure systemd-logind to handle events like lid closure and power button presses.
    logind.settings = {
      Login = {
        HandleLidSwitch              = "suspend";   # Suspend when the lid is closed.
        HandleLidSwitchDocked        = "suspend";   # Also suspend when docked.
        HandleLidSwitchExternalPower = "suspend";   # Also suspend even when on AC power.
        HandlePowerKey               = "ignore";    # Ignore short power key presses to prevent accidents.
        HandlePowerKeyLongPress      = "poweroff";  # Long press will initiate a shutdown.
        HandleSuspendKey             = "suspend";   # Handle dedicated suspend key.
        HandleHibernateKey           = "hibernate"; # Handle dedicated hibernate key.
      };
    };

    # Enable the SPICE guest agent for improved integration in virtual machine environments.
    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
  };

  # ============================================================================
  # POST-SLEEP AUTOMATIC RESTORATION HOOK
  # ============================================================================
  # This systemd-sleep hook ensures that our custom power management settings
  # are reliably re-applied after the system resumes from suspend or hibernate.
  #
  # Why this is necessary:
  # - Suspend-to-RAM or hibernation can cause some hardware registers and firmware
  #   settings to revert to their default state.
  # - This can undo our careful configuration of RAPL limits, EPP, EPB, platform
  #   profile, and minimum performance percentage.
  #
  # By restarting all relevant services during the "post" phase of the sleep
  # cycle, we guarantee the system returns to its optimal power configuration
  # every time it wakes up.
  environment.etc."systemd/system-sleep/10-power-restore" = {
    mode = "0755";
    text = ''
      #!${pkgs.bash}/bin/bash
      # This script is called by systemd-sleep with two arguments:
      # $1: "pre" (before sleep) or "post" (after wake).
      # $2: The sleep state ("suspend", "hibernate", etc.).
      case "''${1}" in
        pre)
          # (no-op)
          ;;
        post)
          # After waking up, restart all power management services to restore our settings.
          /run/current-system/sw/bin/systemctl restart cpu-epp.service || true
          /run/current-system/sw/bin/systemctl restart cpu-epb.service || true
          /run/current-system/sw/bin/systemctl restart rapl-power-limits.service || true
          /run/current-system/sw/bin/systemctl restart cpu-min-freq-guard.service || true
          /run/current-system/sw/bin/systemctl restart platform-profile.service || true
          /run/current-system/sw/bin/systemctl restart rapl-thermo-guard.service || true
          /run/current-system/sw/bin/systemctl start   rapl-mmio-sync.service || true
          /run/current-system/sw/bin/systemctl start   disable-rapl-mmio.service || true
          ;;
      esac
    '';
  };

  # ============================================================================
  # MONITORING & DIAGNOSTIC TOOLS
  # ============================================================================
  # This section provides a suite of custom, user-friendly command-line scripts
  # for monitoring, diagnosing, and testing the power management configuration.
  # These tools are designed to provide clear, actionable information about the
  # system's real-time power and performance behavior.
  #
  # Available commands:
  # - system-status:         A comprehensive overview of the entire power management state.
  # - turbostat-quick:       Shows real CPU frequency and power behavior (requires root).
  # - turbostat-stress:      Performs a CPU stress test while monitoring with turbostat.
  # - power-check:           Measures instantaneous CPU package power consumption.
  # - power-monitor:         A real-time, continuously updating power monitoring dashboard.
  # - power-profile-refresh: Manually restarts all power management services.
  environment.systemPackages = with pkgs; lib.optionals isPhysicalMachine [
    lm_sensors                     # For reading CPU temperatures (`sensors` command).
    stress-ng                      # A versatile tool for stress testing the CPU.
    powertop                       # For in-depth power consumption analysis.
    bc                             # A command-line calculator used in scripts for power math.
    linuxPackages_latest.turbostat # The definitive tool for Intel CPU frequency/power analysis.
    linuxPackages_latest.cpupower  # For controlling and reading settings like EPB.
    # ========================================================================
    # SCRIPT: system-status
    # Provides a comprehensive, one-page snapshot of the current power
    # management configuration. This is the first tool to run when diagnosing
    # any power or performance issues. It reports on: Power source, P-State/HWP
    # status, platform profile, EPP, RAPL limits, battery thresholds, and more.
    # Also checks MSR vs MMIO RAPL parity to catch mismatches.
    # ========================================================================
    (writeScriptBin "system-status" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail

        echo "=== SYSTEM STATUS (v15.1.1) ==="
        echo ""

        # Power Source Detection
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
            [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Power Source: $([ "''${ON_AC}" = "1" ] && echo "⚡ AC Power" || echo "🔋 Battery")"

        # Intel P-State Status
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

        # ACPI Platform Profile
        if [[ -r "/sys/firmware/acpi/platform_profile" ]]; then
            PROFILE=$(cat /sys/firmware/acpi/platform_profile)
            echo "Platform Profile: ''${PROFILE}"
        fi

        # Energy Performance Preference (EPP) Summary
        echo ""
        CPU_COUNT=$(${pkgs.coreutils}/bin/ls -d /sys/devices/system/cpu/cpu[0-9]* 2>/dev/null | ${pkgs.coreutils}/bin/wc -l | ${pkgs.coreutils}/bin/tr -d ' ')
        declare -A EPP_MAP=()
        for pol in /sys/devices/system/cpu/cpufreq/policy*; do
            [[ -r "$pol/energy_performance_preference" ]] || continue
            epp=$(${pkgs.coreutils}/bin/cat "$pol/energy_performance_preference")
            # Safe increment under 'set -u'
            EPP_MAP["$epp"]=$(( ''${EPP_MAP["$epp"]-0} + 1 ))
        done

        echo "EPP (Energy Performance Preference):"
        if [[ "''${#EPP_MAP[@]}" -eq 0 ]]; then
            echo "  (EPP interface not found)"
        else
            for k in "''${!EPP_MAP[@]}"; do
                count="''${EPP_MAP[$k]-0}"
                echo "  - ''${k} (on ''${count} policies)"
            done
        fi

        # RAPL Power Limits (per domain)
        echo ""
        echo "RAPL POWER LIMITS (per domain):"
        if [[ -d /sys/class/powercap/intel-rapl:0 ]]; then
            for R in /sys/class/powercap/intel-rapl:*; do
                [[ -d "$R" ]] || continue
                NAME=$(basename "$R")
                LABEL=$(cat "$R/name" 2>/dev/null || echo "$NAME")

                PL1=$(cat "$R/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
                PL2=$(cat "$R/constraint_1_power_limit_uw" 2>/dev/null || echo 0)

                echo "  Domain: ''${LABEL} (''${NAME})"
                ${pkgs.coreutils}/bin/printf "    PL1 (Sustained): %3d W\n" $((PL1/1000000))
                if [[ "$PL2" -gt 0 ]]; then
                    ${pkgs.coreutils}/bin/printf "    PL2 (Burst):     %3d W\n" $((PL2/1000000))
                fi
            done
        else
            echo "  (RAPL interface not available)"
        fi

        # RAPL Consistency Check: MSR vs MMIO (Package 0)
        echo ""
        echo "RAPL CONSISTENCY (MSR vs MMIO, package-0):"
        MSR_BASE="/sys/class/powercap/intel-rapl:0"
        MMIO_BASE="/sys/class/powercap/intel-rapl-mmio:0"
        if [[ -d "$MSR_BASE" && -d "$MMIO_BASE" ]]; then
            msr_pl1=$(cat "$MSR_BASE/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
            msr_pl2=$(cat "$MSR_BASE/constraint_1_power_limit_uw" 2>/dev/null || echo 0)
            mmio_pl1=$(cat "$MMIO_BASE/constraint_0_power_limit_uw" 2>/dev/null || echo 0)
            mmio_pl2=$(cat "$MMIO_BASE/constraint_1_power_limit_uw" 2>/dev/null || echo 0)

            msr_pl1_w=$((msr_pl1/1000000)); msr_pl2_w=$((msr_pl2/1000000))
            mmio_pl1_w=$((mmio_pl1/1000000)); mmio_pl2_w=$((mmio_pl2/1000000))

            match_pl1=$([ "''${msr_pl1}" = "''${mmio_pl1}" ] && echo "✓" || echo "⚠")
            match_pl2=$([ "''${msr_pl2}" = "''${mmio_pl2}" ] && echo "✓" || echo "⚠")

            echo "  PL1: MSR=''${msr_pl1_w} W  |  MMIO=''${mmio_pl1_w} W   [$match_pl1 match]"
            if [[ "$msr_pl2_w" -gt 0 || "$mmio_pl2_w" -gt 0 ]]; then
                echo "  PL2: MSR=''${msr_pl2_w} W  |  MMIO=''${mmio_pl2_w} W   [$match_pl2 match]"
            fi
            if [[ "$match_pl1" = "⚠" || "$match_pl2" = "⚠" ]]; then
                echo "  Note: Mismatch detected. A service or firmware may be rewriting one interface."
            fi
        else
            echo "  (One or both interfaces missing; skipping parity check)"
        fi

        # Battery Status and Health Settings
        echo ""
        echo "BATTERY STATUS:"
        found_bat=0
        for bat in /sys/class/power_supply/BAT*; do
            [[ -d "$bat" ]] || continue
            found_bat=1
            NAME=$(basename "$bat")
            CAPACITY=$(cat "$bat/capacity" 2>/dev/null || echo "N/A")
            STATUS=$(cat "$bat/status" 2>/dev/null || echo "N/A")
            START=$(cat "$bat/charge_control_start_threshold" 2>/dev/null || echo "N/A")
            STOP=$(cat "$bat/charge_control_end_threshold" 2>/dev/null || echo "N/A")
            echo "  ''${NAME}: ''${CAPACITY}% (''${STATUS}) | Charge Thresholds: Start=''${START}%, Stop=''${STOP}%"
        done
        [[ "$found_bat" -eq 0 ]] && echo "  (No battery detected)"

        # Service Health Status
        echo ""
        echo "SERVICE STATUS:"
        for svc in battery-thresholds platform-profile cpu-epp cpu-epb cpu-min-freq-guard rapl-power-limits rapl-thermo-guard disable-rapl-mmio rapl-mmio-sync; do
            STATE=$(${pkgs.systemd}/bin/systemctl show -p ActiveState --value "$svc.service" 2>/dev/null)
            RESULT=$(${pkgs.systemd}/bin/systemctl show -p Result --value "$svc.service" 2>/dev/null)
            if [[ ( "''${STATE}" == "inactive" && "''${RESULT}" == "success" ) || "''${STATE}" == "active" ]]; then
                ${pkgs.coreutils}/bin/printf "  %-25s [ ✅ OK ]\n" "$svc"
            else
                ${pkgs.coreutils}/bin/printf "  %-25s [ ⚠️  ''${STATE} (''${RESULT}) ]\n" "$svc"
            fi
        done

        echo ""
        echo "💡 Tip: Use 'turbostat-quick' for real-time frequency analysis (requires root)."
        echo "💡 Tip: Use 'power-monitor' for a live power consumption dashboard."
    '')

    # ========================================================================
    # TURBOSTAT-QUICK: Real CPU frequency analysis
    # ========================================================================
    # Shows the *actual* CPU behavior by reading hardware counters. This is
    # essential because `scaling_cur_freq` is often misleading with HWP enabled.
    # Key metrics to watch:
    # - Avg_MHz: True average frequency, including idle time.
    # - Bzy_MHz: Average frequency of non-idle cores.
    # - PkgWatt: Total power consumption of the CPU package.
    # Requires root privileges to access Model-Specific Registers (MSRs).
    # ========================================================================
    (writeScriptBin "turbostat-quick" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
        
      echo "=== TURBOSTAT QUICK ANALYSIS (5 seconds) ==="
      echo ""
      echo "NOTE: 'Avg_MHz' is the true average frequency. 'Bzy_MHz' is frequency when busy."
      echo "      scaling_cur_freq from sysfs may show 400 MHz; ignore it under HWP."
      echo ""
      
      # Check if turbostat is available
      if ! command -v ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat &>/dev/null; then
        echo "⚠ turbostat not found. Ensure linuxPackages_latest.turbostat is installed."
        exit 1
      fi
      
      # Check root privileges
      if [[ $EUID -ne 0 ]]; then
        echo "⚠ This script requires root privileges to read MSRs."
        echo "   Please run: sudo turbostat-quick"
        exit 1
      fi
      
      ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat --interval 5 --num_iterations 1
    '')

    # ========================================================================
    # TURBOSTAT-STRESS: Performance testing under load
    # ========================================================================
    # Combines a CPU stress test with `turbostat` monitoring to verify that
    # the system can achieve and sustain high performance under load.
    # What to look for during the test:
    # - `Avg_MHz` and `Bzy_MHz` should ramp up significantly under load.
    # - `PkgWatt` should approach the configured PL1 (35W sustained) or PL2 (55W burst) limits.
    # - Package temperature should remain within safe limits (ideally < 85°C).
    # 
    # Test sequence:
    # 1. Measure baseline idle state (2 seconds)
    # 2. Launch stress-ng with full CPU load
    # 3. Monitor performance under load (8 seconds)
    # 
    # Expected results:
    # - Sustained (PL1): ~1900 MHz @ 27W
    # - Burst (PL2): ~2700 MHz @ 41W (first 2 seconds)
    # ========================================================================
    (writeScriptBin "turbostat-stress" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      ANALYZE=0
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --analyze) ANALYZE=1; shift ;;
          -h|--help)
            echo "Usage: sudo turbostat-stress [--analyze]"
            exit 0
            ;;
          *) echo "Unknown arg: $1" >&2; exit 2;;
        esac
      done

      echo "=== CPU PERFORMANCE STRESS TEST (10 seconds) ==="
      echo ""

      # Check required tools
      MISSING=""
      if ! command -v ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat &>/dev/null; then
        MISSING="turbostat"
      fi
      if ! command -v ${pkgs.stress-ng}/bin/stress-ng &>/dev/null; then
        MISSING="''${MISSING:+$MISSING, }stress-ng"
      fi
      if [[ -n "''${MISSING}" ]]; then
        echo "⚠ Required tools not found: ''${MISSING}"
        exit 1
      fi

      # Root check
      if [[ $EUID -ne 0 ]]; then
        echo "⚠ This script requires root privileges to read MSRs."
        echo "   Please run: sudo turbostat-stress"
        exit 1
      fi

      echo "--- Measuring initial idle state (2 seconds)... ---"
      ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat --interval 2 --num_iterations 1

      echo ""
      echo "--- Starting stress test and monitoring under load (8 seconds)... ---"

      # Start stress
      ${pkgs.stress-ng}/bin/stress-ng --cpu 0 --timeout 10s &
      STRESS_PID=$!
      sleep 1

      if [[ "''${ANALYZE}" -eq 1 ]]; then
        # Show turbostat table to stderr and analysis summary to stdout
        ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat --interval 8 --num_iterations 1 \
          | ${pkgs.coreutils}/bin/tee /dev/stderr \
          | turbostat-analyze --file - --mode load
      else
        ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat --interval 8 --num_iterations 1
      fi

      wait "''${STRESS_PID}" 2>/dev/null || true

      echo ""
      echo "Stress test complete."
      echo ""
      echo "📊 Evaluation Criteria:"
      echo "   - Avg_MHz ≥ 2000 MHz indicates good performance"
      echo "   - PkgWatt should approach RAPL limits (35W sustained, 55W burst)"
      echo "   - Package Temperature should stay below 85°C"
      echo "   - Bzy_MHz shows frequency when cores are busy"
    '')

    # ========================================================================
    # TURBOSTAT-ANALYZE: Parse turbostat output and print a concise summary
    # ------------------------------------------------------------------------
    # Usage:
    #   sudo turbostat-analyze                      # run turbostat (default: 5s/1 iter)
    #   sudo turbostat-analyze --interval 2 --iters 3
    #   turbostat ... | sudo turbostat-analyze --file -        # parse from STDIN
    #   sudo turbostat-analyze --file /path/to/turbostat.log
    #   sudo turbostat-analyze --mode load          # force load thresholds (no IDLE shortcut)
    #   sudo turbostat-analyze --mode idle          # force IDLE verdict (for quiet checks)
    #
    # Outputs:
    #  • Key metrics (Avg_MHz, Busy%, Bzy_MHz, IPC, PkgWatt, CorWatt, GFXWatt)
    #  • RAPL limits (PL1/PL2) and how close PkgWatt is to them
    #  • Verdict: OK / WARN / IDLE (IDLE if very low load in --mode auto)
    # ========================================================================
    (writeScriptBin "turbostat-analyze" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # Defaults
      INTERVAL=5
      ITERS=1
      INPUT="-"
      RUN_TURBOSTAT=1
      MODE="auto"   # auto | load | idle

      # Parse args
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --interval) INTERVAL="$2"; shift 2 ;;
          --iters|--num-iterations) ITERS="$2"; shift 2 ;;
          --file) INPUT="$2"; RUN_TURBOSTAT=0; shift 2 ;;
          --mode) MODE="$2"; shift 2 ;;
          -h|--help)
            echo "Usage: sudo turbostat-analyze [--interval N] [--iters N] [--file path|-] [--mode auto|load|idle]"
            exit 0
            ;;
          *)
            echo "Unknown arg: $1" >&2
            exit 2
            ;;
        esac
      done

      # Ensure turbostat exists when running it
      if [[ "''${RUN_TURBOSTAT}" -eq 1 ]]; then
        if [[ $EUID -ne 0 ]]; then
          echo "⚠ This tool needs root to read MSRs. Try: sudo turbostat-analyze" >&2
          exit 1
        fi
        if ! command -v ${pkgs.linuxPackages_latest.turbostat}/bin/turbostat >/dev/null 2>&1; then
          echo "⚠ turbostat not found." >&2
          exit 1
        fi
      fi

      # Acquire input stream
      if [[ "''${RUN_TURBOSTAT}" -eq 1 ]]; then
        DATA="$(${pkgs.linuxPackages_latest.turbostat}/bin/turbostat --interval "''${INTERVAL}" --num_iterations "''${ITERS}" 2>/dev/null)"
      else
        if [[ "''${INPUT}" = "-" ]]; then
          DATA="$(cat -)"
        else
          DATA="$(cat "''${INPUT}")"
        fi
      fi

      # Parse: detect header line (starts with "Core"), map column -> index,
      # then read the *summary row* where first field is "-"
      parse_out="$(
        echo "''${DATA}" | ${pkgs.gawk}/bin/awk '
          BEGIN { FS="[ \t]+"; gotHdr=0 }
          $1=="Core" {
            gotHdr=1
            for (i=1; i<=NF; i++) h[$i]=i
            next
          }
          gotHdr && $1=="-" {
            avg=""; busy=""; bzy=""; ipc=""; pkgw=""; corw=""; gfxw=""; unc=""; diec6=""
            i=h["Avg_MHz"]; if (i>0 && i<=NF) avg=$(i)
            i=h["Busy%"];  if (i>0 && i<=NF) busy=$(i)
            i=h["Bzy_MHz"]; if (i>0 && i<=NF) bzy=$(i)
            i=h["IPC"];     if (i>0 && i<=NF) ipc=$(i)
            i=h["PkgWatt"]; if (i>0 && i<=NF) pkgw=$(i)
            i=h["CorWatt"]; if (i>0 && i<=NF) corw=$(i)
            i=h["GFXWatt"]; if (i>0 && i<=NF) gfxw=$(i)
            i=h["UncMHz"];  if (i>0 && i<=NF) unc=$(i)
            i=h["Die%c6"];  if (i>0 && i<=NF) diec6=$(i)
            print avg "\t" busy "\t" bzy "\t" ipc "\t" pkgw "\t" corw "\t" gfxw "\t" unc "\t" diec6
            exit
          }
        '
      )"

      if [[ -z "''${parse_out}" ]]; then
        echo "⚠ Could not parse turbostat summary row. Is the input complete?" >&2
        echo "Tip: Ensure the output includes a header line starting with 'Core' and a summary row starting with '-'." >&2
        exit 3
      fi

      IFS=$'\t' read -r AVG_MHZ BUSY_PCT BZY_MHZ IPC PKG_W COR_W GFX_W UNC_MHZ DIE_C6 <<< "''${parse_out}"

      # Read RAPL limits if available
      PL1=""; PL2=""
      if [[ -r /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw ]]; then
        PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo "")
        [[ -n "''${PL1}" ]] && PL1=$((PL1/1000000))
      fi
      if [[ -r /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw ]]; then
        PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo "")
        [[ -n "''${PL2}" ]] && PL2=$((PL2/1000000))
      fi

      # Helper for % of limit
      pct_of() {
        local val="$1" lim="$2"
        if [[ -z "''${val}" || -z "''${lim}" || "''${lim}" = "0" ]]; then
          echo "N/A"; return
        fi
        ${pkgs.coreutils}/bin/printf "%0.1f%%" "$(echo "scale=3; (''${val}/''${lim})*100" | ${pkgs.bc}/bin/bc)"
      }

      # Pretty print
      echo "=== TURBOSTAT ANALYZE SUMMARY ==="
      ${pkgs.coreutils}/bin/printf "Avg_MHz:   %s\n" "''${AVG_MHZ:-N/A}"
      ${pkgs.coreutils}/bin/printf "Busy%%:     %s\n" "''${BUSY_PCT:-N/A}"
      ${pkgs.coreutils}/bin/printf "Bzy_MHz:   %s\n" "''${BZY_MHZ:-N/A}"
      ${pkgs.coreutils}/bin/printf "IPC:       %s\n" "''${IPC:-N/A}"
      ${pkgs.coreutils}/bin/printf "PkgWatt:   %s W\n" "''${PKG_W:-N/A}"
      ${pkgs.coreutils}/bin/printf "CorWatt:   %s W\n" "''${COR_W:-N/A}"
      ${pkgs.coreutils}/bin/printf "GFXWatt:   %s W\n" "''${GFX_W:-N/A}"
      ${pkgs.coreutils}/bin/printf "UncMHz:    %s\n"   "''${UNC_MHZ:-N/A}"
      [[ -n "''${DIE_C6:-}" ]] && ${pkgs.coreutils}/bin/printf "Die%%c6:   %s\n" "''${DIE_C6}"

      # RAPL Limits (compute percentages first to avoid nested substitution)
      PCT_PL1=""
      PCT_PL2=""
      if [[ -n "''${PL1}" && -n "''${PKG_W}" ]]; then
        PCT_PL1="$(pct_of "''${PKG_W}" "''${PL1}")"
      fi
      if [[ -n "''${PL2}" && -n "''${PKG_W}" ]]; then
        PCT_PL2="$(pct_of "''${PKG_W}" "''${PL2}")"
      fi

      if [[ -n "''${PL1}" || -n "''${PL2}" ]]; then
        echo ""
        echo "RAPL Limits:"
        if [[ -n "''${PL1}" ]]; then
          if [[ -n "''${PCT_PL1}" && "''${PCT_PL1}" != "N/A" ]]; then
            echo "  PL1 (Sustained): ''${PL1} W  → ''${PCT_PL1} of PL1"
          else
            echo "  PL1 (Sustained): ''${PL1} W"
          fi
        fi
        if [[ -n "''${PL2}" ]]; then
          if [[ -n "''${PCT_PL2}" && "''${PCT_PL2}" != "N/A" ]]; then
            echo "  PL2 (Burst):     ''${PL2} W  → ''${PCT_PL2} of PL2"
          else
            echo "  PL2 (Burst):     ''${PL2} W"
          fi
        fi
      fi

      # -----------------------------
      # Verdict (OK / WARN / IDLE)
      # -----------------------------
      echo ""
      verdict="OK"
      reason=()

      # Parse numbers to integers/floats we can compare
      if [[ -n "''${AVG_MHZ:-}" ]]; then
        avg_int=$(${pkgs.coreutils}/bin/printf "%.0f" "''${AVG_MHZ}")
      else
        avg_int=0
      fi
      busy_int=$(${pkgs.gawk}/bin/awk -v v="''${BUSY_PCT:-0}" 'BEGIN{print int(v+0.5)}')

      # Mode logic
      case "''${MODE}" in
        idle)
          verdict="IDLE"
          ;;
        load)
          (( avg_int < 2000 )) && { verdict="WARN"; reason+=("Avg_MHz < 2000"); }
          (( busy_int < 95 )) && reason+=("Busy% < 95 (may not be full load)")
          if [[ -n "''${PL1:-}" && -n "''${PKG_W:-}" ]]; then
            hit_pl1=$(${pkgs.bc}/bin/bc <<< "scale=3; ''${PKG_W}/''${PL1} >= 0.8")
            [[ "''${hit_pl1}" -ne 1 ]] && reason+=("PkgWatt < 80% of PL1")
          fi
          ;;
        auto|*)
          # If clearly idle, mark as IDLE instead of WARN
          if (( busy_int < 10 )) && (( avg_int < 500 )); then
            verdict="IDLE"
          else
            (( avg_int < 2000 )) && { verdict="WARN"; reason+=("Avg_MHz < 2000"); }
            (( busy_int < 95 )) && reason+=("Busy% < 95 (may not be full load)")
            if [[ -n "''${PL1:-}" && -n "''${PKG_W:-}" ]]; then
              hit_pl1=$(${pkgs.bc}/bin/bc <<< "scale=3; ''${PKG_W}/''${PL1} >= 0.8")
              [[ "''${hit_pl1}" -ne 1 ]] && reason+=("PkgWatt < 80% of PL1")
            fi
          fi
          ;;
      esac

      echo "Verdict: ''${verdict}"
      if ((''${#reason[@]})); then
        echo "Notes:"
        for r in "''${reason[@]}"; do
          echo "  - $r"
        done
      fi
    '')

    # ========================================================================
    # SCRIPT: power-check
    # Measures the current CPU package power consumption by sampling RAPL energy
    # counters over a short interval. It calculates the difference to determine
    # the power rate in watts and provides context with active RAPL limits and
    # a qualitative interpretation of the power level.
    # ========================================================================
    (writeScriptBin "power-check" ''
      #!${pkgs.bash}/bin/bash
      echo "=== INSTANTANEOUS POWER CONSUMPTION CHECK ==="
      echo ""

      # Power Source Detection
      ON_AC=0
      for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
      done
      echo "Power Source: $([ "''${ON_AC}" = "1" ] && echo "⚡ AC Power" || echo "🔋 Battery")"
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
      [[ "''${ENERGY_DIFF}" -lt 0 ]] && ENERGY_DIFF="''${ENERGY_AFTER}"

      # Watts = (Joules / seconds) = (microjoules / 1,000,000) / 2
      WATTS=$(echo "scale=2; ''${ENERGY_DIFF} / 2000000" | ${pkgs.bc}/bin/bc)

      echo ""
      echo ">> INSTANTANEOUS PACKAGE POWER: ''${WATTS} W"
      echo ""

      # Show current RAPL limits for context.
      PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)
      PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw)
      printf "Active RAPL Limits:\n  PL1 (Sustained): %3d W\n  PL2 (Burst):     %3d W\n\n" $((PL1/1000000)) $((PL2/1000000))

      # Interpret the power level.
      WATTS_INT=$(echo "''${WATTS}" | ${pkgs.coreutils}/bin/cut -d. -f1)
      if   [[ "''${WATTS_INT}" -lt 10 ]]; then echo "📊 Status: Idle or light usage."
      elif [[ "''${WATTS_INT}" -lt 30 ]]; then echo "📊 Status: Normal productivity workload."
      elif [[ "''${WATTS_INT}" -lt 50 ]]; then echo "📊 Status: High load (compiling, gaming)."
      else                                  echo "📊 Status: Very high load (stress test)."
      fi
    '')

    # ========================================================================
    # SCRIPT: power-monitor
    # A continuously updating, real-time dashboard showing key power management
    # metrics. Useful for observing the power impact of different applications
    # or verifying that profile changes take effect instantly. Refreshes every
    # second until stopped with Ctrl+C.
    # ========================================================================
    (writeScriptBin "power-monitor" ''
      #!${pkgs.bash}/bin/bash
      trap "tput cnorm; exit" INT # Ensure cursor is visible on exit.
      tput civis # Hide cursor.

      while true; do
        clear
        echo "=== REAL-TIME POWER MONITOR (v15.0.0) | Press Ctrl+C to stop ==="
        echo "Timestamp: $(date '+%H:%M:%S')"
        echo "------------------------------------------------------------"

        # Power Source
        ON_AC=0
        for PS in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
          [[ -f "$PS" ]] && ON_AC="$(cat "$PS")" && break
        done
        echo "Power Source:  $([ "''${ON_AC}" = "1" ] && echo "⚡ AC Power" || echo "🔋 Battery")"

        # EPP
        EPP=$(cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference 2>/dev/null || echo "N/A")
        echo "EPP Setting:   ''${EPP}"

        # Temperature
        TEMP=$(${pkgs.lm_sensors}/bin/sensors 2>/dev/null | ${pkgs.gnugrep}/bin/grep "Package id 0" | ${pkgs.gawk}/bin/awk '{match($0, /[+]?([0-9]+\.[0-9]+)/, a); print a[1]}')
        [[ -n "''${TEMP}" ]] && printf "Temperature:   %.1f°C\n" "''${TEMP}" || echo "Temperature:   N/A"

        echo "------------------------------------------------------------"

        # Power Consumption (0.5 second sample for faster updates)
        if [[ -f /sys/class/powercap/intel-rapl:0/energy_uj ]]; then
          ENERGY_BEFORE=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)
          sleep 0.5
          ENERGY_AFTER=$(cat /sys/class/powercap/intel-rapl:0/energy_uj)

          ENERGY_DIFF=$((ENERGY_AFTER - ENERGY_BEFORE))
          [[ "''${ENERGY_DIFF}" -lt 0 ]] && ENERGY_DIFF="''${ENERGY_AFTER}"
          WATTS=$(echo "scale=2; ''${ENERGY_DIFF} / 500000" | ${pkgs.bc}/bin/bc)

          PL1=$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)
          PL2=$(cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw 2>/dev/null || echo 0)

          echo "PACKAGE POWER (RAPL):"
          printf "  Current Consumption: %6.2f W\n" "''${WATTS}"
          printf "  Sustained Limit (PL1): %4d W\n" $((PL1/1000000))
          printf "  Burst Limit (PL2):     %4d W\n" $((PL2/1000000))
        else
          echo "PACKAGE POWER (RAPL): Not Available"
        fi

        echo "------------------------------------------------------------"
        # Frequency Statistics
        echo "CPU FREQUENCY (scaling_cur_freq):"
        FREQS=($(cat  /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq))
        if [[ ''${#FREQS[@]} -gt 0 ]]; then
            SUM=$(IFS=+; echo "$((''${FREQS[*]}))")
            AVG=$((SUM / ''${#FREQS[@]} / 1000))
            MIN=$(printf "%s\n" "''${FREQS[@]}" | sort -n | head -1)
            MAX=$(printf "%s\n" "''${FREQS[@]}" | sort -n | tail -1)
            printf "  Average: %5d MHz\n" "$AVG"
            printf "  Min/Max: %5d / %d MHz\n" "$((MIN/1000))" "$((MAX/1000))"
            echo "  (NOTE: This value can be misleading; use turbostat for ground truth)"
        else
            echo "  Frequency data not available."
        fi
        sleep 0.5 # Remainder of the 1-second loop.
      done
    '')

    # ========================================================================
    # SCRIPT: power-profile-refresh
    # A convenience utility to manually restart all custom power management
    # services. This is useful for testing configuration changes or recovering
    # from a failed state without needing a full reboot. Requires sudo.
    # ========================================================================
    (writeScriptBin "power-profile-refresh" ''
        #!${pkgs.bash}/bin/bash
        echo "=== RESTARTING POWER PROFILE SERVICES ==="
        echo ""
        if [[ $EUID -ne 0 ]]; then
            echo "⚠ This script requires root privileges. Please run with sudo."
            exit 1
        fi

        # Ordered restart sequence (dependency-safe)
        SERVICES=(
            "platform-profile.service"
            "cpu-epp.service"
            "cpu-epb.service"
            "cpu-min-freq-guard.service"
            "rapl-power-limits.service"
            "disable-rapl-mmio.service"
            "rapl-mmio-sync.service"
            "rapl-thermo-guard.service"
            "battery-thresholds.service"
        )

        for SVC in "''${SERVICES[@]}"; do
            printf "Restarting %-30s ... " "$SVC"
            if systemctl restart "$SVC" 2>/dev/null; then
                echo "[ OK ]"
            else
                echo "[ FAILED ]"
            fi
        done

        echo ""
        echo "✓ All power-related services have been refreshed."
        echo "-------------------------------------------------"
        system-status
    '')
  ];
}

