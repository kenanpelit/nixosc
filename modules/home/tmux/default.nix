{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs) fetchFromGitHub;
  
  # Import custom plugins
  customPlugins = import ./custom-plugins.nix { inherit pkgs; };

  # Oh-my-tmux plugin
  oh-my-tmux = fetchFromGitHub {
    owner = "gpakosz";
    repo = ".tmux";
    rev = "065da52c67c2c9021957f8a3164003695740418d";  # January 3, 2024
    sha256 = "sha256-Os0L8NFss+V+YQkEPYaew3bm+vyzVU/mOfa7OE47KRc=";
  };

  # Local tmux.conf settings
  tmux-conf-local = builtins.readFile ./tmux.conf.local;
in
{
  programs.tmux = {
    enable = true;
    clock24 = true;
    baseIndex = 1;
    prefix = "C-a";
    terminal = "tmux-256color";
    mouse = true;
    keyMode = "vi";
    sensibleOnTop = true;

    # Oh-my-tmux configuration
    extraConfig = ''
      # Oh-my-tmux main configuration
      source-file ${oh-my-tmux}/.tmux.conf

      # Local settings
      ${tmux-conf-local}
    '';

    plugins = with pkgs.tmuxPlugins; [
      # Custom plugins
      customPlugins.tmux-window-name
      customPlugins.tmux-ssh-status
      customPlugins.tmux-online-status
      
      # Standard plugins
      sensible
      open
      {
        plugin = power-theme;
        extraConfig = "";
      }
      {
        plugin = vim-tmux-navigator;
        extraConfig = "";
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
        extraConfig = "";
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
        plugin = fuzzback;
        extraConfig = ''
          set -g @fuzzback-bind m
          set -g @fuzzback-popup 1
          set -g @fuzzback-popup-size '70%'
          set -g @fuzzback-fzf-bind 'ctrl-y:execute-silent(echo -n {3..} | xsel -ib)+abort'
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
          set -g @continuum-save-interval '15'
        '';
      }
      {
        plugin = sessionist;
        extraConfig = "";
      }
      {
        plugin = tilish;
        extraConfig = "";
      }
      {
        plugin = copycat;
        extraConfig = "";
      }
      {
        plugin = yank;
        extraConfig = "";
      }
      {
        plugin = extrakto;
        extraConfig = "";
      }
      {
        plugin = mode-indicator;
        extraConfig = "";
      }
      {
        plugin = t-smart-tmux-session-manager;
        extraConfig = "";
      }
    ];
  };

  # Required packages
  home.packages = with pkgs; [
    wl-clipboard  # Wayland clipboard support
    fzf           # Fuzzy finder
    sesh          # Session manager
    playerctl     # Media player control
    xsel          # For tmux yank and other plugins
  ];
}
