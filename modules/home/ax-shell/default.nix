# modules/home/ax-shell/default.nix
# ==============================================================================
# Home-level Ax-Shell switch. Imports upstream HM module and enables the program
# when my.user.ax-shell.enable is set in the home profile.
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
      settings = {
        terminalCommand = "foot -e";
        wallpapersDir = "${config.home.homeDirectory}/wallpapers";
      };
    };
  };
}
