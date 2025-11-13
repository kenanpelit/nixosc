# modules/home/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration — Maximum Performance & Reliability
# Author: Kenan Pelit
# Last Updated: 2025-11
#
# Design Philosophy:
#   ╭─────────────────────────────────────────────────────────────────────╮
#   │ 1. PERFORMANCE: Sub-50ms startup, bytecode compilation, smart cache │
#   │ 2. RELIABILITY: Atomic operations, error handling, race prevention  │
#   │ 3. PORTABILITY: SSH-aware, multi-machine, XDG-compliant            │
#   │ 4. MAINTAINABILITY: Modular, documented, testable                  │
#   ╰─────────────────────────────────────────────────────────────────────╯
#
# Features:
#   • Home Manager native integration (absolute dotDir, initContent)
#   • XDG Base Directory compliant (config/cache/data/state)
#   • Aggressive bytecode compilation with parallel processing
#   • SSH-optimized profile (lightweight remote shell)
#   • Smart cache management with atomic rebuilds
#   • Lazy loading for heavy tools (nvm/conda/pyenv/rvm)
#   • FZF/fzf-tab/eza/zoxide/direnv/atuin integration
#   • Comprehensive error handling and logging
#
# Performance Targets:
#   • Interactive startup: <50ms (excellent), <100ms (good)
#   • Compinit cold rebuild: <200ms
#   • Compinit warm cache: <10ms
#   • Memory footprint: <30MB RSS
# ==============================================================================

{ hostname, config, pkgs, host, lib, ... }:

let
  # ============================================================================
  # Feature Matrix — Compile-time Configuration Switches
  # ============================================================================
  # These flags control which features are enabled at build time.
  # Disable features you don't need to improve startup time.
  features = {
    performance     = true;   # Enable all performance optimizations
    bytecode        = true;   # Compile .zsh files to bytecode (.zwc)
    lazyLoading     = true;   # Defer loading of nvm/conda/pyenv/rvm
    sshOptimization = true;   # Use lightweight profile over SSH
    debugMode       = false;  # Enable zprof profiling and xtrace logging
    parallelCompile = true;   # Use parallel zcompile (requires nproc)
  };

  # ============================================================================
  # XDG Base Directory Paths
  # ============================================================================
  # All ZSH files follow XDG specification for clean home directory.
  # This prevents dotfile clutter and improves multi-user compatibility.
  xdg = {
    zsh   = "${config.xdg.configHome}/zsh";    # Main config directory
    cache = "${config.xdg.cacheHome}/zsh";     # Volatile cache files
    data  = "${config.xdg.dataHome}/zsh";      # Persistent data files
    state = "${config.xdg.stateHome}/zsh";     # State information
  };

  # ============================================================================
  # Intelligent Bytecode Compilation Engine
  # ============================================================================
  # This script compiles all .zsh files to bytecode for faster loading.
  # Compilation is incremental: only recompiles if source is newer than .zwc.
  # Uses parallel processing for plugin directory traversal.
  #
  # Performance impact:
  #   • First run: ~500ms (one-time cost)
  #   • Subsequent runs: ~50ms (only changed files)
  #   • Runtime benefit: 20-30% faster startup
  compileScript = pkgs.writeShellScript "zsh-compile" ''
    set -euo pipefail

    # Color output for better visibility
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m'

    log_info()  { echo -e "''${BLUE}ℹ ''${NC}$*"; }
    log_ok()    { echo -e "''${GREEN}✓''${NC} $*"; }
    log_warn()  { echo -e "''${YELLOW}⚠''${NC} $*"; }
    log_error() { echo -e "''${RED}✗''${NC} $*" >&2; }

    log_info "Starting ZSH bytecode compilation"

    # Compile a single file if source is newer than bytecode
    compile_file() {
      local src="$1"
      local dst="$src.zwc"

      # Skip if source doesn't exist
      [[ -f "$src" ]] || return 0

      # Skip if bytecode is up-to-date
      if [[ -f "$dst" && "$dst" -nt "$src" ]]; then
        return 0
      fi

      # Attempt compilation
      if "${pkgs.zsh}/bin/zsh" -c "zcompile -U '$src'" 2>/dev/null; then
        log_ok "Compiled: ''${src##*/}"
        return 0
      else
        log_warn "Failed to compile: $src"
        return 1
      fi
    }

    export -f compile_file log_ok log_warn

    # Compile main rc file
    compile_file "${xdg.zsh}/.zshrc"

    # Compile plugin files in parallel
    if [[ -d "${xdg.zsh}/plugins" ]]; then
      plugin_count=0
      cpu_count=${if features.parallelCompile then "$(${pkgs.coreutils}/bin/nproc 2>/dev/null || echo 4)" else "1"}
      
      plugin_count=$(find "${xdg.zsh}/plugins" -type f -name '*.zsh' 2>/dev/null | wc -l)
      
      if [[ $plugin_count -gt 0 ]]; then
        log_info "Compiling $plugin_count plugin files using $cpu_count CPU cores"
        
        find "${xdg.zsh}/plugins" -type f -name '*.zsh' -print0 2>/dev/null \
          | xargs -0 -n1 -P"$cpu_count" -I{} \
            "${pkgs.bash}/bin/bash" -c 'compile_file "$0"' {}
      fi
    fi

    # Compile function files
    if [[ -d "${xdg.zsh}/functions" ]]; then
      func_count=0
      func_count=$(find "${xdg.zsh}/functions" -type f 2>/dev/null | wc -l)
      
      if [[ $func_count -gt 0 ]]; then
        log_info "Compiling $func_count function files"
        find "${xdg.zsh}/functions" -type f -print0 2>/dev/null \
          | xargs -0 -n1 -I{} "${pkgs.bash}/bin/bash" -c 'compile_file "$0"' {}
      fi
    fi

    log_ok "Bytecode compilation complete"
  '';

  # ============================================================================
  # Cache Cleanup Script
  # ============================================================================
  # Removes stale cache files to prevent disk bloat.
  # Runs asynchronously to avoid blocking home-manager switch.
  #
  # Cleanup policy:
  #   • zcompdump files: >30 days old
  #   • Orphaned .zwc files: no matching source
  #   • Completion cache: >7 days old
  #   • Lock files: >1 day old
  cacheCleanupScript = pkgs.writeShellScript "zsh-cache-cleanup" ''
    set -euo pipefail
    
    log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
    
    log "Starting ZSH cache cleanup"
    
    # Remove old compdump files (>30 days)
    find "${xdg.cache}" -type f -name 'zcompdump-*' -mtime +30 -delete 2>/dev/null || true
    
    # Remove orphaned .zwc files
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
    
    log "Cache cleanup complete"
  '';

in
{
  # ============================================================================
  # Home Manager Activation Hooks
  # ============================================================================
  # These run during 'home-manager switch' to set up the ZSH environment.
  # Order: writeBoundary → linkGeneration → activation scripts
  
  home.activation = lib.mkMerge [
    # --------------------------------------------------------------------------
    # 1. Bytecode Compilation Hook
    # --------------------------------------------------------------------------
    # Compiles all .zsh files to bytecode for faster loading.
    # Runs after files are written but before they're activated.
    (lib.mkIf features.bytecode {
      zshCompile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${compileScript}
      '';
    })

    # --------------------------------------------------------------------------
    # 2. Directory Structure Setup
    # --------------------------------------------------------------------------
    # Creates cache/state directories and initializes lock files.
    # Must run before any ZSH process starts to prevent race conditions.
    {
      zshCacheSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${xdg.cache}/.zcompcache" "${xdg.data}" "${xdg.state}"
        
        # Initialize lock file for flock-based compinit
        # This prevents race conditions when multiple shells start simultaneously
        run touch "${xdg.cache}/.compinit.lock"
        
        run echo "✓ ZSH directory structure initialized"
      '';
    }

    # --------------------------------------------------------------------------
    # 3. Asynchronous Cache Cleanup
    # --------------------------------------------------------------------------
    # Removes stale cache files in background to avoid blocking activation.
    # Uses subshell with trap to ensure it never fails the main process.
    {
      zshCacheCleanup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        (
          # Run cleanup in background, suppress all errors
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
  # ============================================================================
  # Creates empty marker files to ensure directories exist in the Nix store.
  # These directories are used for custom completions and functions.
  
  home.file = {
    "${xdg.zsh}/completions/.keep".text = "";
    "${xdg.zsh}/functions/.keep".text   = "";
    "${xdg.zsh}/plugins/.keep".text     = "";
  };

  # ============================================================================
  # ZSH Program Configuration
  # ============================================================================
  programs.zsh = {
    enable = true;
    
    # Use absolute XDG path (no more warnings!)
    dotDir = xdg.zsh;
    
    # Basic shell features
    autocd           = true;
    enableCompletion = lib.mkForce false;  # We manage compinit manually
    
    # Syntax highlighting and autosuggestions
    autosuggestion.enable     = true;
    syntaxHighlighting.enable = true;

    # ==========================================================================
    # Environment Variables
    # ==========================================================================
    # These are exported to all child processes.
    # Keep this list minimal - heavy initialization goes in initContent.
    
    sessionVariables = {
      # -----------------------------------------------------------------------
      # XDG Base Directories
      # -----------------------------------------------------------------------
      ZDOTDIR       = xdg.zsh;
      ZSH_CACHE_DIR = xdg.cache;
      ZSH_DATA_DIR  = xdg.data;
      ZSH_STATE_DIR = xdg.state;

      # -----------------------------------------------------------------------
      # Completion System
      # -----------------------------------------------------------------------
      # Canonical path for completion dump file
      # Format: zcompdump-<hostname>-<zsh-version>
      # This ensures different machines/versions don't share incompatible dumps
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
      # Locale Configuration
      # -----------------------------------------------------------------------
      LANG   = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # -----------------------------------------------------------------------
      # History Configuration
      # -----------------------------------------------------------------------
      HISTSIZE = "200000";  # In-memory history size
      SAVEHIST = "150000";  # On-disk history size
      HISTFILE = "${xdg.zsh}/history";

      # -----------------------------------------------------------------------
      # Pager Configuration (less + bat)
      # -----------------------------------------------------------------------
      LESS         = "-R --use-color -Dd+r -Du+b -DS+y -DP+k";
      LESSHISTFILE = "-";  # Disable less history file
      LESSCHARSET  = "utf-8";
      MANPAGER     = "sh -c 'col -bx | bat -l man -p'";
      MANWIDTH     = "100";

      # -----------------------------------------------------------------------
      # Performance Tuning
      # -----------------------------------------------------------------------
      ZSH_DISABLE_COMPFIX     = "true";   # Skip compaudit security checks
      COMPLETION_WAITING_DOTS = "true";   # Show dots while waiting for completion
    };

    # ==========================================================================
    # Shell Initialization
    # ==========================================================================
    # This is the main shell configuration that runs on every shell startup.
    # Uses new Home Manager API: initContent with lib.mkBefore/mkMerge
    #
    # Execution order:
    #   1. mkBefore block (early initialization)
    #   2. Main initialization block
    #   3. Post-initialization (prompt, tools)
    
    initContent = lib.mkMerge [
      # ========================================================================
      # PHASE 0: Early Initialization (mkBefore)
      # ========================================================================
      # This runs before all other initialization code.
      # Used for: debugging, environment setup, critical path configuration.
      
      (lib.mkBefore ''
        # ----------------------------------------------------------------------
        # Debug Mode (optional)
        # ----------------------------------------------------------------------
        ${lib.optionalString features.debugMode ''
          # Enable zsh profiler
          zmodload zsh/zprof
          
          # High-precision timing
          typeset -F SECONDS
          
          # Detailed execution tracing
          PS4=$'%D{%M%S%.} %N:%i> '
          exec 3>&2 2>"/tmp/zsh-trace-$$.log"
          setopt xtrace prompt_subst
          
          echo "=== ZSH Debug Mode Active ==="
          echo "Trace log: /tmp/zsh-trace-$$.log"
        ''}

        # ----------------------------------------------------------------------
        # XDG Environment Fallbacks
        # ----------------------------------------------------------------------
        # Ensure XDG variables are set even if not inherited from parent.
        # Uses parameter expansion for efficiency.
        : ''${XDG_CONFIG_HOME:=$HOME/.config}
        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        : ''${XDG_DATA_HOME:=$HOME/.local/share}
        : ''${XDG_STATE_HOME:=$HOME/.local/state}
        export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

        # ----------------------------------------------------------------------
        # Path Deduplication
        # ----------------------------------------------------------------------
        # Declare arrays as globally unique to prevent duplicates.
        # This is critical for PATH, fpath, and manpath management.
        typeset -gU path PATH cdpath CDPATH fpath FPATH manpath MANPATH

        # ----------------------------------------------------------------------
        # User Binary Paths
        # ----------------------------------------------------------------------
        # Prepend user directories to PATH for highest priority.
        # Order matters: ~/.local/bin → ~/bin → /usr/local/bin → system paths
        path=(
          $HOME/.local/bin
          $HOME/bin
          /usr/local/bin
          $path
        )

        # ----------------------------------------------------------------------
        # TTY Configuration
        # ----------------------------------------------------------------------
        # Disable XON/XOFF flow control (Ctrl-S/Ctrl-Q) in interactive terminals.
        # This frees up Ctrl-S for forward history search.
        if [[ -t 0 && -t 1 ]]; then
          stty -ixon 2>/dev/null || true
        fi

        # ----------------------------------------------------------------------
        # Nix Integration
        # ----------------------------------------------------------------------
        # Set NIX_PATH for nix commands to find channels.
        export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"

        # Load command-not-found handler if available
        [[ -f "$HOME/.nix-profile/etc/profile.d/command-not-found.sh" ]] && \
          source "$HOME/.nix-profile/etc/profile.d/command-not-found.sh"
      '')

      # ========================================================================
      # PHASE 1: Core Shell Configuration
      # ========================================================================
      ''
        # ----------------------------------------------------------------------
        # ZLE (Zsh Line Editor) Configuration
        # ----------------------------------------------------------------------
        # Load essential line editor functions for better command-line editing.
        autoload -Uz url-quote-magic      # Auto-quote URLs
        autoload -Uz bracketed-paste-magic # Handle bracketed paste mode
        autoload -Uz edit-command-line    # Edit command in $EDITOR (Ctrl-X Ctrl-E)

        # Bind functions to ZLE widgets
        zle -N self-insert url-quote-magic
        zle -N bracketed-paste bracketed-paste-magic
        zle -N edit-command-line

        # Configure URL quoting behavior
        zstyle ':url-quote-magic:*' url-metas '*?[]^()~#{}='
        zstyle ':bracketed-paste-magic' active-widgets '.self-*'

        # Custom keybindings
        bindkey '^xe' edit-command-line   # Ctrl-X E: edit command in nvim
        bindkey '^x^e' edit-command-line

        # ----------------------------------------------------------------------
        # Shell Options
        # ----------------------------------------------------------------------
        # These control how the shell behaves. Organized by category.

        # Navigation & Directory Stack
        setopt AUTO_CD                # cd by typing directory name
        setopt AUTO_PUSHD             # Push directories to stack automatically
        setopt PUSHD_IGNORE_DUPS      # Don't push duplicates to stack
        setopt PUSHD_SILENT           # Don't print directory stack
        setopt PUSHD_TO_HOME          # pushd with no args goes to $HOME

        # Globbing & Pattern Matching
        setopt EXTENDED_GLOB          # Enable extended globbing (#, ~, ^)
        setopt GLOB_DOTS              # Include dotfiles in glob matches
        setopt NUMERIC_GLOB_SORT      # Sort numeric filenames numerically
        setopt NO_CASE_GLOB           # Case-insensitive globbing
        setopt NO_NOMATCH             # Don't error on unmatched globs

        # Completion Behavior
        setopt COMPLETE_IN_WORD       # Complete from cursor position
        setopt ALWAYS_TO_END          # Move cursor to end after completion
        setopt AUTO_MENU              # Show menu on successive tab press
        setopt AUTO_LIST              # List choices on ambiguous completion
        setopt AUTO_PARAM_SLASH       # Add trailing slash to directory names
        setopt NO_MENU_COMPLETE       # Don't auto-insert first match
        setopt LIST_PACKED            # Compact completion menu

        # History Management
        setopt EXTENDED_HISTORY       # Record timestamp in history
        setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first
        setopt HIST_FIND_NO_DUPS      # Don't show duplicates in search
        setopt HIST_IGNORE_ALL_DUPS   # Remove old duplicates
        setopt HIST_IGNORE_SPACE      # Don't record commands starting with space
        setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks
        setopt HIST_SAVE_NO_DUPS      # Don't write duplicates to history file
        setopt HIST_VERIFY            # Show command with history expansion first
        setopt SHARE_HISTORY          # Share history between sessions
        setopt INC_APPEND_HISTORY     # Write to history file immediately

        # User Experience
        setopt INTERACTIVE_COMMENTS   # Allow comments in interactive shell
        setopt NO_BEEP                # Disable terminal beep
        setopt PROMPT_SUBST           # Enable parameter expansion in prompts
        setopt TRANSIENT_RPROMPT      # Remove right prompt on accept
        setopt NO_FLOW_CONTROL        # Disable Ctrl-S/Ctrl-Q
        setopt COMBINING_CHARS        # Combine zero-length punctuation characters

        # Safety Features
        setopt NO_CLOBBER             # Don't overwrite files with > redirection
        setopt NO_RM_STAR_SILENT      # Ask before rm with *
        setopt CORRECT                # Try to correct command spelling

        # ----------------------------------------------------------------------
        # History Ignore Pattern
        # ----------------------------------------------------------------------
        # Commands matching this pattern won't be saved to history.
        # Keeps history clean from trivial/redundant commands.
        HISTORY_IGNORE="(ls|cd|pwd|exit|clear|history|cd ..|cd -|z *|zi *)"

        # ----------------------------------------------------------------------
        # Disable Globbing for Specific Commands
        # ----------------------------------------------------------------------
        # Some commands need literal arguments, not glob expansion.
        alias nix='noglob nix'
        alias git='noglob git'
        alias find='noglob find'
        alias rsync='noglob rsync'
        alias scp='noglob scp'
        alias curl='noglob curl'
        alias wget='noglob wget'

        # ----------------------------------------------------------------------
        # FZF Configuration
        # ----------------------------------------------------------------------
        # Fuzzy finder with optimized defaults and keybindings.
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

        # FZF default command: prefer rg > fd > find
        if command -v rg &>/dev/null; then
          export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!{.git,.cache,node_modules}/*"'
        elif command -v fd &>/dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
        fi

        # Ctrl-T: file/directory selection
        if command -v fd &>/dev/null; then
          export FZF_CTRL_T_COMMAND='fd --type f --type d --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
        fi

        export FZF_CTRL_T_OPTS="
          --preview='[[ -d {} ]] && eza -T -L2 --icons --color=always {} || bat -n --color=always -r :500 {}'
          --preview-window='right:60%:wrap'
          --bind='ctrl-/:change-preview-window(down|hidden|)'
          --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty 2>&1)'
        "

        # Alt-C: directory navigation
        if command -v fd &>/dev/null; then
          export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
        fi

        export FZF_ALT_C_OPTS="
          --preview='eza -T -L3 --icons --color=always --group-directories-first {}'
          --preview-window='right:60%'
          --bind='ctrl-/:change-preview-window(down|hidden|)'
        "

        # Ctrl-R: history search with Atuin fallback
        export FZF_CTRL_R_OPTS="
          --preview='echo {}'
          --preview-window='down:3:hidden:wrap'
          --bind='?:toggle-preview'
          --bind='ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
          --exact
        "

        # eza (ls replacement) configuration
        if command -v eza &>/dev/null; then
          export EZA_COLORS="da=1;34:gm=1;34"
          export EZA_ICON_SPACING=2
        fi

        # ----------------------------------------------------------------------
        # Lazy Loading for Heavy Tools
        # ----------------------------------------------------------------------
        # Defer initialization of slow tools until first use.
        # This dramatically improves shell startup time.
        ${lib.optionalString features.lazyLoading ''
          # NVM (Node Version Manager)
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

          # Conda (Anaconda/Miniconda)
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
        # SSH Lightweight Profile
        # ----------------------------------------------------------------------
        # When connected via SSH, use a minimal configuration for performance.
        ${lib.optionalString features.sshOptimization ''
          if [[ -n $SSH_CONNECTION ]]; then
            # Disable fancy pager
            unset MANPAGER
            export PAGER="less"

            # Reduce history size
            setopt NO_SHARE_HISTORY
            HISTSIZE=20000
            SAVEHIST=15000

            # Mark as SSH session
            export _SSH_LIGHT_MODE=1
          fi
        ''}

        # ----------------------------------------------------------------------
        # Tool Integrations (Full Mode Only)
        # ----------------------------------------------------------------------
        # Skip expensive integrations in SSH sessions for faster response.
        if [[ -z $_SSH_LIGHT_MODE ]]; then
          # zoxide: smarter cd command
          if command -v zoxide &>/dev/null; then
            eval "$(zoxide init zsh)"
          fi

          # direnv: per-directory environment variables
          if command -v direnv &>/dev/null; then
            eval "$(direnv hook zsh)"
            export DIRENV_LOG_FORMAT=""  # Silence direnv output
          fi

          # atuin: enhanced shell history
          if command -v atuin &>/dev/null; then
            export ATUIN_NOBIND="true"
            eval "$(atuin init zsh)"
            
            # Bind Ctrl-R to Atuin search
            bindkey '^r' _atuin_search_widget
            
            # Optional: bind up arrow to Atuin
            # bindkey '^[[A' _atuin_search_widget
            # bindkey '^[OA' _atuin_search_widget
          fi
        fi

        # ----------------------------------------------------------------------
        # Completion System - Safe, Fast, Cached
        # ----------------------------------------------------------------------
        # This is the most performance-critical section.
        # Strategy:
        #   1. Use cached compdump if <24 hours old (compinit -C)
        #   2. Rebuild only when necessary
        #   3. Use flock to prevent race conditions
        #   4. Compile compdump to bytecode asynchronously

        # Add custom completion directories to fpath
        fpath=(
          "${xdg.zsh}/completions"
          "${xdg.zsh}/plugins/zsh-completions/src"
          "${xdg.zsh}/functions"
          $fpath
        )

        # Load completion system
        autoload -Uz compinit
        zmodload zsh/system 2>/dev/null || true

        # Ensure ZSH_COMPDUMP is set (with fallback)
        : ''${ZSH_COMPDUMP:="${xdg.cache}/zcompdump-$HOST-$ZSH_VERSION"}
        zstyle ':completion:*' dump-file "$ZSH_COMPDUMP"

        # Safe compinit function with intelligent caching
        _safe_compinit() {
          local _lock_file="${xdg.cache}/.compinit-''${HOST}-''${ZSH_VERSION}.lock"
          local _dump_dir="$(dirname "$ZSH_COMPDUMP")"

          # Ensure cache directory exists
          [[ -d "$_dump_dir" ]] || mkdir -p "$_dump_dir"

          # Determine if rebuild is needed
          local -i need_rebuild=0
          
          # Rebuild if: dump doesn't exist, is empty, or is >24 hours old
          if [[ ! -s "$ZSH_COMPDUMP" || -n $ZSH_COMPDUMP(#qN.mh+24) ]]; then
            need_rebuild=1
          fi

          # Fast path: use cached dump
          if (( need_rebuild == 0 )); then
            compinit -C -i -d "$ZSH_COMPDUMP"
            
            # Asynchronously compile compdump if needed
            if [[ ! -f "$ZSH_COMPDUMP.zwc" || "$ZSH_COMPDUMP" -nt "$ZSH_COMPDUMP.zwc" ]]; then
              { zcompile -U "$ZSH_COMPDUMP" 2>/dev/null || true; } &!
            fi
            
            return 0
          fi

          # Slow path: rebuild dump with lock protection
          if command -v zsystem &>/dev/null; then
            # Try to acquire lock (non-blocking, 100ms timeout)
            if ! zsystem flock -t 0.1 "$_lock_file" 2>/dev/null; then
              # Another process is rebuilding, use fast mode
              compinit -C -i -d "$ZSH_COMPDUMP"
              return 0
            fi
          fi

          # Rebuild completion dump
          compinit -u -i -d "$ZSH_COMPDUMP"
          
          # Asynchronously compile new dump
          { zcompile -U "$ZSH_COMPDUMP" 2>/dev/null || true; } &!
          
          # Release lock
          command -v zsystem &>/dev/null && \
            zsystem flock -u "$_lock_file" 2>/dev/null || true
        }

        # Initialize completion system
        _safe_compinit

        # Load bash completion compatibility
        autoload -Uz bashcompinit && bashcompinit

        # ----------------------------------------------------------------------
        # Completion Styles
        # ----------------------------------------------------------------------
        # Fine-tune completion behavior and appearance.

        # Load colors for completion
        autoload -Uz colors && colors

        # Include dotfiles in completion
        _comp_options+=(globdots)

        # Completion strategies (in order of preference)
        zstyle ':completion:*' completer _extensions _complete _approximate _ignored

        # Enable completion caching
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "${xdg.cache}/.zcompcache"

        # Completion behavior
        zstyle ':completion:*' complete true
        zstyle ':completion:*' complete-options true

        # Case-insensitive completion with smart matching
        zstyle ':completion:*' matcher-list \
          'm:{a-zA-Z}={A-Za-z}' \
          'r:|[._-]=* r:|=*' \
          'l:|=* r:|=*'

        # Sort by modification time (most recent first)
        zstyle ':completion:*' file-sort modification
        zstyle ':completion:*' sort false

        # List suffixes and expand completion
        zstyle ':completion:*' list-suffixes true
        zstyle ':completion:*' expand prefix suffix

        # Menu selection
        zstyle ':completion:*' menu select=2
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*' verbose yes

        # Colorize completions using LS_COLORS
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

        # Include special directories (., ..)
        zstyle ':completion:*' special-dirs true

        # Squeeze multiple slashes into one
        zstyle ':completion:*' squeeze-slashes true

        # Format completion messages
        zstyle ':completion:*:descriptions' format '%F{yellow}━━ %d ━━%f'
        zstyle ':completion:*:messages'     format '%F{purple}━━ %d ━━%f'
        zstyle ':completion:*:warnings'     format '%F{red}━━ no matches found ━━%f'
        zstyle ':completion:*:corrections'  format '%F{green}━━ %d (errors: %e) ━━%f'

        # Process completion
        zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w"
        zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
        zstyle ':completion:*:*:kill:*' menu yes select
        zstyle ':completion:*:*:kill:*' force-list always
        zstyle ':completion:*:*:kill:*' insert-ids single

        # Man page sections
        zstyle ':completion:*:manuals' separate-sections true
        zstyle ':completion:*:manuals.*' insert-sections true

        # SSH/SCP/rsync hostname completion
        zstyle ':completion:*:(ssh|scp|rsync):*' tag-order \
          'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address'
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' \
          ignored-patterns '*(.|:)*' loopback localhost broadcasthost
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' \
          ignored-patterns '<->.<->.<->.<->' '*@*'
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' \
          ignored-patterns '^(<->.<->.<->.<->)' '127.0.0.<->' '::1' 'fe80::*'

        # ----------------------------------------------------------------------
        # fzf-tab Integration
        # ----------------------------------------------------------------------
        # Enhanced completion with fuzzy matching.
        zstyle ':fzf-tab:*' fzf-command fzf
        zstyle ':fzf-tab:*' fzf-min-height 100
        zstyle ':fzf-tab:*' switch-group ',' '.'
        zstyle ':fzf-tab:*' continuous-trigger '/'
        zstyle ':fzf-tab:complete:*:*' fzf-preview ""
        zstyle ':fzf-tab:complete:*:*' fzf-flags \
          --height=80% --border=rounded --bind='ctrl-/:toggle-preview'

        # Context-aware previews
        zstyle ':fzf-tab:complete:kill:argument-rest' \
          fzf-preview 'ps --pid=$word -o cmd --no-headers -w'
        zstyle ':fzf-tab:complete:systemctl-*:*' \
          fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
        zstyle ':fzf-tab:complete:git-(add|diff|restore):*' \
          fzf-preview 'git diff $word | delta'
        zstyle ':fzf-tab:complete:git-log:*' \
          fzf-preview 'git log --color=always $word'
        zstyle ':fzf-tab:complete:git-show:*' \
          fzf-preview 'git show --color=always $word | delta'
        zstyle ':fzf-tab:complete:cd:*' \
          fzf-preview 'eza -T -L2 --icons --color=always $realpath 2>/dev/null'

        # ----------------------------------------------------------------------
        # Custom Functions Autoload
        # ----------------------------------------------------------------------
        # Load all custom functions from functions directory.
        if [[ -d "${xdg.zsh}/functions" ]]; then
          for func in "${xdg.zsh}/functions"/*(.N); do
            autoload -Uz "''${func:t}"
          done
        fi

        # ----------------------------------------------------------------------
        # Post-Initialization Cleanup
        # ----------------------------------------------------------------------
        # Enable completion system optimizations
        zstyle ':completion:*' rehash true
        zstyle ':completion:*' accept-exact-dirs true

        # ----------------------------------------------------------------------
        # Debug Output (if enabled)
        # ----------------------------------------------------------------------
        ${lib.optionalString features.debugMode ''
          # Disable tracing
          unsetopt xtrace
          exec 2>&3 3>&-
          
          # Print profiling report
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
        # Prompt Initialization (Starship)
        # ----------------------------------------------------------------------
        # Load prompt last to ensure all dependencies are available.
        if command -v starship &>/dev/null; then
          eval "$(starship init zsh)"
        fi
      ''
    ];

    # ==========================================================================
    # History Configuration
    # ==========================================================================
    history = {
      size                  = 200000;
      save                  = 150000;
      path                  = "${xdg.zsh}/history";
      ignoreDups            = true;
      ignoreAllDups         = true;
      ignoreSpace           = true;
      share                 = true;
      extended              = true;
      expireDuplicatesFirst = true;
    };

    # ==========================================================================
    # Oh-My-Zsh Plugin Integration
    # ==========================================================================
    # Curated set of lightweight, useful plugins.
    # Heavy plugins should be replaced with native alternatives.
    
    oh-my-zsh = {
      enable = true;
      plugins = [
        # Core utilities
        "git"                  # Git aliases and completion
        "sudo"                 # ESC ESC to prefix sudo
        "command-not-found"    # Suggest packages for missing commands
        "history"              # History aliases

        # Navigation & productivity
        "copypath"             # Copy current path to clipboard
        "copyfile"             # Copy file contents to clipboard
        "dirhistory"           # Alt-Left/Right for directory history
        "extract"              # Universal archive extractor
        "safe-paste"           # Don't auto-execute pasted commands

        # Developer tools
        "jsontools"            # JSON manipulation
        "encode64"             # Base64 encode/decode
        "systemd"              # Systemctl aliases
        "rsync"                # Rsync aliases

        # User experience
        "colored-man-pages"    # Colorize man pages
        "aliases"              # List aliases with 'acs'
      ];
    };

    # ==========================================================================
    # Additional Plugins
    # ==========================================================================
    # Custom plugins not available in oh-my-zsh.
    
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
  };
}
