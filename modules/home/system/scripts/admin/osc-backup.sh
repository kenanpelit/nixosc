#!/usr/bin/env bash
#===============================================================================
#
#   Script: NixOS Configuration Backup Tool
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: NixOS configuration backup utility that creates timestamped
#                backups either as tar archives or direct copies
#
#   Features:
#   - Creates timestamped backups of NixOS configurations
#   - Supports both tar.gz archives and direct copies
#   - Automatically manages backup directory structure
#   - Simple command-line interface
#
#   License: MIT
#
#===============================================================================
# Yedekleme dizini
BACKUP_DIR="$HOME/.nixosb"

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
