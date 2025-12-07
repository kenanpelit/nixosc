# modules/home/ax-shell/default.nix
# ==============================================================================
# Home-level Ax-Shell switch. Imports upstream HM module and enables the program
# when my.user.ax-shell.enable is set in the home profile.
# ==============================================================================
{ inputs, lib, pkgs, config, ... }:
let
  cfg = config.my.user.ax-shell;
  system = pkgs.stdenv.hostPlatform.system;
  axPkg = inputs.ax-shell.packages.${system}.default;
  overlay = final: prev: {
    ax-shell = inputs.ax-shell.packages.${system}.default;
    ax-send  = inputs.ax-shell.packages.${system}.ax-send or inputs.ax-shell.packages.${system}.default;
  };
in {
  imports = [ inputs.ax-shell.homeManagerModules.default ];

  options.my.user.ax-shell = {
    enable = lib.mkEnableOption "Ax-Shell Hyprland shell";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ overlay ];

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
