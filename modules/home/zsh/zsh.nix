# modules/home/zsh/zsh.nix
# ==============================================================================
# ZSH Configuration — Ultra Performance, Race-free Compinit, Starship Prompt
# Author: Kenan Pelit
# Description:
#   • Bytecode compilation for user config & plugins
#   • Safe (flock) & smart compinit with fpath/version fingerprint
#   • Single cache location under XDG, old dumps auto-cleaned
#   • Lazy loading for heavy toolchains (nvm/rvm/pyenv/conda)
#   • FZF/FZF-Tab tuned (previews toggle-on to avoid stalls)
# ==============================================================================

{ hostname, config, pkgs, host, lib, ... }:

let
  # ----------------------------------------------------------------------------
  # Feature toggles
  # ----------------------------------------------------------------------------
  enablePerformanceOpts = true;    # Safe compinit, aggressive caching
  enableBytecodeCompile = true;    # zcompile user files & plugins
  enableLazyLoading    = true;     # Lazy-load heavy env managers
  enableDebugMode      = false;    # zprof/xtrace for startup profiling

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
  # Home Activation — compile user files & keep caches sane
  # =============================================================================
  home.activation = lib.mkMerge [
    # Bytecode compile (user rc + plugins); skip zcompdump here (handled at runtime)
    (lib.mkIf enableBytecodeCompile {
      zshCompile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run echo "🚀 Compiling ZSH files for optimal performance..."

        compile_zsh() {
          local file="$1"
          if [[ -f "$file" && ( ! -f "$file.zwc" || "$file" -nt "$file.zwc" ) ]]; then
            ${pkgs.zsh}/bin/zsh -c "zcompile '$file'" 2>/dev/null || true
            [[ -f "$file.zwc" ]] && run echo "  ✓ Compiled: $file"
          fi
        }

        # Compile main rc (Nix writes to dotDir; runtime symlinks will exist)
        compile_zsh "${zshDir}/.zshrc"

        # Compile all plugin .zsh files (background)
        if [[ -d "${zshDir}/plugins" ]]; then
          while IFS= read -r -d "" file; do
            compile_zsh "$file" &
          done < <(find "${zshDir}/plugins" -type f -name "*.zsh" -print0 2>/dev/null)
          wait
        fi

        run echo "✅ ZSH bytecode compilation completed"
      '';
    })

    # Ensure cache layout & lock file (prevents first-run flock errors)
    {
      zshCacheEnsure = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${cacheDir}" "${cacheDir}/.zcompcache" 2>/dev/null || true
        : > "${cacheDir}/compinit.lock" 2>/dev/null || true
      '';
    }

    # One-shot fix: remove wrongly placed .zcompdump under $zshDir (we keep dumps only in cache)
    {
      zshCacheLocationFix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        find "${zshDir}" -maxdepth 1 -type f -name ".zcompdump*" -delete 2>/dev/null || true
      '';
    }

    # Periodic cache housekeeping
    {
      zshCacheCleanup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run echo "🧹 Cleaning old ZSH cache files..."

        (
          # Bu alt kabukta "set -e" etkisini kapatıp bütün hataları yutuyoruz
          set +e

          # Dizinlerin varlığını garanti et (yoksa find hata verir)
          [[ -d "${cacheDir}" ]] || mkdir -p "${cacheDir}"
          [[ -d "${cacheDir}/.zcompcache" ]] || true

          # Eski completion dump'ları (30+ gün)
          if [[ -d "${cacheDir}" ]]; then
            find "${cacheDir}" -type f -name 'zcompdump*' -mtime +30 -delete 2>/dev/null || true
          fi

          # Orphan .zwc temizliği (kaynak dosyası yoksa)
          if [[ -d "${zshDir}" || -d "${cacheDir}" ]]; then
            while IFS= read -r zwc; do
              src="''${zwc%.zwc}"
              [[ -f "$src" ]] || rm -f "$zwc" 2>/dev/null || true
            done < <( ( find "${zshDir}" "${cacheDir}" -type f -name '*.zwc' 2>/dev/null ) || true )
          fi

          # .zcompcache içindeki 7+ günlük dosyalar (dizin yoksa atla)
          if [[ -d "${cacheDir}/.zcompcache" ]]; then
            find "${cacheDir}/.zcompcache" -type f -mtime +7 -delete 2>/dev/null || true
          fi
        )

        run echo "✅ Cache cleanup completed"
      '';
    }
  ];

  # =============================================================================
  # Ensure directory structure
  # =============================================================================
  home.file = {
    ".ssh/.keep".text = "";
    "${zshDir}/completions/.keep".text = "";
    "${zshDir}/functions/.keep".text   = "";
  };

  # =============================================================================
  # ZSH Program Configuration
  # =============================================================================
  programs.zsh = {
    enable  = true;
    dotDir  = zshDir;
    autocd  = true;
    enableCompletion = true;

    # Environment/session vars
    sessionVariables = {
      # Performance & safety
      ZSH_DISABLE_COMPFIX = "true";
      COMPLETION_WAITING_DOTS = "true";

      # XDG
      ZDOTDIR       = zshDir;
      ZSH_CACHE_DIR = cacheDir;
      ZSH_DATA_DIR  = dataDir;
      ZSH_STATE_DIR = stateDir;

      # Defaults
      EDITOR   = "nvim";
      VISUAL   = "nvim";
      TERMINAL = "kitty";
      BROWSER  = "brave";
      PAGER    = "less";
      TERM     = "xterm-256color";

      # Pager & locale
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANWIDTH = "100";
      LESS = "-R --use-color -Dd+r -Du+b -DS+y -DP+k";
      LESSHISTFILE = "-";
      LESSCHARSET  = "utf-8";

      LC_ALL = "en_US.UTF-8";
      LANG   = "en_US.UTF-8";

      # Hosts & history
      HOSTALIASES = "${config.xdg.configHome}/hblock/hosts";
      HISTSIZE = "150000";
      SAVEHIST = "120000";
      HISTFILE = "${zshDir}/history";

      # NOTE: Do NOT set ZCOMPDUMP here; we compute a fingerprinted path at runtime.
    };

    # ----------------------------------------------------------------------------
    # Initialization (phased)
    # ----------------------------------------------------------------------------
    initContent = lib.mkMerge [
      # =============================== PHASE 1: Early ==========================
      (lib.mkBefore ''
        ${lib.optionalString enableDebugMode ''
          zmodload zsh/zprof
          typeset -F SECONDS
          PS4=$'%D{%M%S%.} %N:%i> '
          exec 3>&2 2>/tmp/zsh_profile.$$.log
          setopt xtrace prompt_subst
        ''}

        ${lib.optionalString enablePerformanceOpts ''
          # Skip global compinit; we run our own safe/locked compinit.
          skip_global_compinit=1

          # Create needed XDG dirs (cheap guards prevent extra stats)
          [[ -d "${cacheDir}" ]] || mkdir -p "${cacheDir}"
          [[ -d "${dataDir}"  ]] || mkdir -p "${dataDir}"
          [[ -d "${stateDir}" ]] || mkdir -p "${stateDir}"
          [[ -d "${cacheDir}/.zcompcache" ]] || mkdir -p "${cacheDir}/.zcompcache"
          : > "${cacheDir}/compinit.lock" 2>/dev/null || true
        ''}

        # XDG fallbacks (if not set by login manager)
        export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
        export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"
        export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
        export XDG_STATE_HOME="''${XDG_STATE_HOME:-$HOME/.local/state}"

        # Force key exports (prevent overrides later)
        export EDITOR="nvim" VISUAL="nvim" TERMINAL="kitty" TERM="xterm-256color" BROWSER="brave"

        # PATH de-dup & priority
        typeset -U path PATH cdpath CDPATH fpath FPATH manpath MANPATH
        path=(
          $HOME/.local/bin
          $HOME/.iptv/bin
          $HOME/bin
          /usr/local/bin
          $path
        )

        # Better TTY UX
        stty -ixon 2>/dev/null

        # Nix env & command-not-found
        export NIX_PATH="''${NIX_PATH:-nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos}"
        if [[ -f "$HOME/.nix-profile/etc/profile.d/command-not-found.sh" ]]; then
          source "$HOME/.nix-profile/etc/profile.d/command-not-found.sh"
        fi
      '')

      # =============================== PHASE 2: Core ===========================
      (''
        # ----- ZLE goodies -----
        autoload -Uz url-quote-magic bracketed-paste-magic
        zle -N self-insert url-quote-magic
        zle -N bracketed-paste bracketed-paste-magic
        autoload -Uz edit-command-line
        zle -N edit-command-line
        zstyle ':url-quote-magic:*' url-metas '*?[]^()~#{}='
        zstyle ':bracketed-paste-magic' active-widgets '.self-*'

        # ----- Options (performance & UX) -----
        setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT PUSHD_TO_HOME CD_SILENT
        setopt EXTENDED_GLOB GLOB_DOTS NUMERIC_GLOB_SORT NO_CASE_GLOB GLOB_COMPLETE
        setopt COMPLETE_IN_WORD ALWAYS_TO_END AUTO_MENU AUTO_LIST AUTO_PARAM_SLASH NO_MENU_COMPLETE LIST_PACKED
        setopt CORRECT NO_CORRECT_ALL
        setopt NO_BG_NICE NO_HUP NO_CHECK_JOBS LONG_LIST_JOBS
        setopt NO_FLOW_CONTROL INTERACTIVE_COMMENTS RC_QUOTES COMBINING_CHARS
        setopt PROMPT_SUBST TRANSIENT_RPROMPT
        setopt NO_CLOBBER NO_RM_STAR_SILENT
        setopt NO_BEEP MULTI_OS

        # Disable globbing for some tools (avoid surprises)
        alias nix='noglob nix'
        alias git='noglob git'
        alias find='noglob find'
        alias rsync='noglob rsync'
        alias scp='noglob scp'

        # ----- History -----
        setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_FIND_NO_DUPS HIST_IGNORE_ALL_DUPS
        setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_SAVE_NO_DUPS
        setopt HIST_VERIFY HIST_FCNTL_LOCK SHARE_HISTORY INC_APPEND_HISTORY HIST_NO_STORE
        HISTORY_IGNORE="(ls|cd|pwd|exit|cd ..|cd -|z *|zi *)"

        # ----- FZF (safe defaults; previews toggle with ctrl-/) -----
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
        export FZF_COMPLETION_OPTS="--info=inline --border=rounded --height=80%"

        # Prefer rg/fd when available
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

        # ----- eza -----
        if command -v eza &>/dev/null; then
          export EZA_COLORS="da=1;34:gm=1;34"
          export EZA_ICON_SPACING=2
        fi

        ${lib.optionalString enableLazyLoading ''
          # ----- Generic lazy loader -----
          __lazy_load() {
            local func_name="$1"; local init_cmd="$2"; shift 2
            local alias_cmds=("$@")
            eval "
              $func_name() {
                unfunction $func_name 2>/dev/null
                for cmd in \''${alias_cmds[@]}; do unalias \$cmd 2>/dev/null || true; done
                eval '$init_cmd' 2>/dev/null || return 1
                if type $func_name &>/dev/null; then
                  $func_name \"\$@\"
                else
                  command \''${alias_cmds[1]:-\''${func_name#__init_}} \"\$@\"
                fi
              }
            "
            for cmd in "''${alias_cmds[@]}"; do alias $cmd="$func_name"; done
          }

          # nvm / rvm / pyenv / conda
          if [[ -d "$HOME/.nvm" ]]; then
            __lazy_load __init_nvm \
              'export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"' \
              nvm node npm npx
          fi
          if [[ -d "$HOME/.rvm" ]]; then
            __lazy_load __init_rvm \
              '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' \
              rvm ruby gem bundle
          fi
          if [[ -d "$HOME/.pyenv" ]]; then
            __lazy_load __init_pyenv \
              'export PYENV_ROOT="$HOME/.pyenv"; export PATH="$PYENV_ROOT/bin:$PATH"; eval "$(pyenv init --path)"; eval "$(pyenv init -)"' \
              pyenv python pip
          fi
          if [[ -d "$HOME/.conda/miniconda3" ]] || [[ -d "$HOME/.conda/anaconda3" ]]; then
            __lazy_load __init_conda \
              'eval "$(conda shell.zsh hook 2>/dev/null)"' \
              conda
          fi
        ''}

        # ----- SSH-light profile -----
        if [[ -n $SSH_CONNECTION ]]; then
          unset MANPAGER
          export PAGER="less"
          setopt NO_SHARE_HISTORY
          HISTSIZE=15000
          SAVEHIST=12000
        fi

        # ----- Tool hooks -----
        if command -v zoxide &>/dev/null; then eval "$(zoxide init zsh)"; fi
        if command -v direnv &>/dev/null; then eval "$(direnv hook zsh)"; export DIRENV_LOG_FORMAT=""; fi
        if command -v atuin &>/dev/null; then eval "$(atuin init zsh --disable-up-arrow)"; fi

        # ----- Custom completion/function paths (prepend before hashing) -----
        fpath=(
          "${zshDir}/completions"
          "${zshDir}/plugins/zsh-completions/src"
          "${zshDir}/functions"
          $fpath
        )

        # ----- Safe, smart, locked compinit -----
        autoload -Uz compinit
        zmodload zsh/system 2>/dev/null || true

        # Fingerprint: ZSH version + fpath hash (cache invalidates when either changes)
        local _ver="$(print -r -- $ZSH_VERSION)"
        local _fpath_hash="$(print -rl -- $fpath | md5sum 2>/dev/null | awk '{print $1}')"
        local _dump_base="${cacheDir}/zcompdump-''${HOST}-''${_ver}-''${_fpath_hash}"
        local _zcompdump="$_dump_base"
        # Lock'u hash'e bağla ki farklı fpath sürümleri birbirini bloklamasın
        local _lock="${cacheDir}/compinit-''${_fpath_hash}.lock"

        _safe_compinit() {
          # Klasör hazır
          [[ -d "${cacheDir}" ]] || mkdir -p "${cacheDir}"

          # 24 saatten eskiyse yeniden kuracağız
          local _need_rebuild=0
          if [[ ! -s "$_zcompdump" || -n $_zcompdump(#qN.mh+24) ]]; then
            _need_rebuild=1
          fi

          # --- CACHE VARSA: Hızlı yol, hiç kilit deneme ---
          if (( _need_rebuild == 0 )); then
            compinit -C -i -d "$_zcompdump"
            # .zwc güncel değilse arka planda derle
            [[ ! -f "$_zcompdump.zwc" || "$_zcompdump" -nt "$_zcompdump.zwc" ]] && { zcompile "$_zcompdump" 2>/dev/null || true; } &!
            return
          fi

          # --- YENİDEN KURULUM GEREKİYOR: kilidi dene, anında vazgeç ---
          if command -v zsystem >/dev/null 2>&1; then
            # 0.1 sn içinde kilit alınamazsa hızlı yola dön
            zsystem flock -t 0.1 "$_lock" || {
              compinit -C -i -d "$_zcompdump"
              return
            }
          fi

          # Gerçek rebuild
          compinit -u -i -d "$_zcompdump"
          { zcompile "$_zcompdump" 2>/dev/null || true; } &!

          # Kilidi bırak
          if command -v zsystem >/dev/null 2>&1; then
            zsystem flock -u "$_lock" 2>/dev/null || true
          fi
        }

        _safe_compinit

        # Bash completion (optional)
        autoload -Uz bashcompinit && bashcompinit
      '')

      # =============================== PHASE 3: Late ===========================
      (lib.mkAfter ''
        # Autoload custom functions found in ${zshDir}/functions
        if [[ -d "${zshDir}/functions" ]]; then
          local func_file
          for func_file in "${zshDir}/functions"/*(.N); do
            autoload -Uz "''${func_file:t}"
          done
        fi

        # Completion styles that benefit after compinit
        zstyle ':completion:*' rehash true
        zstyle ':completion:*' accept-exact-dirs true
        zstyle ':completion:*' use-cache on

        ${lib.optionalString enableDebugMode ''
          unsetopt xtrace
          exec 2>&3 3>&-
          echo "\n=== ZSH Startup Profile ==="
          zprof | head -20
        ''}

        # Starship at the very end for lowest latency
        if command -v starship &>/dev/null; then
          eval "$(starship init zsh)"
        fi
      '')
    ];

    # ----------------------------------------------------------------------------
    # History (HM-level)
    # ----------------------------------------------------------------------------
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

    # ----------------------------------------------------------------------------
    # Completion styles (HM-level)
    # ----------------------------------------------------------------------------
    completionInit = ''
      autoload -Uz colors && colors
      _comp_options+=(globdots)

      # Core completion behavior
      zstyle ':completion:*' completer _extensions _complete _approximate _ignored
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "${cacheDir}/.zcompcache"
      zstyle ':completion:*' complete true
      zstyle ':completion:*' complete-options true

      # Matching/sorting
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' file-sort modification
      zstyle ':completion:*' sort false
      zstyle ':completion:*' list-suffixes true
      zstyle ':completion:*' expand prefix suffix

      # Menu & grouping
      zstyle ':completion:*' menu select=2
      zstyle ':completion:*' auto-description 'specify: %d'
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*' keep-prefix true
      zstyle ':completion:*' preserve-prefix '//[^/]##/'

      # Visuals
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:messages'     format '%F{purple}-- %d --%f'
      zstyle ':completion:*:warnings'     format '%F{red}-- no matches found --%f'
      zstyle ':completion:*:corrections'  format '%F{green}-- %d (errors: %e) --%f'

      # Specials
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

      # Manuals
      zstyle ':completion:*:manuals' separate-sections true
      zstyle ':completion:*:manuals.*' insert-sections true
      zstyle ':completion:*:man:*' menu yes select

      # SSH/SCP/RSYNC hosts grouping/ignores
      zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
      zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
      zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

      # fzf-tab: previews are opt-in (toggle with ctrl-/ to avoid initial stalls)
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-min-height 100
      zstyle ':fzf-tab:*' switch-group ',' '.'
      zstyle ':fzf-tab:*' continuous-trigger '/'
      zstyle ':fzf-tab:*' print-query alt-enter
      zstyle ':fzf-tab:complete:*:*' fzf-preview ""              # default OFF
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

    # ----------------------------------------------------------------------------
    # Oh-My-Zsh — curated plugin set
    # ----------------------------------------------------------------------------
    oh-my-zsh = {
      enable = true;
      plugins = [
        # Core
        "git" "sudo" "command-not-found" "history"

        # Navigation / UX
        "copypath" "copyfile" "dirhistory" "jump"
        "colored-man-pages" "extract" "aliases" "safe-paste" "web-search"

        # Dev / Sys
        "jsontools" "encode64" "urltools"
        "systemd" "rsync"
      ];
    };
  };
}
