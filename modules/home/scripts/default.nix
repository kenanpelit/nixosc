# modules/home/scripts/default.nix
# ==============================================================================
# Home module packaging custom user scripts into $PATH.
# Build and install script set from modules/home/scripts/bin.
# Keep script distribution centralized here instead of manual copies.
# ==============================================================================

{ lib, config, pkgs, ... }:
let
  cfg = config.my.user.scripts;
in
{
  options.my.user.scripts = {
    enable = lib.mkEnableOption "custom user scripts";
  };

  # Submodules are internally gated; import unconditionally
  imports = [
    ./bin.nix
    ./start.nix
  ];

  config = lib.mkIf cfg.enable {
    # Auto-run bluetooth_toggle at compositor session start (Hyprland/Niri).
    #
    # We define this once (instead of per-compositor modules) to avoid conflicts
    # when multiple compositor modules are enabled in the same HM profile.
    systemd.user.services.bluetooth-auto-toggle = {
      Unit = {
        Description = "Auto toggle/connect Bluetooth on login";
        After = [ "hyprland-session.target" "niri-session.target" ];
        PartOf = [ "hyprland-session.target" "niri-session.target" ];
      };
      Service = {
        Type = "oneshot";
        TimeoutStartSec = 30;
        ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 5 && /etc/profiles/per-user/${config.home.username}/bin/bluetooth_toggle'";
      };
      Install = {
        WantedBy = [ "hyprland-session.target" "niri-session.target" ];
      };
    };
  };
}
