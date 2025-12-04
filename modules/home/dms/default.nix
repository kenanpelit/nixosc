# modules/home/dms/default.nix
# ==============================================================================
# DankMaterialShell (DMS) - Home Manager integration
# ==============================================================================
{ inputs, lib, config, ... }:
let
  cfg = config.my.user.dms;
in
{
  options.my.user.dms = {
    enable = lib.mkEnableOption "DankMaterialShell";
  };

  config = lib.mkIf cfg.enable {
    # Import upstream DMS Home Manager module
    imports = [ inputs.dankMaterialShell.homeModules.dankMaterialShell.default ];

    programs.dankMaterialShell.enable = true;
  };
}
