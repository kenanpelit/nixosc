# modules/home/terminal/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration
# Author: Kenan Pelit
# Description: Performance-optimized ZSH configuration with XDG compliance
# ==============================================================================
{ hostname, config, pkgs, host, lib, ... }:
{
  # ==============================================================================
  # Base Directory Structure
  # ==============================================================================
  home.file = {
    # Create empty .ssh directory
    ".ssh/.keep".text = "";

    # Powerlevel10k theme configuration
    ".config/zsh/p10k.zsh" = {
      enable = true;
      source = ../p10k/.p10k.zsh;
    };
  };

  # ==============================================================================
  # ZSH Configuration
  # ==============================================================================
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    # -----------------------------------------------------------------------------
    # Init Content - using the new API
    # -----------------------------------------------------------------------------
    initContent = lib.mkMerge [
      # Early initialization (previously initExtraFirst)
      (lib.mkBefore ''
        # Nix store is secure, disable unnecessary compfix checks
        export ZSH_DISABLE_COMPFIX="true"

        # XDG Base Directory Specification
        export XDG_CONFIG_HOME="$HOME/.config"
        export XDG_CACHE_HOME="$HOME/.cache"
        export XDG_DATA_HOME="$HOME/.local/share"
        export XDG_STATE_HOME="$HOME/.local/state"

        # Application Paths
        export PATH=$PATH:$HOME/.iptv/bin

        # ZSH Directory Structure
        export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
        mkdir -p "$XDG_CACHE_HOME/zsh"
        mkdir -p "$ZDOTDIR"
        
        # Completion Cache Configuration
        export ZCOMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$HOST"
        export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"

        # URL and Quote Magic Configuration
        autoload -U url-quote-magic bracketed-paste-magic
        zle -N self-insert url-quote-magic
        zle -N bracketed-paste bracketed-paste-magic
        zstyle ':url-quote-magic:*' url-metas ""
        
        # Powerlevel10k Instant Prompt
        typeset -g POWERLEVEL9K_INSTANT_PROMPT="quiet"
        [[ -r "$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh" ]] && source "$XDG_CACHE_HOME/p10k-instant-prompt-''${(%):-%n}.zsh"

        # Default Applications
        export EDITOR='nvim'
        export VISUAL='nvim'
        export PAGER='most'
        export TERM=xterm-256color

        # History Settings
        setopt HIST_REDUCE_BLANKS
        setopt HIST_VERIFY
        setopt HIST_FCNTL_LOCK
        setopt HIST_BEEP

        # FZF Configuration
        export FZF_DEFAULT_OPTS="--height 80% --layout=reverse --border --cycle --marker='✓' --pointer='▶'"
        export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
        export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
        export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

        # fd Integration
        if command -v fd > /dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
          export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
        fi
        
        # Host Aliases Configuration
        export HOSTALIASES="$XDG_CONFIG_HOME/hblock/hosts"

        # Zoxide Integration
        eval "$(zoxide init zsh)"
        
        # Initialize completion early
        autoload -Uz compinit
        compinit -d "$ZCOMPDUMP"
      '')
      
      # Late initialization (previously initExtra)
      ''
        # Load P10k Theme
        [[ ! -f "$ZDOTDIR/p10k.zsh" ]] || source "$ZDOTDIR/p10k.zsh"
        
        # Add completions to fpath
        fpath=("$ZDOTDIR/plugins/zsh-completions/src" "$ZDOTDIR/completions" $fpath)
      ''
    ];
   
    # -----------------------------------------------------------------------------
    # History Configuration
    # -----------------------------------------------------------------------------
    history = {
      size = 60000;                  # Maximum events in memory
      save = 50000;                  # Maximum events in history file
      path = "$ZDOTDIR/history";     # History file location
      ignoreDups = true;             # Ignore duplicate commands
      share = true;                  # Share history between sessions
      extended = true;               # Use extended history format
      expireDuplicatesFirst = true;  # Expire duplicates first when trimming
      ignoreSpace = true;            # Ignore commands starting with space
      ignoreAllDups = true;          # Remove older duplicate entries
    };

    # -----------------------------------------------------------------------------
    # Completion System Configuration
    # -----------------------------------------------------------------------------
    completionInit = ''
      # Basic Settings
      autoload -Uz colors && colors
      _comp_options+=(globdots)

      # Command Line Editor
      autoload -Uz edit-command-line
      zle -N edit-command-line

      # Completion System Style and Behavior
      zstyle ':completion:*' completer _extensions _complete _approximate
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR/.zcompcache"
      zstyle ':completion:*' complete true
      zstyle ':completion:*' complete-options true
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' keep-prefix true
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' squeeze-slashes true
      zstyle ':completion:*' sort false
      zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories

      # FZF-Tab Configuration
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'eza --icons -a --group-directories-first -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-min-height 100
      zstyle ':fzf-tab:*' switch-group ',' '.'
    '';
    
    # -----------------------------------------------------------------------------
    # Oh-My-Zsh Configuration
    # -----------------------------------------------------------------------------
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"               # Git integration and aliases
        "sudo"              # Press ESC twice to add sudo
        "command-not-found" # Suggest packages for unknown commands
        "history"           # Enhanced history management
        "copypath"          # Copy current directory path
        "dirhistory"        # Directory navigation shortcuts
        "colored-man-pages" # Colorized man pages
        "extract"           # Universal archive extractor
        "aliases"           # Alias management and overview
      ];
    };
  };
}

