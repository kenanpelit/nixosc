#!/usr/bin/env bash
# ~/.bin/passclip-both.sh adında bir dosya oluşturun

# Tüm stdin'i oku ve bir değişkende sakla
input=$(cat)

# Wayland clipboard'a kopyala
echo "$input" | wl-copy -n

# tmux buffer'a kopyala
if [ -n "$TMUX" ]; then
  tmux set-buffer "$input"
fi
