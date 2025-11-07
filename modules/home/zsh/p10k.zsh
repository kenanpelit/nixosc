# ==============================================================================
# Powerlevel10k — "Pure Pro Minimal (Catppuccin Lavender Edition)"
# ==============================================================================
# Minimal, performance-first Pure-style prompt. No bloat, maximum speed.
#
# ✨ Essential Features Only:
#   • Enhanced Git status with comprehensive indicators
#   • Smart context hiding (auto-detects $DEFAULT_USER)
#   • Refined color palette
#   • Python virtualenv indicator (when active)
#   • Intelligent directory truncation with Git-aware anchoring
#   • Maximum async performance (sub-50ms latency)
#   • Enhanced SSH detection
#   • Command failure feedback with exit code
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
  # 🎨 Catppuccin Lavender Color Palette
  # -----------------------------------------------------------------------------
  local grey='242'          # Subtle elements / secondary text
  local dark_grey='238'     # Muted backgrounds
  local darker_grey='236'   # Deep backgrounds
  local red='204'           # Errors / conflicts
  local bright_red='196'    # Critical errors
  local yellow='221'        # Warnings / SSH
  local blue='75'           # Directories
  local green='114'         # Success / clean state
  local bright_green='156'  # Emphasized success
  local magenta='176'       # Prompt char
  local cyan='117'          # Info
  local orange='215'        # Branch names
  local teal='109'          # Upstream sync

  # -----------------------------------------------------------------------------
  # 🧩 Minimal Prompt Structure — Two Lines
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    # Line 1 — Context → Directory → Git → Performance → Status
    context                   # user@host (smart display)
    dir                       # current directory
    vcs                       # git status
    command_execution_time    # execution duration
    status                    # exit code
    
    # Line 2 — Virtualenv → Jobs → Prompt
    newline
    virtualenv                # Python venv (only when active)
    background_jobs           # Background jobs
    prompt_char               # VI-aware prompt
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # Empty for minimal look
    newline
  )

  # -----------------------------------------------------------------------------
  # 🧱 Layout Configuration
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # Clean separator
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR='%F{236}│%f'
  
  # Spacing
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=' '

  # -----------------------------------------------------------------------------
  # ⌨️ Prompt Character with VI Mode Support
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$magenta
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$red
  
  # VI mode indicators
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶'
  
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

  # -----------------------------------------------------------------------------
  # 🐍 Python Virtualenv (Minimal)
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$green
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=
  
  # Auto-detect common venv names
  typeset -g POWERLEVEL9K_VIRTUALENV_GENERIC_NAMES=(
    venv .venv env .env virtualenv .virtualenv
  )

  # -----------------------------------------------------------------------------
  # 📁 Directory Segment — Intelligent Truncation
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
  
  # Truncation strategy
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=50
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=true
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'
  
  # Git repository anchoring
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER='(.git|.svn|.hg|package.json|Cargo.toml|go.mod|requirements.txt|pyproject.toml)'
  
  # Smart directory shortening in Git repos
  typeset -g POWERLEVEL9K_DIR_SHORTEN_BEFORE_REPO=true

  # -----------------------------------------------------------------------------
  # 👤 Smart Context Segment (user@host)
  # -----------------------------------------------------------------------------
  # Set your default user to auto-hide locally
  typeset -g DEFAULT_USER="${USER}"
  
  # Context templates
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$bright_red}%B%n%b%f%F{$grey}@%f%F{$red}%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_TEMPLATE="%F{$yellow}%n%f%F{$grey}@%f%F{$yellow}%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$grey}%n@%m%f"
  
  # Smart visibility — hide for default user locally, show on SSH/root
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=false
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_USER=false

  # -----------------------------------------------------------------------------
  # ⏱️ Command Execution Time
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=2
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='%F{242}took '

  # -----------------------------------------------------------------------------
  # ✅ Status Segment — Error Reporting
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
  # 🌿 Git Status — Comprehensive & Fast
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
  
  # Status icons
  typeset -g POWERLEVEL9K_VCS_CLEAN_ICON='%F{114}✓%f'
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='%F{117}?%f'
  typeset -g POWERLEVEL9K_VCS_MODIFIED_ICON='%F{221}!%f'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='%F{156}+%f'
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_ICON='%F{204}✖%f'
  typeset -g POWERLEVEL9K_VCS_STASHES_ICON='%F{117}*%f'
  
  # Remote tracking
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='%F{109}⇣%f'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='%F{109}⇡%f'
  typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=99
  
  # Action states
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
  
  # Git hooks
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(
    vcs-detect-changes
    git-untracked
    git-aheadbehind
    git-stash
    git-remotebranch
    git-tagname
  )
  
  # Enable all repos
  typeset -g POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN=''
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'

  # -----------------------------------------------------------------------------
  # ⚙️ Background Jobs
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$cyan
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=true
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE_ALWAYS=true

  # -----------------------------------------------------------------------------
  # ⚡ Maximum Performance Configuration
  # -----------------------------------------------------------------------------
  
  # Transient prompt: OFF
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  
  # Instant prompt for fastest startup
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  
  # Hot reload: disabled
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
  
  # Gitstatus optimization
  typeset -g GITSTATUS_LOG_LEVEL=INFO
  typeset -g GITSTATUS_NUM_THREADS=10
  typeset -g GITSTATUS_ENABLE_LOGGING=0
  
  # Cache configuration
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=4096
  typeset -g POWERLEVEL9K_USE_CACHE=true
  typeset -g POWERLEVEL9K_MAX_CACHE_SIZE=10000

  # Apply configuration immediately
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
# 💡 Customization:
# ==============================================================================
# 1. Set DEFAULT_USER at line 134 to your username for smart context hiding
# 2. Adjust colors at lines 34-46 if desired
# 3. Change execution time threshold at line 154 (default: 3 seconds)
# 4. Tune GITSTATUS_NUM_THREADS at line 227 based on your CPU (8-12 optimal)
# ==============================================================================
