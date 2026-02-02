# modules/nixos/kernel/default.nix
# ==============================================================================
# NixOS kernel selection and module options: packages, parameters, extra modules.
# Centralize kernel policy and overrides for every host.
#
# Philosophy:
# - Keep this module "safe by default" (no risky kernelParams globally).
# - Prefer host opt-ins for workaround/tuning params (i915, C-states, etc.).
# - Avoid forcing device-specific modules on machines where they don't apply.
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  inherit (lib) mkEnableOption mkIf mkMerge mkOption mkDefault optionalString optionals types;

  cfg = config.my.kernel;
  isPhysicalMachine = config.my.host.isPhysicalHost or false;

  effectiveKernelFlavor =
    if cfg.useLatestKernel != null then (if cfg.useLatestKernel then "latest" else "stable") else cfg.kernelFlavor;

  kernelPackagesFor =
    if effectiveKernelFlavor == "latest" then pkgs.linuxPackages_latest
    else if effectiveKernelFlavor == "lts" then (pkgs.linuxPackages_lts or pkgs.linuxPackages)
    else pkgs.linuxPackages;

in
{
  options.my.kernel = {
    kernelFlavor = mkOption {
      type = types.enum [ "latest" "stable" "lts" ];
      default = "latest";
      description = "Kernel package set: latest (pkgs.linuxPackages_latest), stable (pkgs.linuxPackages), or lts (pkgs.linuxPackages_lts).";
    };

    useLatestKernel = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Deprecated: use my.kernel.kernelFlavor. When set, true -> latest; false -> stable.";
    };

    # Force-loading is usually unnecessary because udev/module autoload works.
    # Keep this as an opt-in knob for machines that occasionally fail to bring
    # up Wi-Fi early in boot.
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

      # Intel i915 tuning (host opt-in)
      i915 = {
        enable = mkEnableOption "Enable Intel i915 tuning kernel parameters (opt-in; can cause flicker/quirks).";

        enableGuc = mkOption {
          type = types.ints.between 0 3;
          default = 3;
          description = "i915.enable_guc value (0..3).";
        };

        enableFbc = mkOption {
          type = types.ints.between 0 1;
          default = 1;
          description = "i915.enable_fbc value (0|1).";
        };

        enableDc = mkOption {
          type = types.ints.between 0 2;
          default = 2;
          description = "i915.enable_dc value (0..2).";
        };

        enablePsr = mkOption {
          type = types.ints.between 0 1;
          default = 0;
          description = "i915.enable_psr value (0|1).";
        };

        fastboot = mkOption {
          type = types.ints.between 0 1;
          default = 1;
          description = "i915.fastboot value (0|1).";
        };
      };

      suspend.s2idleByDefault = mkEnableOption "Set mem_sleep_default=s2idle (opt-in; suspend behaviour is platform-specific).";

      rapl.blacklistIntelRaplMmio = mkEnableOption "Blacklist intel_rapl_mmio (preference; depends on your power tooling).";
    };
  };

  config = mkMerge [
    {
      boot.kernelPackages = mkDefault kernelPackagesFor;
    }

    # Firmware + microcode are "hardware enablement", not a tweak.
    # Keep as safe defaults for physical machines, while allowing host overrides.
    (mkIf isPhysicalMachine {
      hardware.enableRedistributableFirmware = mkDefault true;
      hardware.enableAllFirmware             = mkDefault true;
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
      #
      # Physical-only modules:
      #   - i2c-dev:      Userspace I²C interface (/dev/i2c-*)
      #   - i2c-i801:     Intel SMBus/I²C controller driver
      #   - thinkpad_acpi: ThinkPad ACPI interface (opt-in)
      #   - iwlwifi:      Intel Wi-Fi (opt-in force-load)
      #
      # Note:
      #   - i915 is intentionally NOT force-loaded here; KMS autoloads it.
      #
      # i2c-dev + i2c-i801 are useful for:
      #   - `ddcutil` DDC/CI control (external monitor brightness/controls)
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
      # Kernel parameters (opt-in only)
      # -----------------------------------------------------------------------
      boot.kernelParams =
        optionals isPhysicalMachine (
          optionals cfg.tweaks.cpu.intelPstateActive [
            "intel_pstate=active"
          ]
          ++ optionals (cfg.tweaks.cpu.maxCstate != null) [
            "intel_idle.max_cstate=${builtins.toString cfg.tweaks.cpu.maxCstate}"
          ]
          ++ optionals cfg.tweaks.cpu.ignorePpc [
            "processor.ignore_ppc=1"
          ]
          ++ optionals cfg.tweaks.i915.enable [
            "i915.enable_guc=${builtins.toString cfg.tweaks.i915.enableGuc}"
            "i915.enable_fbc=${builtins.toString cfg.tweaks.i915.enableFbc}"
            "i915.enable_dc=${builtins.toString cfg.tweaks.i915.enableDc}"
            "i915.enable_psr=${builtins.toString cfg.tweaks.i915.enablePsr}"
            "i915.fastboot=${builtins.toString cfg.tweaks.i915.fastboot}"
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
