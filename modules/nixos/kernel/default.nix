# modules/nixos/kernel/default.nix
# ==============================================================================
# NixOS module for kernel (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  # ---------------------------------------------------------------------------
  # Host type detection
  # ---------------------------------------------------------------------------
  # my.host.isPhysicalHost must be defined in your host modules.
  # Used to avoid loading laptop/ThinkPad-specific modules on VMs.
  # ---------------------------------------------------------------------------
  isPhysicalMachine = config.my.host.isPhysicalHost;

in
{
  boot = {
    # -------------------------------------------------------------------------
    # Kernel package
    # -------------------------------------------------------------------------
    kernelPackages = pkgs.linuxPackages_latest;

    # -------------------------------------------------------------------------
    # Kernel modules
    # -------------------------------------------------------------------------
    # Always-loaded modules:
    #   - msr:      RAPL / MSR access (for power/energy monitoring)
    #   - coretemp: CPU temperature sensors
    #   - i915:     Intel iGPU (KMS, acceleration)
    #   - iwlwifi:  Intel Wi-Fi (force load when autoload fails)
    #
    # Physical-only modules:
    #   - thinkpad_acpi: ThinkPad ACPI interface (hotkeys, LEDs, fan, etc.)
    #   - i2c-dev:       Userspace I²C interface (/dev/i2c-*)
    #   - i2c-i801:      Intel SMBus/I²C controller driver
    #
    # i2c-dev + i2c-i801 are required for:
    #   - `ddcutil` DDC/CI control (external monitor brightness/controls)
    #   - Other tools that talk to monitors/embedded controllers via I²C
    # -------------------------------------------------------------------------
    kernelModules =
      [
        "msr"      # RAPL MSR access
        "coretemp" # CPU temperature sensors
        "i915"     # Intel iGPU
        "iwlwifi"  # Intel Wi-Fi (force load when autoload fails)
      ]
      ++ lib.optionals isPhysicalMachine [
        "thinkpad_acpi" # ThinkPad-specific ACPI features
        "i2c-dev"       # Userspace I²C devices (/dev/i2c-*)
        "i2c-i801"      # Intel I²C/SMBus controller
      ];

    # -------------------------------------------------------------------------
    # Modprobe options for specific modules
    # -------------------------------------------------------------------------
    extraModprobeConfig = lib.optionalString isPhysicalMachine ''
      # Enable experimental features in thinkpad_acpi (fan, LEDs, etc.)
      options thinkpad_acpi experimental=1
    '';

    # -------------------------------------------------------------------------
    # Kernel parameters
    # -------------------------------------------------------------------------
    # Power / CPU:
    #   - intel_pstate=active      : Use Intel P-state driver (HWP/EPP aware)
    #   - intel_idle.max_cstate=7 : Allow deep C-states (balance power/latency)
    #   - processor.ignore_ppc=1  : Ignore firmware P-state hints (more control)
    #
    # GPU (Intel i915):
    #   - i915.enable_guc=3       : Enable GuC/HuC for scheduling & media
    #   - i915.enable_fbc=1       : Framebuffer compression for lower power
    #   - i915.enable_dc=2        : Deeper display C-states
    #   - i915.enable_psr=1       : Panel Self Refresh (laptop power saving)
    #   - i915.fastboot=1         : Fast KMS handover (less flicker on boot)
    #
    # Suspend:
    #   - mem_sleep_default=s2idle : Modern low-power suspend (s2idle) by default
    # -------------------------------------------------------------------------
    kernelParams = [
      "intel_pstate=active"
      "intel_idle.max_cstate=7"
      "processor.ignore_ppc=1"
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "i915.enable_dc=2"
      "i915.enable_psr=1"
      "i915.fastboot=1"
      "mem_sleep_default=s2idle"
    ];

    # -------------------------------------------------------------------------
    # Blacklisted kernel modules
    # -------------------------------------------------------------------------
    # - intel_rapl_mmio:
    #     Can conflict with MSR-based RAPL drivers and cause duplicated
    #     power domains or misleading readings. We prefer MSR-based access.
    # -------------------------------------------------------------------------
    blacklistedKernelModules = [
      "intel_rapl_mmio"
    ];
  };
}

