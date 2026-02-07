#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# niri-keybinds
# -----------------------------------------------------------------------------
# Purpose:
# - Parse Niri `binds { ... }` blocks into launcher-friendly plain text lines.
# - Produce keybind/title/command entries consumable by rofi/fuzzel/dmenu.
#
# Input/Output model:
# - Input: KDL config (default: ~/.config/niri/config.kdl)
# - Output: one formatted line per bind to stdout
# - Optional cleanup: remove spawn prefixes and/or command quotes
#
# Typical usage:
# - niri-keybinds | rofi -dmenu -i -p "Niri Keybinds"
# - niri-keybinds | fuzzel -d
#
# Dependencies:
# - awk
# - notify-send (optional; used for parse/file errors)
#
# Notes:
# - Parser is intentionally pragmatic (line-oriented) for speed and portability.
# - Run `niri-keybinds --help` for formatting and filtering options.
# -----------------------------------------------------------------------------

set -euo pipefail

# -----------------------------
# Defaults
DEFAULT_KDL="${HOME}/.config/niri/config.kdl"
DEFAULT_SEP_KB=$'\t| '
DEFAULT_SEP_TITLE=$' |\t'
DEFAULT_LINE_END=$'\n'

KEYBIND_KDL_PATH="$DEFAULT_KDL"
INCLUDE_OVERLAY_TITLES=1 # Python: default include (exclude_titles flag toggles)
REMOVE_CMD_QUOTATIONS=1  # Python: default remove (include_command_quotes toggles)
REMOVE_SPAWN_PREFIX=1    # Python: default remove (include_spawn_prefix toggles)
PAD_KEYBIND=8
PAD_TITLE=32
SEP_KEYBIND="$DEFAULT_SEP_KB"
SEP_TITLE="$DEFAULT_SEP_TITLE"
OUTPUT_LINE_END="$DEFAULT_LINE_END"

# -----------------------------
# Helpers
notify_error() {
  local title="$1"
  local msg="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$msg"
  else
    printf 'ERROR: %s\n%s\n' "$title" "$msg" >&2
  fi
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Parse niri keybinds into launcher-friendly output.

Options:
  -i,  --keybind_kdl PATH        Path to keybinds.kdl (default: $DEFAULT_KDL)
  -t,  --exclude_titles          Do not include 'hotkey-overlay-title' in output
  -s,  --include_spawn_prefix    Keep 'spawn'/'spawn-sh' prefix in commands
  -c,  --include_command_quotes  Keep apostrophes & quotation marks in commands
  -pk, --pad_keybind N           Padding added to keybinds (default: 8)
  -pt, --pad_title N             Padding added to titles (default: 32)
  -ak, --sep_keybind STR         Separator after keybind text (default: \$'\\t| ')
  -at, --sep_title STR           Separator after title text (default: \$' |\\t')
  -e,  --output_line_end STR     Line ending string for output (default: \$'\\n')
  -h,  --help                    Show this help

Example:
  $(basename "$0") | fuzzel -d
EOF
}

# -----------------------------
# Arg parsing (supports short + long, including -pk/-pt/-ak/-at)
while [[ $# -gt 0 ]]; do
  case "$1" in
  -i | --keybind_kdl)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    KEYBIND_KDL_PATH="$2"
    shift 2
    ;;
  -t | --exclude_titles)
    INCLUDE_OVERLAY_TITLES=0
    shift
    ;;
  -s | --include_spawn_prefix)
    REMOVE_SPAWN_PREFIX=0
    shift
    ;;
  -c | --include_command_quotes)
    REMOVE_CMD_QUOTATIONS=0
    shift
    ;;
  -pk | --pad_keybind)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    PAD_KEYBIND="$2"
    shift 2
    ;;
  -pt | --pad_title)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    PAD_TITLE="$2"
    shift 2
    ;;
  -ak | --sep_keybind)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    SEP_KEYBIND="$2"
    shift 2
    ;;
  -at | --sep_title)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    SEP_TITLE="$2"
    shift 2
    ;;
  -e | --output_line_end)
    [[ $# -ge 2 ]] || {
      usage >&2
      exit 2
    }
    OUTPUT_LINE_END="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    printf 'Unknown option: %s\n\n' "$1" >&2
    usage >&2
    exit 2
    ;;
  esac
done

# Expand ~ manually (bash does it for unquoted, but we want to be safe)
if [[ "$KEYBIND_KDL_PATH" == "~/"* ]]; then
  KEYBIND_KDL_PATH="${HOME}/${KEYBIND_KDL_PATH#~/}"
fi

# -----------------------------
# Read & validate file
if [[ ! -f "$KEYBIND_KDL_PATH" ]]; then
  notify_error "Error parsing keybinds!" "Not found: $KEYBIND_KDL_PATH"
  exit 1
fi

# -----------------------------
# Parse using awk
# We:
# - enter binds section when we see: ^\s*binds(\s*\{)?
# - start processing after that line
# - stop at a line that is exactly: }
#
# Notes:
# - We keep the parsing behavior close to your Python version (simple split on '{' and ';').
# - If a line contains multiple '{', it is skipped (same as Python).
#
awk \
  -v include_titles="$INCLUDE_OVERLAY_TITLES" \
  -v remove_quotes="$REMOVE_CMD_QUOTATIONS" \
  -v remove_spawn="$REMOVE_SPAWN_PREFIX" \
  -v pad_k="$PAD_KEYBIND" \
  -v pad_t="$PAD_TITLE" \
  -v sep_k="$SEP_KEYBIND" \
  -v sep_t="$SEP_TITLE" \
  -v out_end="$OUTPUT_LINE_END" \
  '
  function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
  function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
  function trim(s)  { return rtrim(ltrim(s)) }

  BEGIN {
    in_binds = 0
    found_binds = 0
    out_count = 0
  }

  {
    raw = $0

    # Detect binds section start (line may contain extra spaces before "{")
    if (!in_binds) {
      if (raw ~ /^[ \t]*binds([ \t]*\{)?[ \t]*$/ || raw ~ /^[ \t]*binds[ \t]*\{[ \t]*$/) {
        in_binds = 1
        found_binds = 1
        next
      }
    } else {
      line = trim(raw)

      # End of binds section
      if (line == "}") {
        in_binds = 0
        next
      }

      # Skip comments and short/junk lines
      if (line ~ /^\/\//) next
      if (length(line) < 3) next

      # Split on "{"
      # If more than 1 "{", skip (unexpected)
      n = split(line, parts, "{")
      if (n != 2) next

      config = parts[1]
      cmdpart = parts[2]

      # Extract keybind: first token in config
      # Similar to python: config.split(" ", 1)[0]
      keybind = config
      sub(/[ \t].*$/, "", keybind)

      # Extract first command up to ";"
      m = split(cmdpart, cmds, ";")
      command = trim(cmds[1])

      # Remove spawn/spawn-sh prefix if requested
      if (remove_spawn == 1) {
        if (command ~ /^spawn-sh[ \t]+/) sub(/^spawn-sh[ \t]+/, "", command)
        else if (command ~ /^spawn[ \t]+/) sub(/^spawn[ \t]+/, "", command)
      }

      # Remove quotes if requested
      if (remove_quotes == 1) {
        gsub(/"/, "", command)
        gsub(/\x27/, "", command)   # single quote
      }

      # Parse hotkey overlay title if requested
      title = ""
      if (include_titles == 1) {
        target = "hotkey-overlay-title="
        pos = index(config, target)
        if (pos > 0) {
          rest = substr(config, pos + length(target))
          rest = trim(rest)
          if (rest !~ /^null/) {
            marker = substr(rest, 1, 1)   # quote char
            # Split by marker: <marker> TITLE <marker> ...
            k = split(rest, tt, marker)
            if (k >= 3) title = tt[2]
          }
        }
      }

      # Padding
      keybind_padded = sprintf("%-*s", pad_k, keybind)

      if (length(title) > 0) {
        title_padded = sprintf("%-*s", pad_t, title)
        out[++out_count] = keybind_padded sep_k title_padded sep_t command
      } else {
        out[++out_count] = keybind_padded sep_k command
      }
    }
  }

  END {
    if (found_binds == 0) {
      # Mirror python behavior: notify + error
      # We cannot call notify-send reliably from awk portably, so print to stderr.
      # Caller bash already validated file, but not binds presence.
      print "Error parsing keybinds! Could not find binds {...} section" > "/dev/stderr"
      exit 3
    }

    for (i=1; i<=out_count; i++) {
      # Print with custom line terminator between lines
      printf "%s", out[i]
      if (i < out_count) printf "%s", out_end
    }
    if (out_count > 0) printf "%s", out_end
  }
  ' "$KEYBIND_KDL_PATH" || {
  # If awk returned our binds-not-found exit code or other error, also send notify.
  rc=$?
  if [[ $rc -eq 3 ]]; then
    notify_error "Error parsing keybinds!" "Could not find binds {...} section"
  fi
  exit "$rc"
}
