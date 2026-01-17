# modules/home/rmpc/default.nix
# ==============================================================================
# Home module for rmpc: installs rmpc and manages its configuration.
# Moves manual ~/.config/rmpc management to Nix.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.rmpc;
in
{
  options.my.user.rmpc = {
    enable = lib.mkEnableOption "rmpc configuration";
  };

  config = lib.mkIf cfg.enable {
    # Install rmpc package
    home.packages = [ pkgs.rmpc ];

    # Map the entire config directory to ~/.config/rmpc
    xdg.configFile."rmpc" = {
      source = ./config;
      recursive = true;
    };
  };
}
