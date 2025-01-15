#!/usr/bin/env bash

# Base configuration
BASE_DIR="$HOME/.projects"
CACHE_DIR="$BASE_DIR/.cache"
mkdir -p "$CACHE_DIR"

# Default editor
EDITOR="${EDITOR:-nvim}"

# Get cache file for directory
get_cache_file() {
  local dir_name
  dir_name="$(basename "$1" | tr -d '\0')"
  echo "$CACHE_DIR/${dir_name}_cache"
}

# Cache update function - with null byte handling
update_cache() {
  local item cache_file
  item="$(echo "$1" | tr -d '\0')"
  cache_file="$2"
  touch "$cache_file"

  # Single operation cache update with proper null byte handling
  {
    echo "$item"
    grep -av "^$(echo "$item" | sed 's/[[\.*^$/]/\\&/g')\$" "$cache_file"
  } | head -n 50 >"$cache_file.temp"
  mv "$cache_file.temp" "$cache_file"
}

# Clipboard and notification function
copy_to_clipboard() {
  local file content
  file="$1"
  content="$(cat "$file" | tr -d '\0')"

  if command -v wl-copy >/dev/null; then
    printf '%s' "$content" | wl-copy
  elif command -v xsel >/dev/null; then
    printf '%s' "$content" | xsel -b
  elif command -v xclip >/dev/null; then
    printf '%s' "$content" | xclip -selection clipboard
  else
    echo "Error: No clipboard utility found"
    exit 1
  fi

  if [ -n "$TMUX" ]; then
    printf '%s' "$content" | tmux load-buffer -
    tmux display-message "Copied: $(basename "$file" | tr -d '\0')"
  fi

  if command -v notify-send >/dev/null; then
    notify-send -t 750 "Copied" "$(basename "$file" | tr -d '\0')"
  fi
}

# Content search function
do_content_search() {
  local dir
  dir="$1"
  cd "$dir" || exit

  while true; do
    local subdirs
    subdirs=$(find . -maxdepth 1 -type d -not -name ".*" -print0 |
      tr '\0' '\n' | sed 's|^./||' | grep -v '^$')

    if [ -n "$subdirs" ]; then
      selected_dir=$(echo "$subdirs" | fzf -e -i \
        --prompt="Select subdir (ESC: Search) > " \
        --header="Tab/S-Tab: Nav | ESC: Back | Enter: Select" \
        --preview "ls -l {}" \
        --preview-window="right:50%:wrap")

      [ -z "$selected_dir" ] && break
      cd "$selected_dir" || exit
      continue
    fi

    find . -type f -not -path '*/\.*' -print0 |
      tr '\0' '\n' |
      xargs -d '\n' grep -H -n --color=always . 2>/dev/null |
      fzf -e -i \
        --ansi \
        --height "100%" \
        --prompt="Search > " \
        --header="Enter: Edit | ESC: Back | Tab/S-Tab: Nav" \
        --bind "enter:execute($EDITOR \$(echo {} | cut -d: -f1) +\$(echo {} | cut -d: -f2))" \
        --bind "esc:abort" \
        --bind 'tab:down,shift-tab:up' \
        --preview 'bat --style=plain --color=always --highlight-line $(echo {} | cut -d: -f2) $(echo {} | cut -d: -f1) 2>/dev/null || cat $(echo {} | cut -d: -f1)' \
        --preview-window="right:50%:wrap" \
        --layout=reverse
    break
  done
}

# Main program loop
while true; do
  # Directory selection
  cd "$BASE_DIR" || exit
  selected_dir=$(find . -mindepth 1 -maxdepth 1 -type d -not -name ".*" -print0 |
    tr '\0' '\n' |
    sed 's|^./||' |
    fzf -e -i \
      --height "100%" \
      --prompt="Dir > " \
      --header=$'ESC: Exit | Enter: Select | C-f: Search Content\nTab/S-Tab: Navigate' \
      --preview "ls -lh {}" \
      --preview-window='right:50%:wrap' \
      --bind "ctrl-f:execute(echo {} > /tmp/currdir)+abort" \
      --bind 'tab:down,shift-tab:up' \
      --layout=reverse)

  if [[ -f /tmp/currdir ]]; then
    curr_dir=$(cat /tmp/currdir | tr -d '\0')
    rm -f /tmp/currdir
    selected_file=$(do_content_search "$BASE_DIR/$curr_dir")
    [ -z "$selected_file" ] && continue
  else
    [ -z "$selected_dir" ] && exit 0
    selected_dir="$BASE_DIR/$selected_dir"
    cache_file=$(get_cache_file "$selected_dir")

    # File selection
    cd "$selected_dir" || exit
    base_name="$(basename "$selected_dir" | tr -d '\0')"
    selected_file=$(find . -type f -not -path '*/\.*' -print0 |
      tr '\0' '\n' |
      sed 's|^./||' |
      fzf -e -i \
        --height "100%" \
        --prompt="$base_name > " \
        --header=$'ESC: Back | Enter: Copy | C-e: Edit | C-f: Search\nTab/S-Tab: Navigate' \
        --preview "bat --style=plain --color=always --paging=never {} 2>/dev/null || cat {}" \
        --preview-window='right:50%:wrap' \
        --bind "ctrl-f:execute-silent(pwd > /tmp/currdir)+abort" \
        --bind "ctrl-e:execute($EDITOR {})" \
        --bind 'tab:down,shift-tab:up' \
        --layout=reverse)

    if [[ -f /tmp/currdir ]]; then
      curr_dir=$(cat /tmp/currdir | tr -d '\0')
      rm -f /tmp/currdir
      selected_file=$(do_content_search "$curr_dir")
      [ -z "$selected_file" ] && continue
    else
      [ -z "$selected_file" ] && continue
      selected_file="$selected_dir/$selected_file"
      update_cache "$selected_file" "$cache_file"
    fi
  fi

  # Copy selected file
  copy_to_clipboard "$selected_file"
  exit 0
done
