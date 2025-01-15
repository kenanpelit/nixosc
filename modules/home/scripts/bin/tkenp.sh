#!/usr/bin/env bash

# Hata kontrolü için
set -e

# TMux session kontrolü
if ! tmux has-session 2>/dev/null; then
	echo "No tmux session found. Creating a new one..."
	tmux new-session -d
fi

# Layout oluşturma
tmux new-window -n 'kenp' \; \
	split-window -h \; \
	select-pane -t 2 \; \
	resize-pane -y 60 \; \
	split-window -v \; \
	select-pane -t 1 \; \
	resize-pane -x 40 \; \
	select-pane -t 3 \; \
	resize-pane -y 40

# Script başarılı mesajı
echo "Kenp layout created successfully!"
