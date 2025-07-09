#!/usr/bin/env bash

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Başlık göster
echo -e "${BLUE}=== Bozuk Görsel Dosyaları Tespit Aracı ===${NC}"

# İşlem sayaçları
total=0
corrupted=0
deleted=0

# Görsel dosyaları bul ve kontrol et
find . \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) -type f -print0 | while IFS= read -r -d '' file; do
	((total++))
	echo -e "\n${YELLOW}Kontrol ediliyor:${NC} $file"

	# identify ile dosyayı kontrol et
	if ! identify "$file" &>/dev/null; then
		((corrupted++))
		echo -e "${RED}Bozuk dosya bulundu!${NC}"

		# Dosya boyutunu göster
		size=$(ls -lh "$file" | awk '{print $5}')
		echo -e "Dosya boyutu: $size"

		# Kullanıcıya sor
		read -p "Bu dosyayı silmek istiyor musunuz? (e/h) " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Ee]$ ]]; then
			rm "$file"
			((deleted++))
			echo -e "${GREEN}Dosya silindi${NC}"
		else
			echo -e "${YELLOW}Dosya atlandı${NC}"
		fi
	fi
done

# İstatistikleri göster
echo -e "\n${BLUE}=== İşlem Tamamlandı ===${NC}"
echo -e "Toplam kontrol edilen: $total dosya"
echo -e "Bozuk bulunan: $corrupted dosya"
echo -e "Silinen: $deleted dosya"
