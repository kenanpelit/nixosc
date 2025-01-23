#!/usr/bin/env bash
#===============================================================================
#
#   Script: OSC SSH Hosts Backup Tool
#   Version: 1.0.0
#   Date: 2024-01-23
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Remote host /etc/hosts file backup utility that creates
#                organized backups with connection details and timestamps
#
#   Features:
#   - Backs up remote /etc/hosts files via SSH
#   - Adds connection metadata and timestamps
#   - Automatically organizes backups by connection name
#   - Simple command-line interface
#   - Built-in error handling and validation
#
#   License: MIT
#
#===============================================================================

# Script adını al
SCRIPT_NAME=$(basename "$0")

# Kullanım bilgisini göster
usage() {
	echo "Kullanım: $SCRIPT_NAME <ssh_bağlantı_adı>"
	echo "Örnek: $SCRIPT_NAME sunucu_adi"
	exit 1
}

# Parametre kontrolü
if [ $# -ne 1 ]; then
	usage
fi

# SSH bağlantı bilgisini al
SSH_CONNECTION="$1"

# ~/.anote/hosts dizinini oluştur
HOSTS_DIR="$HOME/.anote/hosts"
mkdir -p "$HOSTS_DIR"

echo "Uzak makineden bilgiler alınıyor..."

# Hostname bilgisini al
HOSTNAME=$(ssh "$SSH_CONNECTION" 'hostname' 2>/dev/null)
if [ $? -ne 0 ]; then
	echo "Hata: Hostname bilgisi alınamadı!"
	exit 1
fi

echo "Hostname: $HOSTNAME"

# Geçici bir dosya oluştur
TEMP_FILE=$(mktemp)

# Hosts dosyasını geçici dosyaya kopyala
scp "$SSH_CONNECTION:/etc/hosts" "$TEMP_FILE" 2>/dev/null
if [ $? -ne 0 ]; then
	echo "Hata: Hosts dosyası kopyalanamadı!"
	rm -f "$TEMP_FILE"
	exit 1
fi

# Yeni hosts dosyası oluştur
TARGET_FILE="$HOSTS_DIR/${SSH_CONNECTION}_${HOSTNAME}_hosts"

# Bağlantı bilgilerini dosyanın başına ekle
echo "# SSH Connection: $SSH_CONNECTION" >"$TARGET_FILE"
echo "# Hostname: $HOSTNAME" >>"$TARGET_FILE"
echo "# Backup tarihi: $(date '+%Y-%m-%d %H:%M:%S')" >>"$TARGET_FILE"
echo "" >>"$TARGET_FILE"
cat "$TEMP_FILE" >>"$TARGET_FILE"

# Geçici dosyayı sil
rm -f "$TEMP_FILE"

# İzinleri ayarla
chmod 644 "$TARGET_FILE"

# İşlem özeti
echo -e "\nİşlem Özeti:"
echo "-------------"
echo "Hosts Dosyası: $TARGET_FILE"
echo "SSH Bağlantısı: $SSH_CONNECTION"
echo "Host İsmi: $HOSTNAME"
