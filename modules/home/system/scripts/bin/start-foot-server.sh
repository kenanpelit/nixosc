#!/usr/bin/env bash

# Foot server'ın çalışıp çalışmadığını kontrol et
if ! pgrep -f "foot --server" >/dev/null; then
	# Eğer çalışmıyorsa başlat
	foot --server &
	echo "Foot server başlatıldı."

	# Server'ın başlaması için kısa bir süre bekle
	sleep 1

	# İlk terminal penceresini aç
	footclient
else
	echo "Foot server zaten çalışıyor."
	# Yeni bir terminal penceresi aç
	footclient
fi
