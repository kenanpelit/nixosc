#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: TodoScript - Basit Todo Yöneticisi
#
# Bu script basit bir TODO listesi yönetimi sağlar.
# Temel özellikleri:
# - XDG standartlarına uygun depolama
# - Doğrudan komut satırından todo ekleme
# - Varsayılan editör ile todo düzenleme
#
# Kullanım:
# todo "yapılacak iş"  # Yeni todo ekler
# todo                 # Editör ile todoları düzenler
#
# License: MIT
#
#######################################
TODO_FILE="${XDG_DATA_HOME:-$HOME/}.todo"
if [ -n "$1" ]; then
  echo "$@" >>"$TODO_FILE"
else
  "${EDITOR:-nvim}" "$TODO_FILE"
fi
