# Powerlevel10k - "Pure-plus" style: minimal aesthetics with pragmatic fixes
# - Keeps Pure's clean two-line look
# - Improves UX on narrow terminals, SSH clarity, and git async awareness

# Preserve and normalize shell options for this block.
builtin local -a p10k_config_opts
[[ ! -o aliases         ]] || p10k_config_opts+=(aliases)
[[ ! -o sh_glob         ]] || p10k_config_opts+=(sh_glob)
[[ ! -o no_brace_expand ]] || p10k_config_opts+=(no_brace_expand)
builtin setopt no_aliases no_sh_glob brace_expand

() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  # Require Zsh 5.1+
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return

  # ---- Palette (Catppuccin-friendly but neutral) ----
  local grey='242' red='1' yellow='3' blue='4' magenta='5' cyan='6' white='7'

  # ---- Segments (Pure-like 2 lines) ----
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    # Line 1
    context                 # user@host (only on SSH/root; see rules below)
    dir                     # current directory (smart shortening)
    vcs                     # git
    command_execution_time  # previous cmd duration (>= threshold)
    # Line 2
    newline
    virtualenv              # python venv (subtle)
    prompt_char             # ❯ / ❮ with error coloring
  )

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # Line 1 (kept empty for Pure look; enable 'time' if you like)
    # time
    # Line 2
    newline
  )

  # ---- Global layout: keep it airy & minimal ----
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

  # ---- Prompt char & VI mode ----
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$magenta
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
  # Insert mode
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  # Command/visual mode (distinct from Pure; UX improvement)
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false

  # ---- Python venv (subtle) ----
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=

  # ---- Directory: smart shortening to avoid ugly wraps ----
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
  # Prefer unique-edge truncation; keeps rightmost dirs readable
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=80
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=true
  typeset -g POWERLEVEL9K_SHORTEN_DELIMITER='…'

  # ---- Context: only on SSH or when root ----
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$white}%n%f%F{$grey}@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$grey}%n@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=
  # Show on SSH (remote) automatically:
  typeset -g POWERLEVEL9K_CONTEXT_SHOW_ON_SSH=true

  # ---- Command timing ----
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow

  # ---- Git (vcs): async & clear loading; minimal icons ----
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=$grey

  # Show a subtle loading hint so you know git is catching up (reduces "stale" ambiguity)
  typeset -g POWERLEVEL9K_VCS_LOADING_TEXT='…'

  # Never block on git; always async update
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0

  # Keep it clean but informative
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'
  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED}_ICON=
  typeset -g POWERLEVEL9K_VCS_DIRTY_ICON='*'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON=':⇣'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON=':⇡'
  typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=1
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${${${P9K_CONTENT/⇣* :⇡/⇣⇡}// }//:/ }'
  # Hooks: detect changes + ahead/behind (fast & minimal)
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(vcs-detect-changes git-untracked git-aheadbehind)

  # ---- Optional right-side time (disabled for Pure look) ----
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false

  # ---- Transient prompt (keeps history compact), but not after cd ----
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=same-dir

  # ---- Instant prompt: faster shell startup with explicit warnings ----
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

  # ---- Hot reload off for max performance ----
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  # Apply immediately if p10k is already loaded
  (( ! $+functions[p10k] )) || p10k reload
}

# Ensure p10k knows which file to overwrite if you run `p10k configure`.
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}

# Restore prior shell options.
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
builtin unset p10k_config_opts
