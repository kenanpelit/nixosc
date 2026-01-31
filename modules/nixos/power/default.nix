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

    (mkIf (isPhysicalMachine && thresholds.enable) {
      systemd.services.battery-thresholds = {
        description = "Set battery charge thresholds";
        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-udev-settle.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "battery-thresholds" ''
            set -euo pipefail

            START="${toString thresholds.start}"
            STOP="${toString thresholds.stop}"

            write_sysfs() {
              local path="$1"
              local value="$2"
              for ((i=0;i<40;i++)); do
                if echo "$value" >"$path" 2>/dev/null; then
                  return 0
                fi
                sleep 0.05
              done
              return 1
            }

            found=0
            for bat in /sys/class/power_supply/BAT*; do
              [[ -d "$bat" ]] || continue
              found=1

              if [[ -w "$bat/charge_control_start_threshold" ]]; then
                if ! write_sysfs "$bat/charge_control_start_threshold" "$START"; then
                  echo "WARN: failed to set start threshold for $bat" >&2
                fi
              fi

              if [[ -w "$bat/charge_control_end_threshold" ]]; then
                if ! write_sysfs "$bat/charge_control_end_threshold" "$STOP"; then
                  echo "WARN: failed to set stop threshold for $bat" >&2
                fi
              fi
            done

            # No battery detected (desktop/VM) → no-op.
            [[ "$found" -eq 1 ]] || exit 0
          '';
        };
      };
    })
  ];
}
