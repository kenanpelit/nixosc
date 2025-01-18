#!/usr/bin/env bash

# Yedekleme dizini
BACKUP_DIR="$HOME/.nixoscb"

# Yedekleme dizini yoksa oluştur
mkdir -p "$BACKUP_DIR"

# Zaman damgası oluştur
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Kopya dosya adı
COPY_FILE="$BACKUP_DIR/$TIMESTAMP"

# Kullanıcıdan argüman al
if [[ "$1" == "tar" ]]; then
	# .tar.gz dosyası olarak yedekleme
	BACKUP_FILE="$COPY_FILE.tar.gz"
	tar -czf "$BACKUP_FILE" -C "$HOME" .nixosc
	echo "Yedekleme başarılı: $BACKUP_FILE"
else
	# Normal kopya olarak yedekleme
	BACKUP_FILE="$COPY_FILE"
	cp -r "$HOME/.nixosc" "$BACKUP_FILE"
	echo "Yedekleme başarılı: $BACKUP_FILE"
fi
