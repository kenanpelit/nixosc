# ==============================================================================
# Powerlevel10k — Ultra Performance Minimal Pro (Refined)
# ==============================================================================
# Goals:
#   • Lowest possible latency on enter
#   • Zero blocking on huge Git repos / remote FS
#   • Minimal redraws and allocations
#   • Clean, informative, Catppuccin-friendly look
# ==============================================================================

builtin local -a p10k_config_opts
[[ ! -o aliases         ]] || p10k_config_opts+=(aliases)
[[ ! -o sh_glob         ]] || p10k_config_opts+=(sh_glob)
[[ ! -o no_brace_expand ]] || p10k_config_opts+=(no_brace_expand)
setopt no_aliases no_sh_glob brace_expand

() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return 0

  # ----------------------------- Palette -------------------------------------
  # Catppuccin Lavender-ish 256 palette (lean set)
  local grey=242 dark_grey=238 darker_grey=236
  local red=204 bright_red=196 yellow=221 blue=75
  local green=114 bright_green=156 magenta=176 cyan=117
  local orange=215 teal=109 lavender=183

  # ----------------------------- Layout --------------------------------------
  # Left prompt is compact; right prompt disabled (fastest, least redraw)
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    context
    dir
    vcs
    command_execution_time
    status
    newline
    virtualenv
    background_jobs
    prompt_char
  )
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

  # No background, single-space joins, no heavy separators
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
  typeset -g POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR="%F{$darker_grey}│%f"
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=

  # --------------------------- Prompt Char -----------------------------------
  # VI-mode aware, minimal glyphs; avoid extra symbol swapping cost
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$magenta
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$red
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='V'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIOWR_CONTENT_EXPANSION='▶'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

  # --------------------------- Virtualenv ------------------------------------
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$green
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=
  typeset -g POWERLEVEL9K_VIRTUALENV_GENERIC_NAMES=(venv .venv env .env virtualenv .virtualenv)

  # ----------------------------- Directory -----------------------------------
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
  # Shorten aggressively but predictably; never block on $PWD
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=40
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=true
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_FOLDER_MARKER='(.git|.hg|.svn|package.json|Cargo.toml|go.mod|pyproject.toml|composer.json|Makefile)'
  typeset -g POWERLEVEL9K_DIR_SHORTEN_BEFORE_REPO=true
  typeset -g POWERLEVEL9K_DIR_CLASSES=(
    '*/.config(|/*)'     CONFIG     '%F{117}⚙%f'
    '*/Documents(|/*)'   DOCUMENTS  '%F{114}📄%f'
    '*/Downloads(|/*)'   DOWNLOADS  '%F{221}📥%f'
    '~'                  HOME       '%F{75}~%f'
  )
  # Disable directory hyperlinks (saves formatting work in some terminals)
  typeset -g POWERLEVEL9K_DIR_HYPERLINK=false

  # ------------------------------ Context ------------------------------------
  # Show user@host only when it matters (root, SSH, or non-default user)
  typeset -g DEFAULT_USER="${USER}"
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=false
  typeset -g POWERLEVEL9K_ALWAYS_SHOW_USER=false
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$grey}%n@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$bright_red}%B%n%b%f%F{$grey}@%f%F{$red}%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{REMOTE,REMOTE_SUDO}_TEMPLATE="%F{$yellow}%n%f%F{$grey}@%f%F{$yellow}%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=
  # Fast path: compute once, avoid subshells per prompt
  if [[ -n $SSH_CONNECTION || -n $SSH_TTY || $EUID -eq 0 || $USER != $DEFAULT_USER ]]; then
    typeset -g POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=true
  fi

  # --------------------- Command Execution Time ------------------------------
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=2
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=1
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PREFIX='%F{242}took '

  # -------------------------------- Status -----------------------------------
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE=false
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$red
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=$bright_red
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=$red
  typeset -g POWERLEVEL9K_STATUS_ERROR_CONTENT_EXPANSION='✘${P9K_CONTENT}'
  # Pipes are common in HPC; skip per-stage pipe status to keep things lean
  typeset -g POWERLEVEL9K_STATUS_SHOW_PIPESTATUS=false

  # --------------------------------- VCS -------------------------------------
  # Keep VCS blazing fast and non-blocking on huge repos/remote FS
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=$orange
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'
  typeset -g POWERLEVEL9K_VCS_TAG_ICON='🏷 '

  # State colors + lightweight ASCII-ish icons (still readable without Nerd Font)
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=$green
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=$cyan
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=$red

  typeset -g POWERLEVEL9K_VCS_CLEAN_ICON='%F{114}✔%f'
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='%F{117}?%f'
  typeset -g POWERLEVEL9K_VCS_MODIFIED_ICON='%F{221}!%f'
  typeset -g POWERLEVEL9K_VCS_STAGED_ICON='%F{156}+%f'
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_ICON='%F{204}✖%f'
  typeset -g POWERLEVEL9K_VCS_STASHES_ICON='%F{117}*%f'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='%F{109}⇣%f'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='%F{109}⇡%f'

  typeset -g POWERLEVEL9K_VCS_SHOW_NUM_CHANGES=true
  typeset -g POWERLEVEL9K_VCS_SHOW_DIVERGENCE=true
  typeset -g POWERLEVEL9K_VCS_SHOW_STASH=true
  typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=99
  typeset -g POWERLEVEL9K_VCS_ACTIONFORMAT_FOREGROUND=$red
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${P9K_CONTENT//:/ }'

  # Non-blocking VCS: wait tiny time for sync, otherwise go async immediately
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0.02

  # Avoid crawling deep untracked trees (node_modules, target, build, etc.)
  # Show "?" count up to a cap; keeps prompt constant-time on huge repos
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_MAX_NUM=200

  # Disable VCS in heavy/remote/system paths to prevent I/O stalls
  # (regex; | separates patterns)
  typeset -g POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN='
    ^/nix/store($|/)|
    ^/proc($|/)|
    ^/sys($|/)|
    ^/dev($|/)|
    ^/run($|/)|
    ^/tmp($|/)|
    /node_modules(/|$)|
    /target(/|$)|
    /build(/|$)|
    /.venv(/|$)|
    /.direnv(/|$)
  '

  # Don’t recurse untracked dirs; massive speed-up on mono-repos
  typeset -g POWERLEVEL9K_VCS_RECURSE_UNTRACKED_DIRS=false

  # Minimal Git hooks set (all you need for branch/divergence/stash/remote)
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(
    vcs-detect-changes
    git-untracked
    git-aheadbehind
    git-stash
    git-remotebranch
  )

  # ---------------------------- Gitstatus Daemon ------------------------------
  # Auto-tune threads once; keep logging silent
  integer _p10k_ncpu=8
  if command -v nproc >/dev/null 2>&1; then
    _p10k_ncpu=$(nproc 2>/dev/null || echo 8)
  elif [[ "$OSTYPE" == darwin* ]] && command -v sysctl >/dev/null 2>&1; then
    _p10k_ncpu=$(sysctl -n hw.ncpu 2>/dev/null || echo 8)
  fi
  # Cap at 16 threads (more rarely helps) and at least 4 to keep latency low
  (( _p10k_ncpu < 4 )) && _p10k_ncpu=4
  (( _p10k_ncpu > 16 )) && _p10k_ncpu=16

  typeset -g GITSTATUS_NUM_THREADS=$_p10k_ncpu
  typeset -g GITSTATUS_LOG_LEVEL=ERROR
  typeset -g GITSTATUS_ENABLE_LOGGING=0
  typeset -g GITSTATUS_DAEMON_TIMEOUT=0

  # Keep index scans cheap; if index is too big, fall back to async
  typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=4096

  # ------------------------------ Jobs ---------------------------------------
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$cyan
  # Print count only when non-zero (and keep it short)
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=false

  # --------------------------- Global toggles --------------------------------
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  # --------------------------- Micro-optimizations ----------------------------
  # Avoid terminal title writes (some terminals make them synchronous)
  typeset -g POWERLEVEL9K_TERM_SHELL_INTEGRATION=false
  typeset -g POWERLEVEL9K_RPROMPT_ON_NEWLINE=false
  typeset -g POWERLEVEL9K_DIR_OMIT_FIRST_CHARACTER=false

  (( ! $+functions[p10k] )) || p10k reload
}

typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
unset p10k_config_opts
