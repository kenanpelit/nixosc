# modules/nixos/power/default.nix
# ==============================================================================
# Power management (PPD-first)
# ------------------------------------------------------------------------------
# This repo prefers `power-profiles-daemon` (+ `powerprofilesctl`) for day-to-day
# power profile switching (power-saver / balanced / performance).
#
# Keep only the conflict-free parts here (e.g., battery charge thresholds) and
# avoid writing low-level CPU knobs that would fight with PPD.
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkOption types;
  cfg = config.my.power;

  isPhysicalMachine = config.my.host.isPhysicalHost or false;
  usePpd = cfg.stack == "ppd";

  thresholds = cfg.battery.chargeThresholds;

  # UPower can "Hibernate" on critical battery, but hibernation requires a
  # configured resume device. Without it, the action may fail or reboot.
  resumeDevice =
    if config.boot ? resumeDevice then config.boot.resumeDevice else null;
  canHibernate = resumeDevice != null;
in
{
  options.my.power = {
    # Profile manager for the machine.
    stack = mkOption {
      type = types.enum [ "ppd" "none" ];
      default = "ppd";
      description = "Power profile manager: 'ppd' (power-profiles-daemon / powerprofilesctl) or 'none'.";
    };

    # Battery thresholds are independent of CPU profile switching.
    battery.chargeThresholds = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable battery charge thresholds (BAT*/charge_control_*_threshold).";
      };
      start = mkOption {
        type = types.ints.between 0 100;
        default = 75;
        description = "Charge start threshold percentage (e.g., 75).";
      };
      stop = mkOption {
        type = types.ints.between 0 100;
        default = 80;
        description = "Charge stop threshold percentage (e.g., 80).";
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = thresholds.start < thresholds.stop;
          message = "my.power.battery.chargeThresholds.start must be < stop.";
        }
      ];

      # Centralize UPower configuration
      services.upower = {
        enable = true;
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
        criticalPowerAction = lib.mkDefault (if canHibernate then "Hibernate" else "PowerOff");
      };

      # PPD for interactive profile switching (`powerprofilesctl set ...`).
      services.power-profiles-daemon.enable =
        if isPhysicalMachine && usePpd then true else lib.mkForce false;

      # Ensure the CLI exists (also provides the service binary).
      environment.systemPackages = lib.optionals (isPhysicalMachine && usePpd) [
        pkgs.power-profiles-daemon
      ];

      # Most systems that want PPD also want polkit; keep it as a default.
      security.polkit.enable = lib.mkDefault true;
    }

    # Use Udev rules instead of a systemd service/bash script.
    # Why: Udev is event-based. It reapplies settings instantly on boot,
    # resume from suspend, or device redetection, ensuring thresholds never get reset.
    (mkIf (isPhysicalMachine && thresholds.enable) {
      services.udev.extraRules = ''
        SUBSYSTEM=="power_supply", KERNEL=="BAT*", \
          TEST=="charge_control_start_threshold", TEST=="charge_control_end_threshold", \
          ATTR{charge_control_start_threshold}="${builtins.toString thresholds.start}", \
          ATTR{charge_control_end_threshold}="${builtins.toString thresholds.stop}"
      '';
    })
  ];
}
