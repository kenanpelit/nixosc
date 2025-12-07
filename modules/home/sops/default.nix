# modules/user-modules/sops/default.nix
# ==============================================================================
# SOPS Home Manager Configuration
# ==============================================================================

{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.my.user.sops;
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
  homeDir = config.home.homeDirectory;
  secretsDir = ../../../secrets;
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  options.my.user.sops = {
    enable = lib.mkEnableOption "SOPS secrets management";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = secretsDir + "/home-secrets.enc.yaml";
      validateSopsFiles = false;
  
      age.keyFile = "${homeDir}/.config/sops/age/keys.txt";
  
      secrets = {
        "github_token" = {
          path = "${homeDir}/.config/github/token";
        };
        
        "nix_conf" = {
          path = "${homeDir}/.config/nix/nix.conf";
        };
        
        "gist_token" = {
          path = "${homeDir}/.gist";
        };
        
        "subliminal_config" = {
          sopsFile = secretsDir + "/subliminal.enc.toml";
          path = "${homeDir}/.config/subliminal/subliminal.toml";
          format = "binary";
        };
        
        # mpv configs now live in modules/home/mpv/config (no encrypted tar)
      } // lib.optionalAttrs (builtins.pathExists (secretsDir + "/fzf.enc.tar.gz")) {
        "tmux_fzf" = {
          sopsFile = secretsDir + "/fzf.enc.tar.gz";
          path = "${homeDir}/.backup/fzf.tar.gz";
          format = "binary";
        };
      };
    };
  
    # Ensure directories exist
    home.activation.createSopsDirs = dag.entryBefore ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "${homeDir}/.config/sops/age"
      $DRY_RUN_CMD mkdir -p "${homeDir}/.config/github"
      $DRY_RUN_CMD mkdir -p "${homeDir}/.config/nix"
      $DRY_RUN_CMD mkdir -p "${homeDir}/.config/subliminal"
      $DRY_RUN_CMD mkdir -p "${homeDir}/.backup"
    '';
  };
}
