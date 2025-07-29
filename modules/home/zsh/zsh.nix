# modules/home/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration - Performance Optimized with Smart Features
# Author: Kenan Pelit
# Description: Core ZSH configuration with bytecode compilation and lazy loading
# ==============================================================================
{ hostname, config, pkgs, host, lib, ... }:

let
  # Performance and feature toggles
  enableInstantPrompt = true;      # P10k instant prompt for faster startup
  enablePerformanceOpts = true;    # Smart compinit and other optimizations
  enableBytecodeCompile = true;    # Compile ZSH files for 20-30% speed boost
  enableLazyLoading = true;        # Lazy load heavy tools (safe implementation)
  
  # Centralized path management
  zshDir = "${config.xdg.configHome}/zsh";
  cacheDir = "${config.xdg.cacheHome}/zsh";
  
in {
  # ==============================================================================
  # Home Activation - Bytecode Compilation for Performance
  # ==============================================================================
  home.activation = lib.mkIf enableBytecodeCompile {
    zshCompile = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "🚀 Compiling ZSH files for better performance..."
      
      # Compile main ZSH configuration files
      if [[ -f "${zshDir}/.zshrc" ]]; then
        ${pkgs.zsh}/bin/zsh -c "zcompile ${zshDir}/.zshrc" 2>/dev/null || true
      fi
      
      # Compile completion dump for faster completion loading
      if [[ -f "${cacheDir}/zcompdump" ]]; then
        ${pkgs.zsh}/bin/zsh -c "zcompile ${cacheDir}/zcompdump" 2>/dev/null || true
      fi
      
      # Compile plugin files
      find "${zshDir}/plugins" -name "*.zsh" -type f -exec ${pkgs.zsh}/bin/zsh -c "zcompile {}" \; 2>/dev/null || true
      
      echo "✅ ZSH bytecode compilation completed"
    '';
  };

  # ==============================================================================
  # Base Directory Structure
  # ==============================================================================
  home.file = {
    # Create empty .ssh directory
    ".ssh/.keep".text = "";

    # Powerlevel10k theme configuration
    "${zshDir}/p10k.zsh" = {
      enable = true;
      source = ../p10k/.p10k.zsh;
    };
  };

  # ==============================================================================
  # ZSH Program Configuration - Core Settings
  # ==============================================================================
  programs.zsh = {
    enable = true;
    dotDir = zshDir;
    autocd = true;  # Auto cd to directories by typing directory name
    
    # Enhanced autosuggestions - Better history-based suggestions
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];  # Use both history and completion
      highlight = "fg=8";                     # Subtle gray highlighting
    };
    
    # Enhanced syntax highlighting - More colors and better recognition
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" "pattern" "regexp" "root" "line" ];
      styles = {
        "alias" = "fg=magenta";           # Magenta for aliases
        "builtin" = "fg=cyan";            # Cyan for builtins
        "function" = "fg=blue";           # Blue for functions
        "command" = "fg=green";           # Green for valid commands
        "precommand" = "fg=green,underline"; # Underlined green for precommands
        "path" = "underline";             # Underline paths
        "globbing" = "fg=yellow";         # Yellow for glob patterns
      };
    };
    
    enableCompletion = true;
    
    # Session variables - Essential environment configuration
    sessionVariables = {
      # Performance optimizations
      ZSH_DISABLE_COMPFIX = "true";        # Skip unnecessary permission checks
      COMPLETION_WAITING_DOTS = "true";    # Show dots while waiting for completion
      
      # XDG Base Directory compliance
      ZDOTDIR = zshDir;
      ZSH_CACHE_DIR = cacheDir;
      ZCOMPDUMP = "${cacheDir}/zcompdump-$HOST";
      
      # Plugin configurations
      YSU_MESSAGE_POSITION = "after";      # Show you-should-use messages after command
      YSU_HARDCORE = "0";                  # Gentle alias reminders
      
      # Essential application defaults
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "most";
      TERM = "xterm-256color";
      
      # Enhanced pager configuration
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";  # Use bat for colorized man pages
      LESS = "-R --use-color -Dd+r -Du+b";            # Enhanced less with colors
      LESSHISTFILE = "-";                             # Disable less history for performance
      
      # Host aliases configuration
      HOSTALIASES = "${config.xdg.configHome}/hblock/hosts";
    };

    # -----------------------------------------------------------------------------
    # Initialization Content - Startup Performance Critical
    # -----------------------------------------------------------------------------
    initContent = lib.mkMerge [
      # Early initialization - Performance critical path
      (lib.mkBefore ''
        ${lib.optionalString enablePerformanceOpts ''
          # Performance: Skip global compinit for faster startup
          skip_global_compinit=1
          
          # Smart directory creation - only if needed
          [[ -d "${cacheDir}" ]] || mkdir -p "${cacheDir}"
          [[ -d "${zshDir}" ]] || mkdir -p "${zshDir}"
        ''}
        
        # XDG Base Directory Specification - Modern file organization
        export XDG_CONFIG_HOME="$HOME/.config"
        export XDG_CACHE_HOME="$HOME/.cache"
        export XDG_DATA_HOME="$HOME/.local/share"
        export XDG_STATE_HOME="$HOME/.local/state"

        # Smart PATH management - Avoid duplicates and ensure proper ordering
        typeset -U path PATH
        path=(
          $HOME/.local/bin
          $HOME/.iptv/bin
          $path
        )

        ${lib.optionalString enableInstantPrompt ''
          # Powerlevel10k instant prompt - Critical for sub-100ms startup
          typeset -g POWERLEVEL9K_INSTANT_PROMPT="quiet"
          [[ -r "${cacheDir}/p10k-instant-prompt-''${(%):-%n}.zsh" ]] && \
            source "${cacheDir}/p10k-instant-prompt-''${(%):-%n}.zsh"
        ''}

        # URL and Quote Magic - Essential for better terminal UX
        autoload -Uz url-quote-magic bracketed-paste-magic
        zle -N self-insert url-quote-magic
        zle -N bracketed-paste bracketed-paste-magic
        zstyle ':url-quote-magic:*' url-metas ""

        # ZSH Options - Performance and user experience focused
        setopt AUTO_CD                   # cd to directories by typing name
        setopt GLOB_DOTS                 # Include dotfiles in glob patterns
        setopt EXTENDED_GLOB             # Enable extended globbing syntax
        setopt NUMERIC_GLOB_SORT         # Sort numerically when possible
        setopt CORRECT                   # Enable command correction
        setopt COMPLETE_IN_WORD          # Complete from both ends of cursor
        setopt ALWAYS_TO_END             # Move cursor to end after completion
        
        # Disable globbing for common commands that use # character
        alias nix='noglob nix'
        alias git='noglob git'
        
        # History options - Complement programs.zsh.history configuration
        setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks from history
        setopt HIST_VERIFY               # Show expanded history before execution
        setopt HIST_FCNTL_LOCK           # Use better file locking for history
        setopt HIST_IGNORE_ALL_DUPS      # Remove all earlier duplicate entries
        setopt HIST_SAVE_NO_DUPS         # Don't save duplicate entries
        setopt HIST_FIND_NO_DUPS         # Don't find duplicates when searching
        setopt SHARE_HISTORY             # Share history between sessions
        setopt EXTENDED_HISTORY          # Save command timestamps

        # FZF Configuration - Modern fuzzy finder setup
        export FZF_DEFAULT_OPTS="--height 80% --layout=reverse --border --cycle --marker='✓' --pointer='▶' --bind='ctrl-/:toggle-preview'"
        export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
        export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {} | head -200'"
        export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"

        # Smart tool integration - Use fd if available, fallback gracefully
        if command -v fd > /dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
          export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
        fi

        ${lib.optionalString enableLazyLoading ''
          # Safe lazy loading implementation for heavy tools
          # Only lazy load non-critical tools to avoid breaking basic functionality
          
          # Lazy load NVM (Node Version Manager) - Heavy and not always needed
          function __lazy_load_nvm() {
            unfunction __lazy_load_nvm nvm
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
            nvm "$@"
          }
          alias nvm='__lazy_load_nvm'
          
          # Lazy load RVM (Ruby Version Manager) - if present
          if [[ -d "$HOME/.rvm" ]]; then
            function __lazy_load_rvm() {
              unfunction __lazy_load_rvm rvm
              [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
              rvm "$@"
            }
            alias rvm='__lazy_load_rvm'
          fi
        ''}

        # Conditional loading based on environment
        if [[ -n $SSH_CONNECTION ]]; then
          # Lightweight configuration for SSH sessions
          POWERLEVEL9K_INSTANT_PROMPT="off"
          unset MANPAGER  # Use simple pager over SSH for better compatibility
        fi

        # Direct zoxide loading - Keep simple and reliable for core navigation
        eval "$(zoxide init zsh)"
        
        # Optimized completion initialization
        autoload -Uz compinit
        ${lib.optionalString enablePerformanceOpts ''
          # Smart compinit - Only rebuild completion cache when older than 24 hours
          # This provides significant startup performance improvement
          if [[ -n ${cacheDir}/zcompdump(#qN.mh+24) ]]; then
            compinit -d "${cacheDir}/zcompdump"
          else
            compinit -C -d "${cacheDir}/zcompdump"
          fi
        ''}
        ${lib.optionalString (!enablePerformanceOpts) ''
          # Standard compinit for maximum compatibility
          compinit -d "${cacheDir}/zcompdump"
        ''}
      '')
      
      # Late initialization - Non-critical features loaded after core functionality
      (lib.mkAfter ''
        # Load P10k theme configuration
        [[ ! -f "${zshDir}/p10k.zsh" ]] || source "${zshDir}/p10k.zsh"
        
        # Add completion paths to fpath
        fpath=("${zshDir}/plugins/zsh-completions/src" "${zshDir}/completions" $fpath)
        
        # Performance: Enable completion rehashing only when needed
        zstyle ':completion:*' rehash true
      '')
    ];
   
    # -----------------------------------------------------------------------------
    # History Configuration - Optimized for large history management
    # -----------------------------------------------------------------------------
    history = {
      size = 110000;                      # Large in-memory history for better suggestions
      save = 100000;                      # Substantial persistent history
      path = "${zshDir}/history";         # Use modular history configuration
      ignoreDups = true;                  # Ignore immediate duplicates
      ignoreAllDups = true;               # Remove all duplicate entries
      ignoreSpace = true;                 # Ignore commands starting with space
      share = true;                       # Share history between sessions
      extended = true;                    # Save timestamps with commands
      expireDuplicatesFirst = true;       # When trimming, remove duplicates first
    };

    # -----------------------------------------------------------------------------
    # Completion System - Performance Optimized with Enhanced Features
    # -----------------------------------------------------------------------------
    completionInit = ''
      # Efficient color loading
      autoload -Uz colors && colors
      _comp_options+=(globdots)

      # Command line editor for editing commands in $EDITOR
      autoload -Uz edit-command-line
      zle -N edit-command-line

      # Core completion system configuration - Performance focused
      zstyle ':completion:*' completer _extensions _complete _approximate
      zstyle ':completion:*' use-cache on                                    # Enable completion caching
      zstyle ':completion:*' cache-path "${cacheDir}/.zcompcache"           # Cache location
      zstyle ':completion:*' complete true
      zstyle ':completion:*' complete-options true
      zstyle ':completion:*' file-sort modification                          # Sort by modification time
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' keep-prefix true
      zstyle ':completion:*' menu select                                     # Interactive menu selection
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}              # Use LS_COLORS for file coloring
      zstyle ':completion:*' special-dirs true                              # Complete . and .. specially
      zstyle ':completion:*' squeeze-slashes true                           # Squeeze multiple slashes
      zstyle ':completion:*' sort false                                     # Disable default sorting
      zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories

      # Enhanced visual feedback for completions
      zstyle ':completion:*:descriptions' format '%F{green}-- %d --%f'      # Green section headers
      zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'  # Red warning messages

      # FZF-Tab integration - Enhanced previews for better UX
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'eza --icons -a --group-directories-first -1 --color=always $realpath 2>/dev/null || ls -la $realpath'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
      zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
      zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
      zstyle ':fzf-tab:complete:ssh:argument-1' fzf-preview 'dig $word'
      zstyle ':fzf-tab:complete:man:*' fzf-preview 'man $word | head -50'
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-min-height 100
      zstyle ':fzf-tab:*' switch-group ',' '.'                              # Use comma and period to switch groups
    '';
    
    # -----------------------------------------------------------------------------
    # Oh-My-Zsh Configuration - Curated plugin selection
    # -----------------------------------------------------------------------------
    oh-my-zsh = {
      enable = true;
      plugins = [
        # Core functionality - Essential plugins
        "git"               # Git integration and helpful aliases
        "sudo"              # Press ESC twice to prepend sudo
        "command-not-found" # Suggest packages for unknown commands
        "history"           # Enhanced history management and search
        
        # Navigation and productivity enhancers
        "copypath"          # Copy current directory path to clipboard
        "dirhistory"        # Navigate directory history with Alt+arrows
        
        # Enhanced user experience
        "colored-man-pages" # Colorized manual pages for better readability
        "extract"           # Universal archive extractor with simple syntax
        "aliases"           # Alias management and discovery
        "safe-paste"        # Safe pasting with automatic escaping
        
        # Development tools - Lightweight utilities
        "jsontools"         # JSON formatting and validation commands
        "encode64"          # Base64 encoding/decoding utilities
        "urltools"          # URL encoding/decoding utilities
      ];
    };
  };
}

