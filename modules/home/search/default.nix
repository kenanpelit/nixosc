# modules/home/search/default.nix
# ==============================================================================
# Global Search Configuration
# ==============================================================================
# Configures system-wide search utilities and integrations.
# - Integrates with nix-search-tv for Nix package and option search.
#
# ==============================================================================

{ inputs, config, lib, pkgs, ... }:
let
  cfg = config.my.user.search;
in
{
  # Bring in the upstream dsearch Home Manager module
  imports = [ inputs.dsearch.homeModules.default ];

  options.my.user.search = {
    enable = lib.mkEnableOption "Search utilities configuration";

    dsearchConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "dsearch yapılandırması (boş bırakılırsa varsayılanı kullanır).";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."television/nix_channels.toml".text = ''
      [[cable_channel]]
      name = "nixpkgs"
      source_command = "nix-search-tv print"
      preview_command = "nix-search-tv preview {}"
    '';

    programs.dsearch = {
      enable = true;
      config = cfg.dsearchConfig;
    };
  };
}
