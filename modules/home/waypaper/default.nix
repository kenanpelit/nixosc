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

  # Submodule is internally gated; import unconditionally
  imports = [
    ./config.nix    # Config settings
  ];
}
