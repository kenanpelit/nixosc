#!/usr/bin/env bash

# Hata kontrolü için
set -e

# Root yetki kontrolü
if [ "$EUID" -ne 0 ]; then
	echo "Bu script root yetkisi gerektirir."
	echo "Lütfen 'sudo' ile çalıştırın."
	exit 1
fi

# foot yüklü mü kontrol et
if ! command -v foot &>/dev/null; then
	echo "foot terminal yüklü değil. Yükleniyor..."
	pacman -S --noconfirm foot
fi

echo "Sistem genelinde terminal ayarları yapılandırılıyor..."

# /usr/local/bin altında symlink oluştur
mkdir -p /usr/local/bin
ln -sf /usr/bin/foot /usr/local/bin/x-terminal-emulator

# Sistem genelinde varsayılan terminal tanımı
mkdir -p /etc/profile.d/
echo 'export TERMINAL=/usr/bin/foot' >/etc/profile.d/terminal.sh
chmod +x /etc/profile.d/terminal.sh

# Desktop dosyası oluştur
mkdir -p /usr/share/applications
cat >/usr/share/applications/terminal.desktop <<EOL
[Desktop Entry]
Name=Terminal
Comment=Default Terminal Emulator
TryExec=foot
Exec=foot
Icon=utilities-terminal
Type=Application
Categories=System;TerminalEmulator;
StartupNotify=true
MimeType=x-scheme-handler/terminal;
EOL

# Sistem geneli mime associations
mkdir -p /etc/xdg
cat >/etc/xdg/mimeapps.list <<EOL
[Default Applications]
x-scheme-handler/terminal=terminal.desktop
EOL

# Kullanıcı bazlı ayarlar için
USER_HOME=$(eval echo ~${SUDO_USER})
mkdir -p ${USER_HOME}/.config/environment.d/
echo "TERMINAL=/usr/bin/foot" >${USER_HOME}/.config/environment.d/terminal.conf
chown ${SUDO_USER}:${SUDO_USER} ${USER_HOME}/.config/environment.d/terminal.conf

# XDG MIME ayarını kullanıcı için de yap
su - ${SUDO_USER} -c 'xdg-mime default terminal.desktop x-scheme-handler/terminal'

echo "Yapılandırma tamamlandı!"
echo "Lütfen sistemi yeniden başlatın."

# Mevcut oturum için TERMINAL değişkenini ayarla
export TERMINAL=/usr/bin/foot
