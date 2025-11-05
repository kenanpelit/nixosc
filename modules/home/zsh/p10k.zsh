# Powerlevel10k - "Pure Pro" Configuration
# ========================================
# Enhanced Pure-style prompt with productivity improvements
# - Maintains Pure's clean two-line aesthetic
# - Adds smart Git visibility, SSH context, and developer tools
# - Optimized for daily development workflow
# - Features: Podman support, background jobs, error highlighting

# Preserve original shell options and set up clean environment for configuration
builtin local -a p10k_config_opts
[[ ! -o aliases         ]] || p10k_config_opts+=(aliases)
[[ ! -o sh_glob         ]] || p10k_config_opts+=(sh_glob)
[[ ! -o no_brace_expand ]] || p10k_config_opts+=(no_brace_expand)
builtin setopt no_aliases no_sh_glob brace_expand

() {
  emulate -L zsh -o extended_glob
  
  # Clear all existing Powerlevel9k configuration to start fresh
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Version check: require Zsh 5.1 or newer for compatibility
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # ============================
  # Color Palette Definition
  # ============================
  # Neutral, Catppuccin-friendly colors that work across themes
  local grey='242'    # Subtle text, secondary information
  local red='1'       # Errors, root user, critical states
  local yellow='3'    # Warnings, SSH context, highlights
  local blue='4'      # Directories, primary information
  local magenta='5'   # Prompt character, visual elements
  local cyan='6'      # Podman context, technical indicators
  local white='7'     # Bright text for emphasis

  # ============================
  # Prompt Segment Organization
  # ============================
  
  # Left Prompt (Two-line Pure-style layout)
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    # Line 1: Context and status information
    context                   # user@host (visible only on SSH/root)
    dir                       # current directory with smart truncation
    vcs                       # Git repository status with clear icons
    command_execution_time    # duration of long-running commands (≥3s)
    
    # Line 2: Environment and interactive elements  
    newline                   # line break for two-line layout
    virtualenv                # Python virtual environment indicator
    podman                    # Podman/Docker context when active
    background_jobs           # background jobs indicator
    prompt_char               # interactive prompt symbol (❯/❮)
  )

  # Right Prompt (Minimalist, Pure-style empty)
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # Line 1: Can be used for time/date if desired
    # time                    # current time (commented for Pure look)
    
    # Line 2: Structural element only
    newline                   # maintains symmetry with left prompt
  )

  # ============================
  # Global Layout & Appearance
  # ============================
  typeset -g POWERLEVEL9K_BACKGROUND=                            # transparent background
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=  # no extra padding
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '  # space between segments
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=        # no end separators
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=           # disable segment icons
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true               # blank line before each prompt

  # ============================
  # Prompt Character & VI Modes
  # ============================
  # Color coding for prompt character based on command success
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$magenta
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
  
  # Symbol definitions for different VI modes
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'      # Insert mode
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'      # Command mode
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'      # Visual mode
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false                       # No overwrite mode indicator

  # ============================
  # Python Virtual Environment
  # ============================
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$grey            # subtle grey color
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false   # keep it minimal
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=     # no extra delimiters

  # ============================
  # Directory Segment
  # ============================
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue                   # blue for visibility
  
  # Smart truncation settings to prevent line wrapping
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique    # show unique parts
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1                   # minimum characters to show
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80                      # maximum directory length
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40             # adjust based on terminal width
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=true        # truncate before special markers
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'                  # ellipsis for truncated parts

  # ============================
  # Context Segment (user@host)
  # ============================
  # Templates for different context scenarios
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$red}%n%f%F{$grey}@%m%f"      # root: red user
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$yellow}%n@%m%f"                   # SSH: yellow user@host
  
  # Display rules: only show context when relevant
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=              # hide locally
  typeset -g POWERLEVEL9K_CONTEXT_SHOW_ON_SSH=true                               # show on SSH
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=$red                           # root in red
  typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_FOREGROUND=$yellow        # SSH in yellow

  # ============================
  # Command Execution Time
  # ============================
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3     # show if ≥3 seconds
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0     # no decimal places
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s' # human readable format
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow # yellow for visibility

  # ============================
  # Git Status Segment
  # ============================
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=$grey                   # subtle grey for Git info

  # Async loading indicator for large repositories
  typeset -g POWERLEVEL9K_VCS_LOADING_TEXT='…'                   # ellipsis during loading

  # Performance: never block prompt waiting for Git
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0         # always async update

  # Git status icons for clear visual feedback
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=''                     # no branch icon
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'                    # commit symbol
  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED}_ICON='' # no individual state icons
  typeset -g POWERLEVEL9K_VCS_DIRTY_ICON='✗'                     # clear dirty indicator
  typeset -g POWERLEVEL9K_VCS_CLEAN_ICON='✓'                     # clean repository
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'                 # untracked files
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON=':⇣'         # incoming changes
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON=':⇡'         # outgoing changes
  
  # Limit commit counts for compact display
  typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=1
  
  # Clean formatting: remove spaces and colons from ahead/behind display
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${${${P9K_CONTENT/⇣* :⇡/⇣⇡}// }//:/ }'
  
  # Git hooks for status detection (optimized for speed)
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(vcs-detect-changes git-untracked git-aheadbehind)

  # ============================
  # Podman Context Segment
  # ============================
  typeset -g POWERLEVEL9K_PODMAN_FOREGROUND=$cyan                # cyan for container context
  typeset -g POWERLEVEL9K_PODMAN_SHOW_ON_COMMAND='podman|docker|kubectl' # show after relevant commands

  # ============================
  # Background Jobs Indicator
  # ============================
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false          # don't show job count
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$grey       # subtle grey indicator

  # ============================
  # Error Status Highlighting
  # ============================
  typeset -g POWERLEVEL9K_STATUS_ERROR=true                      # enable error display
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$red           # red for errors
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true               # show signal errors
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘' # cross symbol for errors

  # ============================
  # Time Segment (Optional)
  # ============================
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=$grey                  # subtle time display
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'             # 24-hour time format
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false           # don't update on enter

  # ============================
  # Transient Prompt
  # ============================
  # Compact prompt for multi-line commands while preserving context after directory changes
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir

  # ============================
  # Instant Prompt
  # ============================
  # Faster Zsh startup with compatibility warnings
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

  # ============================
  # Performance Optimization
  # ============================
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true               # disable runtime changes for speed

  # Reload configuration if Powerlevel10k is already running
  (( ! $+functions[p10k] )) || p10k reload
}

# ============================
# Configuration Management
# ============================
# Set the config file path for `p10k configure` command
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

# Restore original shell options after configuration
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
builtin unset p10k_config_opts
