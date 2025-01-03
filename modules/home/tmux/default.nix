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
    shell = "${pkgs.fish}/bin/fish";
    sensibleOnTop = true;

    # Oh my tmux konfigürasyonu
    plugins = with pkgs.tmuxPlugins; [
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
        plugin = fzf;
        extraConfig = ''
          TMUX_FZF_LAUNCH_KEY="C-f"
          TMUX_FZF_ORDER="session|window|pane|command|keybinding|clipboard|process"
          TMUX_FZF_OPTIONS="-p -w 50% -h 30% -m"
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
    ];

    extraConfig = ''
      # -- ENV - kenp ----------------------------------------------------------------
      set-option -g update-environment "DISPLAY WAYLAND_DISPLAY SSH_AUTH_SOCK"
      set -ag terminal-overrides ",xterm-256color:RGB"

      # -- window & pane options ----------------------------------------------------
      set -g set-titles-string '#h ║ #S ║ #I ║ #W'
      set -g status-position top
      set -g allow-rename on
      set -g detach-on-destroy off

      # -- bindings ----------------------------------------------------------------
      bind-key A command-prompt "rename-window %%"
      bind-key -n C-l send-keys C-l \; run 'sleep 0.05' \; clear-history
      bind q confirm-before kill-window
      bind C-q confirm-before kill-pane
      bind-key x kill-pane
      bind C-a last-window

      # -- copy mode --------------------------------------------------------------
      bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "wl-copy"

      # -- theme -----------------------------------------------------------------
      # Your theme colors
      tmux_conf_theme_colour_1="#1a1b26"
      tmux_conf_theme_colour_2="#24283b"
      # ... (your other color definitions)

      # -- status line ----------------------------------------------------------
      tmux_conf_theme_status_left=" #S | #{pairing} |  #{online_status} |"
      tmux_conf_theme_status_right=" #{prefix} #{mouse} #{synchronized} | #{continuum_status} | #{playerctl_status} #{playerctl_short} | #{kripto} | #{ssh_status} | #{hostname} , ☠ | "

      # -- navigation ----------------------------------------------------------
      bind C-n next-window
      bind C-p previous-window
      set -g display-panes-time 5000
      bind -T prefix ü display-panes -d 0

      # -- clipboard ----------------------------------------------------------
      bind > choose-buffer 'run "tmux save-buffer -b %% - | wl-copy > /dev/null"'
      bind < run 'wl-paste | tmux load-buffer -'
      bind + choose-buffer 'delete-buffer -b %%'
      bind b choose-buffer

      # -- fzf snippets ------------------------------------------------------
      bind 'e' display-popup -w 60% -h 60% -E "anote -S"
      bind 'E' display-popup -w 60% -h 60% -E "anote -M"
      bind -n M-s display-popup -w 60% -h 60% -E "snippetp"
      bind -n M-n display-popup -w 60% -h 60% -E "anote"
      bind -n M-h display-popup -w 60% -h 60% -E "tmux-copy -b"
      bind -n M-b display-popup -w 60% -h 60% -E "tmux-copy -c"
      bind -n M-k display-popup -w 60% -h 60% -E "tmux-fspeed"

      # -- sesh integration --------------------------------------------------
      bind -r C-t run-shell "/usr/bin/sesh connect \"\$(/usr/bin/sesh list --icons | fzf-tmux -p 55%,60% \
          --no-sort \
          --ansi \
          --border-label ' sesh ' \
          --prompt '⚡  ' \
          --bind 'ctrl-a:change-prompt(⚡  )+reload(/usr/bin/sesh list --icons)' \
          --bind 'ctrl-t:change-prompt(🪟  )+reload(/usr/bin/sesh list -t --icons)' \
          --bind 'ctrl-g:change-prompt(⚙️  )+reload(/usr/bin/sesh list -c --icons)' \
          --bind 'ctrl-x:change-prompt(📁  )+reload(/usr/bin/sesh list -z --icons)' \
          --bind 'ctrl-d:execute(tmux kill-session -t {2..})+reload(/usr/bin/sesh list --icons)'\
      )\""
      bind -N "last-session" Tab run-shell "/usr/bin/sesh last"

      # -- repeat time -------------------------------------------------------
      set -sg repeat-time 300
    '';
  };

  # Gerekli paketlerin yüklenmesi
  home.packages = with pkgs; [
    wl-clipboard  # Wayland clipboard desteği için
    fzf          # Fuzzy finder
    sesh         # Session manager
  ];
}
