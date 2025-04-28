#!/usr/bin/env bash

# Tüm Brave oturumlarını düzgün şekilde kapatma script'i

echo "Brave oturumları kapatılıyor..."

# Brave process ID'lerini bul
brave_pids=$(pgrep -f "brave")

if [ -z "$brave_pids" ]; then
	echo "Çalışan Brave oturumu bulunamadı."
	exit 0
fi

# Önce düzgün bir şekilde kapatmayı dene (SIGTERM)
echo "Brave'e düzgün kapanma sinyali gönderiliyor..."
kill -15 $brave_pids

# Birkaç saniye bekle
echo "Kapanma için 5 saniye bekleniyor..."
sleep 5

# Hala çalışan Brave process'leri var mı kontrol et
remaining_pids=$(pgrep -f "brave")

if [ ! -z "$remaining_pids" ]; then
	echo "Bazı Brave oturumları hala çalışıyor. Zorla kapatılıyor..."
	kill -9 $remaining_pids
	echo "Tüm Brave oturumları kapatıldı."
else
	echo "Tüm Brave oturumları başarıyla kapatıldı."
fi

exit 0
