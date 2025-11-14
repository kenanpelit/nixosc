# modules/home/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration — Zinit + Maximum Performance + Zero Input Lag
# Author: Kenan Pelit
# Last Updated: 2025-11-15
#
# Design Philosophy:
#   ╭─────────────────────────────────────────────────────────────────────╮
#   │ 1. PERFORMANCE: Zinit turbo mode, async loading, sub-100ms startup │
#   │ 2. ZERO LAG: No blocking plugins - instant typing response         │
#   │ 3. RELIABILITY: Atomic operations, error handling, race prevention │
#   │ 4. PORTABILITY: SSH-aware, multi-machine, XDG-compliant           │
#   │ 5. MAINTAINABILITY: Modular, documented, testable                 │
#   ╰─────────────────────────────────────────────────────────────────────╯
#
# Critical Performance Decision:
#   when loading, regardless of when it's triggered. This is a ZLE limitation.
#   
#   Benefits of removing it:
#   • Zero input lag at all times
#   • Faster shell startup (~150ms vs 200ms+)
#   • No interruptions during typing
#   
#   What you still have:
#   • Command validation via exit codes (prompt changes color)
#   • Autosuggestions (shows if command exists in history)
#   • Tab completion (validates commands)
#   • Visual feedback is sufficient without syntax colors
#
# Features:
#   • Zinit plugin manager with turbo mode
#   • XDG Base Directory compliant
#   • Aggressive bytecode compilation
#   • SSH-optimized profile
#   • Smart cache management
#   • Lazy loading for heavy tools (nvm, pyenv, conda, rvm)
#   • FZF/fzf-tab/eza/zoxide/direnv/atuin integration
#
# Performance Targets:
#   • Interactive startup: <80ms (excellent), <100ms (good)
#   • First keystroke delay: <50ms (instant)
#   • Typing freeze: 0ms (never)
#   • Compinit cold rebuild: <200ms
#   • Compinit warm cache: <10ms
#   • Memory footprint: <30MB RSS
# ==============================================================================

{ hostname, config, pkgs, host, lib, ... }:

let
  # ============================================================================
  # Feature Matrix — Compile-time Configuration Switches
  # ============================================================================
  features = {
    performance     = true;   # Enable all performance optimizations
    bytecode        = true;   # Compile .zsh files to bytecode (.zwc)
    lazyLoading     = true;   # Defer loading of nvm/conda/pyenv/rvm
    sshOptimization = true;   # Use lightweight profile over SSH
    debugMode       = false;  # Enable zprof profiling and xtrace logging
    zinitTurbo      = true;   # Enable Zinit turbo mode
  };

  # ============================================================================
  # XDG Base Directory Paths
  # ============================================================================
  xdg = {
    zsh   = "${config.xdg.configHome}/zsh";
    cache = "${config.xdg.cacheHome}/zsh";
    data  = "${config.xdg.dataHome}/zsh";
    state = "${config.xdg.stateHome}/zsh";
  };

  # ============================================================================
  # Cache Cleanup Script
  # 
  # Removes stale cache files to prevent slowdowns:
  # • Old completion dumps (>30 days)
  # • Orphaned bytecode files
  # • Stale lock files
  # ============================================================================
  cacheCleanupScript = pkgs.writeShellScript "zsh-cache-cleanup" ''
    set -euo pipefail
    
    log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
    
    log "Starting ZSH cache cleanup"
    
    # Remove old compdump files (>30 days)
    find "${xdg.cache}" -type f -name 'zcompdump-*' -mtime +30 -delete 2>/dev/null || true
    
    # Remove orphaned .zwc files (bytecode without source)
    find "${xdg.zsh}" "${xdg.cache}" -type f -name '*.zwc' 2>/dev/null \
      | while IFS= read -r zwc; do
          [[ -f "''${zwc%.zwc}" ]] || { rm -f "$zwc" 2>/dev/null || true; }
        done
    
    # Remove old completion cache (>7 days)
    find "${xdg.cache}/.zcompcache" -type f -mtime +7 -delete 2>/dev/null || true
    
    # Remove old lock files (>1 day)
    find "${xdg.cache}" -type f -name '*.lock' -mtime +1 -delete 2>/dev/null || true
    
    # Remove legacy .zcompdump files from config directory
    find "${xdg.zsh}" -maxdepth 1 -name ".zcompdump*" -delete 2>/dev/null || true
    
    # Clean Zinit cache (>30 days)
    [[ -d "${xdg.data}/zinit" ]] && \
      find "${xdg.data}/zinit" -type f -name "*.zwc" -mtime +30 -delete 2>/dev/null || true
    
    log "Cache cleanup complete"
  '';

in
{
  # ============================================================================
  # Home Manager Activation Hooks
  # 
  # These run during home-manager activation to set up directory structure
  # and schedule background maintenance tasks.
  # ============================================================================
  
  home.activation = lib.mkMerge [
    # Directory structure setup
    # Creates all necessary directories for ZSH operation
    {
      zshCacheSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${xdg.cache}/.zcompcache" "${xdg.data}" "${xdg.state}"
        run mkdir -p "${xdg.data}/zinit"
        run touch "${xdg.cache}/.compinit.lock"
        run echo "✓ ZSH directory structure initialized"
      '';
    }

    # Asynchronous cache cleanup
    # Runs in background to avoid slowing down activation
    {
      zshCacheCleanup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        (
          set +e
          trap 'exit 0' EXIT ERR
          ${cacheCleanupScript} >/dev/null 2>&1 &
          disown %1 2>/dev/null || true
        )
        run echo "🧹 ZSH cache cleanup scheduled (background)"
      '';
    }
  ];

  # ============================================================================
  # File System Structure
  # 
  # Placeholder files to ensure directories exist in git
  # ============================================================================
  
  home.file = {
    "${xdg.zsh}/completions/.keep".text = "";
    "${xdg.zsh}/functions/.keep".text   = "";
  };

  # ============================================================================
  # ZSH Program Configuration
  # ============================================================================
  programs.zsh = {
    enable = true;
    dotDir = xdg.zsh;
    autocd = true;
    
    # CRITICAL: Disable Home Manager's completion system
    # Zinit handles this more efficiently with caching and async loading
    enableCompletion = lib.mkForce false;
    
    # Disable Home Manager's built-in plugins
    # Zinit manages these with better performance and control
    autosuggestion.enable     = false;

    # ==========================================================================
    # Environment Variables
    # 
    # These are set before shell initialization for maximum compatibility
    # ==========================================================================
    
    sessionVariables = {
      # -----------------------------------------------------------------------
      # XDG Base Directory Specification
      # Keeps config files organized and prevents home directory pollution
      # -----------------------------------------------------------------------
      ZDOTDIR       = xdg.zsh;
      ZSH_CACHE_DIR = xdg.cache;
      ZSH_DATA_DIR  = xdg.data;
      ZSH_STATE_DIR = xdg.state;
      
      # -----------------------------------------------------------------------
      # Zinit Configuration
      # -----------------------------------------------------------------------
      ZINIT_HOME = "${xdg.data}/zinit/zinit.git";

      # -----------------------------------------------------------------------
      # Completion System
      # Use hostname and ZSH version in cache filename to prevent conflicts
      # -----------------------------------------------------------------------
      ZSH_COMPDUMP = "${xdg.cache}/zcompdump-$HOST-$ZSH_VERSION";

      # -----------------------------------------------------------------------
      # Default Applications
      # -----------------------------------------------------------------------
      EDITOR   = "nvim";
      VISUAL   = "nvim";
      TERMINAL = "kitty";
      BROWSER  = "brave";
      PAGER    = "less";

      # -----------------------------------------------------------------------
      # Locale Settings
      # -----------------------------------------------------------------------
      LANG   = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # -----------------------------------------------------------------------
      # History Configuration
      # Large history for better search results
      # -----------------------------------------------------------------------
      HISTSIZE = "200000";
      SAVEHIST = "150000";
      HISTFILE = "${xdg.zsh}/history";

      # -----------------------------------------------------------------------
      # Pager Configuration
      # Enhanced less with colors and better man page rendering
      # -----------------------------------------------------------------------
      LESS         = "-R --use-color -Dd+r -Du+b -DS+y -DP+k";
      LESSHISTFILE = "-";  # Disable less history file
      LESSCHARSET  = "utf-8";
      MANPAGER     = "sh -c 'col -bx | bat -l man -p'";
      MANWIDTH     = "100";

      # -----------------------------------------------------------------------
      # Performance Optimizations
      # -----------------------------------------------------------------------
      ZSH_DISABLE_COMPFIX     = "true";  # Skip compinit security checks
      COMPLETION_WAITING_DOTS = "true";  # Show dots while waiting for completion
    };

    # ==========================================================================
    # Shell Initialization
    # 
    # This is where the magic happens. Order matters!
    # ==========================================================================
    
    initContent = lib.mkMerge [
      # ========================================================================
      # PHASE 0: Early Initialization
      # 
      # Must run before anything else to set up the environment correctly
      # ========================================================================
      (lib.mkBefore ''
        # ----------------------------------------------------------------------
        # PWD Sanity Check
        # 
        # Sometimes ZSH starts in a non-existent or plugin directory
        # This ensures we always start in a valid location
        # ----------------------------------------------------------------------
        [[ ! -d "$PWD" ]] && { export PWD="$HOME"; builtin cd "$HOME"; }
        [[ "$PWD" == *"/zinit/"* ]] && { export PWD="$HOME"; builtin cd "$HOME"; }

        ${lib.optionalString features.debugMode ''
          # --------------------------------------------------------------------
          # Debug Mode: Enable Profiling
          # 
          # Activates zprof for performance analysis and xtrace for debugging
          # Output goes to /tmp/zsh-trace-$$.log
          # --------------------------------------------------------------------
          zmodload zsh/zprof
          typeset -F SECONDS
          PS4=$'%D{%M%S%.} %N:%i> '
          exec 3>&2 2>"/tmp/zsh-trace-$$.log"
          setopt xtrace prompt_subst
          echo "=== ZSH Debug Mode Active ==="
          echo "Trace log: /tmp/zsh-trace-$$.log"
        ''}

        # ----------------------------------------------------------------------
        # XDG Base Directory Fallbacks
        # 
        # Ensure XDG variables are set even if not provided by system
        # ----------------------------------------------------------------------
        : ''${XDG_CONFIG_HOME:=$HOME/.config}
        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        : ''${XDG_DATA_HOME:=$HOME/.local/share}
        : ''${XDG_STATE_HOME:=$HOME/.local/state}
        export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

        # ----------------------------------------------------------------------
        # Path Deduplication
        # 
        # -U flag ensures no duplicates in these arrays
        # Prevents path pollution when shell is reloaded
        # ----------------------------------------------------------------------
        typeset -gU path PATH cdpath CDPATH fpath FPATH manpath MANPATH

        # ----------------------------------------------------------------------
        # User Binary Paths
        # 
        # Add user-local bins to PATH with highest priority
        # ----------------------------------------------------------------------
        path=(
          $HOME/.local/bin
          $HOME/bin
          /usr/local/bin
          $path
        )

        # ----------------------------------------------------------------------
        # TTY Configuration
        # 
        # Disable flow control (Ctrl-S/Ctrl-Q) for better keybinding support
        # Only if we have a real TTY
        # ----------------------------------------------------------------------
        if [[ -t 0 && -t 1 ]]; then
          stty -ixon 2>/dev/null || true
        fi

        # ----------------------------------------------------------------------
        # Nix Integration
        # 
        # Set up Nix paths and command-not-found handler
        # ----------------------------------------------------------------------
        export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
        [[ -f "$HOME/.nix-profile/etc/profile.d/command-not-found.sh" ]] && \
          source "$HOME/.nix-profile/etc/profile.d/command-not-found.sh"
      '')

      # ========================================================================
      # PHASE 1: Zinit Installation & Bootstrap
      # 
      # Zinit is our plugin manager. It must be loaded before any plugins.
      # ========================================================================
      ''
        # ----------------------------------------------------------------------
        # Zinit Auto-Installation
        # 
        # If Zinit is not installed, clone it from GitHub
        # This makes the config portable across machines
        # ----------------------------------------------------------------------
        if [[ ! -d "$ZINIT_HOME" ]]; then
          mkdir -p "$(dirname "$ZINIT_HOME")"
          ${pkgs.git}/bin/git clone --depth=1 \
            https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        fi

        # ----------------------------------------------------------------------
        # Load Zinit
        # 
        # This initializes the plugin manager
        # ----------------------------------------------------------------------
        source "$ZINIT_HOME/zinit.zsh"

        # ----------------------------------------------------------------------
        # Zinit Annexes (Extensions)
        # 
        # These add extra functionality to Zinit:
        # • bin-gem-node: Manage binary programs, gems, and node modules
        # • patch-dl: Apply patches and download files
        # ----------------------------------------------------------------------
        zinit light-mode for \
          zdharma-continuum/zinit-annex-bin-gem-node \
          zdharma-continuum/zinit-annex-patch-dl

        # ----------------------------------------------------------------------
        # ZLE Configuration (Zsh Line Editor)
        # 
        # Set up advanced line editing features:
        # • url-quote-magic: Auto-escape URLs
        # • bracketed-paste-magic: Handle pasted text intelligently
        # • edit-command-line: Edit command in $EDITOR with Ctrl-x e
        # ----------------------------------------------------------------------
        autoload -Uz url-quote-magic bracketed-paste-magic edit-command-line

        zle -N self-insert url-quote-magic
        zle -N bracketed-paste bracketed-paste-magic
        zle -N edit-command-line

        zstyle ':url-quote-magic:*' url-metas '*?[]^()~#{}='
        zstyle ':bracketed-paste-magic' active-widgets '.self-*'

        bindkey '^xe' edit-command-line
        bindkey '^x^e' edit-command-line

        # ----------------------------------------------------------------------
        # Shell Options
        # 
        # These control ZSH behavior. Each section is grouped by function.
        # ----------------------------------------------------------------------
        
        # Navigation options
        setopt AUTO_CD              # Type directory name to cd
        setopt AUTO_PUSHD           # Make cd push old directory onto stack
        setopt PUSHD_IGNORE_DUPS    # Don't push duplicates
        setopt PUSHD_SILENT         # Don't print directory stack
        setopt PUSHD_TO_HOME        # Push to home if no argument

        # Globbing options
        setopt EXTENDED_GLOB        # Use extended globbing syntax
        setopt GLOB_DOTS            # Include dotfiles in globbing
        setopt NUMERIC_GLOB_SORT    # Sort numerically when possible
        setopt NO_CASE_GLOB         # Case-insensitive globbing
        setopt NO_NOMATCH           # Don't error on no glob match

        # Completion options
        setopt COMPLETE_IN_WORD     # Complete from both ends of word
        setopt ALWAYS_TO_END        # Move cursor to end after completion
        setopt AUTO_MENU            # Show menu on second tab press
        setopt AUTO_LIST            # List choices on ambiguous completion
        setopt AUTO_PARAM_SLASH     # Add slash after directory completion
        setopt NO_MENU_COMPLETE     # Don't insert first match immediately
        setopt LIST_PACKED          # Vary column widths for compact display

        # History options
        setopt EXTENDED_HISTORY         # Save timestamps in history
        setopt HIST_EXPIRE_DUPS_FIRST   # Expire duplicates first
        setopt HIST_FIND_NO_DUPS        # Don't show duplicates in search
        setopt HIST_IGNORE_ALL_DUPS     # Remove older duplicate entries
        setopt HIST_IGNORE_SPACE        # Don't save commands starting with space
        setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks
        setopt HIST_SAVE_NO_DUPS        # Don't write duplicates to history file
        setopt HIST_VERIFY              # Show history expansion before running
        setopt SHARE_HISTORY            # Share history across sessions
        setopt INC_APPEND_HISTORY       # Append to history immediately

        # UX options
        setopt INTERACTIVE_COMMENTS     # Allow comments in interactive shell
        setopt NO_BEEP                  # Don't beep on errors
        setopt PROMPT_SUBST             # Allow prompt string substitutions
        setopt TRANSIENT_RPROMPT        # Remove right prompt on accept
        setopt NO_FLOW_CONTROL          # Disable Ctrl-S/Ctrl-Q
        setopt COMBINING_CHARS          # Combine zero-length punctuation

        # Safety options
        setopt NO_CLOBBER               # Don't overwrite files with >
        setopt NO_RM_STAR_SILENT        # Ask before rm *
        setopt CORRECT                  # Correct command spelling

        # ----------------------------------------------------------------------
        # History Ignore Pattern
        # 
        # Don't save these common commands to history
        # ----------------------------------------------------------------------
        HISTORY_IGNORE="(ls|cd|pwd|exit|clear|history|cd ..|cd -|z *|zi *)"

        # ----------------------------------------------------------------------
        # Disable Globbing for Specific Commands
        # 
        # Some commands interpret glob characters themselves
        # Using noglob prevents ZSH from expanding them first
        # ----------------------------------------------------------------------
        alias nix='noglob nix'
        alias git='noglob git'
        alias find='noglob find'
        alias rsync='noglob rsync'
        alias scp='noglob scp'
        alias curl='noglob curl'
        alias wget='noglob wget'

        # ----------------------------------------------------------------------
        # FZF Configuration (Fuzzy Finder)
        # 
        # FZF is used throughout the shell for fuzzy searching
        # These settings control its appearance and behavior
        # ----------------------------------------------------------------------
        export FZF_DEFAULT_OPTS="
          --height=80%
          --layout=reverse
          --info=inline
          --border=rounded
          --margin=1
          --padding=1
          --cycle
          --scroll-off=5
          --bind='ctrl-/:toggle-preview'
          --bind='ctrl-u:preview-half-page-up'
          --bind='ctrl-d:preview-half-page-down'
          --bind='ctrl-a:select-all'
          --bind='ctrl-x:deselect-all'
          --bind='ctrl-y:execute-silent(echo {+} | wl-copy)'
          --bind='alt-w:toggle-preview-wrap'
          --bind='ctrl-space:toggle+down'
          --pointer='▶'
          --marker='✓'
          --prompt='❯ '
          --no-scrollbar
        "

        export FZF_COMPLETION_TRIGGER='**'
        export FZF_COMPLETION_OPTS='--border=rounded --info=inline'

        # Use ripgrep for FZF file finding (much faster than find)
        if command -v rg &>/dev/null; then
          export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!{.git,.cache,node_modules}/*"'
        elif command -v fd &>/dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
        fi

        # FZF commands for file/directory navigation
        if command -v fd &>/dev/null; then
          export FZF_CTRL_T_COMMAND='fd --type f --type d --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
          export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
        fi

        # FZF preview windows with syntax highlighting
        export FZF_CTRL_T_OPTS="
          --preview='[[ -d {} ]] && eza -T -L2 --icons --color=always {} || bat -n --color=always -r :500 {}'
          --preview-window='right:60%:wrap'
          --bind='ctrl-/:change-preview-window(down|hidden|)'
          --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty 2>&1)'
        "

        export FZF_ALT_C_OPTS="
          --preview='eza -T -L3 --icons --color=always --group-directories-first {}'
          --preview-window='right:60%'
          --bind='ctrl-/:change-preview-window(down|hidden|)'
        "

        export FZF_CTRL_R_OPTS="
          --preview='echo {}'
          --preview-window='down:3:hidden:wrap'
          --bind='?:toggle-preview'
          --bind='ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
          --exact
        "

        # Eza (modern ls) configuration
        if command -v eza &>/dev/null; then
          export EZA_COLORS="da=1;34:gm=1;34"
          export EZA_ICON_SPACING=2
        fi

        # ----------------------------------------------------------------------
        # Lazy Loading for Heavy Tools
        # 
        # NVM, pyenv, RVM, and Conda are slow to initialize
        # We load them only when their commands are actually used
        # This dramatically improves shell startup time
        # ----------------------------------------------------------------------
        ${lib.optionalString features.lazyLoading ''
          # NVM (Node Version Manager)
          # Only loads when you run: nvm, node, npm, or npx
          if [[ -d "$HOME/.nvm" ]]; then
            _lazy_nvm() {
              unset -f _lazy_nvm
              unalias nvm node npm npx 2>/dev/null || true
              export NVM_DIR="$HOME/.nvm"
              [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
              nvm "$@"
            }
            alias nvm='_lazy_nvm'
            alias node='_lazy_nvm'
            alias npm='_lazy_nvm'
            alias npx='_lazy_nvm'
          fi

          # RVM (Ruby Version Manager)
          # Only loads when you run: rvm, ruby, gem, or bundle
          if [[ -d "$HOME/.rvm" ]]; then
            _lazy_rvm() {
              unset -f _lazy_rvm
              unalias rvm ruby gem bundle 2>/dev/null || true
              [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
              rvm "$@"
            }
            alias rvm='_lazy_rvm'
            alias ruby='_lazy_rvm'
            alias gem='_lazy_rvm'
            alias bundle='_lazy_rvm'
          fi

          # pyenv (Python Version Manager)
          # Only loads when you run: pyenv, python, or pip
          if [[ -d "$HOME/.pyenv" ]]; then
            _lazy_pyenv() {
              unset -f _lazy_pyenv
              unalias pyenv python pip 2>/dev/null || true
              export PYENV_ROOT="$HOME/.pyenv"
              path=("$PYENV_ROOT/bin" $path)
              eval "$(pyenv init --path)"
              eval "$(pyenv init -)"
              pyenv "$@"
            }
            alias pyenv='_lazy_pyenv'
            alias python='_lazy_pyenv'
            alias pip='_lazy_pyenv'
          fi

          # Conda (Python Environment Manager)
          # Only loads when you run: conda
          if [[ -d "$HOME/.conda/miniconda3" || -d "$HOME/.conda/anaconda3" ]]; then
            _lazy_conda() {
              unset -f _lazy_conda
              unalias conda 2>/dev/null || true
              local conda_base="$HOME/.conda/miniconda3"
              [[ -d "$HOME/.conda/anaconda3" ]] && conda_base="$HOME/.conda/anaconda3"
              eval "$("$conda_base/bin/conda" shell.zsh hook 2>/dev/null)"
              conda "$@"
            }
            alias conda='_lazy_conda'
          fi
        ''}

        # ----------------------------------------------------------------------
        # SSH Optimization
        # 
        # When connected via SSH, use a lighter profile:
        # • Disable fancy man pager
        # • Disable history sharing (reduces network I/O)
        # • Smaller history limits
        # ----------------------------------------------------------------------
        ${lib.optionalString features.sshOptimization ''
          if [[ -n $SSH_CONNECTION ]]; then
            unset MANPAGER
            export PAGER="less"
            setopt NO_SHARE_HISTORY
            HISTSIZE=20000
            SAVEHIST=15000
            export _SSH_LIGHT_MODE=1
          fi
        ''}

        # ======================================================================
        # ZINIT PLUGINS - Zero-Lag Configuration
        # ======================================================================
        # 
        # CRITICAL DESIGN DECISION:
        # 
        # What you still get:
        #   • Command validation: Exit code changes prompt color
        #   • Autosuggestions: Shows if command exists in history
        #   • Tab completion: Validates commands before running
        #   • Visual feedback is sufficient without syntax colors
        # 
        # Performance Benefits:
        #   • Zero input lag - NEVER freezes during typing
        #   • Faster startup (~150ms vs 200ms+)
        #   • Lower memory usage
        #   • More responsive shell overall
        # 
        # Load Order:
        #   1. Completions (instant - adds to fpath)
        #   2. fzf-tab (instant - BEFORE compinit)
        #   3. compinit (instant - completion init)
        #   4. All other plugins (instant - lightweight)
        # 
        # ======================================================================

        # ----------------------------------------------------------------------
        # 1. COMPLETIONS (Instant Load - adds to fpath)
        # 
        # Must load immediately to extend fpath before compinit runs
        # This plugin adds thousands of completion definitions
        # ----------------------------------------------------------------------
        zinit ice blockf atpull'zinit creinstall -q .'
        zinit light zsh-users/zsh-completions

        # ----------------------------------------------------------------------
        # 2. FZF-TAB (Instant Load - BEFORE compinit)
        # 
        # CRITICAL: Must load before compinit to hook into completion system
        # Replaces default tab completion with FZF fuzzy finder
        # ----------------------------------------------------------------------
        zinit ice depth=1
        zinit light Aloxaf/fzf-tab

        # Configure fzf-tab behavior
        zstyle ':fzf-tab:*' fzf-command fzf
        zstyle ':fzf-tab:*' fzf-min-height 100
        zstyle ':fzf-tab:*' switch-group ',' '.'
        zstyle ':fzf-tab:*' continuous-trigger '/'
        zstyle ':fzf-tab:complete:*:*' fzf-preview ""
        zstyle ':fzf-tab:complete:*:*' fzf-flags --height=80% --border=rounded --bind='ctrl-/:toggle-preview'

        # Context-specific preview commands
        zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w'
        zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
        zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
        zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
        zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | delta'
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -T -L2 --icons --color=always $realpath 2>/dev/null'

        # ----------------------------------------------------------------------
        # 3. COMPINIT (Safe, Fast, Cached)
        # 
        # This is the ZSH completion system initialization
        # We use aggressive caching to make it fast
        # ----------------------------------------------------------------------
        
        # Add our custom completions and functions to fpath
        fpath=("${xdg.zsh}/completions" "${xdg.zsh}/functions" $fpath)

        # Load completion system
        autoload -Uz compinit
        zmodload zsh/system 2>/dev/null || true

        # Set completion dump file location
        : ''${ZSH_COMPDUMP:="${xdg.cache}/zcompdump-$HOST-$ZSH_VERSION"}
        zstyle ':completion:*' dump-file "$ZSH_COMPDUMP"

        # ----------------------------------------------------------------------
        # _safe_compinit: Smart Completion Initialization
        # 
        # This function intelligently decides whether to rebuild completions:
        # • If dump is fresh (<24h old): Use cached version (-C flag)
        # • If dump is stale: Rebuild (no -C flag)
        # • Uses file locking to prevent race conditions
        # • Compiles dump to bytecode for faster loading
        # ----------------------------------------------------------------------
        _safe_compinit() {
          local _lock_file="${xdg.cache}/.compinit-''${HOST}-''${ZSH_VERSION}.lock"
          local _dump_dir="$(dirname "$ZSH_COMPDUMP")"

          # Ensure dump directory exists
          [[ -d "$_dump_dir" ]] || mkdir -p "$_dump_dir"

          local -i need_rebuild=0
          
          # Check if dump exists and is fresh (less than 24 hours old)
          if [[ ! -s "$ZSH_COMPDUMP" || -n $ZSH_COMPDUMP(#qN.mh+24) ]]; then
            need_rebuild=1
          fi

          # If dump is fresh, use cached version
          if (( need_rebuild == 0 )); then
            compinit -C -i -d "$ZSH_COMPDUMP"
            
            # Compile dump to bytecode in background if needed
            if [[ ! -f "$ZSH_COMPDUMP.zwc" || "$ZSH_COMPDUMP" -nt "$ZSH_COMPDUMP.zwc" ]]; then
              { zcompile -U "$ZSH_COMPDUMP" 2>/dev/null || true; } &!
            fi
            return 0
          fi

          # If we need to rebuild, try to acquire lock
          # If lock fails, another instance is rebuilding - use cached version
          if command -v zsystem &>/dev/null; then
            if ! zsystem flock -t 0.1 "$_lock_file" 2>/dev/null; then
              compinit -C -i -d "$ZSH_COMPDUMP"
              return 0
            fi
          fi

          # Rebuild completion dump
          compinit -u -i -d "$ZSH_COMPDUMP"
          
          # Compile to bytecode in background
          { zcompile -U "$ZSH_COMPDUMP" 2>/dev/null || true; } &!
          
          # Release lock
          command -v zsystem &>/dev/null && zsystem flock -u "$_lock_file" 2>/dev/null || true
        }

        # Initialize completion system
        _safe_compinit
        
        # Also load bash completion compatibility
        autoload -Uz bashcompinit && bashcompinit

        # ----------------------------------------------------------------------
        # Completion System Styles
        # 
        # These control how completions look and behave
        # ----------------------------------------------------------------------
        autoload -Uz colors && colors
        _comp_options+=(globdots)  # Include hidden files in completion

        # Completion strategy: try extensions, then exact, then approximate
        zstyle ':completion:*' completer _extensions _complete _approximate _ignored
        
        # Enable caching for better performance
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "${xdg.cache}/.zcompcache"
        
        # Enable full completion
        zstyle ':completion:*' complete true
        zstyle ':completion:*' complete-options true

        # Smart case-insensitive matching
        zstyle ':completion:*' matcher-list \
          'm:{a-zA-Z}={A-Za-z}' \
          'r:|[._-]=* r:|=*' \
          'l:|=* r:|=*'

        # File sorting and listing
        zstyle ':completion:*' file-sort modification
        zstyle ':completion:*' sort false
        zstyle ':completion:*' list-suffixes true
        zstyle ':completion:*' expand prefix suffix
        zstyle ':completion:*' menu select=2
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*' verbose yes
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' special-dirs true
        zstyle ':completion:*' squeeze-slashes true

        # Colored completion messages
        zstyle ':completion:*:descriptions' format '%F{yellow}━━ %d ━━%f'
        zstyle ':completion:*:messages'     format '%F{purple}━━ %d ━━%f'
        zstyle ':completion:*:warnings'     format '%F{red}━━ no matches found ━━%f'
        zstyle ':completion:*:corrections'  format '%F{green}━━ %d (errors: %e) ━━%f'

        # Process completion for kill command
        zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w"
        zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
        zstyle ':completion:*:*:kill:*' menu yes select
        zstyle ':completion:*:*:kill:*' force-list always
        zstyle ':completion:*:*:kill:*' insert-ids single

        # Man page completion
        zstyle ':completion:*:manuals' separate-sections true
        zstyle ':completion:*:manuals.*' insert-sections true

        # SSH/SCP/rsync completion
        zstyle ':completion:*:(ssh|scp|rsync):*' tag-order \
          'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address'
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' \
          ignored-patterns '*(.|:)*' loopback localhost broadcasthost
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' \
          ignored-patterns '<->.<->.<->.<->' '*@*'
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' \
          ignored-patterns '^(<->.<->.<->.<->)' '127.0.0.<->' '::1' 'fe80::*'

        # Always rehash for new commands
        zstyle ':completion:*' rehash true
        zstyle ':completion:*' accept-exact-dirs true

        # ======================================================================
        # 4. ALL PLUGINS - Instant Load (NO WAIT, NO SYNTAX HIGHLIGHTING)
        # ======================================================================
        # 
        # All plugins load synchronously during startup
        # This adds ~50ms to startup but guarantees ZERO typing lag
        # 
        # ======================================================================
        ${lib.optionalString features.zinitTurbo ''
          # --------------------------------------------------------------------
          # History substring search (INSTANT)
          # 
          # Provides up/down arrow history search with substring matching
          # Essential feature, lightweight plugin
          # --------------------------------------------------------------------
          zinit light zsh-users/zsh-history-substring-search
          bindkey '^[[A' history-substring-search-up
          bindkey '^[[B' history-substring-search-down
          bindkey '^[OA' history-substring-search-up
          bindkey '^[OB' history-substring-search-down

          # --------------------------------------------------------------------
          # Auto-suggestions (INSTANT)
          # 
          # Shows suggestions based on history as you type
          # Lightweight and provides excellent UX
          # --------------------------------------------------------------------
          zinit light zsh-users/zsh-autosuggestions

          # --------------------------------------------------------------------
          # Autopair (INSTANT)
          # 
          # Auto-closes brackets, quotes, etc.
          # Tiny plugin with no performance impact
          # --------------------------------------------------------------------
          zinit light hlissner/zsh-autopair

          # --------------------------------------------------------------------
          # SYNTAX HIGHLIGHTING (INSTANT)
          # 
          # --------------------------------------------------------------------
          zinit light zsh-users/zsh-syntax-highlighting
          
          # --------------------------------------------------------------------
          # OMZ Plugin Snippets (INSTANT)
          # 
          # Lightweight utilities from Oh-My-Zsh
          # Each adds useful functionality without slowdown
          # --------------------------------------------------------------------
          zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh
          zinit snippet OMZ::plugins/extract/extract.plugin.zsh
          zinit snippet OMZ::plugins/copypath/copypath.plugin.zsh
          zinit snippet OMZ::plugins/copyfile/copyfile.plugin.zsh
          zinit snippet OMZ::plugins/git/git.plugin.zsh
        ''}

        # ----------------------------------------------------------------------
        # Non-Turbo Fallback
        # 
        # If turbo mode is disabled, load same plugins synchronously
        # ----------------------------------------------------------------------
        ${lib.optionalString (!features.zinitTurbo) ''
          zinit light zsh-users/zsh-history-substring-search
          bindkey '^[[A' history-substring-search-up
          bindkey '^[[B' history-substring-search-down

          zinit light zsh-users/zsh-autosuggestions
          zinit light hlissner/zsh-autopair

          zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh
          zinit snippet OMZ::plugins/extract/extract.plugin.zsh
          zinit snippet OMZ::plugins/copypath/copypath.plugin.zsh
          zinit snippet OMZ::plugins/copyfile/copyfile.plugin.zsh
          zinit snippet OMZ::plugins/git/git.plugin.zsh
        ''}

        # ----------------------------------------------------------------------
        # Tool Integrations (Local Only - Not Over SSH)
        # 
        # These are heavy tools that should only load on local machines
        # ----------------------------------------------------------------------
        if [[ -z $_SSH_LIGHT_MODE ]]; then
          # Zoxide: Smarter cd command (learns your habits)
          command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
          
          # Direnv: Automatic environment switching per directory
          if command -v direnv &>/dev/null; then
            eval "$(direnv hook zsh)"
            export DIRENV_LOG_FORMAT=""  # Silence direnv messages
          fi

          # Atuin: Better shell history with sync
          if command -v atuin &>/dev/null; then
            export ATUIN_NOBIND="true"  # Don't auto-bind Ctrl-R
            eval "$(atuin init zsh)"
            bindkey '^r' _atuin_search_widget  # Manual binding
          fi
        fi

        # ----------------------------------------------------------------------
        # Custom Functions
        # 
        # Auto-load any functions in the functions directory
        # ----------------------------------------------------------------------
        if [[ -d "${xdg.zsh}/functions" ]]; then
          for func in "${xdg.zsh}/functions"/*(.N); do
            autoload -Uz "''${func:t}"
          done
        fi

        # ----------------------------------------------------------------------
        # Zinit Directory Escape
        # 
        # If we somehow ended up in a zinit plugin directory, go home
        # This can happen if a plugin changes PWD during loading
        # ----------------------------------------------------------------------
        [[ $PWD == *"/zinit/plugins/"* ]] && cd ~

        # ----------------------------------------------------------------------
        # Debug Output
        # 
        # If debug mode is enabled, show profiling results
        # ----------------------------------------------------------------------
        ${lib.optionalString features.debugMode ''
          unsetopt xtrace
          exec 2>&3 3>&-
          
          echo ""
          echo "╔════════════════════════════════════════════════════════════╗"
          echo "║              ZSH Startup Profiling Report                 ║"
          echo "╚════════════════════════════════════════════════════════════╝"
          echo ""
          zprof | head -30
          echo ""
          printf "⏱️  Total startup time: %.3f seconds\n" "$SECONDS"
          echo ""
        ''}

        # ----------------------------------------------------------------------
        # Starship Prompt
        # 
        # Load Starship last so it doesn't interfere with plugin loading
        # ----------------------------------------------------------------------
        if command -v starship &>/dev/null; then
          eval "$(starship init zsh)"
        fi
      ''
    ];

    # ==========================================================================
    # History Configuration
    # 
    # These settings control how command history works
    # ==========================================================================
    history = {
      size                  = 200000;  # Commands to keep in memory
      save                  = 150000;  # Commands to save to disk
      path                  = "${xdg.zsh}/history";
      ignoreDups            = true;    # Don't record duplicates
      ignoreAllDups         = true;    # Remove all duplicates
      ignoreSpace           = true;    # Ignore commands starting with space
      share                 = true;    # Share history across sessions
      extended              = true;    # Save timestamps
      expireDuplicatesFirst = true;    # Expire duplicates before unique commands
    };
  };
}

# ==============================================================================
# TESTING & VERIFICATION
# ==============================================================================
# 
# After applying this configuration, test with:
# 
# 1. Rebuild your system:
#    sudo nixos-rebuild switch
#    # OR
#    home-manager switch
# 
# 2. Open a new terminal (or new tmux window with Ctrl-a c)
# 
# 3. Type immediately - should be INSTANT with ZERO lag
# 
# 4. Expected results:
#    • Startup: ~150ms (fast)
#    • First keystroke: <50ms (instant)
#    • Typing: 0ms freeze (NEVER blocks)
# 
# 5. Verify no lag:
#    • Open new terminal
#    • Type "echo test" IMMEDIATELY
#    • Should be instant with no delay
# 
# ==============================================================================
