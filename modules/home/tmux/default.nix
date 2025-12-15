# modules/home/tmux/default.nix
# ==============================================================================
# Home module for tmux: installs tmux and writes tmux.conf defaults.
# Centralize keybinds/plugins here instead of manual config management.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.tmux;

in
{
  options.my.user.tmux = {
    enable = lib.mkEnableOption "tmux configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      terminal = "screen-256color";
      shortcut = "a";
      baseIndex = 1;
      clock24 = true;
      sensibleOnTop = true;
      plugins = [ ]; # TPM will self-install from tmux.conf.local
    };

    home.sessionVariables.TMUX_PLUGIN_MANAGER_PATH = "${config.xdg.configHome}/tmux/plugins";

    xdg.configFile = {
      "tmux/tmux.conf".source = ./config/tmux.conf;
      "tmux/tmux.conf.local".source = ./config/tmux.conf.local;
      # fzf directory is populated via SOPS secret below
    };

    # Unpack encrypted fzf bundle if present (managed by sops home secrets)
    systemd.user.services.tmux-fzf-install = {
      Unit = {
        Description = "Install tmux fzf bundle from secret tar.gz";
        ConditionPathExists = "%h/.backup/fzf.tar.gz";
        After = [ "sops-nix.service" ];
        Wants = [ "sops-nix.service" ];
      };
      Service = {
        Type = "oneshot";
        # If the archive is missing/corrupt, do not fail the whole login with a red unit.
        ExecStart = pkgs.writeShellScript "install-tmux-fzf" ''
          set -euo pipefail

          src="$HOME/.backup/fzf.tar.gz"
          dest="$HOME/.config/tmux"

          # Be resilient: this is optional user convenience, not critical boot.
          if [ ! -f "$src" ]; then
            exit 0
          fi

          ${pkgs.coreutils}/bin/mkdir -p "$dest"

          if ! ${pkgs.gnutar}/bin/tar --no-same-owner -xzf "$src" -C "$dest"; then
            ${pkgs.coreutils}/bin/echo "tmux-fzf-install: failed to extract $src (continuing)" >&2
            exit 0
          fi
        '';
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
