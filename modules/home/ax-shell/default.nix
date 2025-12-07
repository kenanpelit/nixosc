# modules/home/ax-shell/default.nix
# ==============================================================================
# Ax-Shell (Axenide/DMS fork) integration
# - Imports upstream HM module
# - Picks the flake package explicitly to avoid pkgs.ax-shell lookup errors
# ==============================================================================
{ inputs, lib, pkgs, config, ... }:
let
  cfg = config.my.user.ax-shell;
  axPkg = inputs.ax-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.my.user.ax-shell = {
    enable = lib.mkEnableOption "Ax-Shell Hyprland shell";
  };

  config = lib.mkIf cfg.enable {
    imports = [ inputs.ax-shell.homeManagerModules.default ];

    programs.ax-shell = {
      enable = true;
      package = axPkg;
      # Keep settings minimal; override via cfg if needed
      settings = {
        terminalCommand = "foot -e";
        wallpapersDir = "${config.home.homeDirectory}/wallpapers";
      };
    };
  };
}
