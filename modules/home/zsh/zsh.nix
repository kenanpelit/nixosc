# modules/home/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration — Ultra Performance & Reliability
# Author: Kenan Pelit
# Description:
#   • Optimized bytecode compilation with parallel processing
#   • Lock-free compinit with smart fingerprinting
#   • Minimal XDG setup with lazy directory creation
#   • Lazy loading for heavy toolchains
#   • FZF/FZF-Tab with instant preview toggling
#   • Reduced startup overhead through deferred operations
# ==============================================================================

{ hostname, config, pkgs, host, lib, ... }:

let
  # ----------------------------------------------------------------------------
  # Feature toggles
  # ----------------------------------------------------------------------------
  enablePerformanceOpts = true;
  enableBytecodeCompile = true;
  enableLazyLoading    = true;
  enableDebugMode      = false;

  # ----------------------------------------------------------------------------
  # XDG paths
  # ----------------------------------------------------------------------------
  zshDir   = "${config.xdg.configHome}/zsh";
  cacheDir = "${config.xdg.cacheHome}/zsh";
  dataDir  = "${config.xdg.dataHome}/zsh";
  stateDir = "${config.xdg.stateHome}/zsh";
in
{
  # =============================================================================
  # Home Activation — Optimized compilation & maintenance
  # =============================================================================
  home.activation = lib.mkMerge [
    # Bytecode compilation with parallel processing
    (lib.mkIf enableBytecodeCompile {
      zshCompile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run echo "🚀 Compiling ZSH files..."

        # Parallel compile function
        ${pkgs.zsh}/bin/zsh -c '
          compile_batch() {
            local -a files=("$@")
            local file
            for file in $files; do
              if [[ -f "$file" && ( ! -f "$file.zwc" || "$file" -nt "$file.zwc" ) ]]; then
                zcompile "$file" 2>/dev/null || true
              fi
            done
          }

          # Main RC
          [[ -f "${zshDir}/.zshrc" ]] && zcompile "${zshDir}/.zshrc" 2>/dev/null || true

          # Plugins in parallel batches
          if [[ -d "${zshDir}/plugins" ]]; then
            local -a plugin_files
            plugin_files=("${zshDir}/plugins"/**/*.zsh(N))
            
            if (( ''${#plugin_files} > 0 )); then
              # Split into batches for parallel processing
              local batch_size=10
              local i
              for ((i=1; i<=''${#plugin_files}; i+=batch_size)); do
                compile_batch "''${plugin_files[@]:$i:$batch_size}" &
              done
              wait
            fi
          fi
        ' 2>/dev/null || true

        run echo "✅ Compilation completed"
      '';
    })

    # Minimal cache setup
    {
      zshCacheSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${cacheDir}" 2>/dev/null || true
        : > "${cacheDir}/compinit.lock" 2>/dev/null || true
      '';
    }

    # Cleanup old cache files (optimized with single find)
    {
      zshCacheCleanup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run echo "🧹 Cache cleanup..."
        (
          set +e
          [[ -d "${cacheDir}" ]] || exit 0
          
          # Single find for all cleanup operations
          find "${cacheDir}" \( \
            -name 'zcompdump*' -mtime +30 -o \
            -name '*.zwc' -type f \
          \) -delete 2>/dev/null || true
          
          # Orphan .zwc cleanup
          [[ -d "${zshDir}" ]] && find "${zshDir}" -name '*.zwc' -type f | while read zwc; do
            [[ -f "''${zwc%.zwc}" ]] || rm -f "$zwc" 2>/dev/null || true
          done
        ) &
        run echo "✅ Cleanup scheduled"
      '';
    }
  ];

  # =============================================================================
  # Directory structure (lazy creation)
  # =============================================================================
  home.file = {
    "${zshDir}/.keep".text = "";
  };

  # =============================================================================
  # ZSH Program Configuration
  # =============================================================================
  programs.zsh = {
    enable  = true;
    dotDir  = zshDir;  # Use absolute path from let binding
    autocd  = true;
    enableCompletion = true;

    # Environment variables
    sessionVariables = {
      # Performance
      ZSH_DISABLE_COMPFIX = "true";
      COMPLETION_WAITING_DOTS = "true";
      LISTMAX = "0";  # Instant completion listing

      # XDG
      ZDOTDIR       = zshDir;
      ZSH_CACHE_DIR = cacheDir;
      ZSH_DATA_DIR  = dataDir;
      ZSH_STATE_DIR = stateDir;

      # Editor & Terminal
      EDITOR   = "nvim";
      VISUAL   = "nvim";
      TERMINAL = "kitty";
      BROWSER  = "brave";
      PAGER    = "less";
      TERM     = "xterm-256color";

      # Pager config
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      LESS = "-R --use-color -Dd+r -Du+b";
      LESSHISTFILE = "-";

      # Locale
      LC_ALL = "en_US.UTF-8";
      LANG   = "en_US.UTF-8";

      # History
      HISTSIZE = "100000";
      SAVEHIST = "80000";
      HISTFILE = "${zshDir}/history";
    };

    # ----------------------------------------------------------------------------
    # Init content - Modern approach with lib.mkOrder
    # ----------------------------------------------------------------------------
    initContent = lib.mkMerge [
      # Early initialization (before compinit)
      (lib.mkOrder 550 ''
        ${lib.optionalString enableDebugMode ''
          zmodload zsh/zprof
          typeset -F SECONDS
        ''}

        # Skip global compinit for speed
        skip_global_compinit=1

        # Lazy XDG directory creation
        [[ -d "${cacheDir}" ]] || mkdir -p "${cacheDir}"

        # XDG fallbacks
        : ''${XDG_CONFIG_HOME:=$HOME/.config}
        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        : ''${XDG_DATA_HOME:=$HOME/.local/share}
        : ''${XDG_STATE_HOME:=$HOME/.local/state}

        # PATH optimization (typeset -U deduplicates)
        typeset -U path PATH fpath FPATH
        path=(
          $HOME/.local/bin
          $HOME/bin
          $path
        )

        # TTY optimization
        stty -ixon 2>/dev/null || true

        # Nix environment
        [[ -f "$HOME/.nix-profile/etc/profile.d/command-not-found.sh" ]] && \
          source "$HOME/.nix-profile/etc/profile.d/command-not-found.sh"
      '')

      # Main initialization (default order)
      (''
      # ============================= ZLE & Options =============================
      
      # ZLE widgets (lightweight)
      autoload -Uz edit-command-line
      zle -N edit-command-line
      
      # Core options (performance-focused)
      setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
      setopt EXTENDED_GLOB GLOB_DOTS NO_CASE_GLOB
      setopt COMPLETE_IN_WORD AUTO_MENU AUTO_LIST AUTO_PARAM_SLASH
      setopt NO_MENU_COMPLETE LIST_PACKED
      setopt NO_FLOW_CONTROL INTERACTIVE_COMMENTS
      setopt PROMPT_SUBST TRANSIENT_RPROMPT
      setopt NO_BEEP COMBINING_CHARS

      # History options
      setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_SAVE_NO_DUPS
      setopt HIST_VERIFY SHARE_HISTORY INC_APPEND_HISTORY
      
      HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|sudo poweroff)"

      # Disable globbing for select commands
      alias nix='noglob nix'
      alias git='noglob git'

      # ============================= FZF Configuration =========================
      
      export FZF_DEFAULT_OPTS="
        --height=80%
        --layout=reverse
        --info=inline
        --border=rounded
        --cycle
        --bind='ctrl-/:toggle-preview'
        --bind='ctrl-d:half-page-down'
        --bind='ctrl-u:half-page-up'
        --bind='ctrl-a:select-all'
        --bind='ctrl-y:execute-silent(echo {+} | wl-copy)'
        --pointer='▶'
        --marker='✓'
        --prompt='❯ '
        --no-scrollbar
      "
      
      # Smart command detection
      if command -v rg &>/dev/null; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow -g "!.git" -g "!node_modules"'
      elif command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow -E .git -E node_modules'
      fi
      
      if command -v fd &>/dev/null; then
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow -E .git'
      fi

      # ============================= Lazy Loading ==============================
      
      ${lib.optionalString enableLazyLoading ''
        # Generic lazy loader
        __lazy_load() {
          local func_name="$1" init_cmd="$2"
          shift 2
          local -a cmds=("$@")
          
          eval "
            $func_name() {
              unfunction $func_name 2>/dev/null
              for cmd in \''${cmds[@]}; do unalias \$cmd 2>/dev/null; done
              eval '$init_cmd' || return 1
              command \''${cmds[1]} \"\$@\"
            }
          "
          
          for cmd in "''${cmds[@]}"; do
            alias $cmd="$func_name"
          done
        }

        # Lazy load tools
        [[ -d "$HOME/.nvm" ]] && \
          __lazy_load __init_nvm \
            'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"' \
            nvm node npm npx

        [[ -d "$HOME/.pyenv" ]] && \
          __lazy_load __init_pyenv \
            'export PYENV_ROOT="$HOME/.pyenv"; path=("$PYENV_ROOT/bin" $path); eval "$(pyenv init -)"' \
            pyenv python pip

        command -v conda &>/dev/null && \
          __lazy_load __init_conda \
            'eval "$(conda shell.zsh hook)"' \
            conda
      ''}

      # ============================= Tool Integrations =========================
      
      # Fast integrations
      command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
      command -v direnv &>/dev/null && { eval "$(direnv hook zsh)"; export DIRENV_LOG_FORMAT=""; }
      command -v atuin &>/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

      # ============================= Completion Setup ==========================
      
      # Add custom completion paths
      fpath=(
        "${zshDir}/completions"
        "${zshDir}/plugins/zsh-completions/src"
        $fpath
      )

      # Fast compinit with smart caching
      autoload -Uz compinit
      
      # Fingerprint-based cache
      local _zsh_ver="$ZSH_VERSION"
      local _fpath_sum="$(print -rl -- $fpath | md5sum 2>/dev/null | awk '{print $1}')"
      local _zcompdump="${cacheDir}/zcompdump-$HOST-$_zsh_ver-$_fpath_sum"
      
      # Use cache if less than 24h old
      if [[ -s "$_zcompdump" && ! -n $_zcompdump(#qN.mh+24) ]]; then
        compinit -C -d "$_zcompdump"
        # Async recompile if needed
        [[ ! -f "$_zcompdump.zwc" || "$_zcompdump" -nt "$_zcompdump.zwc" ]] && \
          { zcompile "$_zcompdump" 2>/dev/null } &!
      else
        compinit -d "$_zcompdump"
        { zcompile "$_zcompdump" 2>/dev/null } &!
      fi

      autoload -Uz bashcompinit && bashcompinit

      ${lib.optionalString enableDebugMode ''
        echo "\n=== ZSH Startup Profile ==="
        zprof | head -20
      ''}

      # Starship prompt (deferred for speed)
      command -v starship &>/dev/null && eval "$(starship init zsh)"
    '')
    ]; # End of initContent lib.mkMerge

    # ----------------------------------------------------------------------------
    # History config
    # ----------------------------------------------------------------------------
    history = {
      size  = 100000;
      save  = 80000;
      path  = "${zshDir}/history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;
      expireDuplicatesFirst = true;
    };

    # ----------------------------------------------------------------------------
    # Completion styles (streamlined)
    # ----------------------------------------------------------------------------
    completionInit = ''
      autoload -Uz colors && colors
      _comp_options+=(globdots)

      # Core completion
      zstyle ':completion:*' completer _extensions _complete _approximate
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "${cacheDir}/.zcompcache"
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
      zstyle ':completion:*' menu select
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' squeeze-slashes true

      # Descriptions
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'

      # Process completion
      zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,comm -w"
      zstyle ':completion:*:*:kill:*' menu yes select
      zstyle ':completion:*:*:kill:*' force-list always

      # SSH/SCP hosts
      zstyle ':completion:*:(ssh|scp):*:hosts-host' ignored-patterns 'localhost' '127.0.0.*'

      # fzf-tab (minimal config, previews off by default)
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' switch-group ',' '.'
      zstyle ':fzf-tab:complete:*:*' fzf-preview ""
      zstyle ':fzf-tab:complete:*:*' fzf-flags --height=80% --border=rounded --bind='ctrl-/:toggle-preview'
      zstyle ':fzf-tab:complete:kill:*' fzf-preview 'ps -p $word -o cmd'
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -T --level=2 --icons $realpath 2>/dev/null'
    '';

    # ----------------------------------------------------------------------------
    # Oh-My-Zsh plugins (minimal set)
    # ----------------------------------------------------------------------------
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "command-not-found"
        "history"
        "copypath"
        "extract"
        "safe-paste"
      ];
    };
  };
}

