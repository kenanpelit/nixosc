# modules/home/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration — Zinit + Maximum Performance
# Author: Kenan Pelit
# Last Updated: 2025-11
#
# Design Philosophy:
#   ╭─────────────────────────────────────────────────────────────────────╮
#   │ 1. PERFORMANCE: Zinit turbo mode, async loading, sub-100ms startup │
#   │ 2. RELIABILITY: Atomic operations, error handling, race prevention  │
#   │ 3. PORTABILITY: SSH-aware, multi-machine, XDG-compliant            │
#   │ 4. MAINTAINABILITY: Modular, documented, testable                  │
#   ╰─────────────────────────────────────────────────────────────────────╯
#
# Features:
#   • Zinit plugin manager with turbo mode
#   • XDG Base Directory compliant
#   • Aggressive bytecode compilation
#   • SSH-optimized profile
#   • Smart cache management
#   • Lazy loading for heavy tools
#   • FZF/fzf-tab/eza/zoxide/direnv/atuin integration
#
# Performance Targets:
#   • Interactive startup: <80ms (excellent), <100ms (good)
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
    zinitTurbo      = true;   # Enable Zinit turbo mode (wait'0')
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
  # ============================================================================
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
    
    # Clean Zinit cache (>30 days)
    [[ -d "${xdg.data}/zinit" ]] && \
      find "${xdg.data}/zinit" -type f -name "*.zwc" -mtime +30 -delete 2>/dev/null || true
    
    log "Cache cleanup complete"
  '';

in
{
  # ============================================================================
  # Home Manager Activation Hooks
  # ============================================================================
  
  home.activation = lib.mkMerge [
    # Directory structure setup
    {
      zshCacheSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run mkdir -p "${xdg.cache}/.zcompcache" "${xdg.data}" "${xdg.state}"
        run mkdir -p "${xdg.data}/zinit"
        run touch "${xdg.cache}/.compinit.lock"
        run echo "✓ ZSH directory structure initialized"
      '';
    }

    # Asynchronous cache cleanup
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
    enableCompletion = lib.mkForce false;  # Zinit handles this
    
    # Disable Home Manager's built-ins (Zinit manages these)
    autosuggestion.enable     = false;
    syntaxHighlighting.enable = false;

    # ==========================================================================
    # Environment Variables
    # ==========================================================================
    
    sessionVariables = {
      # XDG
      ZDOTDIR       = xdg.zsh;
      ZSH_CACHE_DIR = xdg.cache;
      ZSH_DATA_DIR  = xdg.data;
      ZSH_STATE_DIR = xdg.state;
      
      # Zinit
      ZINIT_HOME = "${xdg.data}/zinit/zinit.git";

      # Completion
      ZSH_COMPDUMP = "${xdg.cache}/zcompdump-$HOST-$ZSH_VERSION";

      # Default Apps
      EDITOR   = "nvim";
      VISUAL   = "nvim";
      TERMINAL = "kitty";
      BROWSER  = "brave";
      PAGER    = "less";

      # Locale
      LANG   = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # History
      HISTSIZE = "200000";
      SAVEHIST = "150000";
      HISTFILE = "${xdg.zsh}/history";

      # Pager
      LESS         = "-R --use-color -Dd+r -Du+b -DS+y -DP+k";
      LESSHISTFILE = "-";
      LESSCHARSET  = "utf-8";
      MANPAGER     = "sh -c 'col -bx | bat -l man -p'";
      MANWIDTH     = "100";

      # Performance
      ZSH_DISABLE_COMPFIX     = "true";
      COMPLETION_WAITING_DOTS = "true";
    };

    # ==========================================================================
    # Shell Initialization
    # ==========================================================================
    
    initContent = lib.mkMerge [
      # ========================================================================
      # PHASE 0: Early Initialization
      # ========================================================================
      (lib.mkBefore ''
        ${lib.optionalString features.debugMode ''
          zmodload zsh/zprof
          typeset -F SECONDS
          PS4=$'%D{%M%S%.} %N:%i> '
          exec 3>&2 2>"/tmp/zsh-trace-$$.log"
          setopt xtrace prompt_subst
          echo "=== ZSH Debug Mode Active ==="
          echo "Trace log: /tmp/zsh-trace-$$.log"
        ''}

        # XDG fallbacks
        : ''${XDG_CONFIG_HOME:=$HOME/.config}
        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        : ''${XDG_DATA_HOME:=$HOME/.local/share}
        : ''${XDG_STATE_HOME:=$HOME/.local/state}
        export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

        # Path deduplication
        typeset -gU path PATH cdpath CDPATH fpath FPATH manpath MANPATH

        # User paths
        path=(
          $HOME/.local/bin
          $HOME/bin
          /usr/local/bin
          $path
        )

        # TTY configuration
        if [[ -t 0 && -t 1 ]]; then
          stty -ixon 2>/dev/null || true
        fi

        # Nix integration
        export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
        [[ -f "$HOME/.nix-profile/etc/profile.d/command-not-found.sh" ]] && \
          source "$HOME/.nix-profile/etc/profile.d/command-not-found.sh"
      '')

      # ========================================================================
      # PHASE 1: Zinit Installation & Bootstrap
      # ========================================================================
      ''
        # ----------------------------------------------------------------------
        # Zinit Auto-Installation
        # ----------------------------------------------------------------------
        if [[ ! -d "$ZINIT_HOME" ]]; then
          mkdir -p "$(dirname "$ZINIT_HOME")"
          ${pkgs.git}/bin/git clone --depth=1 \
            https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
        fi

        # Load Zinit
        source "$ZINIT_HOME/zinit.zsh"

        # Zinit annexes (optional but recommended)
        zinit light-mode for \
          zdharma-continuum/zinit-annex-bin-gem-node \
          zdharma-continuum/zinit-annex-patch-dl

        # ----------------------------------------------------------------------
        # ZLE Configuration
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
        # ----------------------------------------------------------------------
        
        # Navigation
        setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT PUSHD_TO_HOME

        # Globbing
        setopt EXTENDED_GLOB GLOB_DOTS NUMERIC_GLOB_SORT NO_CASE_GLOB NO_NOMATCH

        # Completion
        setopt COMPLETE_IN_WORD ALWAYS_TO_END AUTO_MENU AUTO_LIST
        setopt AUTO_PARAM_SLASH NO_MENU_COMPLETE LIST_PACKED

        # History
        setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS
        setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
        setopt HIST_SAVE_NO_DUPS HIST_VERIFY SHARE_HISTORY INC_APPEND_HISTORY

        # UX
        setopt INTERACTIVE_COMMENTS NO_BEEP PROMPT_SUBST TRANSIENT_RPROMPT
        setopt NO_FLOW_CONTROL COMBINING_CHARS

        # Safety
        setopt NO_CLOBBER NO_RM_STAR_SILENT CORRECT

        HISTORY_IGNORE="(ls|cd|pwd|exit|clear|history|cd ..|cd -|z *|zi *)"

        # Disable globbing for specific commands
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

        if command -v rg &>/dev/null; then
          export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!{.git,.cache,node_modules}/*"'
        elif command -v fd &>/dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
        fi

        if command -v fd &>/dev/null; then
          export FZF_CTRL_T_COMMAND='fd --type f --type d --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
          export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --strip-cwd-prefix -E .git -E .cache -E node_modules'
        fi

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

        if command -v eza &>/dev/null; then
          export EZA_COLORS="da=1;34:gm=1;34"
          export EZA_ICON_SPACING=2
        fi

        # ----------------------------------------------------------------------
        # Lazy Loading
        # ----------------------------------------------------------------------
        ${lib.optionalString features.lazyLoading ''
          # NVM
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

          # RVM
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

          # pyenv
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

          # Conda
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
        # ZINIT PLUGINS - Performance Optimized Loading Order
        # ======================================================================
        # Load order matters for optimal performance:
        #   1. Completions (adds to fpath)
        #   2. fzf-tab (BEFORE compinit)
        #   3. compinit (initialization)
        #   4. Other plugins (AFTER compinit)
        #   5. Syntax highlighting (LAST - wraps ZLE)
        # ======================================================================

        # ----------------------------------------------------------------------
        # 1. COMPLETIONS (Instant Load - adds to fpath)
        # ----------------------------------------------------------------------
        zinit ice blockf atpull'zinit creinstall -q .'
        zinit light zsh-users/zsh-completions

        # ----------------------------------------------------------------------
        # 2. FZF-TAB (Instant Load - BEFORE compinit)
        # ----------------------------------------------------------------------
        zinit ice depth=1
        zinit light Aloxaf/fzf-tab

        # Configure fzf-tab
        zstyle ':fzf-tab:*' fzf-command fzf
        zstyle ':fzf-tab:*' fzf-min-height 100
        zstyle ':fzf-tab:*' switch-group ',' '.'
        zstyle ':fzf-tab:*' continuous-trigger '/'
        zstyle ':fzf-tab:complete:*:*' fzf-preview ""
        zstyle ':fzf-tab:complete:*:*' fzf-flags --height=80% --border=rounded --bind='ctrl-/:toggle-preview'

        zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w'
        zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
        zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
        zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
        zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | delta'
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -T -L2 --icons --color=always $realpath 2>/dev/null'

        # ----------------------------------------------------------------------
        # 3. COMPINIT (Safe, Fast, Cached)
        # ----------------------------------------------------------------------
        fpath=("${xdg.zsh}/completions" "${xdg.zsh}/functions" $fpath)

        autoload -Uz compinit
        zmodload zsh/system 2>/dev/null || true

        : ''${ZSH_COMPDUMP:="${xdg.cache}/zcompdump-$HOST-$ZSH_VERSION"}
        zstyle ':completion:*' dump-file "$ZSH_COMPDUMP"

        _safe_compinit() {
          local _lock_file="${xdg.cache}/.compinit-''${HOST}-''${ZSH_VERSION}.lock"
          local _dump_dir="$(dirname "$ZSH_COMPDUMP")"

          [[ -d "$_dump_dir" ]] || mkdir -p "$_dump_dir"

          local -i need_rebuild=0
          
          if [[ ! -s "$ZSH_COMPDUMP" || -n $ZSH_COMPDUMP(#qN.mh+24) ]]; then
            need_rebuild=1
          fi

          if (( need_rebuild == 0 )); then
            compinit -C -i -d "$ZSH_COMPDUMP"
            if [[ ! -f "$ZSH_COMPDUMP.zwc" || "$ZSH_COMPDUMP" -nt "$ZSH_COMPDUMP.zwc" ]]; then
              { zcompile -U "$ZSH_COMPDUMP" 2>/dev/null || true; } &!
            fi
            return 0
          fi

          if command -v zsystem &>/dev/null; then
            if ! zsystem flock -t 0.1 "$_lock_file" 2>/dev/null; then
              compinit -C -i -d "$ZSH_COMPDUMP"
              return 0
            fi
          fi

          compinit -u -i -d "$ZSH_COMPDUMP"
          { zcompile -U "$ZSH_COMPDUMP" 2>/dev/null || true; } &!
          command -v zsystem &>/dev/null && zsystem flock -u "$_lock_file" 2>/dev/null || true
        }

        _safe_compinit
        autoload -Uz bashcompinit && bashcompinit

        # Completion styles
        autoload -Uz colors && colors
        _comp_options+=(globdots)

        zstyle ':completion:*' completer _extensions _complete _approximate _ignored
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "${xdg.cache}/.zcompcache"
        zstyle ':completion:*' complete true
        zstyle ':completion:*' complete-options true

        zstyle ':completion:*' matcher-list \
          'm:{a-zA-Z}={A-Za-z}' \
          'r:|[._-]=* r:|=*' \
          'l:|=* r:|=*'

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

        zstyle ':completion:*:descriptions' format '%F{yellow}━━ %d ━━%f'
        zstyle ':completion:*:messages'     format '%F{purple}━━ %d ━━%f'
        zstyle ':completion:*:warnings'     format '%F{red}━━ no matches found ━━%f'
        zstyle ':completion:*:corrections'  format '%F{green}━━ %d (errors: %e) ━━%f'

        zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w"
        zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
        zstyle ':completion:*:*:kill:*' menu yes select
        zstyle ':completion:*:*:kill:*' force-list always
        zstyle ':completion:*:*:kill:*' insert-ids single

        zstyle ':completion:*:manuals' separate-sections true
        zstyle ':completion:*:manuals.*' insert-sections true

        zstyle ':completion:*:(ssh|scp|rsync):*' tag-order \
          'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address'
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' \
          ignored-patterns '*(.|:)*' loopback localhost broadcasthost
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' \
          ignored-patterns '<->.<->.<->.<->' '*@*'
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' \
          ignored-patterns '^(<->.<->.<->.<->)' '127.0.0.<->' '::1' 'fe80::*'

        zstyle ':completion:*' rehash true
        zstyle ':completion:*' accept-exact-dirs true

        # ----------------------------------------------------------------------
        # 4. TURBO MODE PLUGINS (Load with 0ms delay - imperceptible)
        # ----------------------------------------------------------------------
        ${lib.optionalString features.zinitTurbo ''
          # History substring search
          zinit ice wait lucid
          zinit light zsh-users/zsh-history-substring-search
          bindkey '^[[A' history-substring-search-up
          bindkey '^[[B' history-substring-search-down
          bindkey '^[OA' history-substring-search-up
          bindkey '^[OB' history-substring-search-down

          # Auto-suggestions
          zinit ice wait lucid atload'_zsh_autosuggest_start'
          zinit light zsh-users/zsh-autosuggestions

          # Autopair
          zinit ice wait lucid
          zinit light hlissner/zsh-autopair

          # OMZ Plugins (only the essential ones)
          zinit ice wait lucid
          zinit snippet OMZ::plugins/sudo/sudo.plugin.zsh

          zinit ice wait lucid
          zinit snippet OMZ::plugins/extract/extract.plugin.zsh

          zinit ice wait lucid
          zinit snippet OMZ::plugins/copypath/copypath.plugin.zsh

          zinit ice wait lucid
          zinit snippet OMZ::plugins/copyfile/copyfile.plugin.zsh

          # Git aliases (lightweight custom)
          zinit ice wait lucid
          zinit snippet OMZ::plugins/git/git.plugin.zsh
        ''}

        # ----------------------------------------------------------------------
        # 5. SYNTAX HIGHLIGHTING (LAST - Wraps ZLE)
        # ----------------------------------------------------------------------
        ${lib.optionalString features.zinitTurbo ''
          zinit ice wait lucid atinit'zicompinit; zicdreplay'
          zinit light zdharma-continuum/fast-syntax-highlighting
        ''}

        # Non-turbo fallback (if turbo disabled)
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

          zinit light zdharma-continuum/fast-syntax-highlighting
        ''}

        # ----------------------------------------------------------------------
        # Tool Integrations (Local only)
        # ----------------------------------------------------------------------
        if [[ -z $_SSH_LIGHT_MODE ]]; then
          command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
          
          if command -v direnv &>/dev/null; then
            eval "$(direnv hook zsh)"
            export DIRENV_LOG_FORMAT=""
          fi

          if command -v atuin &>/dev/null; then
            export ATUIN_NOBIND="true"
            eval "$(atuin init zsh)"
            bindkey '^r' _atuin_search_widget
          fi
        fi

        # ----------------------------------------------------------------------
        # Custom Functions
        # ----------------------------------------------------------------------
        if [[ -d "${xdg.zsh}/functions" ]]; then
          for func in "${xdg.zsh}/functions"/*(.N); do
            autoload -Uz "''${func:t}"
          done
        fi

        # ----------------------------------------------------------------------
        # Debug Output
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
        # Prompt (Starship)
        # ----------------------------------------------------------------------
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
  };
}

