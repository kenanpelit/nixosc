# ==============================================================================
# Powerlevel10k — "Pure Pro v3.0 Refined (Catppuccin Lavender Edition)"
# ==============================================================================
# Ultra-refined, performance-optimized Pure-style prompt with essential
# features only. No bloat, maximum clarity.
#
# ✨ Core Features:
#   • Enhanced Git status with comprehensive indicators
#   • Smart context hiding (auto-detects $DEFAULT_USER)
#   • Improved visual hierarchy with refined color palette
#   • Python, Node.js, and Rust version indicators
#   • Intelligent directory truncation with Git-aware anchoring
#   • Optimized async performance with sub-50ms latency
#   • Enhanced SSH detection with visual distinction
#   • Command failure feedback with exit code display
#   • VI mode indicators
#   • Background jobs counter
#
# ------------------------------------------------------------------------------

# Preserve shell options for clean environment
builtin local -a p10k_config_opts
[[ ! -o aliases         ]] || p10k_config_opts+=(aliases)
[[ ! -o sh_glob         ]] || p10k_config_opts+=(sh_glob)
[[ ! -o no_brace_expand ]] || p10k_config_opts+=(no_brace_expand)
builtin setopt no_aliases no_sh_glob brace_expand

() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Require zsh ≥ 5.1 for full functionality
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # -----------------------------------------------------------------------------
  # 🎨 Enhanced Catppuccin Lavender Color Palette
  # -----------------------------------------------------------------------------
  local grey='242'          # Subtle elements / secondary text
  local dark_grey='238'     # Muted backgrounds
  local darker_grey='236'   # Deep backgrounds
  local red='204'           # Errors / conflicts (softer for eyes)
  local bright_red='196'    # Critical errors
  local yellow='221'        # Warnings / SSH
  local blue='75'           # Directories (sky blue)
  local bright_blue='117'   # Active elements
  local green='114'         # Success / clean state
  local bright_green='156'  # Emphasized success
  local magenta='176'       # Prompt char (vibrant)
  local cyan='117'          # Info / network
  local orange='215'        # Branch names
  local lavender='147'      # Primary accent
  local peach='216'         # Staged changes
  local teal='109'          # Upstream sync

  # -----------------------------------------------------------------------------
  # 🧩 Optimized Prompt Structure — Clean Two-Line Layout
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    # Line 1 — Context → Directory → Git → Performance → Status
    context                   # user@host (smart display)
    dir                       # current directory
    vcs                       # git status
    command_execution_time    # execution duration
    status                    # exit code
    
    # Line 2 — Dev Environment → Jobs → Prompt
    newline
    virtualenv                # Python venv
    pyenv                     # Python version
    nodenv                    # Node.js version
    rustenv                   # Rust version
    background_jobs           # Background jobs
    prompt_char               # VI-aware prompt
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # Minimal right prompt (Pure philosophy)
    newline
  )

  # -----------------------------------------------------------------------------
  # 🧱 Enhanced Layout Configuration
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # Professional separator with refined aesthetics
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR='%F{236}│%f'
  
  # Whitespace padding for breathing room
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=' '

  # -----------------------------------------------------------------------------
  # ⌨️ Enhanced Prompt Character with VI Mode Support
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$magenta
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$red
  
  # Enhanced VI mode indicators
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶'
  
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

  # -----------------------------------------------------------------------------
  # 🐍 Enhanced Python Environment
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$green
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=true
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=
  
  # Auto-detect common venv names
  typeset -g POWERLEVEL9K_VIRTUALENV_GENERIC_NAMES=(
    venv .venv env .env virtualenv .virtualenv
  )

  # Pyenv — show when different from global
  typeset -g POWERLEVEL9K_PYENV_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=false
  typeset -g POWERLEVEL9K_PYENV_CONTENT_EXPANSION='🐍${P9K_CONTENT}${${P9K_PYENV_PYTHON_VERSION:#$P9K_PYENV_GLOBAL_PYTHON_VERSION}:+ %F{green}⊕%f}'

  # -----------------------------------------------------------------------------
  # 🟢 Enhanced Node.js Environment
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_NODENV_FOREGROUND=$green
  typeset -g POWERLEVEL9K_NODENV_PROMPT_ALWAYS_SHOW=false
  typeset -g POWERLEVEL9K_NODENV_CONTENT_EXPANSION='⬢${P9K_CONTENT}${${P9K_NODENV_NODE_VERSION:#$P9K_NODENV_GLOBAL_NODE_VERSION}:+ %F{green}⊕%f}'

  # -----------------------------------------------------------------------------
  # 🦀 Rust Environment
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_RUSTENV_FOREGROUND=$orange
  typeset -g POWERLEVEL9K_RUSTENV_SOURCES=(rustup rust-toolchain rust-toolchain.toml)
  typeset -g POWERLEVEL9K_RUSTENV_PROMPT_ALWAYS_SHOW=false
  typeset -g POWERLEVEL9K_RUSTENV_CONTENT_EXPANSION='🦀 ${P9K_CONTENT}'

  # -----------------------------------------------------------------------------
  # 📁 Advanced Directory Segment — Intelligent Truncation
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
  
  # Advanced truncation strategy
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=50
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=true
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'
  
  # Git repository anchoring
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER='(
    .git|.svn|.hg|
    package.json|package-lock.json|
    Cargo.toml|Cargo.lock|
    go.mod|requirements.txt|pyproject.toml
  )'
  
  # Enhanced directory classification
  typeset -g POWERLEVEL9K_DIR_CLASSES=(
    '~'                      HOME          ''
    '~/.config(|/*)'         CONFIG        '⚙'
    '~/Documents(|/*)'       DOCUMENTS     '📄'
    '~/Downloads(|/*)'       DOWNLOADS     '📥'
    '~/Projects(|/*)'        PROJECTS      '💼'
    '~/Dev(|/*)'             DEV           '💻'
    '~/Code(|/*)'            CODE          '💻'
    '/etc(|/*)'              ETC           '⚙'
    '*'                      DEFAULT       ''
  )
  
  # Special states
  typeset -g POWERLEVEL9K_DIR_NOT_WRITABLE_FOREGROUND=$red
  typeset -g POWERLEVEL9K_DIR_NOT_WRITABLE_VISUAL_IDENTIFIER_EXPANSION='🔒'
  typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=true

  # -----------------------------------------------------------------------------
  # 👤 Smart Context Segment (user@host)
  # -----------------------------------------------------------------------------
  # Set your default user to auto-hide locally
  typeset -g DEFAULT_USER="${USER}"
  
  # Context templates with enhanced styling
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$bright_red}%B%n%b%f%F{$grey}@%f%F{$red}%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=$bright_red
  
  typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_TEMPLATE="%F{$yellow}%n%f%F{$grey}@%f%F{$yellow}%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_FOREGROUND=$yellow
  
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$grey}%n@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=$grey
  
  # Smart visibility rules
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=false
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_USER=false
  
  # Visual indicators
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_VISUAL_IDENTIFIER_EXPANSION='⚡'
  typeset -g POWERLEVEL9K_CONTEXT_REMOTE_VISUAL_IDENTIFIER_EXPANSION='🌐'

  # -----------------------------------------------------------------------------
  # ⏱️ Enhanced Command Execution Time
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=2
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='%F{242}⏱ '

  # -----------------------------------------------------------------------------
  # ✅ Advanced Status Segment — Comprehensive Error Reporting
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE=false
  
  # Error display with exit codes
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$red
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  
  # Signal handling
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=$bright_red
  
  # Pipe status
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=$red
  
  # Show exit code
  typeset -g POWERLEVEL9K_STATUS_ERROR_CONTENT_EXPANSION='✘ ${P9K_CONTENT}'

  # -----------------------------------------------------------------------------
  # 🌿 Professional Git Status — Maximum Information Density
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=$orange
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=$grey
  
  # Branch and commit styling
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=''
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'
  typeset -g POWERLEVEL9K_VCS_TAG_ICON='🏷 '
  
  # State-based coloring
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=$green
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=$cyan
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=$red
  
  # Comprehensive status icons with enhanced visibility
  typeset -g POWERLEVEL9K_VCS_CLEAN_ICON='%F{114}✓%f'
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='%F{117}?%f'
  typeset -g POWERLEVEL9K_VCS_MODIFIED_ICON='%F{221}!%f'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='%F{156}+%f'
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_ICON='%F{204}✖%f'
  typeset -g POWERLEVEL9K_VCS_STASHES_ICON='%F{117}*%f'
  typeset -g POWERLEVEL9K_VCS_DELETED_ICON='%F{red}−%f'
  typeset -g POWERLEVEL9K_VCS_RENAMED_ICON='%F{cyan}→%f'
  
  # Remote tracking with visual indicators
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='%F{109}⇣%f'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='%F{109}⇡%f'
  typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=99
  
  # Action states (merge, rebase, cherry-pick, bisect, etc.)
  typeset -g POWERLEVEL9K_VCS_ACTIONFORMAT_FOREGROUND=$red
  
  # Display configuration
  typeset -g POWERLEVEL9K_VCS_SHOW_NUM_CHANGES=true
  typeset -g POWERLEVEL9K_VCS_SHOW_DIVERGENCE=true
  typeset -g POWERLEVEL9K_VCS_SHOW_STASH=true
  
  # Clean formatting
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${P9K_CONTENT//:/ }'
  
  # Performance optimization
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0.05
  typeset -g POWERLEVEL9K_VCS_RECURSE_UNTRACKED_DIRS=false
  typeset -g POWERLEVEL9K_VCS_LOADING_TEXT='%F{236}⋯%f'
  
  # Comprehensive Git hooks
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(
    vcs-detect-changes
    git-untracked
    git-aheadbehind
    git-stash
    git-remotebranch
    git-tagname
  )
  
  # Repository patterns (empty = all enabled)
  typeset -g POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN=''
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'

  # -----------------------------------------------------------------------------
  # ⚙️ Enhanced Background Jobs
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$cyan
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=true
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE_ALWAYS=true
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VISUAL_IDENTIFIER_EXPANSION='⚙'

  # -----------------------------------------------------------------------------
  # ⚡ Performance Optimization & Advanced Behavior
  # -----------------------------------------------------------------------------
  
  # Transient prompt: OFF for full context visibility
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  
  # Instant prompt mode for sub-second startup
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  
  # Hot reload: disabled for maximum performance
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
  
  # Gitstatus optimization
  typeset -g GITSTATUS_LOG_LEVEL=INFO
  typeset -g GITSTATUS_NUM_THREADS=10
  typeset -g GITSTATUS_ENABLE_LOGGING=0
  
  # Cache configuration
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=4096
  
  # Performance tuning
  typeset -g POWERLEVEL9K_USE_CACHE=true
  typeset -g POWERLEVEL9K_MAX_CACHE_SIZE=10000

  # -----------------------------------------------------------------------------
  # 🎯 Quality-of-Life Features
  # -----------------------------------------------------------------------------
  
  # Smart directory shortening in Git repos
  typeset -g POWERLEVEL9K_DIR_SHORTEN_BEFORE_REPO=true
  
  # Anchor important directories
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true

  # Apply configuration immediately if already active
  (( ! $+functions[p10k] )) || p10k reload
}

# -----------------------------------------------------------------------------
# 📝 Configuration File Reference
# -----------------------------------------------------------------------------
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

# Restore original shell options
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
builtin unset p10k_config_opts

# ==============================================================================
# 💡 Quick Customization Guide:
# ==============================================================================
# 1. Set your username at line 202: DEFAULT_USER="${USER}"
# 2. Adjust colors at lines 33-48 for personal preference
# 3. Modify directory classes at lines 165-176 for custom paths
# 4. Tune performance at line 323: GITSTATUS_NUM_THREADS (8-12 recommended)
# 5. Change execution time threshold at line 225 (default: 3 seconds)
# ==============================================================================
