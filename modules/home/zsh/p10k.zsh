# Powerlevel10k - "Pure Pro v3.0 (Catppuccin Lavender · kenp_vcs)"
# ==============================================================================
# Minimal Pure görünüm + pratik iyileştirmeler:
# - Akıllı dizin kısaltma (dar terminallerde sarma yapmaz)
# - Özel kenp_vcs: gitstatusd’ye bağımlı değil; her zaman dal/adım görünür
# - SSH/root bağlamı sadece gerektiğinde
# - Hata kodu (status) sadece başarısızlıkta görünür
# - Arka plan işleri segmenti (yalnızca >0 iken)
# - Catppuccin Mocha uyumlu renkler (lavender/mauve vurgu)
# - Instant prompt açık (quiet)
# ==============================================================================

# Mevcut shell seçeneklerini koru.
builtin local -a p10k_config_opts
[[ ! -o aliases         ]] || p10k_config_opts+=(aliases)
[[ ! -o sh_glob         ]] || p10k_config_opts+=(sh_glob)
[[ ! -o no_brace_expand ]] || p10k_config_opts+=(no_brace_expand)
builtin setopt no_aliases no_sh_glob brace_expand

() {
  emulate -L zsh -o extended_glob

  # Temiz başlangıç.
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Zsh 5.1+ gerekli.
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # ----------------------------------------------------------------------------
  # PALLETTE (Catppuccin Mocha uyumlu)
  # ----------------------------------------------------------------------------
  local grey='245'       # ikincil metin
  local red='1'          # hatalar/root
  local yellow='3'       # SSH/uyarılar/zaman
  local blue='4'         # dizin
  local lavender='141'   # ana vurgu (dizin, git dalı)
  local mauve='176'      # prompt karakteri
  local cyan='6'         # teknik ipuçları
  local white='255'      # parlak vurgu

  # ----------------------------------------------------------------------------
  # ÖZEL SEGMENT: kenp_vcs
  # - gitstatusd yoksa bile dal/commit + bayraklar (⇡ ⇣ ✗ ?) görünür
  # - p10k segment API sayesinde kaçışlar dengeli; '}' sızıntısı olmaz
  # --- Custom Git segment: robust & safe, no stray '}' & no out-of-context calls ---
  # ----------------------------------------------------------------------------
  function prompt_kenp_vcs() {
    # Çizim bağlamı koruması: p10k segment sadece prompt render sırasında çağrılmalı.
    (( $+functions[p10k] )) || return         # p10k yüklenmemişse çık
    typeset -p _p9k_t &>/dev/null || return   # p10k render bağlamı yoksa çık

    # Git deposunda değilsek segmenti gösterme.
    command git rev-parse --is-inside-work-tree &>/dev/null || return

    # Dal adı ya da kısa commit.
    local ref
    ref=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo '?')

    # Kirli / untracked
    local dirty= untracked=
    git diff --no-ext-diff --quiet --ignore-submodules -- 2>/dev/null || dirty=1
    [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]] && untracked=1

    # Upstream varsa ahead/behind
    local ahead= behind= counts= upstream=
    upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [[ -n $upstream ]]; then
      counts=$(git rev-list --left-right --count HEAD..."$upstream" 2>/dev/null || echo "0	0")
      ahead=${counts%%	*}; behind=${counts##*	}
      (( ahead > 0 )) || unset ahead
      (( behind > 0 )) || unset behind
    fi

    # Bayraklar (Pure'a yakın): ⇡ ⇣ ✗ ?
    local flags=""
    [[ -n $ahead     ]] && flags+=" ⇡$ahead"
    [[ -n $behind    ]] && flags+=" ⇣$behind"
    [[ -n $dirty     ]] && flags+=" ✗"
    [[ -n $untracked ]] && flags+=" ?"

    # Catppuccin Lavender ile yazdır.
    p10k segment -f 141 -t "${ref}${flags}"
  }

  # ----------------------------------------------------------------------------
  # SOL/SAĞ SEGMENT DÜZENİ (Pure benzeri iki satır)
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    context                 # sadece SSH/root’ta
    dir                     # akıllı kısaltma
    kenp_vcs                # özel git segmenti (her zaman güvenilir)
    command_execution_time  # ≥ eşik süresi ise göster
    newline
    virtualenv              # venv adı (sade)
    background_jobs         # >0 ise göster
    status                  # hata kodu (başarısızlıkta)
    prompt_char             # ❯ / ❮
  )
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # time                  # istersen aç
    newline
  )

  # ----------------------------------------------------------------------------
  # GENEL GÖRÜNÜM
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=' · '   # { } artığını da önler
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # ----------------------------------------------------------------------------
  # PROMPT KARAKTERİ & VI MOD
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$mauve
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false

  # ----------------------------------------------------------------------------
  # PYTHON VENV
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  # ----------------------------------------------------------------------------
  # DİZİN (akıllı kısaltma)
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$lavender
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=true
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'

  # ----------------------------------------------------------------------------
  # CONTEXT (user@host)
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$red}%n%f%F{$grey}@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$yellow}%n@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=
  typeset -g POWERLEVEL9K_CONTEXT_SHOW_ON_SSH=true

  # ----------------------------------------------------------------------------
  # KOMUT SÜRESİ
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow

  # ----------------------------------------------------------------------------
  # ARKA PLAN İŞLERİ
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=true
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_CONTENT_EXPANSION='%j jobs'

  # ----------------------------------------------------------------------------
  # HATA DURUMU
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$red
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_CONTENT_EXPANSION='%F{1}${P9K_CONTENT}%f'

  # ----------------------------------------------------------------------------
  # SAĞ ZAMAN (opsiyonel; kapalı)
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false

  # ----------------------------------------------------------------------------
  # TRANSIENT & INSTANT PROMPT
  # ----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  # Yüklenmişse yeniden uygula.
  (( ! $+functions[p10k] )) || p10k reload
}

# p10k configure’in üzerine yazacağı dosya yolu.
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

# Shell seçeneklerini geri yükle.
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
builtin unset p10k_config_opts
