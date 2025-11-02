# modules/home/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration - Ultra Performance Optimized with Smart Features
# Author: Kenan Pelit
# Description: Production-ready ZSH with bytecode compilation, lazy loading,
#              and intelligent caching strategies
# ==============================================================================
{ hostname, config, pkgs, host, lib, ... }:

let
  # ============================================================================
  # Performance and Feature Toggles
  # ============================================================================
  enableInstantPrompt = true;      # P10k instant prompt (sub-100ms startup)
  enablePerformanceOpts = true;    # Smart compinit and aggressive caching
  enableBytecodeCompile = true;    # Bytecode compilation (20-30% speed boost)
  enableLazyLoading = true;        # Lazy load heavy tools (saves ~50-100ms)
  enableDebugMode = false;         # Enable startup profiling (for optimization)
  
  # ============================================================================
  # Centralized Path Management - XDG Compliant
  # ============================================================================
  zshDir = "${config.xdg.configHome}/zsh";
  cacheDir = "${config.xdg.cacheHome}/zsh";
  dataDir = "${config.xdg.dataHome}/zsh";
  stateDir = "${config.xdg.stateHome}/zsh";
  
in {
  # ============================================================================
  # Home Activation - Bytecode Compilation & Cache Management
  # ============================================================================
  home.activation = lib.mkMerge [
    # Bytecode compilation for performance
    (lib.mkIf enableBytecodeCompile {
      zshCompile = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run echo "🚀 Compiling ZSH files for optimal performance..."
        
        # Function to safely compile ZSH files
        compile_zsh() {
          local file="$1"
          if [[ -f "$file" ]]; then
            ${pkgs.zsh}/bin/zsh -c "zcompile '$file'" 2>/dev/null || true
            [[ -f "$file.zwc" ]] && run echo "  ✓ Compiled: $file"
          fi
        }
        
        # Compile main configuration
        compile_zsh "${zshDir}/.zshrc"
        
        # Compile completion dump
        compile_zsh "${cacheDir}/zcompdump"
        
        # Compile all plugin files
        if [[ -d "${zshDir}/plugins" ]]; then
          while IFS= read -r -d "" file; do
            compile_zsh "$file"
          done < <(find "${zshDir}/plugins" -name "*.zsh" -type f -print0 2>/dev/null)
        fi
        
        run echo "✅ ZSH bytecode compilation completed"
      '';
    })
    
    # Cache cleanup for old files (keeps system clean)
    {
      zshCacheCleanup = lib.hm.dag.entryAfter ["writeBoundary"] ''
        run echo "🧹 Cleaning old ZSH cache files..."
        
        # Remove old completion dumps (older than 30 days)
        find "${cacheDir}" -name "zcompdump*" -mtime +30 -delete 2>/dev/null || true
        
        # Remove orphaned .zwc files
        find "${zshDir}" "${cacheDir}" -name "*.zwc" -type f 2>/dev/null | while read zwc; do
          source_file="''${zwc%.zwc}"
          [[ ! -f "$source_file" ]] && rm -f "$zwc" 2>/dev/null || true
        done
        
        run echo "✅ Cache cleanup completed"
      '';
    }
  ];

  # ============================================================================
  # Directory Structure & File Management
  # ============================================================================
  home.file = {
    # Ensure .ssh directory exists
    ".ssh/.keep".text = "";

    # Powerlevel10k theme configuration
    "${zshDir}/p10k.zsh" = {
      enable = true;
      source = ./p10k.zsh;
    };
    
    # Custom completions directory
    "${zshDir}/completions/.keep".text = "";
    
    # ZSH functions directory for custom functions
    "${zshDir}/functions/.keep".text = "";
  };

  # ============================================================================
  # ZSH Program Configuration - Core Settings
  # ============================================================================
  programs.zsh = {
    enable = true;
    dotDir = zshDir;
    autocd = true;
    
    # -------------------------------------------------------------------------
    # Enhanced Autosuggestions - Intelligent History-Based Suggestions
    # -------------------------------------------------------------------------
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
      highlight = "fg=8";
    };
    
    # -------------------------------------------------------------------------
    # Enhanced Syntax Highlighting - Comprehensive Code Recognition
    # -------------------------------------------------------------------------
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" "pattern" "cursor" ];
      styles = {
        "alias" = "fg=magenta,bold";
        "builtin" = "fg=cyan,bold";
        "function" = "fg=blue,bold";
        "command" = "fg=green";
        "precommand" = "fg=green,underline";
        "commandseparator" = "fg=yellow";
        "path" = "underline";
        "path_prefix" = "underline";
        "globbing" = "fg=yellow,bold";
        "history-expansion" = "fg=blue";
        "single-hyphen-option" = "fg=cyan";
        "double-hyphen-option" = "fg=cyan";
        "back-quoted-argument" = "fg=magenta";
        "single-quoted-argument" = "fg=yellow";
        "double-quoted-argument" = "fg=yellow";
        "dollar-quoted-argument" = "fg=yellow";
        "dollar-double-quoted-argument" = "fg=cyan";
        "back-double-quoted-argument" = "fg=cyan";
        "assign" = "fg=magenta";
      };
      patterns = {
        "rm -rf *" = "fg=white,bold,bg=red";  # Dangerous command highlighting
        "rm -fr *" = "fg=white,bold,bg=red";
      };
    };
    
    enableCompletion = true;

    # -------------------------------------------------------------------------
    # Session Variables - Environment Configuration
    # -------------------------------------------------------------------------
    sessionVariables = {
      # Performance optimizations
      ZSH_DISABLE_COMPFIX = "true";
      COMPLETION_WAITING_DOTS = "true";
      
      # XDG Base Directory compliance
      ZDOTDIR = zshDir;
      ZSH_CACHE_DIR = cacheDir;
      ZSH_DATA_DIR = dataDir;
      ZSH_STATE_DIR = stateDir;
      ZCOMPDUMP = "${cacheDir}/zcompdump-$HOST-$ZSH_VERSION";
      
      # Plugin configurations
      #YSU_MESSAGE_POSITION = "after";
      #YSU_HARDCORE = "1";
      
      # Essential application defaults
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "kitty";
      BROWSER = "brave";
      PAGER = "less";  # Changed to 'less' for better compatibility
      TERM = "xterm-256color";
      
      # Enhanced pager configuration
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANWIDTH = "100";
      LESS = "-R --use-color -Dd+r -Du+b -DS+y -DP+k";
      LESSHISTFILE = "-";
      LESSCHARSET = "utf-8";
      
      # System locale
      LC_ALL = "en_US.UTF-8";
      LANG = "en_US.UTF-8";
      
      # Host aliases configuration
      HOSTALIASES = "${config.xdg.configHome}/hblock/hosts";
      
      # History configuration
      HISTSIZE = "150000";
      SAVEHIST = "120000";
      HISTFILE = "${zshDir}/history";
    };

    # -------------------------------------------------------------------------
    # Initialization Content - Unified and Optimized
    # -------------------------------------------------------------------------
    initContent = lib.mkMerge [
      # =======================================================================
      # PHASE 1: EARLY INITIALIZATION (Performance Critical)
      # =======================================================================
      (lib.mkBefore ''
        ${lib.optionalString enableDebugMode ''
          # Debug mode: Profile startup time
          zmodload zsh/zprof
          typeset -F SECONDS
          PS4=$'%D{%M%S%.} %N:%i> '
          exec 3>&2 2>/tmp/zsh_profile.$$.log
          setopt xtrace prompt_subst
        ''}
        
        ${lib.optionalString enablePerformanceOpts ''
          # Performance: Skip global compinit (we handle it ourselves)
          skip_global_compinit=1
          
          # Create directories only if needed (avoid stat calls)
          [[ -d "${cacheDir}" ]] || mkdir -p "${cacheDir}"
          [[ -d "${zshDir}" ]] || mkdir -p "${zshDir}"
          [[ -d "${dataDir}" ]] || mkdir -p "${dataDir}"
          [[ -d "${stateDir}" ]] || mkdir -p "${stateDir}"
        ''}
        
        # XDG Base Directory - Ensure consistency
        export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
        export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"
        export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
        export XDG_STATE_HOME="''${XDG_STATE_HOME:-$HOME/.local/state}"

        # Force essential exports (prevent override by other configs)
        export EDITOR="nvim"
        export VISUAL="nvim"
        export TERMINAL="kitty"
        export TERM="xterm-256color"
        export BROWSER="brave"
        
        # Smart PATH management - Deduplicate and prioritize
        typeset -U path PATH cdpath CDPATH fpath FPATH manpath MANPATH
        path=(
          $HOME/.local/bin
          $HOME/.iptv/bin
          $HOME/bin
          /usr/local/bin
          $path
        )

        ${lib.optionalString enableInstantPrompt ''
          # Powerlevel10k instant prompt - Must be at the top
          typeset -g POWERLEVEL9K_INSTANT_PROMPT="quiet"
          if [[ -r "${cacheDir}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "${cacheDir}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi
        ''}
        
        # Disable flow control (Ctrl-S/Ctrl-Q) for better terminal UX
        stty -ixon 2>/dev/null
      '')
      
      # =======================================================================
      # PHASE 2: CORE FUNCTIONALITY
      # =======================================================================
      (''
        # ---------------------------------------------------------------------
        # ZLE Magic - Enhanced Terminal Experience
        # ---------------------------------------------------------------------
        autoload -Uz url-quote-magic bracketed-paste-magic
        zle -N self-insert url-quote-magic
        zle -N bracketed-paste bracketed-paste-magic
        
        # Additional ZLE improvements
        autoload -Uz edit-command-line
        zle -N edit-command-line
        
        # URL handling configuration
        zstyle ':url-quote-magic:*' url-metas '*?[]^()~#{}='
        zstyle ':bracketed-paste-magic' active-widgets '.self-*'

        # ---------------------------------------------------------------------
        # ZSH Options - Carefully Tuned for Performance & UX
        # ---------------------------------------------------------------------
        # Directory navigation
        setopt AUTO_CD                    # cd by typing directory name
        setopt AUTO_PUSHD                 # Push old directory onto stack
        setopt PUSHD_IGNORE_DUPS          # Don't push duplicates
        setopt PUSHD_SILENT               # Don't print directory stack
        setopt PUSHD_TO_HOME              # Push to home if no argument
        setopt CD_SILENT                  # Don't print directory changes
        
        # Globbing
        setopt EXTENDED_GLOB              # Extended globbing syntax
        setopt GLOB_DOTS                  # Include dotfiles during globbing
        setopt NUMERIC_GLOB_SORT          # Sort numerically when possible
        setopt NO_CASE_GLOB               # Case insensitive globbing
        setopt GLOB_COMPLETE              # Show completions for glob patterns
        
        # Completion
        setopt COMPLETE_IN_WORD           # Complete from cursor position
        setopt ALWAYS_TO_END              # Move cursor after completion
        setopt AUTO_MENU                  # Show menu on successive tab press
        setopt AUTO_LIST                  # List choices on ambiguous completion
        setopt AUTO_PARAM_SLASH           # Add trailing slash to directory completions
        setopt NO_MENU_COMPLETE           # Don't autoselect first completion
        setopt LIST_PACKED                # Compact completion lists
        
        # Correction
        setopt CORRECT                    # Correct commands
        setopt NO_CORRECT_ALL             # Don't correct arguments
        
        # Job control
        setopt NO_BG_NICE                 # Don't nice background jobs
        setopt NO_HUP                     # Don't kill jobs on shell exit
        setopt NO_CHECK_JOBS              # Don't warn about running jobs
        
        # Input/Output
        setopt NO_FLOW_CONTROL            # Disable start/stop characters
        setopt INTERACTIVE_COMMENTS       # Allow comments during interactive shell
        setopt RC_QUOTES                  # Allow doubled single quotes for apostrophes
        setopt COMBINING_CHARS            # Combine zero-length punctuation chars
        
        # Prompt
        setopt PROMPT_SUBST               # Enable parameter expansion for prompts
        setopt TRANSIENT_RPROMPT          # Remove right prompt on accept
        
        # Disable dangerous options
        setopt NO_CLOBBER                 # Don't overwrite files with >
        setopt NO_RM_STAR_SILENT          # Ask for confirmation on rm *
        
        # Disable globbing for specific commands
        alias nix='noglob nix'
        alias git='noglob git'
        alias find='noglob find'
        alias rsync='noglob rsync'
        alias scp='noglob scp'
        
        # ---------------------------------------------------------------------
        # History Configuration - Advanced Settings
        # ---------------------------------------------------------------------
        setopt EXTENDED_HISTORY           # Save timestamp and duration
        setopt HIST_EXPIRE_DUPS_FIRST     # Expire duplicates first
        setopt HIST_FIND_NO_DUPS          # Don't show duplicates when searching
        setopt HIST_IGNORE_ALL_DUPS       # Remove all earlier duplicates
        setopt HIST_IGNORE_DUPS           # Don't record consecutive duplicates
        setopt HIST_IGNORE_SPACE          # Ignore commands starting with space
        setopt HIST_REDUCE_BLANKS         # Remove superfluous blanks
        setopt HIST_SAVE_NO_DUPS          # Don't write duplicate entries
        setopt HIST_VERIFY                # Show before executing from history
        setopt HIST_FCNTL_LOCK            # Use fcntl for better locking
        setopt SHARE_HISTORY              # Share history between sessions
        setopt INC_APPEND_HISTORY         # Append to history immediately
        setopt HIST_NO_STORE              # Don't store history commands
        
        # History performance optimization
        HISTORY_IGNORE="(ls|cd|pwd|exit|cd ..|cd -|z *)"

        # ---------------------------------------------------------------------
        # FZF Configuration - Modern Fuzzy Finder
        # ---------------------------------------------------------------------
        export FZF_DEFAULT_OPTS="
          --height=80%
          --layout=reverse
          --info=inline
          --border=rounded
          --cycle
          --scroll-off=5
          --bind='ctrl-/:toggle-preview'
          --bind='ctrl-u:preview-half-page-up'
          --bind='ctrl-d:preview-half-page-down'
          --bind='ctrl-a:select-all'
          --bind='ctrl-y:execute-silent(echo {+} | xclip -selection clipboard)'
          --color='hl:148,hl+:154,pointer:032,marker:010,bg+:237,gutter:008'
          --pointer='▶'
          --marker='✓'
          --prompt='❯ '
        "
        
        export FZF_CTRL_T_OPTS="
          --preview='bat --style=numbers --color=always --line-range :500 {}' 
          --preview-window='right:60%:wrap'
          --bind='ctrl-/:change-preview-window(down|hidden|)'
        "
        
        export FZF_ALT_C_OPTS="
          --preview='eza --tree --level=2 --color=always --icons {} | head -200'
          --preview-window='right:60%:wrap'
        "
        
        export FZF_CTRL_R_OPTS="
          --preview='echo {}'
          --preview-window='down:3:hidden:wrap'
          --bind='?:toggle-preview'
          --bind='ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort'
          --header='Press ? to toggle preview | Press CTRL-Y to copy command'
        "

        # Use fd for FZF if available (much faster than find)
        if command -v fd &>/dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
          export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
          export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude .cache'
        fi

        # ---------------------------------------------------------------------
        # Eza (Modern ls replacement) Configuration
        # ---------------------------------------------------------------------
        if command -v eza &>/dev/null; then
          export EZA_COLORS="da=1;34:gm=1;34"
          export EZA_ICON_SPACING=2
        fi

        ${lib.optionalString enableLazyLoading ''
          # -------------------------------------------------------------------
          # Lazy Loading - Performance Optimization
          # -------------------------------------------------------------------
          
          # Generic lazy loader function
          __lazy_load() {
            local func_name="$1"
            local init_cmd="$2"
            local alias_cmds=("''${@:3}")
            
            eval "
              $func_name() {
                unfunction $func_name
                for cmd in ''${alias_cmds[@]}; do
                  unalias $cmd 2>/dev/null || true
                done
                $init_cmd
                $func_name \"\$@\"
              }
            "
            
            for cmd in "''${alias_cmds[@]}"; do
              alias $cmd="$func_name"
            done
          }
          
          # Lazy load NVM (Node Version Manager)
          if [[ -d "$HOME/.nvm" ]]; then
            __lazy_load __init_nvm \
              'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"' \
              nvm node npm npx
          fi
          
          # Lazy load RVM (Ruby Version Manager)
          if [[ -d "$HOME/.rvm" ]]; then
            __lazy_load __init_rvm \
              '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' \
              rvm ruby gem bundle
          fi
          
          # Lazy load pyenv (Python Version Manager)
          if [[ -d "$HOME/.pyenv" ]]; then
            __lazy_load __init_pyenv \
              'export PYENV_ROOT="$HOME/.pyenv"; export PATH="$PYENV_ROOT/bin:$PATH"; eval "$(pyenv init --path)"; eval "$(pyenv init -)"' \
              pyenv python pip
          fi
        ''}

        # ---------------------------------------------------------------------
        # Conditional Configuration - Adapt to environment
        # ---------------------------------------------------------------------
        if [[ -n $SSH_CONNECTION ]]; then
          # Lightweight SSH configuration
          POWERLEVEL9K_INSTANT_PROMPT="off"
          unset MANPAGER
          export PAGER="less"
          
          # SSH-specific optimizations
          setopt NO_SHARE_HISTORY
          HISTSIZE=15000
          SAVEHIST=12000
        fi

        # macOS specific settings
        if [[ "$OSTYPE" == "darwin"* ]]; then
          # macOS specific PATH
          path=(/opt/homebrew/bin /usr/local/bin $path)
        fi

        # ---------------------------------------------------------------------
        # Tool Integrations - Fast and reliable
        # ---------------------------------------------------------------------
        
        # Zoxide - Smarter cd command (keep simple, no lazy load)
        if command -v zoxide &>/dev/null; then
          eval "$(zoxide init zsh)"
        fi
        
        # Direnv - Load environment per directory
        if command -v direnv &>/dev/null; then
          eval "$(direnv hook zsh)"
        fi
        
        # ---------------------------------------------------------------------
        # Completion System - Optimized Initialization
        # ---------------------------------------------------------------------
        autoload -Uz compinit
        
        ${lib.optionalString enablePerformanceOpts ''
          # Smart compinit - Only rebuild when necessary
          # Cache for 24 hours, then rebuild
          local zcompdump="${cacheDir}/zcompdump-$HOST-$ZSH_VERSION"
          
          if [[ -n $zcompdump(#qN.mh+24) ]]; then
            # Rebuild completion cache (older than 24 hours)
            compinit -i -d "$zcompdump"
          else
            # Use cached completion (skip check for speed)
            compinit -C -i -d "$zcompdump"
          fi
          
          # Compile completion cache during background for next session
          if [[ ! -f "$zcompdump.zwc" || "$zcompdump" -nt "$zcompdump.zwc" ]]; then
            { zcompile "$zcompdump" } &!
          fi
        ''}
        
        ${lib.optionalString (!enablePerformanceOpts) ''
          # Standard compinit for compatibility
          compinit -i -d "${cacheDir}/zcompdump"
        ''}
        
        # Ensure completion system is initialized
        autoload -Uz bashcompinit && bashcompinit
      '')
      
      # =======================================================================
      # PHASE 3: LATE INITIALIZATION (Post-completion)
      # =======================================================================
      (lib.mkAfter ''
        # Load P10k theme - Must be after compinit
        if [[ -f "${zshDir}/p10k.zsh" ]]; then
          source "${zshDir}/p10k.zsh"
        fi
        
        # Add custom completion paths
        fpath=(
          "${zshDir}/completions"
          "${zshDir}/plugins/zsh-completions/src"
          "${zshDir}/functions"
          $fpath
        )
        
        # Autoload custom functions
        if [[ -d "${zshDir}/functions" ]]; then
          # Add functions directory to fpath
          fpath=("${zshDir}/functions" $fpath)
          # Autoload all functions using shell expansion
          local func_file
          for func_file in "${zshDir}/functions"/*; do
            [[ -f "$func_file" ]] && autoload -Uz "$${func_file##*/}"
          done
        fi
        
        # Rehash on completion for new commands
        zstyle ':completion:*' rehash true
        
        # Performance: Reduce completion delay
        zstyle ':completion:*' accept-exact-dirs true
        zstyle ':completion:*' use-cache on
        
        ${lib.optionalString enableDebugMode ''
          # Debug mode: Show profiling results
          unsetopt xtrace
          exec 2>&3 3>&-
          echo "\n=== ZSH Startup Profile ==="
          zprof | head -20
        ''}
      '')
    ];
   
    # -------------------------------------------------------------------------
    # History Configuration
    # -------------------------------------------------------------------------
    history = {
      size = 150000;
      save = 120000;
      path = "${zshDir}/history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;
      expireDuplicatesFirst = true;
    };

    # -------------------------------------------------------------------------
    # Completion System - Advanced Configuration
    # -------------------------------------------------------------------------
    completionInit = ''
      # Load colors
      autoload -Uz colors && colors
      
      # Enable completion for hidden files
      _comp_options+=(globdots)

      # -----------------------------------------------------------------------
      # Core Completion Configuration
      # -----------------------------------------------------------------------
      zstyle ':completion:*' completer _extensions _complete _approximate _ignored
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "${cacheDir}/.zcompcache"
      zstyle ':completion:*' complete true
      zstyle ':completion:*' complete-options true
      
      # Matching and sorting
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' file-sort modification
      zstyle ':completion:*' sort false
      zstyle ':completion:*' list-suffixes true
      zstyle ':completion:*' expand prefix suffix
      
      # Menu behavior
      zstyle ':completion:*' menu select=2
      zstyle ':completion:*' auto-description 'specify: %d'
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*' keep-prefix true
      zstyle ':completion:*' preserve-prefix '//[^/]##/'
      
      # Visual styling
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
      zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
      zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
      
      # Special completions
      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' squeeze-slashes true
      zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
      zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
      zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
      
      # Process completion
      zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
      zstyle ':completion:*:*:kill:*' menu yes select
      zstyle ':completion:*:*:kill:*' force-list always
      zstyle ':completion:*:*:kill:*' insert-ids single
      
      # Man pages
      zstyle ':completion:*:manuals' separate-sections true
      zstyle ':completion:*:manuals.*' insert-sections true
      zstyle ':completion:*:man:*' menu yes select
      
      # SSH/SCP/RSYNC
      zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
      zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
      zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
      
      # Don't complete uninteresting stuff
      zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
      zstyle ':completion:*:*:*:users' ignored-patterns adm amanda apache at avahi avahi-autoipd backup bin cacti canna clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm ldap lp mail mailman mailnull man messagebus mldonkey mysql nagios named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp usbmux uucp vcsa wwwrun xfs '_*'
      
      # FZF-Tab Integration
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'eza --icons -a --group-directories-first -1 --color=always $realpath 2>/dev/null || ls -lah --color=always $realpath'
      zstyle ':fzf-tab:complete:*:*' fzf-flags --height=80% --border=rounded --info=inline --cycle
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags --preview-window=down:3:wrap
      zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
      zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
      zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
      zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | delta'
      zstyle ':fzf-tab:complete:ssh:argument-1' fzf-preview 'dig $word'
      zstyle ':fzf-tab:complete:man:*' fzf-preview 'man $word | head -100'
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always --icons $realpath'
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-min-height 100
      zstyle ':fzf-tab:*' switch-group ',' '.'
      zstyle ':fzf-tab:*' continuous-trigger '/'
      zstyle ':fzf-tab:*' print-query alt-enter
    '';
    
    # -------------------------------------------------------------------------
    # Oh-My-Zsh - Curated Plugin Selection
    # -------------------------------------------------------------------------
    oh-my-zsh = {
      enable = true;
      plugins = [
        # Core functionality
        "git"
        "sudo"
        "command-not-found"
        "history"
        
        # Navigation
        "copypath"
        "copyfile"
        "dirhistory"
        "jump"
        
        # User experience
        "colored-man-pages"
        "extract"
        "aliases"
        "safe-paste"
        "web-search"
        
        # Development tools
        "jsontools"
        "encode64"
        "urltools"
        
        # System tools
        "systemd"
        "rsync"
      ];
    };
  };
}

