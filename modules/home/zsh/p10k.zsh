# ==============================================================================
# Powerlevel10k – "Pure Pro v1.1 (Catppuccin Lavender Edition)"
# ==============================================================================
# A refined, Pure-style prompt tailored for developers who love simplicity,
# color harmony, and immediate feedback.
#
# ✨ Highlights:
#   • Catppuccin Mocha Lavender-themed color palette
#   • Smart Git awareness (branch, ahead/behind, dirty, untracked)
#   • SSH/root-aware context (auto-hides locally)
#   • Clean Pure-style layout with compact two-line prompt
#   • Optional Podman/Docker context and background job indicator
#   • Instant-prompt enabled for faster shell startup
#   • Transient prompt history (keeps terminal log clean)
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
  # 🎨  Catppuccin Lavender Color Palette
  # -----------------------------------------------------------------------------
  local grey='242'       # subtle elements / secondary text
  local red='1'          # errors / root
  local yellow='3'       # SSH / warnings / timings
  local blue='4'         # directories
  local green='2'        # success / clean Git state / staged
  local magenta='5'      # prompt char / visual highlight
  local cyan='6'         # network / technical
  local orange='214'     # branch name accent (high visibility)
  local lavender='141'   # Catppuccin Lavender accent
  local white='7'        # bright emphasis

  # -----------------------------------------------------------------------------
  # 🧩  Prompt Structure – Two Lines (Pure Layout)
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    # Line 1 – Context → Dir → Git → Exec Time
    context
    dir
    vcs
    command_execution_time
    # Line 2 – Env → Containers → Jobs → Prompt Char
    newline
    virtualenv
    podman
    background_jobs
    prompt_char
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # Minimal right prompt to preserve Pure look
    newline
  )

  # -----------------------------------------------------------------------------
  # 🧱  Layout & Spacing Configuration
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # Catppuccin-lavender sub-segment separator (keeps layout clean & visually balanced)
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR='%F{141} · %f'

  # -----------------------------------------------------------------------------
  # ⌨️  Prompt Character / VI Mode Colors
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$magenta
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false

  # -----------------------------------------------------------------------------
  # 🐍  Python Virtualenv – Subtle and Clean
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  # -----------------------------------------------------------------------------
  # 📁  Directory Segment – Smart Truncation
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=true
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'

  # -----------------------------------------------------------------------------
  # 👤  Context Segment (user@host)
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$red}%n%f%F{$grey}@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$yellow}%n@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=
  typeset -g POWERLEVEL9K_CONTEXT_SHOW_ON_SSH=true

  # -----------------------------------------------------------------------------
  # ⏱️  Command Execution Time
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow

  # -----------------------------------------------------------------------------
  # 🌿  Optimized Git Status Segment (Pure Pro Enhanced)
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=$orange
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'

  # State Indicators (Color Coded)
  typeset -g POWERLEVEL9K_VCS_CLEAN_ICON='%F{2}✓%f'
  typeset -g POWERLEVEL9K_VCS_DIRTY_ICON='%F{1}✗%f'
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='%F{4}?%f'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='%F{2}+%f'
  typeset -g POWERLEVEL9K_VCS_UNSTAGED_ICON='%F{3}!%f'

  # Remote Sync Status (⇡ ⇣)
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='%F{6}⇣%f'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='%F{6}⇡%f'
  typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=99

  # Display both counts and divergence
  typeset -g POWERLEVEL9K_VCS_SHOW_NUM_CHANGES=true
  typeset -g POWERLEVEL9K_VCS_SHOW_DIVERGENCE=true

  # Content Formatting – remove colons, ensure clean spacing
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${P9K_CONTENT//:/ }'

  # Async performance – soft sync for stable branch visibility
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0.2
  typeset -g POWERLEVEL9K_VCS_LOADING_TEXT='%F{245}…%f'

  # Minimal Git Hooks for Speed and Reliability
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(
    vcs-detect-changes
    git-untracked
    git-aheadbehind
  )

  typeset -g POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN=''
  typeset -g POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN=''

  # -----------------------------------------------------------------------------
  # 🐳  Podman / Docker / K8s Context Indicator
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_PODMAN_FOREGROUND=$cyan
  typeset -g POWERLEVEL9K_PODMAN_SHOW_ON_COMMAND='podman|docker|kubectl'

  # -----------------------------------------------------------------------------
  # ⚙️  Background Jobs Indicator
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false

  # -----------------------------------------------------------------------------
  # ❌  Error Status Highlighting
  # -----------------------------------------------------------------------------
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$red
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'

  # -----------------------------------------------------------------------------
  # ⚡  Performance & Behavior
  # -----------------------------------------------------------------------------
  # Transient prompt for a clean scrollback: retains prompt position after `cd`
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir
  # Instant prompt for faster startup (silent mode)
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  # Disable hot reload for maximum speed
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

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
