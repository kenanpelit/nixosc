#!/usr/bin/env bash

# Hata kontrolü
set -e

# Root yetkisi kontrolü
if [ "$EUID" -ne 0 ]; then 
    echo "Bu script root yetkisi gerektirir."
    echo "Lütfen 'sudo' ile çalıştırın."
    exit 1
fi

# Foot kurulu mu kontrol et
if ! command -v foot &> /dev/null; then
    echo "foot terminal yüklü değil. Yükleniyor..."
    pacman -S --noconfirm foot
fi

# ranger.desktop dosyasını oluştur
cat > /usr/share/applications/ranger.desktop << EOL
[Desktop Entry]
Type=Application
Name=ranger
Comment=Launches the ranger file manager
Icon=utilities-terminal
Terminal=false
Exec=foot -e ranger %F
Categories=ConsoleOnly;System;FileTools;FileManager
MimeType=inode/directory;
Keywords=File;Manager;Browser;Explorer;Launcher;Vi;Vim;Python
EOL

# yazi.desktop dosyasını oluştur
cat > /usr/share/applications/yazi.desktop << EOL
[Desktop Entry]
Name=Yazi
Icon=yazi
Comment=Blazing fast terminal file manager written in Rust, based on async I/O
Terminal=false
TryExec=yazi
Exec=foot -e yazi %u
Type=Application
MimeType=inode/directory
Categories=Utility;Core;System;FileTools;FileManager;ConsoleOnly
Keywords=File;Manager;Explorer;Browser;Launcher
EOL

# İzinleri ayarla
chmod 644 /usr/share/applications/ranger.desktop
chmod 644 /usr/share/applications/yazi.desktop

# MIME type veritabanını güncelle
update-desktop-database /usr/share/applications

echo "Desktop dosyaları başarıyla güncellendi!"
echo "ranger ve yazi artık foot terminal ile açılacak."
