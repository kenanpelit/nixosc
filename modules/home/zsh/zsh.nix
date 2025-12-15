# modules/home/zsh/zsh.nix
# ==============================================================================
# Zsh configuration using zinit for fast, ordered plugin loading.
# Documents critical load order to keep completions/widgets stable.
# Centralize Zsh rc/profile logic here via Home Manager.
# ==============================================================================

{ config, pkgs, lib, ... }:

let
  # ============================================================================
  # Feature Matrix — Compile-time Configuration Switches
  # ============================================================================
  features = {
    lazyLoading = true;   # Defer loading of nvm/conda/pyenv/rvm
    debugMode   = false;  # Enable zprof profiling and xtrace logging
    zinitTurbo  = true;   # Enable Zinit plugin loading
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
  # • Orphaned bytecode files (.zwc without source)
  # • Stale lock files (>1 day)
  # • Old completion cache entries (>7 days)
  # • Legacy .zcompdump files in wrong location
  # 
  # Runs asynchronously during home-manager activation
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

  cfg = config.my.user.zsh;
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;

in
lib.mkIf cfg.enable {
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
      zshCacheSetup = dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${xdg.cache}/.zcompcache" "${xdg.data}" "${xdg.state}"
        run mkdir -p "${xdg.data}/zinit"
        run echo "✓ ZSH directory structure initialized"
      '';
    }

    # Asynchronous cache cleanup
    # Runs in background to avoid slowing down activation
    {
      zshCacheCleanup = dag.entryAfter [ "writeBoundary" ] ''
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
  # These prevent git from ignoring empty directories
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
    # Zinit handles this more efficiently with caching and proper sequencing
    enableCompletion = lib.mkForce false;
    
    # CRITICAL: Disable Home Manager's built-in plugins
    # We use Zinit versions which are faster and more configurable
    # Enabling both causes conflicts and performance issues
    autosuggestion.enable     = false;
    syntaxHighlighting.enable = false;

    # ==========================================================================
    # Environment Variables
    # 
    # These are set before shell initialization for maximum compatibility
    # They affect both interactive and non-interactive shells
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
      # Where Zinit stores plugins and its own code
      # -----------------------------------------------------------------------
      ZINIT_HOME = "${xdg.data}/zinit/zinit.git";

      # -----------------------------------------------------------------------
      # Completion System
      # Use hostname and ZSH version in cache filename to prevent conflicts
      # when using the same home directory from different machines/versions
      # -----------------------------------------------------------------------
      ZSH_COMPDUMP = "${xdg.cache}/zcompdump-$HOST-$ZSH_VERSION";

      # -----------------------------------------------------------------------
      # Default Applications
      # These are used by various tools and scripts
      # -----------------------------------------------------------------------
      EDITOR   = "nvim";
      VISUAL   = "nvim";
      TERMINAL = "kitty";
      BROWSER  = "brave";
      PAGER    = "less";

      # -----------------------------------------------------------------------
      # Locale Settings
      # Ensures consistent UTF-8 support across all programs
      # -----------------------------------------------------------------------
      LANG   = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # -----------------------------------------------------------------------
      # History Configuration
      # Large history for better search results and analysis
      # -----------------------------------------------------------------------
      HISTSIZE = "200000";  # Commands to keep in memory
      SAVEHIST = "150000";  # Commands to save to disk
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
    # 
    # The initialization is split into phases:
    # 1. Early setup (PWD, XDG, PATH, debugging)
    # 2. Zinit bootstrap and plugin loading
    # 3. Tool integrations (zoxide, direnv, atuin)
    # 4. Custom functions and final setup
    # ==========================================================================
    
    initContent = lib.mkMerge [
      # ========================================================================
      # PHASE 0: Early Initialization
      # 
      # Must run before anything else to set up the environment correctly
      # These settings are fundamental and affect everything that follows
      # ========================================================================
      (lib.mkBefore ''
        # ----------------------------------------------------------------------
        # PWD Sanity Check
        # 
        # Sometimes ZSH starts in a non-existent or plugin directory
        # This can happen after directory removal or during plugin updates
        # Ensures we always start in a valid location
        # ----------------------------------------------------------------------
        [[ ! -d "$PWD" ]] && { export PWD="$HOME"; builtin cd "$HOME"; }
        [[ "$PWD" == *"/zinit/"* ]] && { export PWD="$HOME"; builtin cd "$HOME"; }

        ${lib.optionalString features.debugMode ''
          # --------------------------------------------------------------------
          # Debug Mode: Enable Profiling
          # 
          # Activates zprof for performance analysis and xtrace for debugging
          # Output goes to /tmp/zsh-trace-$$.log for inspection
          # 
          # Usage:
          #   1. Set debugMode = true in features
          #   2. Rebuild config
          #   3. Open new shell
          #   4. Check /tmp/zsh-trace-$$.log for execution trace
          #   5. zprof output shows at the end
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
        # Some systems don't set these by default
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
        # Prevents path pollution when shell is reloaded or nested
        # This is important for performance and correctness
        # ----------------------------------------------------------------------
        typeset -gU path PATH cdpath CDPATH fpath FPATH manpath MANPATH

        # ----------------------------------------------------------------------
        # User Binary Paths
        # 
        # Add user-local bins to PATH with highest priority
        # This allows user-installed programs to override system ones
        # ----------------------------------------------------------------------
        path=(
          $HOME/.local/bin
          $HOME/bin
          $HOME/.iptv/bin
          /usr/local/bin
          $path
        )

        # ----------------------------------------------------------------------
        # TTY Configuration
        # 
        # Disable flow control (Ctrl-S/Ctrl-Q) for better keybinding support
        # Only if we have a real TTY (not in pipe or script)
        # This prevents Ctrl-S from freezing terminal
        # ----------------------------------------------------------------------
        if [[ -t 0 && -t 1 ]]; then
          stty -ixon 2>/dev/null || true
        fi

        # ----------------------------------------------------------------------
        # Nix Integration
        # 
        # Set up Nix paths and command-not-found handler
        # Provides helpful suggestions when commands are not found
        # ----------------------------------------------------------------------
        export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
        [[ -f "$HOME/.nix-profile/etc/profile.d/command-not-found.sh" ]] && \
          source "$HOME/.nix-profile/etc/profile.d/command-not-found.sh"
      '')

      # ========================================================================
      # PHASE 1: Zinit Installation & Plugin Loading
      # 
      # Zinit is our plugin manager. This phase:
      # 1. Installs Zinit if not present
      # 2. Loads Zinit and its extensions
      # 3. Configures ZSH options
      # 4. Loads plugins IN CORRECT ORDER
      # 
      # If Zinit installation fails (no network, no git), the shell continues
      # to work but without plugins. This ensures robustness.
      # ========================================================================
      ''
        # ----------------------------------------------------------------------
        # Zinit Auto-Installation (Robust)
        # 
        # If Zinit is not installed, try to clone it from GitHub
        # If clone fails (offline, no git, firewall), we skip plugin setup
        # but keep the shell functional
        # 
        # The 2>/dev/null suppresses git errors in offline scenarios
        # ----------------------------------------------------------------------
        if [[ ! -d "$ZINIT_HOME" ]]; then
          mkdir -p "$(dirname "$ZINIT_HOME")"
          if ! ${pkgs.git}/bin/git clone --depth=1 \
            https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" 2>/dev/null; then
            echo "WARNING: Zinit could not be installed; skipping plugin setup." >&2
          fi
        fi

        # Only proceed with plugin setup if Zinit was successfully installed
        if [[ -f "$ZINIT_HOME/zinit.zsh" ]]; then
          # --------------------------------------------------------------------
          # Load Zinit Core
          # 
          # This initializes the plugin manager
          # Must be loaded before any plugins
          # --------------------------------------------------------------------
          source "$ZINIT_HOME/zinit.zsh"

          # --------------------------------------------------------------------
          # Zinit Annexes (Extensions)
          # 
          # These add extra functionality to Zinit:
          # • bin-gem-node: Manage binary programs, gems, and node modules
          # • patch-dl: Apply patches and download files during installation
          # 
          # They enhance Zinit but aren't strictly necessary
          # --------------------------------------------------------------------
          zinit light-mode for \
            zdharma-continuum/zinit-annex-bin-gem-node \
            zdharma-continuum/zinit-annex-patch-dl

          # --------------------------------------------------------------------
          # ZLE Configuration (Zsh Line Editor)
          # 
          # Set up advanced line editing features:
          # • url-quote-magic: Auto-escape special chars in URLs
          # • bracketed-paste-magic: Handle pasted text intelligently
          # • edit-command-line: Edit current command in $EDITOR (Ctrl-x e)
          # --------------------------------------------------------------------
          autoload -Uz url-quote-magic bracketed-paste-magic edit-command-line

          zle -N self-insert url-quote-magic
          zle -N bracketed-paste bracketed-paste-magic
          zle -N edit-command-line

          zstyle ':url-quote-magic:*' url-metas '*?[]^()~#{}='
          zstyle ':bracketed-paste-magic' active-widgets '.self-*'

          bindkey '^xe'   edit-command-line
          bindkey '^x^e'  edit-command-line

          # --------------------------------------------------------------------
          # Shell Options
          # 
          # These control ZSH behavior. Each section is grouped by function.
          # Options are carefully chosen for optimal UX and safety
          # --------------------------------------------------------------------
          
          # Navigation options
          setopt AUTO_CD              # Type directory name to cd into it
          setopt AUTO_PUSHD           # Make cd push old directory onto stack
          setopt PUSHD_IGNORE_DUPS    # Don't push duplicates onto stack
          setopt PUSHD_SILENT         # Don't print directory stack after pushd/popd
          setopt PUSHD_TO_HOME        # pushd with no args goes to home

          # Globbing options
          setopt EXTENDED_GLOB        # Use extended globbing syntax (#, ~, ^)
          setopt GLOB_DOTS            # Include dotfiles in glob matches
          setopt NUMERIC_GLOB_SORT    # Sort numerically when possible
          setopt NO_CASE_GLOB         # Case-insensitive globbing
          setopt NO_NOMATCH           # Don't error on no glob match, pass through

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
          setopt HIST_EXPIRE_DUPS_FIRST   # Expire duplicates first when trimming
          setopt HIST_FIND_NO_DUPS        # Don't show duplicates in search
          setopt HIST_IGNORE_ALL_DUPS     # Remove older duplicate entries
          setopt HIST_IGNORE_SPACE        # Don't save commands starting with space
          setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks before saving
          setopt HIST_SAVE_NO_DUPS        # Don't write duplicates to history file
          setopt HIST_VERIFY              # Show history expansion before running
          setopt SHARE_HISTORY            # Share history across all sessions
          setopt INC_APPEND_HISTORY       # Append to history immediately, not on exit

          # UX options
          setopt INTERACTIVE_COMMENTS     # Allow comments in interactive shell
          setopt NO_BEEP                  # Don't beep on errors
          setopt PROMPT_SUBST             # Allow prompt string substitutions
          setopt TRANSIENT_RPROMPT        # Remove right prompt on accept
          setopt NO_FLOW_CONTROL          # Disable Ctrl-S/Ctrl-Q flow control
          setopt COMBINING_CHARS          # Combine zero-length punctuation chars

          # Safety options
          setopt NO_CLOBBER               # Don't overwrite files with > redirect
          setopt NO_RM_STAR_SILENT        # Ask for confirmation before rm *
          setopt CORRECT                  # Correct command spelling

          # --------------------------------------------------------------------
          # History Ignore Pattern
          # 
          # Don't save these common commands to history
          # Reduces clutter and improves search results
          # Pattern uses ZSH extended glob syntax
          # --------------------------------------------------------------------
          HISTORY_IGNORE="(ls|cd|pwd|exit|clear|history|cd ..|cd -|z *|zi *)"

          # --------------------------------------------------------------------
          # Disable Globbing for Specific Commands
          # 
          # Some commands interpret glob characters themselves
          # Using noglob prevents ZSH from expanding them first
          # This prevents issues with patterns in arguments
          # --------------------------------------------------------------------
          alias nix='noglob nix'
          alias git='noglob git'
          alias find='noglob find'
          alias rsync='noglob rsync'
          alias scp='noglob scp'
          alias curl='noglob curl'
          alias wget='noglob wget'

          # --------------------------------------------------------------------
          # Eza (modern ls) configuration
          if command -v eza &>/dev/null; then
            export EZA_COLORS="da=1;34:gm=1;34"
            export EZA_ICON_SPACING=2
          fi

          # --------------------------------------------------------------------
          # Lazy Loading for Heavy Tools
          # 
          # NVM, pyenv, RVM, and Conda are slow to initialize (100-500ms each)
          # We load them only when their commands are actually used
          # This dramatically improves shell startup time
          # 
          # How it works:
          # 1. Define a lazy loader function
          # 2. Alias the real command to the lazy loader
          # 3. On first use, unalias, load real tool, run command
          # 4. Subsequent uses are normal (no lazy loading overhead)
          # --------------------------------------------------------------------
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

          # ====================================================================
          # ZINIT PLUGINS - CRITICAL: Correct Load Order
          # ====================================================================
          # 
          # Plugin load order is CRITICAL for correct operation:
          # 
          # 1. zsh-completions  → Adds completion definitions to fpath
          # 2. fzf-tab          → Hooks into completion system (before compinit)
          # 3. compinit         → Initializes completion system
          # 4. Other plugins    → Load after completion system is ready
          # 5. syntax highlight → MUST BE LAST (wraps all ZLE widgets)
          # 
          # Loading in wrong order causes:
          # • Missing completions (if completions loaded after compinit)
          # • Widget conflicts (if fzf-tab loaded after compinit)
          # • Keybinding failures (if syntax highlighting not last)
          # • Performance degradation (if heavy plugins load too early)
          # 
          # ====================================================================

          # --------------------------------------------------------------------
          # 1. COMPLETIONS - MUST BE FIRST
          # 
          # Loads additional completion definitions before compinit runs
          # This plugin adds thousands of completions for common tools
          # 
          # blockf: Block default fpath modification
          # atpull: Rebuild completions when plugin updates
          # --------------------------------------------------------------------
          zinit ice blockf atpull'zinit creinstall -q .'
          zinit light zsh-users/zsh-completions

          # --------------------------------------------------------------------
          # 2. FZF-TAB - MUST BE BEFORE COMPINIT
          # 
          # Replaces ZSH's default completion menu with FZF
          # CRITICAL: Must load before compinit to hook into the system
          # If loaded after, tab completion won't be fuzzy
          # 
          # depth=1: Shallow clone for faster download
          # --------------------------------------------------------------------
          zinit ice depth=1
          zinit light Aloxaf/fzf-tab

          # Configure fzf-tab behavior
          # These styles control how the fuzzy completion menu looks and behaves
          zstyle ':fzf-tab:*' fzf-command fzf
          zstyle ':fzf-tab:*' fzf-min-height 100
          zstyle ':fzf-tab:*' switch-group ',' '.'
          zstyle ':fzf-tab:*' continuous-trigger '/'
          zstyle ':fzf-tab:complete:*:*' fzf-preview ""
          zstyle ':fzf-tab:complete:*:*' fzf-flags --height=80% --border=rounded --bind='ctrl-/:toggle-preview'

          # Context-specific preview commands
          # Shows helpful previews for different completion types
          zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w'
          zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
          zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
          zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
          zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | delta'
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -T -L2 --icons --color=always $realpath 2>/dev/null'

          # --------------------------------------------------------------------
          # 3. COMPINIT - MUST BE AFTER COMPLETIONS AND FZF-TAB
          # 
          # Initializes ZSH's completion system
          # This is the core completion engine that makes tab completion work
          # 
          # We use aggressive caching to make this fast:
          # • Cache is valid for 24 hours
          # • Bytecode compilation for faster loading
          # • File locking to prevent race conditions
          # --------------------------------------------------------------------
          
          # Add our custom completions and functions to fpath
          # Must be done before compinit runs
          fpath=("${xdg.zsh}/completions" "${xdg.zsh}/functions" $fpath)

          # Load completion system module
          autoload -Uz compinit
          zmodload zsh/system 2>/dev/null || true

          # Set completion dump file location
          # Uses hostname and ZSH version to prevent conflicts
          : ''${ZSH_COMPDUMP:="${xdg.cache}/zcompdump-$HOST-$ZSH_VERSION"}
          zstyle ':completion:*' dump-file "$ZSH_COMPDUMP"

          # ----------------------------------------------------------------------
          # _safe_compinit: Smart Completion Initialization
          # 
          # This function intelligently decides whether to rebuild completions:
          # 
          # Decision logic:
          # • If dump doesn't exist → Full rebuild
          # • If dump is >24h old → Full rebuild
          # • If dump is fresh → Use cached version (-C flag = trust cache)
          # 
          # Performance optimization:
          # • Full rebuild: ~200ms (cold start)
          # • Cached version: ~10ms (warm start)
          # • Bytecode compilation: Runs in background, doesn't block
          # 
          # Race condition prevention:
          # • Uses file locking to prevent multiple shells from rebuilding
          # • If lock acquisition fails, falls back to cached version
          # • This prevents corruption and wasted CPU cycles
          # 
          # Bytecode compilation:
          # • Compiles .zcompdump to .zcompdump.zwc for faster loading
          # • Only recompiles if source is newer than bytecode
          # • Runs in background (&!) to not block shell startup
          # ----------------------------------------------------------------------
          _safe_compinit() {
            local _lock_file="${xdg.cache}/.compinit-''${HOST}-''${ZSH_VERSION}.lock"
            local _dump_dir="$(dirname "$ZSH_COMPDUMP")"

            # Ensure dump directory exists
            [[ -d "$_dump_dir" ]] || mkdir -p "$_dump_dir"

            local -i need_rebuild=0
            
            # Check if dump exists and is fresh (less than 24 hours old)
            # Glob qualifier: (#qN.mh+24) = hidden, no error if not exist, modified >24h ago
            if [[ ! -s "$ZSH_COMPDUMP" || -n $ZSH_COMPDUMP(#qN.mh+24) ]]; then
              need_rebuild=1
            fi

            # If dump is fresh, use cached version (fast path)
            if (( need_rebuild == 0 )); then
              # -C: Skip security check (trust cache)
              # -i: Ignore insecure directories
              # -d: Specify dump file location
              compinit -C -i -d "$ZSH_COMPDUMP"
              
              # Compile dump to bytecode in background if needed
              if [[ ! -f "$ZSH_COMPDUMP.zwc" || "$ZSH_COMPDUMP" -nt "$ZSH_COMPDUMP.zwc" ]]; then
                # -U: Compile for use only (no execution)
                # &!: Run in background, disown from job table
                { zcompile -U "$ZSH_COMPDUMP" 2>/dev/null || true; } &!
              fi
              return 0
            fi

            # If we need to rebuild, try to acquire lock
            # If lock fails, another shell is already rebuilding
            if command -v zsystem &>/dev/null; then
              # -t 0.1: Try for 0.1 seconds, then give up
              if ! zsystem flock -t 0.1 "$_lock_file" 2>/dev/null; then
                # Lock acquisition failed, use cached version
                compinit -C -i -d "$ZSH_COMPDUMP"
                return 0
              fi
            fi

            # We have the lock, do full rebuild
            # -u: Skip security check during rebuild
            # -i: Ignore insecure directories
            # -d: Specify dump file location
            compinit -u -i -d "$ZSH_COMPDUMP"
            
            # Compile to bytecode in background
            { zcompile -U "$ZSH_COMPDUMP" 2>/dev/null || true; } &!
            
            # Release lock
            command -v zsystem &>/dev/null && zsystem flock -u "$_lock_file" 2>/dev/null || true
          }

          # Initialize completion system using smart function
          _safe_compinit
          
          # Also load bash completion compatibility
          # Allows bash completion scripts to work in ZSH
          autoload -Uz bashcompinit && bashcompinit

          # --------------------------------------------------------------------
          # Completion System Styles
          # 
          # These zstyle commands control how completions look and behave
          # They affect the completion menu, matching, caching, and display
          # --------------------------------------------------------------------
          autoload -Uz colors && colors
          _comp_options+=(globdots)  # Include hidden files in completion

          # Completion strategy: try multiple methods in order
          # 1. _extensions: Try matching file extensions
          # 2. _complete: Standard completion
          # 3. _approximate: Try approximate matching (typo tolerance)
          # 4. _ignored: Try previously ignored matches
          zstyle ':completion:*' completer _extensions _complete _approximate _ignored
          
          # Enable caching for better performance
          # Cache stores results of expensive completions
          zstyle ':completion:*' use-cache on
          zstyle ':completion:*' cache-path "${xdg.cache}/.zcompcache"
          
          # Enable full completion features
          zstyle ':completion:*' complete true
          zstyle ':completion:*' complete-options true

          # Smart case-insensitive matching
          # Three matchers for maximum flexibility:
          # 1. Case-insensitive: 'a' matches 'A'
          # 2. Partial matching: 'f-b' matches 'foo-bar'
          # 3. Left-anchored: 'fb' matches 'foobar'
          zstyle ':completion:*' matcher-list \
            'm:{a-zA-Z}={A-Za-z}' \
            'r:|[._-]=* r:|=*' \
            'l:|=* r:|=*'

          # File sorting and listing options
          zstyle ':completion:*' file-sort modification  # Sort by modification time
          zstyle ':completion:*' sort false              # Don't sort results
          zstyle ':completion:*' list-suffixes true      # Show suffixes in list
          zstyle ':completion:*' expand prefix suffix    # Expand on both sides
          zstyle ':completion:*' menu select=2           # Menu select on 2+ matches
          zstyle ':completion:*' group-name ""           # Group completions by type
          zstyle ':completion:*' verbose yes             # Show descriptions
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}  # Use LS_COLORS
          zstyle ':completion:*' special-dirs true       # Include . and ..
          zstyle ':completion:*' squeeze-slashes true    # Remove duplicate slashes

          # Colored completion messages
          zstyle ':completion:*:descriptions' format '%F{yellow}━━ %d ━━%f'
          zstyle ':completion:*:messages'     format '%F{purple}━━ %d ━━%f'
          zstyle ':completion:*:warnings'     format '%F{red}━━ no matches found ━━%f'
          zstyle ':completion:*:corrections'  format '%F{green}━━ %d (errors: %e) ━━%f'

          # Process completion for kill command
          # Shows processes with PID, user, and command
          zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w"
          zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
          zstyle ':completion:*:*:kill:*' menu yes select
          zstyle ':completion:*:*:kill:*' force-list always
          zstyle ':completion:*:*:kill:*' insert-ids single

          # Man page completion
          # Separates man sections for better navigation
          zstyle ':completion:*:manuals'    separate-sections true
          zstyle ':completion:*:manuals.*'  insert-sections true

          # SSH/SCP/rsync completion
          # Organizes hosts by type (hostname, domain, IP)
          zstyle ':completion:*:(ssh|scp|rsync):*' tag-order \
            'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address'
          zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' \
            ignored-patterns '*(.|:)*' loopback localhost broadcasthost
          zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' \
            ignored-patterns '<->.<->.<->.<->' '*@*'
          zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' \
            ignored-patterns '^(<->.<->.<->.<->)' '127.0.0.<->' '::1' 'fe80::*'

          # Always rehash for new commands
          # Checks for new executables in PATH
          zstyle ':completion:*' rehash true
          zstyle ':completion:*' accept-exact-dirs true

          # ====================================================================
          # 4. OTHER PLUGINS - AFTER COMPINIT
          # ====================================================================
          # 
          # These plugins can safely load after the completion system is ready
          # They don't interact with compinit so order among themselves doesn't matter
          # 
          # All plugins load synchronously (no wait) for simplicity and reliability
          # This adds ~50ms to startup but prevents timing issues
          # 
          # ====================================================================
          ${lib.optionalString features.zinitTurbo ''
            # ------------------------------------------------------------------
            # History substring search
            # 
            # Provides up/down arrow history search with substring matching
            # Essential for efficient history navigation
            # Keybindings work in both standard and application cursor key modes
            # ------------------------------------------------------------------
            zinit light zsh-users/zsh-history-substring-search
            bindkey '^[[A'  history-substring-search-up      # Up arrow
            bindkey '^[[B'  history-substring-search-down    # Down arrow
            bindkey '^[OA'  history-substring-search-up      # Up arrow (app mode)
            bindkey '^[OB'  history-substring-search-down    # Down arrow (app mode)

            # ------------------------------------------------------------------
            # Auto-suggestions
            # 
            # Shows suggestions based on history as you type
            # Lightweight and provides excellent UX
            # Accept suggestion with End key or Ctrl-E
            # ------------------------------------------------------------------
            zinit light zsh-users/zsh-autosuggestions

            # ------------------------------------------------------------------
            # Autopair
            # 
            # Auto-closes brackets, quotes, and other pairs
            # Tiny plugin with no performance impact
            # Smart about when to insert pairs vs not
            # ------------------------------------------------------------------
            zinit light hlissner/zsh-autopair

            # ------------------------------------------------------------------
            # OMZ Plugin Snippets
            # 
            # Lightweight utilities from Oh-My-Zsh
            # Each adds useful functionality without significant overhead
            # 
            # sudo: Press ESC twice to prepend sudo to command
            # extract: Smart archive extraction (extract <file>)
            # copypath: Copy current path to clipboard (copypath)
            # copyfile: Copy file contents to clipboard (copyfile <file>)
            # git: Extensive git aliases (gst, gco, gp, etc.)
            # ------------------------------------------------------------------
            zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh
            zinit snippet OMZ::plugins/extract/extract.plugin.zsh
            zinit snippet OMZ::plugins/copypath/copypath.plugin.zsh
            zinit snippet OMZ::plugins/copyfile/copyfile.plugin.zsh
            zinit snippet OMZ::plugins/git/git.plugin.zsh

            # ------------------------------------------------------------------
            # Syntax Highlighting - MUST BE LAST
            # 
            # CRITICAL: This MUST be the last plugin loaded
            # 
            # Why last?
            # • Wraps all ZLE widgets to provide syntax highlighting
            # • Must wrap widgets after all other plugins have set them up
            # • If loaded earlier, other plugins' widgets won't be highlighted
            # 
            # Performance Note:
            # • Causes ~300-500ms freeze when loading
            # • This is inherent to how it wraps ZLE widgets
            # • Unavoidable - it's a design limitation
            # 
            # Trade-off:
            # • Visual feedback (colored commands)
            # • vs Instant responsiveness (no freeze)
            # 
            # If the freeze is unacceptable, comment out this line
            # The shell works perfectly without syntax highlighting
            # ------------------------------------------------------------------
            zinit light zsh-users/zsh-syntax-highlighting
          ''}

          # Fallback if zinitTurbo is disabled
          # Loads same plugins in non-turbo mode
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

            zinit light zsh-users/zsh-syntax-highlighting
          ''}
        else
          # Zinit not available - shell runs without plugins
          echo "WARNING: Zinit not available; shell running without plugins." >&2
        fi

        # ----------------------------------------------------------------------
        # Tool Integrations
        # 
        # These tools enhance shell functionality
        # They don't depend on Zinit and run regardless of plugin availability
        # Each checks if the tool is installed before integrating
        # ----------------------------------------------------------------------

        # Zoxide: Smarter cd command that learns your habits
        # Usage: z <partial-path> jumps to most frecent match
        if command -v zoxide &>/dev/null; then
          eval "$(zoxide init zsh)"
        fi

        # Direnv: Automatic environment switching per directory
        # Loads .envrc files when entering directories
        # Silenced to avoid clutter during directory changes
        if command -v direnv &>/dev/null; then
          eval "$(direnv hook zsh)"
          export DIRENV_LOG_FORMAT=""  # Silence direnv messages
        fi

        # Atuin: Better shell history with sync and search
        # Provides enhanced Ctrl-R history search
        # ATUIN_NOBIND prevents auto-binding to allow manual configuration
        if command -v atuin &>/dev/null; then
          export ATUIN_NOBIND="true"
          eval "$(atuin init zsh)"
          bindkey '^r' _atuin_search_widget  # Ctrl-R for atuin search
        fi

        # ----------------------------------------------------------------------
        # Custom Functions
        # 
        # Auto-load any functions in the functions directory
        # Functions are lazy-loaded: loaded into memory but not executed
        # until called, saving startup time
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
        # Prevents confusion when shell starts in unexpected location
        # ----------------------------------------------------------------------
        [[ $PWD == *"/zinit/plugins/"* ]] && cd ~

        # ----------------------------------------------------------------------
        # Debug Output
        # 
        # If debug mode is enabled, show profiling results
        # Helps identify slow parts of shell startup
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
        # Starship provides a fast, customizable prompt with git integration
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
    # Separate from sessionVariables for proper precedence
    # ==========================================================================
    history = {
      size                  = 200000;  # Commands to keep in memory
      save                  = 150000;  # Commands to save to disk
      path                  = "${xdg.zsh}/history";
      ignoreDups            = true;    # Don't record consecutive duplicates
      ignoreAllDups         = true;    # Remove all duplicates from history
      ignoreSpace           = true;    # Ignore commands starting with space
      share                 = true;    # Share history across all sessions
      extended              = true;    # Save timestamps with commands
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
# 3. Verify plugins loaded correctly:
#    zinit list
#    # Should show all plugins in correct order
# 
# 4. Test completion:
#    git <TAB>
#    # Should show fuzzy completion menu (fzf-tab)
# 
# 5. Test history search:
#    Type: echo
#    Press: Up arrow
#    # Should search history for commands starting with "echo"
# 
# 6. Test autosuggestions:
#    Start typing a previous command
#    # Should show gray suggestion
# 
# 7. Test syntax highlighting:
#    Type: ls
#    # Should be colored (if syntax highlighting enabled)
#    # Note: May cause brief freeze when first loading
# 
# 8. Check startup time:
#    time zsh -i -c exit
#    # Should be <150ms with syntax highlighting
#    # Should be <100ms without syntax highlighting
# 
# 9. If you experience the 300-500ms freeze:
#    • It's caused by syntax highlighting loading
#    • Comment out: zinit light zsh-users/zsh-syntax-highlighting
#    • Rebuild and test again
#    • Freeze will be gone
# 
# 10. Enable debug mode if issues persist:
#     Set: debugMode = true
#     Rebuild
#     Check: /tmp/zsh-trace-$$.log
#     Run: zprof
# 
# ==============================================================================
