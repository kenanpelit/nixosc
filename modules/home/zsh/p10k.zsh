# Powerlevel10k - "Pure Pro v1.0"
# ==========================================================
# Clean Pure-style prompt with optimized Git status display
# - Clear, colorful Git indicators
# - Fast and reliable
# - Perfect balance of information and simplicity

# Preserve original shell options
builtin local -a p10k_config_opts
[[ ! -o aliases         ]] || p10k_config_opts+=(aliases)
[[ ! -o sh_glob         ]] || p10k_config_opts+=(sh_glob)
[[ ! -o no_brace_expand ]] || p10k_config_opts+=(no_brace_expand)
builtin setopt no_aliases no_sh_glob brace_expand

() {
  emulate -L zsh -o extended_glob
  
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # ============================
  # Enhanced Color Palette
  # ============================
  local grey='242'        # subtle elements
  local red='1'           # errors, dirty state
  local yellow='3'        # warnings, unstaged
  local blue='4'          # directories
  local green='2'         # success, clean state, staged
  local magenta='5'       # prompt character
  local cyan='6'          # ahead/behind, technical
  local orange='214'      # branch name (high visibility)
  local white='7'         # bright text

  # ============================
  # Prompt Segments
  # ============================
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    context                   # user@host (SSH/root only)
    dir                       # smart-truncated directory
    vcs                       # optimized Git segment
    command_execution_time    # long commands (≥3s)
    newline                   # Pure-style line break
    virtualenv                # Python environment
    podman                    # container context
    background_jobs           # background processes
    prompt_char               # interactive prompt
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    newline                   # structural symmetry
  )

  # ============================
  # Global Layout & Appearance
  # ============================
  typeset -g POWERLEVEL9K_BACKGROUND=                    # transparent
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=  # no padding
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '  # space between
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=        # no separators
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=           # no icons
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true               # blank line before prompt

  # ============================
  # Prompt Character & VI Modes
  # ============================
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$magenta
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false

  # ============================
  # Python Virtual Environment
  # ============================
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  # ============================
  # Directory Segment
  # ============================
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
  # Smart truncation to prevent line wrapping
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=true
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'

  # ============================
  # Context Segment (user@host)
  # ============================
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$red}%n%f%F{$grey}@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$yellow}%n@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=  # hide locally
  typeset -g POWERLEVEL9K_CONTEXT_SHOW_ON_SSH=true                   # show on SSH

  # ============================
  # Command Execution Time
  # ============================
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow

  # ============================
  # OPTIMIZED Git Status Segment (robust & explicit)
  # ============================
  # --- Layoutta nokta ayırıcı: { } artıkları ve birleşik görüntüler için iyi
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR=' · '

  # --- VCS: daha görünür ve güvenilir hale getir
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=214         # branch turuncu (yüksek görünürlük)
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=           # Pure gibi: ikon yok
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'

  # Net durum işaretleri (renkli)
  typeset -g POWERLEVEL9K_VCS_CLEAN_ICON='%F{2}✓%f'
  typeset -g POWERLEVEL9K_VCS_DIRTY_ICON='%F{1}✗%f'
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='%F{4}?%f'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='%F{2}+%f'
  typeset -g POWERLEVEL9K_VCS_UNSTAGED_ICON='%F{3}!%f'

  # Uzak durum
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='%F{6}⇣%f'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='%F{6}⇡%f'

  # İçerik biçimleme: iki nokta yerine boşluk; simgeler birleşmesin
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${P9K_CONTENT//:/ }'

  # Rakamları göster ve sapmaları vurgula (Pure minimal ama bilgi dolu)
  typeset -g POWERLEVEL9K_VCS_SHOW_NUM_CHANGES=true
  typeset -g POWERLEVEL9K_VCS_SHOW_DIVERGENCE=true

  # Hafif bekleme: büyük repo’da bile dal/ileri-geri neredeyse her zaman görünür
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0.2

  # Yüklenirken ince ipucu (gri üç nokta)
  typeset -g POWERLEVEL9K_VCS_LOADING_TEXT='%F{245}…%f'

  # Yalın ve hızlı kancalar (destekli olanlar)
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(
    vcs-detect-changes
    git-untracked
    git-aheadbehind
  )

  # VCS'i yanlışlıkla devre dışı bırakacak bir desen olmasın
  typeset -g POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN=''
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN=''

  # ============================
  # Podman Context Segment
  # ============================
  typeset -g POWERLEVEL9K_PODMAN_FOREGROUND=$cyan
  typeset -g POWERLEVEL9K_PODMAN_SHOW_ON_COMMAND='podman|docker|kubectl'

  # ============================
  # Background Jobs Indicator
  # ============================
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false

  # ============================
  # Error Status Highlighting
  # ============================
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$red
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'

  # ============================
  # Performance & Behavior
  # ============================
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off          # Stable prompt behavior
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet          # Fast startup
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true       # Maximum performance

  # Reload configuration if Powerlevel10k is already running
  (( ! $+functions[p10k] )) || p10k reload
}

# ============================
# Configuration Management
# ============================
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

# Restore original shell options
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
builtin unset p10k_config_opts
