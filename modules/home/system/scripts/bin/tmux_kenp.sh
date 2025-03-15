#!/usr/bin/env bash
#######################################
#
# Version: 2.0.0
# Date: 2025-03-15
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: KENPSession - Ana Geliştirme Ortamı için Tmux Oturum Yöneticisi
#
# Bu script ana geliştirme ortamı (KENP) için gürbüz bir tmux oturum yöneticisidir.
# İlk sürümün sadeliğini korurken daha fazla gürbüzlük ekler.
#
# License: MIT
#
#######################################

# Değişkenler
SESSION_NAME="KENP"

# Renkli çıktı fonksiyonları
green() { echo -e "\033[0;32m$*\033[0m"; }
yellow() { echo -e "\033[0;33m$*\033[0m"; }
red() { echo -e "\033[0;31m$*\033[0m"; }

# Tmux kurulu mu kontrol et
if ! command -v tmux >/dev/null 2>&1; then
	red "HATA: Tmux kurulu değil. Lütfen tmux paketini yükleyin."
	exit 1
fi

# Terminal ve kullanıcı shell bilgisi
export TERM=xterm-256color
USER_SHELL="$(getent passwd "$(id -u)")"
USER_SHELL="${USER_SHELL##*:}"

# Tmux içinde miyiz kontrol et
if [ -n "$TMUX" ]; then
	yellow "Zaten bir tmux oturumu içindesiniz."
	exit 0
fi

# Tmux soketlerini temizle (sadece sorun olursa kullanmak için)
clean_sockets() {
	yellow "Soket dosyaları temizleniyor..."
	for socket in /tmp/tmux-$(id -u)/*; do
		if [ -S "$socket" ]; then
			rm -f "$socket" 2>/dev/null || true
		fi
	done
	tmux kill-server >/dev/null 2>&1 || true
	sleep 1
}

# Tmux oturumlarını listele
list_sessions() {
	tmux list-sessions 2>/dev/null || echo "Aktif tmux oturumu yok."
}

# Pencere düzeni oluştur - tm komutu ile 3 panelli düzen
create_layout() {
	green "tm komutu ile 3-panelli düzen oluşturuluyor..."

	# tm komutunu çalıştır
	tm --layout 3

	return 0
}

# Tmux oturum kontrolü
session=$(tmux ls 2>/dev/null | grep "^${SESSION_NAME}:" || echo "")

if [[ $session == *"${SESSION_NAME}: attached"* ]]; then
	# Oturum zaten bağlıysa yeni bir shell başlat
	green "Oturum '${SESSION_NAME}' zaten bağlı, yeni bir shell başlatılıyor..."
	exec "$USER_SHELL"
elif [[ $session == *"${SESSION_NAME}:"* ]]; then
	# Oturum mevcut fakat bağlı değilse, oturuma bağlan
	green "Oturum '${SESSION_NAME}' mevcut, oturuma bağlanılıyor..."
	if ! tmux attach-session -t "$SESSION_NAME"; then
		yellow "Mevcut oturuma bağlanılamadı, yeni bir oturum oluşturuluyor..."
		tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
		tmux new-session -A -s "$SESSION_NAME"
	fi
else
	# Oturum yoksa yeni oturum başlat
	green "Oturum '${SESSION_NAME}' mevcut değil, yeni bir tmux oturumu başlatılıyor..."

	# Eğer tmux sunucusu yanıt vermiyorsa soketleri temizle ve yeniden dene
	if ! tmux start-server 2>/dev/null; then
		yellow "Tmux sunucusu başlatılamadı, soketler temizleniyor..."
		clean_sockets
	fi

	# -A bayrağı "attach if exists, create if not" anlamına gelir
	if ! tmux new-session -d -s "$SESSION_NAME"; then
		red "Oturum oluşturulamadı, son bir deneme daha yapılıyor..."
		clean_sockets
		if ! tmux new-session -d -s "$SESSION_NAME"; then
			red "HATA: Oturum oluşturulamadı!"
			exit 1
		fi
	fi

	# Pencere düzenini oluştur
	create_layout

	# Oturuma bağlan
	green "Yeni oluşturulan '$SESSION_NAME' oturumuna bağlanılıyor..."
	if ! tmux attach-session -t "$SESSION_NAME"; then
		red "HATA: Oturuma bağlanılamadı!"
		exit 1
	fi
fi
