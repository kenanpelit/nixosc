# modules/home/waypaper/default.nix
# ==============================================================================
# Waypaper Configuration
# ==============================================================================
{ pkgs, lib, config, ... }:
let
  cfg = config.my.user.waypaper;
in
{
  options.my.user.waypaper = {
    enable = lib.mkEnableOption "Waypaper";
  };

  # Import config submodule only when enabled
  imports = lib.optionals cfg.enable [
    ./config.nix    # Config settings
  ];
}
