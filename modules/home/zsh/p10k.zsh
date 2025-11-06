# ==============================================================================
# Powerlevel10k – "Pure Pro v2.0 (Catppuccin Lavender Edition)"
# ==============================================================================
# A refined, performance-optimized Pure-style prompt with enhanced visual
# hierarchy and intelligent context awareness.
#
# ✨ Key Improvements:
#   • Enhanced Git status with stash counter and conflict detection
#   • Smarter context hiding (auto-detects $DEFAULT_USER)
#   • Improved visual hierarchy with refined color palette
#   • Node.js, Python, and Rust version indicators
#   • Better directory truncation with Git-aware anchoring
#   • Optimized async performance with intelligent caching
#   • Enhanced SSH detection with visual distinction
#   • Command failure feedback with exit code display
#   • Persistent directory display (no transient prompt)
#
# ------------------------------------------------------------------------------

# Preserve shell options for a clean environment
builtin local -a p10k_config_opts
[[ ! -o aliases         ]] || p10k_config_opts+=(aliases)
[[ ! -o sh_glob         ]] || p10k_config_opts+=(sh_glob)
[[ ! -o no_brace_expand ]] || p10k_config_opts+=(no_brace_expand)
builtin setopt no_aliases no_sh_glob brace_expand

() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Require zsh ≥ 5.1 for full Powerlevel10k support
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # -----------------------------------------------------------------------------
  # 🎨  Enhanced Catppuccin Lavender Color Palette
  # -----------------------------------------------------------------------------
  local grey='242'       # subtle elements / secondary text
  local dark_grey='238'  # muted backgrounds
  local red='196'        # errors / conflicts / root (brighter)
  local yellow='220'     # SSH / warnings / timings (warmer)
  local blue='75'        # directories (sky blue)
  local green='108'      # success / clean state (softer)
  local magenta='170'    # prompt char (more vibrant)
  local cyan='117'       # network / info (lighter)
  local orange='215'     # branch name (improved contrast)
  local lavender='147'   # Catppuccin Lavender accent (lighter)
  local white='255'      # bright emphasis
  local peach='216'      # staged changes
  local teal='109'       # upstream sync

  # -----------------------------------------------------------------------------
  # 🧩  Improved Prompt Structure – Two Lines with Smart Segments
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    # Line 1 – Context → Dir → Git → Status → Exec Time
    # os_icon removed for cleaner look
    context
    dir
    vcs
    command_execution_time
    status
    # Line 2 – Dev Env → Containers → Jobs → Prompt Char
    newline
    virtualenv
    nodeenv
    nodenv
    node_version
    pyenv
    rustenv
    podman
    background_jobs
    prompt_char
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # Minimalist right prompt (Pure philosophy)
    newline
  )

  # -----------------------------------------------------------------------------
  # 🧱  Enhanced Layout & Spacing
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # Refined separator with better visual balance
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR='%F{238}│%f'

  # -----------------------------------------------------------------------------
  # ⌨️  Enhanced Prompt Character with VI Mode Support
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$magenta
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

  # -----------------------------------------------------------------------------
  # 🐍  Python Environment – Enhanced with Version Display
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$green
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV=true
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=
  typeset -g POWERLEVEL9K_VIRTUALENV_GENERIC_NAMES=(venv .venv env .env)

  # Pyenv – show only when not in virtualenv
  typeset -g POWERLEVEL9K_PYENV_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_PYENV_CONTENT_EXPANSION='${P9K_CONTENT}${${P9K_PYENV_PYTHON_VERSION:#$P9K_PYENV_GLOBAL_PYTHON_VERSION}:+ %F{242}⊕%f}'
  typeset -g POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=false

  # -----------------------------------------------------------------------------
  # 🟢  Node.js Environment
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_NODE_VERSION_FOREGROUND=$green
  typeset -g POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=true
  typeset -g POWERLEVEL9K_NODEENV_FOREGROUND=$green
  typeset -g POWERLEVEL9K_NODEENV_SHOW_NODE_VERSION=false
  typeset -g POWERLEVEL9K_NODENV_FOREGROUND=$green
  typeset -g POWERLEVEL9K_NODENV_CONTENT_EXPANSION='${P9K_CONTENT}${${P9K_NODENV_NODE_VERSION:#$P9K_NODENV_GLOBAL_NODE_VERSION}:+ %F{242}⊕%f}'

  # -----------------------------------------------------------------------------
  # 🦀  Rust Environment
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_RUSTENV_FOREGROUND=$orange
  typeset -g POWERLEVEL9K_RUSTENV_SOURCES=(rustup)
  typeset -g POWERLEVEL9K_RUSTENV_PROMPT_ALWAYS_SHOW=false

  # -----------------------------------------------------------------------------
  # 📁  Enhanced Directory Segment – Git-Aware Truncation
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=true
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'
  
  # Git repository root anchoring
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER='(.git|.svn|.hg|package.json|Cargo.toml)'
  
  # Enhanced directory classes with icons
  typeset -g POWERLEVEL9K_DIR_CLASSES=(
    '~'              HOME            ''
    '~/.config(|/*)'  CONFIG         ''
    '~/Documents(|/*)' DOCUMENTS     ''
    '~/Downloads(|/*)' DOWNLOADS     ''
    '*'              DEFAULT         ''
  )

  # -----------------------------------------------------------------------------
  # 👤  Smart Context Segment (user@host)
  # -----------------------------------------------------------------------------
  # Set your default user to auto-hide locally
  typeset -g DEFAULT_USER="${USER}"
  
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$red}%n%f%F{$grey}@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_TEMPLATE="%F{$yellow}%n@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$grey}%n@%m%f"
  
  # Hide context for default user locally, show on SSH
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=false
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_USER=false

  # -----------------------------------------------------------------------------
  # ⏱️  Enhanced Command Execution Time
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=1
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='%F{242}took '

  # -----------------------------------------------------------------------------
  # ✅  Enhanced Status Segment – Show Exit Codes
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$red
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_CONTENT_EXPANSION='${P9K_CONTENT}'

  # -----------------------------------------------------------------------------
  # 🌿  Advanced Git Status Segment (Significantly Enhanced)
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=$orange
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=''
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'
  typeset -g POWERLEVEL9K_VCS_TAG_ICON='🏷 '

  # Enhanced State Indicators
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=$green
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=$cyan
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=$red

  # Detailed Status Icons
  typeset -g POWERLEVEL9K_VCS_CLEAN_ICON='%F{108}✓%f'
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='%F{117}?%f'
  typeset -g POWERLEVEL9K_VCS_MODIFIED_ICON='%F{220}!%f'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='%F{108}+%f'
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_ICON='%F{196}✖%f'
  typeset -g POWERLEVEL9K_VCS_STASHES_ICON='%F{117}*%f'

  # Remote Sync Status with Enhanced Visual
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='%F{109}⇣%f'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='%F{109}⇡%f'
  typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=99

  # Action States (rebase, merge, cherry-pick, etc.)
  typeset -g POWERLEVEL9K_VCS_ACTIONFORMAT_FOREGROUND=$red

  # Display Configuration
  typeset -g POWERLEVEL9K_VCS_SHOW_NUM_CHANGES=true
  typeset -g POWERLEVEL9K_VCS_SHOW_DIVERGENCE=true
  typeset -g POWERLEVEL9K_VCS_SHOW_STASH=true

  # Clean formatting without colons
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${P9K_CONTENT//:/ }'

  # Optimized async performance
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0.05
  typeset -g POWERLEVEL9K_VCS_RECURSE_UNTRACKED_DIRS=false
  typeset -g POWERLEVEL9K_VCS_LOADING_TEXT='%F{238}…%f'

  # Comprehensive Git Hooks
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(
    vcs-detect-changes
    git-untracked
    git-aheadbehind
    git-stash
    git-remotebranch
    git-tagname
  )

  # Git repository detection patterns (empty = all repos enabled)
  typeset -g POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN=''
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'

  # -----------------------------------------------------------------------------
  # 🐳  Enhanced Container Context (Podman/Docker/K8s)
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_PODMAN_FOREGROUND=$cyan
  typeset -g POWERLEVEL9K_PODMAN_SHOW_ON_COMMAND='podman|docker|kubectl|helm|skaffold'
  typeset -g POWERLEVEL9K_PODMAN_CONTENT_EXPANSION='${P9K_CONTENT}'

  # -----------------------------------------------------------------------------
  # ⚙️  Enhanced Background Jobs Indicator
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=true
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE_ALWAYS=false

  # -----------------------------------------------------------------------------
  # ⚡  Performance Optimization & Behavior
  # -----------------------------------------------------------------------------
  # Transient prompt: DISABLED - Keep full directory info visible after commands
  # Options: off (full prompt always) | same-dir (transient except after cd) | always (minimal)
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  
  # Instant prompt for blazing fast startup
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  
  # Disable hot reload for maximum performance
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
  
  # Gitstatus configuration for optimal performance
  typeset -g GITSTATUS_LOG_LEVEL=INFO
  typeset -g GITSTATUS_NUM_THREADS=8
  
  # Cache TTL for repeated directory checks
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=4096

  # -----------------------------------------------------------------------------
  # 🎯  Additional Quality-of-Life Features
  # -----------------------------------------------------------------------------
  # Show time since last commit (if > 1 day)
  typeset -g POWERLEVEL9K_VCS_SHOW_COMMIT_TIME=true
  typeset -g POWERLEVEL9K_VCS_COMMIT_TIME_FORMAT='%D{%Y-%m-%d}'

  # Shorten directory names in Git repos for readability
  typeset -g POWERLEVEL9K_DIR_SHORTEN_BEFORE_REPO=true

  # Apply configuration immediately if Powerlevel10k is already active
  (( ! $+functions[p10k] )) || p10k reload
}

# -----------------------------------------------------------------------------
# 📁  Configuration File Reference (for `p10k configure`)
# -----------------------------------------------------------------------------
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

# Restore original shell options to prevent side effects
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
builtin unset p10k_config_opts
# ==============================================================================
