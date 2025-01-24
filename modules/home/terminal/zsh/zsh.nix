# ==============================================================================
# ZSH Configuration
# Author: Kenan Pelit
# Description: Performance-optimized ZSH configuration with XDG compliance
# ==============================================================================
{ hostname, config, pkgs, host, ... }:
{
  # ==============================================================================
  # Base Directory Structure
  # ==============================================================================
  home.file = {
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
    # Early Initialization
    # -----------------------------------------------------------------------------
    initExtraFirst = ''
      # XDG Base Directory Specification
      export XDG_CONFIG_HOME="$HOME/.config"
      export XDG_CACHE_HOME="$HOME/.cache"
      export XDG_DATA_HOME="$HOME/.local/share"
      export XDG_STATE_HOME="$HOME/.local/state"

      # ZSH Directory Structure
      export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
      mkdir -p "$XDG_CACHE_HOME/zsh"
      mkdir -p "$ZDOTDIR"
      
      # Explicitly set ZCompdump location
      export ZSHCOMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$HOST"
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
      
      # modules/core/hblock/default.nix
      export HOSTALIASES="$XDG_CONFIG_HOME/hblock/hosts"

      # Zoxide Integration
      eval "$(zoxide init zsh)"
    '';

    # -----------------------------------------------------------------------------
    # Late Initialization
    # -----------------------------------------------------------------------------
    initExtra = ''
      # Load P10k Theme
      [[ ! -f "$ZDOTDIR/p10k.zsh" ]] || source "$ZDOTDIR/p10k.zsh"
      # Add completions to fpath
      fpath=("$ZDOTDIR/plugins/zsh-completions/src" "$ZDOTDIR/completions" $fpath)
    '';
   
    # -----------------------------------------------------------------------------
    # History Configuration
    # -----------------------------------------------------------------------------
    history = {
      size = 50000;
      save = 50000;
      path = "$ZDOTDIR/history";  # ~/.config/zsh/history
      ignoreDups = true;
      share = true;
      extended = true;
      expireDuplicatesFirst = true;
      ignoreSpace = true;
      ignoreAllDups = true;
    };

    # -----------------------------------------------------------------------------
    # Completion System Configuration
    # -----------------------------------------------------------------------------
    completionInit = ''
     # Initialize completion system
     autoload -Uz compinit && compinit
 
     # Basic Settings
     autoload -Uz colors && colors
     _comp_options+=(globdots)

     # Command Line Editor
     autoload -Uz edit-command-line
     zle -N edit-command-line

     # Completion System Style and Behavior
     zstyle ':completion:*' completer _extensions _complete _approximate
     zstyle ':completion:*' use-cache on
     zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"
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
        "git"              # Git integration
        "sudo"             # ESC twice to add sudo
        "command-not-found" # Package suggestions
        "history"          # History management
        "copypath"         # Copy PWD to clipboard
        "dirhistory"       # Directory navigation
        "colored-man-pages" # Colored man pages
        "extract"          # Archive extraction
        "aliases"          # Alias management
      ];
    };
  };
}

