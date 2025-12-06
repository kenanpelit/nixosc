#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"

ssh_auto_rename_window_default='on'
ssh_reset_option_name='@reset_window_name'

update_ssh_info() {
  local -r ssh_commad=$(ps -t "$(tmux display -p '#{pane_tty}')" -o command= | awk '/^ssh/')
  local -r parsed_data=($(echo $ssh_commad | perl -pe 's|^ssh\s(-l\s)?(\w+)@?\s?([[:alnum:][:punct:]]+).*$|\2 \3|g'))

  local -r username="${parsed_data[0]}"
  local -r hostname="${parsed_data[1]}"

  local -r auto_rename_window=$(get_tmux_option "@ssh_auto_rename_window" "$ssh_auto_rename_window_default")

  if [[ -n "$hostname" && $auto_rename_window == 'on' ]]; then
    tmux rename-window "ssh:$hostname"
    set_tmux_option "$ssh_reset_option_name" 'yes'
  elif [[ -n "$(get_tmux_option "$ssh_reset_option_name")" ]]; then
    tmux set-window-option automatic-rename 'on' 1>/dev/null
    set_tmux_option "$ssh_reset_option_name" ''
  fi

  if [[ -n "$hostname" && -n "$username" ]]; then
    printf "$username@$hostname"
  else
    printf ""
  fi
}

main() {
  update_ssh_info
}

main
