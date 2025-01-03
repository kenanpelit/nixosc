{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.tmux = {
    enable = true;
    clock24 = true;
    baseIndex = 1;
    prefix = "C-a";
    terminal = "tmux-256color";
    mouse = true;
    keyMode = "vi";
    sensibleOnTop = true;

    # TPM ve oh-my-tmux konfigürasyonu
    extraConfig = let
      oh-my-tmux = pkgs.fetchFromGitHub {
        owner = "gpakosz";
        repo = ".tmux";
        rev = "065da52c67c2c9021957f8a3164003695740418d";  # 3 Ocak 2024
        sha256 = "sha256-Os0L8NFss+V+YQkEPYaew3bm+vyzVU/mOfa7OE47KRc=";
      };
      tmux-conf-local = builtins.readFile ./tmux.conf.local;
    in ''
      # Oh-my-tmux ana konfigürasyonu
      source-file ${oh-my-tmux}/.tmux.conf

      # TPM plugin yönetimi için gerekli ayarlar
      tmux_conf_update_plugins_on_launch=false
      tmux_conf_update_plugins_on_reload=false
      tmux_conf_uninstall_plugins_on_reload=false

      # Local ayarlar
      ${tmux-conf-local}
    '';

    # TMux eklentileri (NixOS paket yöneticisi üzerinden)
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = tmux-window-name;
      }
      {
        plugin = sensible;
      }
      {
        plugin = open;
        extraConfig = ''
          set -g @open-G 'https://www.google.com.tr/search?q='
        '';
      }
      {
        plugin = fzf-tmux-url;
        extraConfig = ''
          set -g @fzf-url-bind 'u'
          set -g @fzf-url-history-limit '2000'
          set -g @fzf-url-fzf-options '-w 50% -h 50% --multi -0 --no-preview --no-border'
          set -g @fzf-url-open "zen-browser"
        '';
      }
      {
        plugin = prefix-highlight;
      }
      {
        plugin = online-status;
      }
      {
        plugin = tmux-fzf;
        extraConfig = ''
          TMUX_FZF_LAUNCH_KEY="C-f"
          TMUX_FZF_ORDER="session|window|pane|command|keybinding|clipboard|process"
          TMUX_FZF_OPTIONS="-p -w 50% -h 30% -m"
        '';
      }
      {
        plugin = tmux-ssh-status;
        extraConfig = ''
          set -g status-right '#{ssh_status} | %a %h-%d %H:%M '
          set -g @ssh_auto_rename_window off
        '';
      }
      {
        plugin = update-display;
      }
      {
        plugin = fuzzback;
        extraConfig = ''
          set -g @fuzzback-bind m
          set -g @fuzzback-popup 1
          set -g @fuzzback-popup-size '70%'
          set -g @fuzzback-fzf-bind 'ctrl-y:execute-silent(echo -n {3..} | xsel -ib)+abort'
        '';
      }
      {
        plugin = tmux-nerd-font-window-name;
      }
      {
        plugin = kripto;
        extraConfig = ''
          set -g @kripto_id "celestia"
          set -g @kripto_ttl 300
          set -g @kripto_currency_symbol " $"
        '';
      }
      {
        plugin = nav-master;
      }
      {
        plugin = spotify-info;
      }
      {
        plugin = sessionx;
      }
      {
        plugin = playerctl;
        extraConfig = ''
          set -g @short_length "40"
          set -g @status_playing "▶"
          set -g @status_paused "⏸"
          set -g @status_stopped "⏹"
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-processes 'ssh psql mysql sqlite3'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'off'
          set -g @continuum-save-interval '15'
        '';
      }
      {
        plugin = sessionist;
      }
    ];
  };

  # Gerekli paketlerin yüklenmesi
  home.packages = with pkgs; [
    wl-clipboard  # Wayland clipboard desteği için
    fzf          # Fuzzy finder
    sesh         # Session manager
    #xsel         # X11 clipboard tool
    playerctl    # Media player control
  ];
}
