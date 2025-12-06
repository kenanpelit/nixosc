#!/usr/bin/env bash

is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?)(diff)?$'" # credit to christoomey, raviqqe and leviticusnelson. See https://github.com/christoomey/vim-tmux-navigator/blob/master/vim-tmux-navigator.tmux
is_fzf="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?fzf$'"
is_lazygit="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?lazygit$'"

tmux bind -n                C-h                    if "$is_vim"                           "send C-h" "select-pane -L"
tmux bind -n                C-j                    if "$is_vim || $is_fzf || $is_lazygit" "send C-j" "select-pane -D"
tmux bind -n                C-k                    if "$is_vim || $is_fzf || $is_lazygit" "send C-k" "select-pane -U"
tmux bind -n                C-l                    if "$is_vim"                           "send C-l" "select-pane -R"

tmux bind -r                C-h                    send C-h
tmux bind -r                C-j                    send C-j
tmux bind -r                C-k                    send C-k
tmux bind -r                C-l                    send C-l

tmux bind                   H                      swap-pane -s "{left-of}"
tmux bind                   J                      swap-pane -s "{down-of}"
tmux bind                   K                      swap-pane -s "{up-of}"
tmux bind                   L                      swap-pane -s "{right-of}"

tmux bind -n                C-Left                 if "$is_vim" "send C-Left"  "resize-pane -L 3"
tmux bind -n                C-Down                 if "$is_vim" "send C-Down"  "resize-pane -D 3"
tmux bind -n                C-Up                   if "$is_vim" "send C-Up"    "resize-pane -U 3"
tmux bind -n                C-Right                if "$is_vim" "send C-Right" "resize-pane -R 3"

tmux bind -T copy-mode-vi   C-h                    select-pane -L
tmux bind -T copy-mode-vi   C-j                    select-pane -D
tmux bind -T copy-mode-vi   C-k                    select-pane -U
tmux bind -T copy-mode-vi   C-l                    select-pane -R

tmux bind -T copy-mode-vi   C-Left                 resize-pane -L 3
tmux bind -T copy-mode-vi   C-Down                 resize-pane -D 3
tmux bind -T copy-mode-vi   C-Up                   resize-pane -U 3
tmux bind -T copy-mode-vi   C-Right                resize-pane -R 3
