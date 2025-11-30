# modules/core/kernel/default.nix
# Kernel package, modules, params, blacklist.

{ pkgs, lib, isPhysicalHost ? false, ... }:

let
  isPhysicalMachine = isPhysicalHost;
in {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [
      "msr"      # RAPL MSR access
      "coretemp" # CPU temperature
      "i915"     # Intel iGPU
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
