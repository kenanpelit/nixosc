{ pkgs, config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  # System packages for power management
  environment.systemPackages = with pkgs; [
    acpi
    brightnessctl
    cpupower-gui
    powertop
  ];

  # Power management services
  services = {
    # Power profiles daemon
    power-profiles-daemon.enable = true;

    # UPower for battery management
    upower = {
      enable = true;
      percentageLow = 20;
      percentageCritical = 5;
      percentageAction = 3;
      criticalPowerAction = "PowerOff";
    };

    # TLP settings for advanced power management
    tlp.settings = {
      # CPU settings
      CPU_ENERGY_PERF_POLICY_ON_AC = "power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 1;

      # Platform profile settings
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "performance";

      # Intel GPU frequency settings
      INTEL_GPU_MIN_FREQ_ON_AC = 500;
      INTEL_GPU_MIN_FREQ_ON_BAT = 500;

      # Commented out settings for reference
      # INTEL_GPU_MAX_FREQ_ON_AC = 0;
      # INTEL_GPU_MAX_FREQ_ON_BAT = 0;
      # INTEL_GPU_BOOST_FREQ_ON_AC = 0;
      # INTEL_GPU_BOOST_FREQ_ON_BAT = 0;
      # PCIE_ASPM_ON_AC = "default";
      # PCIE_ASPM_ON_BAT = "powersupersave";
    };
  };

  # CPU frequency governor setting
  powerManagement.cpuFreqGovernor = "performance";

  # Kernel modules and packages
  boot = {
    kernelModules = [ "acpi_call" ];
    extraModulePackages = with config.boot.kernelPackages; [
      acpi_call
      cpupower
    ] ++ [ pkgs.cpupower-gui ];
  };
}

