# modules/home/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration — Ultra Performance, Race-free Compinit (lazy), pure-prompt
# Author: Kenan Pelit
# Notes:
#   • Starship kapalı
#   • pure-prompt anında; git async, fetch/pull yok
#   • compinit LAZY (ilk tamamlamada); zcompdump build-time’da üretilip .zwc derlenir
#   • OMZ ve ağır hook’lar ilk prompttan sonra yüklenir
# ==============================================================================

{ config, pkgs, lib, ... }:

let
  enablePerformanceOpts = true;
  enableBytecodeCompile = true;
  enableLazyLoading     = true;
  enableDebugMode       = false;

  zshDir   = "${config.xdg.configHome}/zsh";
  cacheDir = "${config.xdg.cacheHome}/zsh";
  dataDir  = "${config.xdg.dataHome}/zsh";
  stateDir = "${config.xdg.stateHome}/zsh";

  omzPath  = "${pkgs.oh-my-zsh}/share/oh-my-zsh";
in
{
  programs.starship.enable = lib.mkForce false;

  home.packages = [
    pkgs.pure-prompt
    pkgs.zsh-completions
    pkgs.oh-my-zsh
  ];

  # ============================ Home Activation ===============================
  home.activation = lib.mkMerge [
    (lib.mkIf enableBytecodeCompile {
      zshCompile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run echo "🚀 Compiling ZSH files for optimal performance..."

        compile_zsh() {
          local f="$1"
          if [[ -f "$f" && ( ! -f "$f.zwc" || "$f" -nt "$f.zwc" ) ]]; then
            ${pkgs.zsh}/bin/zsh -c "zcompile '$f'" 2>/dev/null || true
            [[ -f "$f.zwc" ]] && run echo "  ✓ Compiled: $f"
          fi
        }

        compile_zsh "${zshDir}/.zshrc"

        if [[ -d "${zshDir}/plugins" ]]; then
          while IFS= read -r -d "" f; do
            compile_zsh "$f" &
          done < <(find "${zshDir}/plugins" -type f -name "*.zsh" -print0 2>/dev/null)
          wait
        fi

        run echo "✅ ZSH bytecode compilation completed"
      '';
    })
    {
      zshCacheEnsure = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${cacheDir}" "${cacheDir}/.zcompcache" 2>/dev/null || true
        : > "${cacheDir}/compinit.lock" 2>/dev/null || true
      '';
    }
    {
      zshCacheLocationFix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        find "${zshDir}" -maxdepth 1 -type f -name ".zcompdump*" -delete 2>/dev/null || true
      '';
    }
    # --- Prebuild zcompdump (no awk; hostname güvenli; mutlak path’ler) ---
    {
      prebuildZcompdump = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run echo "⚡ Prebuilding zcompdump..."
        mkdir -p "${cacheDir}"

        fhash="$(
          {
            ${pkgs.coreutils}/bin/printf "%s\n" "${zshDir}/completions"
            ${pkgs.coreutils}/bin/printf "%s\n" "${zshDir}/plugins/zsh-completions/src"
            ${pkgs.coreutils}/bin/printf "%s\n" "${pkgs.zsh-completions}/share/zsh/site-functions"
            ${pkgs.coreutils}/bin/printf "%s\n" "${zshDir}/functions"
          } | ${pkgs.coreutils}/bin/md5sum | ${pkgs.coreutils}/bin/cut -d' ' -f1
        )"

        zver="$(${pkgs.zsh}/bin/zsh -c 'print -r -- $ZSH_VERSION')"
        host="$(${pkgs.coreutils}/bin/hostname 2>/dev/null || ${pkgs.coreutils}/bin/cat /proc/sys/kernel/hostname 2>/dev/null || echo unknown)"
        dump="${cacheDir}/zcompdump-''${host}-''${zver}-''${fhash}"

        ${pkgs.zsh}/bin/zsh -lc '
          autoload -Uz compinit
          compinit -u -i -d "'"$dump"'"
          [[ -s "'"$dump"'" ]] && zcompile "'"$dump"'" || true
        ' >/dev/null 2>&1 || true

        [[ -s "$dump" ]] && run echo "  ✓ zcompdump ready"
      '';
    }
    {
      zshCacheCleanup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run echo "🧹 Cleaning old ZSH cache files..."
        (
          set +e
          [[ -d "${cacheDir}" ]] || mkdir -p "${cacheDir}"
          [[ -d "${cacheDir}/.zcompcache" ]] || true
          find "${cacheDir}" -type f -name 'zcompdump*' -mtime +30 -delete 2>/dev/null || true
          if [[ -d "${zshDir}" || -d "${cacheDir}" ]]; then
            while IFS= read -r zwc; do
              src="''${zwc%.zwc}"
              [[ -f "$src" ]] || rm -f "$zwc" 2>/dev/null || true
            done < <( ( find "${zshDir}" "${cacheDir}" -type f -name '*.zwc' 2>/dev/null ) || true )
          fi
          if [[ -d "${cacheDir}/.zcompcache" ]]; then
            find "${cacheDir}/.zcompcache" -type f -mtime +7 -delete 2>/dev/null || true
          fi
        )
        run echo "✅ Cache cleanup completed"
      '';
    }
  ];

  # ============================ Files / Dirs ==================================
  home.file = {
    ".ssh/.keep".text = "";
    "${zshDir}/completions/.keep".text = "";
    "${zshDir}/functions/.keep".text   = "";
  };

  # ============================ ZSH Program ===================================
  programs.zsh = {
    enable  = true;
    dotDir  = zshDir;
    autocd  = true;
    enableCompletion = true;

    oh-my-zsh.enable = false; # deferred yükleyeceğiz

    sessionVariables = {
      ZSH_DISABLE_COMPFIX = "true";
      COMPLETION_WAITING_DOTS = "true";

      ZDOTDIR       = zshDir;
      ZSH_CACHE_DIR = cacheDir;
      ZSH_DATA_DIR  = dataDir;
      ZSH_STATE_DIR = stateDir;

      EDITOR   = "nvim";
      VISUAL   = "nvim";
      TERMINAL = "kitty";
      BROWSER  = "brave";
      PAGER    = "less";
      TERM     = "xterm-256color";

      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANWIDTH = "100";
      LESS = "-R --use-color -Dd+r -Du+b -DS+y -DP+k";
      LESSHISTFILE = "-";
      LESSCHARSET  = "utf-8";

      LC_ALL = "en_US.UTF-8";
      LANG   = "en_US.UTF-8";

      HOSTALIASES = "${config.xdg.configHome}/hblock/hosts";
      HISTSIZE = "150000";
      SAVEHIST = "120000";
      HISTFILE = "${zshDir}/history";
    };

    initContent = lib.mkMerge [
      # --------------------------- PHASE 1: Early ------------------------------
      (lib.mkBefore ''
        ${lib.optionalString enableDebugMode ''
          zmodload zsh/zprof
          typeset -F SECONDS
          PS4=$'%D{%M%S%.} %N:%i> '
          exec 3>&2 2>/tmp/zsh_profile.$$.log
          setopt xtrace prompt_subst
        ''}

        ${lib.optionalString enablePerformanceOpts ''
          skip_global_compinit=1
          [[ -d "${cacheDir}" ]] || mkdir -p "${cacheDir}"
          [[ -d "${dataDir}"  ]] || mkdir -p "${dataDir}"
          [[ -d "${stateDir}" ]] || mkdir -p "${stateDir}"
          [[ -d "${cacheDir}/.zcompcache" ]] || mkdir -p "${cacheDir}/.zcompcache"
          : > "${cacheDir}/compinit.lock" 2>/dev/null || true
        ''}

        export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
        export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"
        export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
        export XDG_STATE_HOME="''${XDG_STATE_HOME:-$HOME/.local/state}"

        export EDITOR="nvim" VISUAL="nvim" TERMINAL="kitty" TERM="xterm-256color" BROWSER="brave"

        typeset -U path PATH cdpath CDPATH fpath FPATH manpath MANPATH
        path=(
          $HOME/.local/bin
          $HOME/.iptv/bin
          $HOME/bin
          /usr/local/bin
          $path
        )

        stty -ixon 2>/dev/null

        export NIX_PATH="''${NIX_PATH:-nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos}"
        if [[ -f "$HOME/.nix-profile/etc/profile.d/command-not-found.sh" ]]; then
          source "$HOME/.nix-profile/etc/profile.d/command-not-found.sh"
        fi
      '')

      # --------------------------- PHASE 2: Core -------------------------------
      (''
        # ZLE
        autoload -Uz url-quote-magic bracketed-paste-magic
        zle -N self-insert url-quote-magic
        zle -N bracketed-paste bracketed-paste-magic
        autoload -Uz edit-command-line
        zle -N edit-command-line
        zstyle ':url-quote-magic:*' url-metas '*?[]^()~#{}='
        zstyle ':bracketed-paste-magic' active-widgets '.self-*'

        # Options
        setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT PUSHD_TO_HOME CD_SILENT
        setopt EXTENDED_GLOB GLOB_DOTS NUMERIC_GLOB_SORT NO_CASE_GLOB GLOB_COMPLETE
        setopt COMPLETE_IN_WORD ALWAYS_TO_END AUTO_MENU AUTO_LIST AUTO_PARAM_SLASH NO_MENU_COMPLETE LIST_PACKED
        setopt CORRECT NO_CORRECT_ALL
        setopt NO_BG_NICE NO_HUP NO_CHECK_JOBS LONG_LIST_JOBS
        setopt NO_FLOW_CONTROL INTERACTIVE_COMMENTS RC_QUOTES COMBINING_CHARS
        setopt PROMPT_SUBST TRANSIENT_RPROMPT
        setopt NO_CLOBBER NO_RM_STAR_SILENT
        setopt NO_BEEP MULTI_OS

        # Aliases (noglob)
        alias nix='noglob nix'
        alias git='noglob git'
        alias find='noglob find'
        alias rsync='noglob rsync'
        alias scp='noglob scp'

        # History
        setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS HIST_IGNORE_ALL_DUPS
        setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_SAVE_NO_DUPS
        setopt HIST_VERIFY HIST_FCNTL_LOCK SHARE_HISTORY INC_APPEND_HISTORY HIST_NO_STORE
        HISTORY_IGNORE="(ls|cd|pwd|exit|cd ..|cd -|z *|zi *)"

        # FZF
        export FZF_DEFAULT_OPTS="
          --height=80% --layout=reverse --info=inline --border=rounded
          --margin=1 --padding=1 --cycle --scroll-off=5
          --bind='ctrl-/:toggle-preview'
          --bind='ctrl-u:preview-half-page-up'
          --bind='ctrl-d:preview-half-page-down'
          --bind='ctrl-a:select-all'
          --bind='ctrl-x:deselect-all'
          --bind='ctrl-y:execute-silent(echo {+} | wl-copy)'
          --bind='alt-w:toggle-preview-wrap'
          --bind='ctrl-space:toggle+down'
          --pointer='▶' --marker='✓' --prompt='❯ ' --no-scrollbar
        "
        export FZF_COMPLETION_TRIGGER='**'
        export FZF_COMPLETION_OPTS="--info=inline --border=rounded --height=80%"

        if command -v rg &>/dev/null; then
          export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*" --glob "!.cache/*" --glob "!node_modules/*"'
        elif command -v fd &>/dev/null; then
          export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --strip-cwd-prefix --exclude .git --exclude .cache --exclude node_modules'
        fi
        if command -v fd &>/dev/null; then
          export FZF_CTRL_T_COMMAND="fd --type f --type d --hidden --follow --strip-cwd-prefix --exclude .git --exclude .cache --exclude node_modules"
          export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --strip-cwd-prefix --exclude .git --exclude .cache --exclude node_modules'
        fi
        export FZF_CTRL_T_OPTS="
          --preview='[[ -d {} ]] && eza --tree --level=2 --color=always --icons {} || bat --style=numbers --color=always --line-range :500 {}'
          --preview-window='right:60%:wrap'
          --bind='ctrl-/:change-preview-window(down|hidden|)'
          --bind='ctrl-e:execute(nvim {} < /dev/tty > /dev/tty 2>&1)'
          --header='CTRL-/: toggle preview | CTRL-E: edit in nvim'
        "
        export FZF_ALT_C_OPTS="
          --preview='eza --tree --level=3 --color=always --icons --group-directories-first {}'
          --preview-window='right:60%:wrap'
          --bind='ctrl-/:change-preview-window(down|hidden|)'
          --header='CTRL-/: toggle preview'
        "
        export FZF_CTRL_R_OPTS="
          --preview='echo {}'
          --preview-window='down:3:hidden:wrap'
          --bind='?:toggle-preview'
          --bind='ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
          --bind='ctrl-e:execute(echo {2..} | xargs echo > /tmp/fzf-cmd && nvim /tmp/fzf-cmd < /dev/tty > /dev/tty 2>&1)'
          --header='?: toggle preview | CTRL-Y: copy | CTRL-E: edit'
          --exact
        "

        if command -v eza &>/dev/null; then
          export EZA_COLORS="da=1;34:gm=1;34"
          export EZA_ICON_SPACING=2
        fi

        ${lib.optionalString enableLazyLoading ''
          __lazy_load() {
            local fn="$1"; local init="$2"; shift 2
            local alias_cmds=("$@")
            eval "
              $fn() {
                unfunction $fn 2>/dev/null
                for c in \''${alias_cmds[@]}; do unalias \$c 2>/dev/null || true; done
                eval '$init' 2>/dev/null || return 1
                if type $fn &>/dev/null; then
                  $fn \"\$@\"
                else
                  command \''${alias_cmds[1]:-\''${fn#__init_}} \"\$@\"
                fi
              }
            "
            for c in "''${alias_cmds[@]}"; do alias $c="$fn"; done
          }

          if [[ -d "$HOME/.nvm" ]]; then
            __lazy_load __init_nvm 'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"' nvm node npm npx
          fi
          if [[ -d "$HOME/.rvm" ]]; then
            __lazy_load __init_rvm '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' rvm ruby gem bundle
          fi
          if [[ -d "$HOME/.pyenv" ]]; then
            __lazy_load __init_pyenv 'export PYENV_ROOT="$HOME/.pyenv"; export PATH="$PYENV_ROOT/bin:$PATH"; eval "$(pyenv init --path)"; eval "$(pyenv init -)"' pyenv python pip
          fi
          if [[ -d "$HOME/.conda/miniconda3" ]] || [[ -d "$HOME/.conda/anaconda3" ]]; then
            __lazy_load __init_conda 'eval "$(conda shell.zsh hook 2>/dev/null)"' conda
          fi
        ''}

        if [[ -n $SSH_CONNECTION ]]; then
          unset MANPAGER
          export PAGER="less"
          setopt NO_SHARE_HISTORY
          HISTSIZE=15000
          SAVEHIST=12000
        fi

        # Minimal hooks (zoxide hemen; direnv/atuin sonra)
        command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

        # fpath (prepend)
        fpath=(
          "${zshDir}/completions"
          "${zshDir}/plugins/zsh-completions/src"
          "${pkgs.zsh-completions}/share/zsh/site-functions"
          "${zshDir}/functions"
          $fpath
        )

        # ------------------ LAZY COMPINIT: ilk tamamlamada kurulsun ----------------
        autoload -Uz compinit add-zle-hook-widget
        zmodload zsh/system 2>/dev/null || true

        __ensure_compinit() {
          local _ver _fhash _dump _lock _host
          _ver="$(print -r -- $ZSH_VERSION)"
          _fhash="$(print -rl -- $fpath | ${pkgs.coreutils}/bin/md5sum 2>/dev/null | ${pkgs.coreutils}/bin/cut -d' ' -f1)"
          _host="''${HOST:-$(${pkgs.coreutils}/bin/hostname 2>/dev/null || echo unknown)}"
          _dump="${cacheDir}/zcompdump-''${_host}-''${_ver}-''${_fhash}"
          _lock="${cacheDir}/compinit-''${_fhash}.lock"

          if [[ -s "$_dump" ]]; then
            compinit -C -i -d "$_dump"
            [[ ! -f "$_dump.zwc" || "$_dump" -nt "$_dump.zwc" ]] && { zcompile "$_dump" 2>/dev/null || true; } &!
            return 0
          fi

          if command -v zsystem >/dev/null 2>&1; then
            zsystem flock -t 0.1 "$_lock" || { compinit -C -i -d "$_dump"; return 0; }
          fi
          compinit -u -i -d "$_dump"
          { zcompile "$_dump" 2>/dev/null || true; } &!
          if command -v zsystem >/dev/null 2>&1; then
            zsystem flock -u "$_lock" 2>/dev/null || true
          fi
          return 0
        }

        __first_complete() {
          zle -I
          __ensure_compinit
          zle .expand-or-complete
        }
        zle -N expand-or-complete __first_complete

        # ---------------------- Prompt: pure (anında) ----------------------------
        fpath=( ${pkgs.pure-prompt}/share/zsh/site-functions $fpath )
        autoload -Uz promptinit && promptinit

        export PURE_GIT_ASYNC=1
        export PURE_GIT_FETCH_TIMEOUT=0
        export PURE_GIT_PULL=0
        export PURE_GIT_DELAY=0
        export PURE_GIT_UNTRACKED_DIRTY=0
        export PURE_CMD_MAX_EXEC_TIME=3
        export PURE_PROMPT_SYMBOL="❯"
        export PURE_PROMPT_VICMD_SYMBOL="❮"
        export PURE_PROMPT_SPINNER="↻"
        prompt pure

        # --------------- İlk prompttan SONRA ağır şeyleri yükle ------------------
        __after_first_prompt() {
          if [[ -z $__OMZ_LOADED ]]; then
            __OMZ_LOADED=1
            export ZSH="${omzPath}"
            plugins=(
              git sudo command-not-found history
              copypath copyfile dirhistory jump
              colored-man-pages extract aliases safe-paste web-search
              jsontools encode64 urltools systemd rsync
            )
            [[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"
          fi
          command -v direnv >/dev/null && eval "$(direnv hook zsh)"
          command -v atuin  >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"
          add-zle-hook-widget -d zle-line-init __after_first_prompt 2>/dev/null
        }
        add-zle-hook-widget zle-line-init __after_first_prompt
      '')

      # --------------------------- PHASE 3: Late -------------------------------
      (lib.mkAfter ''
        if [[ -d "${zshDir}/functions" ]]; then
          local f; for f in "${zshDir}/functions"/*(.N); do autoload -Uz "''${f:t}"; done
        fi

        zstyle ':completion:*' rehash true
        zstyle ':completion:*' accept-exact-dirs true
        zstyle ':completion:*' use-cache on

        ${lib.optionalString enableDebugMode ''
          unsetopt xtrace
          exec 2>&3 3>&-
          echo "\n=== ZSH Startup Profile ==="
          zprof | head -20
        ''}
      '')
    ];

    history = {
      size  = 150000;
      save  = 120000;
      path  = "${zshDir}/history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      extended = true;
      expireDuplicatesFirst = true;
    };

    completionInit = ''
      autoload -Uz colors && colors
      _comp_options+=(globdots)

      zstyle ':completion:*' completer _extensions _complete _approximate _ignored
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "${cacheDir}/.zcompcache"
      zstyle ':completion:*' complete true
      zstyle ':completion:*' complete-options true

      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' file-sort modification
      zstyle ':completion:*' sort false
      zstyle ':completion:*' list-suffixes true
      zstyle ':completion:*' expand prefix suffix

      zstyle ':completion:*' menu select=2
      zstyle ':completion:*' auto-description 'specify: %d'
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*' keep-prefix true
      zstyle ':completion:*' preserve-prefix '//[^/]##/'

      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:messages'     format '%F{purple}-- %d --%f'
      zstyle ':completion:*:warnings'     format '%F{red}-- no matches found --%f'
      zstyle ':completion:*:corrections'  format '%F{green}-- %d (errors: %e) --%f'

      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' squeeze-slashes true
      zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
      zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
      zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'

      zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
      zstyle ':completion:*:*:kill:*' menu yes select
      zstyle ':completion:*:*:kill:*' force-list always
      zstyle ':completion:*:*:kill:*' insert-ids single

      zstyle ':completion:*:manuals' separate-sections true
      zstyle ':completion:*:manuals.*' insert-sections true
      zstyle ':completion:*:man:*' menu yes select

      zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
      zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
      zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

      # fzf-tab: previews opt-in
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-min-height 100
      zstyle ':fzf-tab:*' switch-group ',' '.'
      zstyle ':fzf-tab:*' continuous-trigger '/'
      zstyle ':fzf-tab:*' print-query alt-enter
      zstyle ':fzf-tab:complete:*:*' fzf-preview ""
      zstyle ':fzf-tab:complete:*:*' fzf-flags --height=80% --border=rounded --info=inline --cycle --bind='ctrl-/:toggle-preview'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-headers -w -w'
      zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags --preview-window=down:3:wrap
      zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
      zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
      zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
      zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | delta'
      zstyle ':fzf-tab:complete:ssh:argument-1' fzf-preview 'dig $word'
      zstyle ':fzf-tab:complete:man:*' fzf-preview 'man $word | head -100'
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always --icons $realpath 2>/dev/null || tree -L 2 -C $realpath 2>/dev/null'
    '';
  };
}

