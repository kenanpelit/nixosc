# modules/home/dms/default.nix
# ==============================================================================
# DankMaterialShell (DMS) - Home Manager integration
# ==============================================================================
{ inputs, lib, config, pkgs, ... }:
let
  cfg = config.my.user.dms;
  dmsPkg = inputs.dankMaterialShell.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # Always import the upstream DMS Home Manager module; actual enable is gated below
  imports = [ inputs.dankMaterialShell.homeModules.dankMaterialShell.default ];

  options.my.user.dms = {
    enable = lib.mkEnableOption "DankMaterialShell";
  };

  config = lib.mkIf cfg.enable {
    programs.dankMaterialShell.enable = true;

    # Autostart DMS for the user session
    home.packages = [ dmsPkg ];

    # Ensure DMS config/cache dirs exist
    home.file.".config/DankMaterialShell/.keep".text = "";
    home.file.".cache/DankMaterialShell/.keep".text = "";

    # Default screenshot editor for DMS (can be overridden by user env)
    home.sessionVariables.DMS_SCREENSHOT_EDITOR = "swappy";

    systemd.user.services.dms = {
      Unit = {
        Description = "DankMaterialShell";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        # Keep in foreground so systemd tracks the process
        ExecStart = "${dmsPkg}/bin/dms run --session";
        Restart = "on-failure";
        RestartSec = 3;
        TimeoutStopSec = 10;
        KillSignal = "SIGINT";
        Environment = [
          "XDG_RUNTIME_DIR=/run/user/%U"
          "XDG_CURRENT_DESKTOP=Hyprland"
          "XDG_SESSION_TYPE=wayland"
        ];
        PassEnvironment = [
          "WAYLAND_DISPLAY"
          "HYPRLAND_INSTANCE_SIGNATURE"
          "HYPRLAND_SOCKET"
        ];
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
