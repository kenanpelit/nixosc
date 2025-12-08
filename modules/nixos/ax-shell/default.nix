# modules/nixos/ax-shell/default.nix
# ==============================================================================
# Ax-Shell system-side glue: registers upstream HM module and enables program
# for the main user when requested.
# ==============================================================================
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.my.user.ax-shell or { enable = false; };
  user = config.my.user.name or "kenan";
  axPkg = inputs.ax-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.my.user.ax-shell.enable = lib.mkEnableOption "Ax-Shell Hyprland shell";

  config = lib.mkIf cfg.enable {
    # Make Ax-Shell HM module available
    home-manager.sharedModules = [ inputs.ax-shell.homeManagerModules.default ];

    # Enable for primary user
    home-manager.users.${user}.programs.ax-shell = {
      enable = true;
      package = axPkg;
      settings = {
        terminalCommand = "foot -e";
        wallpapersDir = "${config.users.users.${user}.home}/wallpapers";
      };
    };
  };
}
