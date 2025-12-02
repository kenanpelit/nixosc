# modules/core/kernel/default.nix
# ==============================================================================
# Kernel Configuration
# ==============================================================================
# Configures the Linux kernel, modules, and parameters.
# - Kernel package (latest)
# - Core modules (msr, coretemp, i915)
# - Host-specific modules (thinkpad_acpi for physical)
# - Kernel boot parameters (Intel p-state, power saving, graphics)
# - Blacklisted modules (intel_rapl_mmio to avoid conflicts)
#
# ==============================================================================

{ pkgs, lib, config, ... }:



let

  isPhysicalMachine = config.my.host.isPhysicalHost;

in

{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [
      "msr"      # RAPL MSR access
      "coretemp" # CPU temperature
      "i915"     # Intel iGPU
      "iwlwifi"  # Intel Wi-Fi (force load when autoload fails)
    ] ++ lib.optionals isPhysicalMachine [
      "thinkpad_acpi"
    ];

    extraModprobeConfig = lib.optionalString isPhysicalMachine ''
      options thinkpad_acpi experimental=1
    '';

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

    blacklistedKernelModules = [ "intel_rapl_mmio" ];
  };
}
