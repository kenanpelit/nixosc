{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs) fetchFromGitHub;
  customPlugins = import ./custom-plugins.nix { inherit pkgs; };
  tmux-conf = builtins.readFile ./tmux.conf;
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
    
    extraConfig = ''
      # Settings
      ${tmux-conf}
    '';
    
    plugins = with pkgs.tmuxPlugins; [
      customPlugins.tmux-window-name
      customPlugins.tmux-ssh-status
      customPlugins.tmux-online-status
      customPlugins.tmux-tokyo-night
      
      sensible
      open
      vim-tmux-navigator
      {
        plugin = fzf-tmux-url;
        extraConfig = ''
          set -g @fzf-url-bind 'u'
          set -g @fzf-url-history-limit '2000'
          set -g @fzf-url-fzf-options '-w 50% -h 50% --multi -0 --no-preview --no-border'
          set -g @fzf-url-open "zen-browser"
        '';
      }
      prefix-highlight
      {
        plugin = tmux-fzf;
        extraConfig = ''
          set -g @tmux-fzf-launch-key 'C-f'
          set -g @tmux-fzf-order 'session|window|pane|command|keybinding|clipboard|process'
          set -g @tmux-fzf-options '-p -w 50% -h 30% -m'
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
      sessionist
      tilish
      copycat
      yank
      extrakto
      mode-indicator
      t-smart-tmux-session-manager
    ];
  };
  
  home.packages = with pkgs; [
    wl-clipboard
    fzf
    sesh
    playerctl
    xsel
  ];
}
