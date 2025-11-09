# modules/home/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration - Ultra Performance Optimized with Starship Prompt
# Author: Kenan Pelit
# Description: Production-ready ZSH with bytecode compilation, lazy loading,
#              and Starship prompt integration
# ==============================================================================
{ hostname, config, pkgs, host, lib, ... }:

let
  # ============================================================================
  # Performance and Feature Toggles
  # ============================================================================
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
          if [[ -f "$file" && ( ! -f "$file.zwc" || "$file" -nt "$file.zwc" ) ]]; then
            ${pkgs.zsh}/bin/zsh -c "zcompile '$file'" 2>/dev/null || true
            [[ -f "$file.zwc" ]] && run echo "  ✓ Compiled: $file"
          fi
        }
        
        # Compile main configuration
        compile_zsh "${zshDir}/.zshrc"
        
        # Compile completion dump
        compile_zsh "${cacheDir}/zcompdump"
        
        # Compile all plugin files in background for better performance
        if [[ -d "${zshDir}/plugins" ]]; then
          while IFS= read -r -d "" file; do
            compile_zsh "$file" &
          done < <(find "${zshDir}/plugins" -name "*.zsh" -type f -print0 2>/dev/null)
          wait
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
        
        # Clean old cache entries
        find "${cacheDir}/.zcompcache" -type f -mtime +7 -delete 2>/dev/null || true
        
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
    # Autosuggestions & Syntax Highlighting
    # DISABLED HERE - Handled in zsh_plugins.nix for better control
    # -------------------------------------------------------------------------
    # autosuggestion.enable = false;  # Using zsh-autosuggestions from plugins
    # syntaxHighlighting.enable = false;  # Using fast-syntax-highlighting from plugins
    
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
      
      # Essential application defaults
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERMINAL = "kitty";
      BROWSER = "brave";
      PAGER = "less";
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
      
      # Completion dump location
      ZCOMPDUMP = "${cacheDir}/zcompdump-$HOST-$ZSH_VERSION";
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
        
        # Disable flow control (Ctrl-S/Ctrl-Q) for better terminal UX
        stty -ixon 2>/dev/null
        
        # NixOS-specific environment setup
        export NIX_PATH="''${NIX_PATH:-nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos}"
        
        # Enable nix-index for command-not-found functionality
        if [[ -f "$HOME/.nix-profile/etc/profile.d/command-not-found.sh" ]]; then
          source "$HOME/.nix-profile/etc/profile.d/command-not-found.sh"
        fi
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
        setopt AUTO_CD
        setopt AUTO_PUSHD
        setopt PUSHD_IGNORE_DUPS
        setopt PUSHD_SILENT
        setopt PUSHD_TO_HOME
        setopt CD_SILENT
        
        # Globbing
        setopt EXTENDED_GLOB
        setopt GLOB_DOTS
        setopt NUMERIC_GLOB_SORT
        setopt NO_CASE_GLOB
        setopt GLOB_COMPLETE
        
        # Completion
        setopt COMPLETE_IN_WORD
        setopt ALWAYS_TO_END
        setopt AUTO_MENU
        setopt AUTO_LIST
        setopt AUTO_PARAM_SLASH
        setopt NO_MENU_COMPLETE
        setopt LIST_PACKED
        
        # Correction
        setopt CORRECT
        setopt NO_CORRECT_ALL
        
        # Job control
        setopt NO_BG_NICE
        setopt NO_HUP
        setopt NO_CHECK_JOBS
        setopt LONG_LIST_JOBS
        
        # Input/Output
        setopt NO_FLOW_CONTROL
        setopt INTERACTIVE_COMMENTS
        setopt RC_QUOTES
        setopt COMBINING_CHARS
        
        # Prompt
        setopt PROMPT_SUBST
        setopt TRANSIENT_RPROMPT
        
        # Disable dangerous options
        setopt NO_CLOBBER
        setopt NO_RM_STAR_SILENT
        
        # Performance optimizations
        setopt NO_BEEP
        setopt MULTI_OS
        
        # Disable globbing for specific commands
        alias nix='noglob nix'
        alias git='noglob git'
        alias find='noglob find'
        alias rsync='noglob rsync'
        alias scp='noglob scp'
        
        # ---------------------------------------------------------------------
        # History Configuration - Advanced Settings
        # ---------------------------------------------------------------------
        setopt EXTENDED_HISTORY
        setopt HIST_EXPIRE_DUPS_FIRST
        setopt HIST_FIND_NO_DUPS
        setopt HIST_IGNORE_ALL_DUPS
        setopt HIST_IGNORE_DUPS
        setopt HIST_IGNORE_SPACE
        setopt HIST_REDUCE_BLANKS
        setopt HIST_SAVE_NO_DUPS
        setopt HIST_VERIFY
        setopt HIST_FCNTL_LOCK
        setopt SHARE_HISTORY
        setopt INC_APPEND_HISTORY
        setopt HIST_NO_STORE
        
        # History performance optimization
        HISTORY_IGNORE="(ls|cd|pwd|exit|cd ..|cd -|z *|zi *)"

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
          --preview='bat --style=numbers --color=always --line-range :500 {} 2>/dev/null || cat {}' 
          --preview-window='right:60%:wrap'
          --bind='ctrl-/:change-preview-window(down|hidden|)'
        "
        
        export FZF_ALT_C_OPTS="
          --preview='eza --tree --level=2 --color=always --icons {} 2>/dev/null || tree -L 2 -C {} 2>/dev/null || ls -lah {}'
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
          
          # Generic lazy loader function with improved error handling
          __lazy_load() {
            local func_name="$1"
            local init_cmd="$2"
            shift 2
            local alias_cmds=("$@")
            
            eval "
              $func_name() {
                unfunction $func_name 2>/dev/null
                for cmd in \''${alias_cmds[@]}; do
                  unalias \$cmd 2>/dev/null || true
                done
                eval '$init_cmd' 2>/dev/null || return 1
                if type $func_name &>/dev/null; then
                  $func_name \"\$@\"
                else
                  command \''${alias_cmds[1]:-\''${func_name#__init_}} \"\$@\"
                fi
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
          
          # Lazy load conda if available
          if [[ -d "$HOME/.conda/miniconda3" ]] || [[ -d "$HOME/.conda/anaconda3" ]]; then
            __lazy_load __init_conda \
              'eval "$(conda shell.zsh hook 2>/dev/null)"' \
              conda
          fi
        ''}

        # ---------------------------------------------------------------------
        # Conditional Configuration - Adapt to environment
        # ---------------------------------------------------------------------
        if [[ -n $SSH_CONNECTION ]]; then
          # Lightweight SSH configuration
          unset MANPAGER
          export PAGER="less"
          
          # SSH-specific optimizations
          setopt NO_SHARE_HISTORY
          HISTSIZE=15000
          SAVEHIST=12000
        fi

        # ---------------------------------------------------------------------
        # Tool Integrations - Fast and reliable
        # ---------------------------------------------------------------------
        
        # Zoxide - Smarter cd command
        if command -v zoxide &>/dev/null; then
          eval "$(zoxide init zsh)"
        fi
        
        # Direnv - Load environment per directory
        if command -v direnv &>/dev/null; then
          eval "$(direnv hook zsh)"
          export DIRENV_LOG_FORMAT=""
        fi
        
        # Atuin - Enhanced shell history (if available)
        if command -v atuin &>/dev/null; then
          eval "$(atuin init zsh --disable-up-arrow)"
        fi
        
        # ---------------------------------------------------------------------
        # Completion System - Optimized Initialization
        # ---------------------------------------------------------------------
        autoload -Uz compinit
        
        ${lib.optionalString enablePerformanceOpts ''
          # Smart compinit - Only rebuild when necessary
          # Cache for 24 hours, then rebuild
          local zcompdump="${cacheDir}/zcompdump-$HOST-$ZSH_VERSION"
          
          # Check if we need to regenerate the completion dump
          if [[ -n $zcompdump(#qN.mh+24) ]]; then
            # Rebuild completion cache (older than 24 hours)
            compinit -i -d "$zcompdump"
            # Compile in background
            { zcompile "$zcompdump" } &!
          else
            # Use cached completion (skip check for speed)
            compinit -C -i -d "$zcompdump"
            # Compile if needed in background
            [[ ! -f "$zcompdump.zwc" || "$zcompdump" -nt "$zcompdump.zwc" ]] && { zcompile "$zcompdump" } &!
          fi
        ''}
        
        ${lib.optionalString (!enablePerformanceOpts) ''
          # Standard compinit for compatibility
          compinit -i -d "${cacheDir}/zcompdump"
        ''}
        
        # Ensure completion system is initialized
        autoload -Uz bashcompinit && bashcompinit
        
        # Add custom completion paths early
        fpath=(
          "${zshDir}/completions"
          "${zshDir}/plugins/zsh-completions/src"
          "${zshDir}/functions"
          $fpath
        )
      '')
      
      # =======================================================================
      # PHASE 3: LATE INITIALIZATION (Post-completion)
      # =======================================================================
      (lib.mkAfter ''
        # Autoload custom functions efficiently
        if [[ -d "${zshDir}/functions" ]]; then
          local func_file
          for func_file in "${zshDir}/functions"/*(.N); do
            autoload -Uz "''${func_file:t}"
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
        
        # =====================================================================
        # STARSHIP PROMPT - Initialize at the very end
        # =====================================================================
        if command -v starship &>/dev/null; then
          eval "$(starship init zsh)"
        fi
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
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'eza --icons -a --group-directories-first -1 --color=always $realpath 2>/dev/null || ls -lah --color=always $realpath 2>/dev/null'
      zstyle ':fzf-tab:complete:*:*' fzf-flags --height=80% --border=rounded --info=inline --cycle
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags --preview-window=down:3:wrap
      zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
      zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
      zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
      zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | delta'
      zstyle ':fzf-tab:complete:ssh:argument-1' fzf-preview 'dig $word'
      zstyle ':fzf-tab:complete:man:*' fzf-preview 'man $word | head -100'
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always --icons $realpath 2>/dev/null || tree -L 2 -C $realpath 2>/dev/null'
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

