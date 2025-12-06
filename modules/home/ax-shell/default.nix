# modules/home/ax-shell/default.nix
# ==============================================================================
# Ax-Shell Hyprland shell - Home Manager integration
# ==============================================================================
{ inputs, lib, config, ... }:
let
  cfg = config.my.user.ax-shell;
in
{
  # Always import upstream module; gating happens via my.user.ax-shell.enable
  imports = [ inputs.ax-shell.homeManagerModules.default ];

  options.my.user.ax-shell = {
    enable = lib.mkEnableOption "Ax-Shell desktop shell on Hyprland";

    settings = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = { };
      description = "Settings forwarded to programs.ax-shell.settings.";
      example = lib.literalExpression ''
        {
          terminalCommand = "kitty -e";
          wallpapersDir = "/home/kenan/wallpapers";
        }
      '';
    };
  };

  config = lib.mkMerge [
    # Bridge my.user.ax-shell.enable -> programs.ax-shell.enable
    { programs.ax-shell.enable = lib.mkDefault cfg.enable; }

    # Allow custom settings to be passed through
    (lib.mkIf (cfg.enable && cfg.settings != { }) {
      programs.ax-shell.settings = cfg.settings;
    })
  ];
}
