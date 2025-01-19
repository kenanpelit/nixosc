#!/usr/bin/env bash

#######################################
#
# Version: 1.0.0
# Date: 2024-12-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow
#
# License: MIT
#
#######################################

kitty --class clipb --title clipb $HOME/.bin/tmux-copy.sh -c >>/dev/null 2>&1 &
disown
