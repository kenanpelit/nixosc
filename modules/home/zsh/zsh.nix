# modules/home/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration — Maximum Performance & Reliability
# Author: Kenan Pelit
# Last Updated: 2025-11
#
# Design goals:
#   - Home Manager ile tam uyum (initContent, absolute dotDir)
#   - XDG uyumlu dizinler (config/cache/data/state)
#   - Bytecode derleme (zcompile) + akıllı cache temizliği
#   - SSH'de hafif profil, lokal shell'de tam özellik
#   - FZF / fzf-tab / eza / zoxide / direnv / atuin entegrasyonu
# ==============================================================================

{ hostname, config, pkgs, host, lib, ... }:

let
  # ============================================================================
  # Feature Matrix — Compile-time switches
  # ============================================================================
  features = {
    performance     = true;   # Cache + compinit fast-path
    bytecode        = true;   # zcompile .zshrc + pluginler
    lazyLoading     = true;   # nvm / conda / pyenv / rvm lazy init
    sshOptimization = true;   # SSH'de hafif profil
    debugMode       = false;  # zprof + xtrace
  };

  # ============================================================================
  # XDG paths
  # ============================================================================
  xdg = {
    zsh   = "${config.xdg.configHome}/zsh";
    cache = "${config.xdg.cacheHome}/zsh";
    data  = "${config.xdg.dataHome}/zsh";
    state = "${config.xdg.stateHome}/zsh";
  };

  # ============================================================================
  # Smart Compilation Engine
  # ============================================================================
  compileScript = pkgs.writeShellScript "zsh-compile" ''
    set -euo pipefail

    echo "🚀 ZSH Bytecode Compilation"

    compile_file() {
      local src="$1"
      local dst="$src.zwc"

      # Kaynak yoksa geç
      [[ -f "$src" ]] || return 0

      # Up-to-date ise atla
      if [[ -f "$dst" && "$dst" -nt "$src" ]]; then
        return 0
      fi

      if "${pkgs.zsh}/bin/zsh" -c "zcompile '$src'" 2>/dev/null; then
        echo "  ✓ $src"
      fi
    }

    # Ana rc dosyası
    compile_file "${xdg.zsh}/.zshrc"

    # Plugin .zsh dosyaları (parallel)
    if [[ -d "${xdg.zsh}/plugins" ]]; then
      find "${xdg.zsh}/plugins" -type f -name '*.zsh' -print0 2>/dev/null \
        | xargs -0 -n1 -P8 -I{} "${pkgs.zsh}/bin/zsh" -c 'compile_file "$0"' {}
    fi

    echo "✅ Compilation complete"
  '';

in
{
  # ============================================================================
  # Home Activation — build-time işleri
  # ============================================================================
  home.activation = lib.mkMerge [
    # Bytecode derleme
    (lib.mkIf features.bytecode {
      zshCompile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${compileScript}
      '';
    })

    # Cache / state dizinleri + eski dump temizliği
    {
      zshCacheSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${xdg.cache}/.zcompcache" "${xdg.data}" "${xdg.state}" 2>/dev/null || true

        # Lock dosyası yoksa oluştur (flock / zsystem için)
        : > "${xdg.cache}/.compinit.lock" 2>/dev/null || true

        # Config dizinindeki legacy .zcompdump'ları temizle
        find "${xdg.zsh}" -maxdepth 1 -name ".zcompdump*" -delete 2>/dev/null || true
      '';
    }

    # Eski cacheleri temizle (asenkron, build'i bloklamaz)
    {
      zshCacheCleanup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        (
          set +e
          trap 'exit 0' ERR

          # 30 günden eski zcompdump
          find "${xdg.cache}" -type f -name 'zcompdump-*' -mtime +30 -delete 2>/dev/null

          # Orphan .zwc dosyaları
          find "${xdg.zsh}" "${xdg.cache}" -type f -name '*.zwc' 2>/dev/null \
            | while IFS= read -r zwc; do
                [[ -f "''${zwc%.zwc}" ]] || rm -f "$zwc" 2>/dev/null
              done

          # 7 günden eski completion cache
          find "${xdg.cache}/.zcompcache" -type f -mtime +7 -delete 2>/dev/null

          exit 0
        ) &

        run echo "🧹 ZSH cache cleanup scheduled"
      '';
    }
  ];

  # ============================================================================
  # Directory Skeleton
  # ============================================================================
  home.file = {
    "${xdg.zsh}/completions/.keep".text = "";
    "${xdg.zsh}/functions/.keep".text   = "";
  };

  # ============================================================================
  # ZSH Configuration
  # ============================================================================
  programs.zsh = {
    enable           = true;
    dotDir           = xdg.zsh;          # 🔥 Artık absolute path, uyarı yok
    autocd           = true;
    enableCompletion = lib.mkForce false; # compinit'i biz yönetiyoruz

    autosuggestion.enable     = true;
    syntaxHighlighting.enable = true;

    # ========================================================================
    # Environment — minimum ama yeterli
    # ========================================================================
    sessionVariables = {
      # XDG
      ZDOTDIR       = xdg.zsh;
      ZSH_CACHE_DIR = xdg.cache;
      ZSH_DATA_DIR  = xdg.data;
      ZSH_STATE_DIR = xdg.state;

      # Completion dump
      ZSH_COMPDUMP  = "${xdg.cache}/zcompdump-$HOST-$ZSH_VERSION";

      # Core tools
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

    # ========================================================================
    # INIT — yeni API: initContent (+ mkBefore)
    # ========================================================================
    initContent = lib.mkMerge [
      # ------------------- PHASE 0–1: eski initExtraFirst -------------------
      (lib.mkBefore ''
        ${lib.optionalString features.debugMode ''
          zmodload zsh/zprof
          typeset -F SECONDS
          PS4=$'%D{%M%S%.} %N:%i> '
          exec 3>&2 2>"/tmp/zsh-trace-$$.log"
          setopt xtrace prompt_subst
        ''}

        # XDG env varsa kullan, yoksa fallback
        : ''${XDG_CONFIG_HOME:=$HOME/.config}
        : ''${XDG_CACHE_HOME:=$HOME/.cache}
        : ''${XDG_DATA_HOME:=$HOME/.local/share}
        : ''${XDG_STATE_HOME:=$HOME/.local/state}
        export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME

        # PATH & fpath uniq
        typeset -gU path PATH cdpath CDPATH fpath FPATH manpath MANPATH

        path=(
          $HOME/.local/bin
          $HOME/bin
          /usr/local/bin
          $path
        )

        # Sadece TTY ise stty uygula
        if [[ -t 0 ]]; then
          stty -ixon 2>/dev/null || true
        fi

        # Nix PATH (isteğe göre kaldırılabilir)
        export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"

        # command-not-found (varsa)
        [[ -f "$HOME/.nix-profile/etc/profile.d/command-not-found.sh" ]] && \
          source "$HOME/.nix-profile/etc/profile.d/command-not-found.sh"
      '')

      # -------------------------- PHASE 2–3: ana init ------------------------
      ''
        # --------------------------------------------------------------------
        # ZLE — line editor
        # --------------------------------------------------------------------
        autoload -Uz url-quote-magic bracketed-paste-magic edit-command-line

        zle -N self-insert url-quote-magic
        zle -N bracketed-paste bracketed-paste-magic
        zle -N edit-command-line

        zstyle ':url-quote-magic:*' url-metas '*?[]^()~#{}='
        zstyle ':bracketed-paste-magic' active-widgets '.self-*'

        # --------------------------------------------------------------------
        # Shell Options
        # --------------------------------------------------------------------
        # Navigation
        setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT PUSHD_TO_HOME

        # Globbing
        setopt EXTENDED_GLOB GLOB_DOTS NUMERIC_GLOB_SORT NO_CASE_GLOB

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

        # History ignore patterns
        HISTORY_IGNORE="(ls|cd|pwd|exit|cd ..|cd -|z *|zi *)"

        # Bazı komutlarda glob kapat
        alias nix='noglob nix'
        alias git='noglob git'
        alias find='noglob find'
        alias rsync='noglob rsync'
        alias scp='noglob scp'

        # --------------------------------------------------------------------
        # FZF — temel ayarlar
        # --------------------------------------------------------------------
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

        # --------------------------------------------------------------------
        # Lazy Loading
        # --------------------------------------------------------------------
        ${lib.optionalString features.lazyLoading ''
          # nvm
          if [[ -d "$HOME/.nvm" ]]; then
            _lazy_nvm() {
              unset -f _lazy_nvm
              unalias nvm 2>/dev/null || true
              unalias node 2>/dev/null || true
              unalias npm 2>/dev/null || true
              unalias npx 2>/dev/null || true
              export NVM_DIR="$HOME/.nvm"
              source "$NVM_DIR/nvm.sh"
              nvm "$@"
            }
            alias nvm=_lazy_nvm
            alias node=_lazy_nvm
            alias npm=_lazy_nvm
            alias npx=_lazy_nvm
          fi

          # rvm
          if [[ -d "$HOME/.rvm" ]]; then
            _lazy_rvm() {
              unset -f _lazy_rvm
              unalias rvm 2>/dev/null || true
              unalias ruby 2>/dev/null || true
              unalias gem 2>/dev/null || true
              unalias bundle 2>/dev/null || true
              source "$HOME/.rvm/scripts/rvm"
              rvm "$@"
            }
            alias rvm=_lazy_rvm
            alias ruby=_lazy_rvm
            alias gem=_lazy_rvm
            alias bundle=_lazy_rvm
          fi

          # pyenv
          if [[ -d "$HOME/.pyenv" ]]; then
            _lazy_pyenv() {
              unset -f _lazy_pyenv
              unalias pyenv 2>/dev/null || true
              unalias python 2>/dev/null || true
              unalias pip 2>/dev/null || true
              export PYENV_ROOT="$HOME/.pyenv"
              path=("$PYENV_ROOT/bin" $path)
              eval "$(pyenv init --path)"
              eval "$(pyenv init -)"
              pyenv "$@"
            }
            alias pyenv=_lazy_pyenv
            alias python=_lazy_pyenv
            alias pip=_lazy_pyenv
          fi

          # conda
          if [[ -d "$HOME/.conda/miniconda3" || -d "$HOME/.conda/anaconda3" ]]; then
            _lazy_conda() {
              unset -f _lazy_conda
              unalias conda 2>/dev/null || true
              eval "$(conda shell.zsh hook 2>/dev/null)"
              conda "$@"
            }
            alias conda=_lazy_conda
          fi
        ''}

        # --------------------------------------------------------------------
        # SSH Profil
        # --------------------------------------------------------------------
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

        # --------------------------------------------------------------------
        # Tool Integrations (lokalde tam, SSH'de hafif)
        # --------------------------------------------------------------------
        if [[ -z $_SSH_LIGHT_MODE ]]; then
          command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
          if command -v direnv &>/dev/null; then
            eval "$(direnv hook zsh)"
            export DIRENV_LOG_FORMAT=""
          fi
          command -v atuin &>/dev/null && eval "$(atuin init zsh --disable-up-arrow)"
        fi

        # --------------------------------------------------------------------
        # Completion System — tek compinit, cache'li
        # --------------------------------------------------------------------
        fpath=(
          "${xdg.zsh}/completions"
          "${xdg.zsh}/plugins/zsh-completions/src"
          "${xdg.zsh}/functions"
          $fpath
        )

        autoload -Uz compinit
        zmodload zsh/system 2>/dev/null || true

        # Canonical dump target (env'den gelmezse fallback)
        : ''${ZSH_COMPDUMP:="${xdg.cache}/zcompdump-$HOST-$ZSH_VERSION"}
        zstyle ':completion:*' dump-file "$ZSH_COMPDUMP"

        _safe_compinit() {
          local _lock_file="${xdg.cache}/.compinit-''${HOST}-''${ZSH_VERSION}.lock"

          [[ -d "${xdg.cache}" ]] || mkdir -p "${xdg.cache}"

          local -i need_rebuild=0
          if [[ ! -s "$ZSH_COMPDUMP" || -n $ZSH_COMPDUMP(#qN.mh+24) ]]; then
            need_rebuild=1
          fi

          if (( need_rebuild == 0 )); then
            compinit -C -i -d "$ZSH_COMPDUMP"
            if [[ ! -f "$ZSH_COMPDUMP.zwc" || "$ZSH_COMPDUMP" -nt "$ZSH_COMPDUMP.zwc" ]]; then
              { zcompile "$ZSH_COMPDUMP" 2>/dev/null || true; } &!
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
          { zcompile "$ZSH_COMPDUMP" 2>/dev/null || true; } &!
          command -v zsystem &>/dev/null && zsystem flock -u "$_lock_file" 2>/dev/null || true
        }

        _safe_compinit
        autoload -Uz bashcompinit && bashcompinit

        # --------------------------------------------------------------------
        # Completion Styles
        # --------------------------------------------------------------------
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
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host'   ignored-patterns '*(.|:)*' loopback localhost broadcasthost
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '*@*'
        zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->)' '127.0.0.<->' '::1' 'fe80::*'

        # fzf-tab
        zstyle ':fzf-tab:*' fzf-command fzf
        zstyle ':fzf-tab:*' fzf-min-height 100
        zstyle ':fzf-tab:*' switch-group ',' '.'
        zstyle ':fzf-tab:*' continuous-trigger '/'
        zstyle ':fzf-tab:complete:*:*' fzf-preview ""
        zstyle ':fzf-tab:complete:*:*' fzf-flags --height=80% --border=rounded --bind='ctrl-/:toggle-preview'

        zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w'
        zstyle ':fzf-tab:complete:systemctl-*:*'      fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
        zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
        zstyle ':fzf-tab:complete:git-log:*'          fzf-preview 'git log --color=always $word'
        zstyle ':fzf-tab:complete:git-show:*'         fzf-preview 'git show --color=always $word | delta'
        zstyle ':fzf-tab:complete:cd:*'               fzf-preview 'eza -T -L2 --icons --color=always $realpath 2>/dev/null'

        # --------------------------------------------------------------------
        # Functions autoload + post-init
        # --------------------------------------------------------------------
        if [[ -d "${xdg.zsh}/functions" ]]; then
          for func in "${xdg.zsh}/functions"/*(.N); do
            autoload -Uz "''${func:t}"
          done
        fi

        zstyle ':completion:*' rehash true
        zstyle ':completion:*' accept-exact-dirs true

        ${lib.optionalString features.debugMode ''
          unsetopt xtrace
          exec 2>&3 3>&-
          echo "\n╔════════════════════════════════════════╗"
          echo "║       ZSH Startup Profile              ║"
          echo "╚════════════════════════════════════════╝"
          zprof | head -25
          echo "\n⏱️  Total time: ''${SECONDS}s"
        ''}

        # Prompt en sonda (Starship)
        if command -v starship &>/dev/null; then
          eval "$(starship init zsh)"
        fi
      ''
    ];

    # ========================================================================
    # History
    # ========================================================================
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

    # ========================================================================
    # Oh-My-Zsh Plugins — hafif ama faydalı set
    # ========================================================================
    oh-my-zsh = {
      enable = true;
      plugins = [
        # Core
        "git"
        "sudo"
        "command-not-found"
        "history"

        # Navigation & productivity
        "copypath"
        "copyfile"
        "dirhistory"
        "extract"
        "safe-paste"

        # Dev tools
        "jsontools"
        "encode64"
        "systemd"
        "rsync"

        # UX
        "colored-man-pages"
        "aliases"
      ];
    };
  };
}
