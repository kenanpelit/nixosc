# modules/home/direnv/default.nix
# ==============================================================================
# Direnv + nix-direnv integration (fast per-project dev shells).
# - Installs direnv and sets up nix-direnv
# - Enables Bash integration (Zsh is hooked in our custom zsh module)
# ==============================================================================

{ lib, config, ... }:

let
  cfg = config.my.user.direnv;
in
{
  options.my.user.direnv = {
    enable = lib.mkEnableOption "direnv + nix-direnv integration";
  };

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;

      # Zsh already runs `direnv hook zsh` in `modules/home/zsh/zsh.nix`.
      enableZshIntegration = false;
      enableBashIntegration = true;
    };

    home.sessionVariables.DIRENV_LOG_FORMAT = lib.mkDefault "";
  };
}

