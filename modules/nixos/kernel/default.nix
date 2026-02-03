# modules/nixos/kernel/default.nix
# ==============================================================================
# NixOS kernel selection and module options: packages, parameters, extra modules.
# Centralize kernel policy and overrides for every host.
#
# Philosophy:
# - Keep this module "safe by default" (no risky kernelParams globally).
# - Prefer host opt-ins for workaround/tuning params.
# - Optimized for modern hardware (Meteor Lake, Zen Kernel, etc.).
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkDefault optionalString optionals types;

  cfg = config.my.kernel;
  isPhysicalMachine = config.my.host.isPhysicalHost or false;

  effectiveKernelFlavor =
    if cfg.useLatestKernel != null then (if cfg.useLatestKernel then "latest" else "stable") else cfg.kernelFlavor;

  kernelPackagesFor =
    if effectiveKernelFlavor == "zen" then pkgs.linuxPackages_zen
    else if effectiveKernelFlavor == "xanmod" then pkgs.linuxPackages_xanmod
    else if effectiveKernelFlavor == "latest" then pkgs.linuxPackages_latest
    else pkgs.linuxPackages;

in
{
  options.my.kernel = {
    kernelFlavor = mkOption {
      type = types.enum [ "zen" "xanmod" "latest" "stable" ];
      default = "zen";
      description = "Kernel package set: zen (recommended for desktop/gaming), xanmod, latest, or stable.";
    };

    useLatestKernel = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Deprecated: use my.kernel.kernelFlavor. When set, true -> latest; false -> stable.";
    };

    forceIwlwifi = mkEnableOption "Force-load iwlwifi at boot (rarely needed).";

    thinkpad = {
      enable = mkEnableOption "Load thinkpad_acpi (ThinkPad-only; avoid on non-ThinkPad hardware).";
      experimental = mkEnableOption "Enable thinkpad_acpi experimental=1 (opt-in; can be risky).";
    };

    tweaks = {
      # CPU workarounds (host opt-in)
      cpu = {
        intelPstateActive = mkEnableOption "Set intel_pstate=active (opt-in; mostly default on Intel laptops).";

        maxCstate = mkOption {
          type = types.nullOr (types.ints.between 0 9);
          default = null;
          description = "Set intel_idle.max_cstate=N (null disables; use only as a targeted workaround).";
        };

        ignorePpc = mkEnableOption "Set processor.ignore_ppc=1 (opt-in; can be aggressive).";
      };

      # GPU tuning
      gpu = {
        useXeDriver = mkEnableOption "Force usage of Intel Xe driver (Experimental/Performance for Meteor Lake).";
      };

      suspend.s2idleByDefault = mkEnableOption "Set mem_sleep_default=s2idle (opt-in; suspend behaviour is platform-specific).";

      rapl.blacklistIntelRaplMmio = mkEnableOption "Blacklist intel_rapl_mmio (preference; depends on your power tooling).";
    };
  };

  config = mkMerge [
    {
      boot.kernelPackages = mkDefault kernelPackagesFor;

      # -----------------------------------------------------------------------
      # ZRAM Swap (Memory Performance)
      # -----------------------------------------------------------------------
      # Compressing RAM is faster than swapping to disk.
      # Essential for responsiveness on modern desktops.
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
      };
    }

    # Firmware + microcode are "hardware enablement", not a tweak.
    # Keep as safe defaults for physical machines, while allowing host overrides.
    (mkIf isPhysicalMachine {
      hardware.enableRedistributableFirmware = mkDefault true;
      hardware.cpu.intel.updateMicrocode     = mkDefault true;
    })

    {
      assertions = [
        {
          assertion = !(cfg.thinkpad.experimental && !cfg.thinkpad.enable);
          message = "my.kernel.thinkpad.experimental requires my.kernel.thinkpad.enable = true.";
        }
      ];

      warnings = optionals (cfg.useLatestKernel != null) [
        "my.kernel.useLatestKernel is deprecated; use my.kernel.kernelFlavor instead."
      ];

      # -----------------------------------------------------------------------
      # Kernel modules
      # -----------------------------------------------------------------------
      # Always-loaded modules:
      #   - msr:      RAPL / MSR access (for power/energy monitoring)
      #   - coretemp: CPU temperature sensors
      # -----------------------------------------------------------------------
      boot.kernelModules =
        [
          "msr"
          "coretemp"
        ]
        ++ optionals isPhysicalMachine (
          [
            "i2c-dev"
            "i2c-i801"
          ]
          ++ optionals cfg.thinkpad.enable [ "thinkpad_acpi" ]
          ++ optionals cfg.forceIwlwifi [ "iwlwifi" ]
        );

      # -----------------------------------------------------------------------
      # Modprobe options
      # -----------------------------------------------------------------------
      boot.extraModprobeConfig = optionalString (isPhysicalMachine && cfg.thinkpad.enable && cfg.thinkpad.experimental) ''
        options thinkpad_acpi experimental=1
      '';

      # -----------------------------------------------------------------------
      # Kernel parameters
      # -----------------------------------------------------------------------
      boot.kernelParams =
        optionals isPhysicalMachine (
          [
            "nowatchdog"             # Disable watchdog to save interrupts/power
            "split_lock_detect=off"  # Avoid micro-stutters in some games/apps
          ]
          ++ optionals cfg.tweaks.gpu.useXeDriver [
            "i915.force_probe=!7d55" # Block i915 for this ID
            "xe.force_probe=7d55"    # Force Xe driver for Meteor Lake-P [Intel Arc Graphics]
          ]
          ++ optionals cfg.tweaks.cpu.intelPstateActive [
            "intel_pstate=active"
          ]
          ++ optionals (cfg.tweaks.cpu.maxCstate != null) [
            "intel_idle.max_cstate=${builtins.toString cfg.tweaks.cpu.maxCstate}"
          ]
          ++ optionals cfg.tweaks.cpu.ignorePpc [
            "processor.ignore_ppc=1"
          ]
          ++ optionals cfg.tweaks.suspend.s2idleByDefault [
            "mem_sleep_default=s2idle"
          ]
        );

      boot.blacklistedKernelModules =
        optionals (isPhysicalMachine && cfg.tweaks.rapl.blacklistIntelRaplMmio) [
          "intel_rapl_mmio"
        ];
    }
  ];
}
