# modules/home/dms/default.nix
# ==============================================================================
# DankMaterialShell (DMS) - Home Manager integration
# ==============================================================================
{ inputs, lib, config, ... }:
let
  cfg = config.my.user.dms;
in
{
  # Always import the upstream DMS Home Manager module; actual enable is gated below
  imports = [ inputs.dankMaterialShell.homeModules.dankMaterialShell.default ];

  options.my.user.dms = {
    enable = lib.mkEnableOption "DankMaterialShell";
  };

  config = lib.mkIf cfg.enable {
    programs.dankMaterialShell.enable = true;
  };
}
