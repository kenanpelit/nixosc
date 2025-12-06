# modules/home/tmux/default.nix
# ==============================================================================
# Tmux Terminal Multiplexer Configuration (direct files + encrypted fzf payload)
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.tmux;

  mkConfigDir = path: {
    source = path;
    recursive = true;
  };
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
      plugins = [ ]; # managed via config files below
    };

    xdg.configFile = {
      "tmux/tmux.conf".source = ./config/tmux.conf;
      "tmux/tmux.conf.local".source = ./config/tmux.conf.local;
      "tmux/plugins" = mkConfigDir ./config/plugins;
      # fzf directory is populated via SOPS secret below
    };

    # Unpack encrypted fzf bundle if present (managed by sops home secrets)
    systemd.user.services.tmux-fzf-install = {
      Unit = {
        Description = "Install tmux fzf bundle from secret tar.gz";
        ConditionPathExists = "/home/${config.home.username}/.backup/fzf.tar.gz";
      };
      Service = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "install-tmux-fzf" ''
          set -e
          dest="$HOME/.config/fzf"
          mkdir -p "$dest"
          ${pkgs.gnutar}/bin/tar --no-same-owner -xzf "$HOME/.backup/fzf.tar.gz" -C "$dest"
        '';
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
