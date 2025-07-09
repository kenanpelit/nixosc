#!/usr/bin/env bash

# Kullanıcıdan hedef dizini al, Tab ile tamamlama etkin
read -e -p "Lütfen dosyaların taşınacağı hedef dizinin tam yolunu girin: " target_dir

# Hedef dizin mevcut mu kontrol et, değilse oluştur
if [ ! -d "$target_dir" ]; then
	echo "Hedef dizin mevcut değil. Oluşturuluyor..."
	mkdir -p "$target_dir" || {
		echo "Hedef dizin oluşturulamadı!"
		exit 1
	}
fi

# Bulunan .mp4 ve .mkv dosyalarını taşı
echo "Dosyalar aranıyor ve taşınıyor..."
find . -type f \( -name "*.mp4" -o -name "*.mkv" \) -exec mv {} "$target_dir" \;

# İşlem tamamlandıktan sonra bilgi mesajı
echo "İşlem tamamlandı. Tüm .mp4 ve .mkv dosyaları $target_dir dizinine taşındı."
