#!/usr/bin/env bash

# Hata kontrolü
set -e

# Root kontrolü
if [ "$EUID" -ne 0 ]; then
	echo "Bu script root yetkisi gerektirir."
	echo "Lütfen 'sudo' ile çalıştırın."
	exit 1
fi

# Mevcut kullanıcı adını al
CURRENT_USER=$(logname || whoami)

# Getty override dizinini oluştur
mkdir -p /etc/systemd/system/getty@tty1.service.d/

# Override dosyasını oluştur
cat >/etc/systemd/system/getty@tty1.service.d/override.conf <<EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $CURRENT_USER -n -o %U %I \$TERM
Type=idle
EOL

# Logind.conf düzenle
# Önce yedek al
cp /etc/systemd/logind.conf /etc/systemd/logind.conf.backup

# UserName satırını kontrol et ve ekle/güncelle
if grep -q "^#\?UserName=" /etc/systemd/logind.conf; then
	# Satır varsa güncelle
	sed -i "s/^#\?UserName=.*/UserName=$CURRENT_USER/" /etc/systemd/logind.conf
else
	# Satır yoksa ekle
	echo "UserName=$CURRENT_USER" >>/etc/systemd/logind.conf
fi

# vconsole.conf oluştur/güncelle
cat >/etc/vconsole.conf <<EOL
# Written by systemd-localed(8) or systemd-firstboot(1), read by systemd-localed
# and systemd-vconsole-setup(8). Use localectl(1) to update this file.
FONT=ter-v20b
KEYMAP=trf
XKBLAYOUT=tr
XKBVARIANT=f
EOL

# TTY login ekranını özelleştir
cat >/etc/issue <<'EOL'
██ ▄█▀▓█████  ███▄    █  ██▓███
██▄█▒ ▓█   ▀  ██ ▀█   █ ▓██░  ██▒
▓███▄░ ▒███   ▓██  ▀█ ██▒▓██░ ██▓▒
▓██ █▄ ▒▓█  ▄ ▓██▒  ▐▌██▒▒██▄█▓▒ ▒
▒██▒ █▄░▒████▒▒██░   ▓██░▒██▒ ░  ░
▒ ▒▒ ▓▒░░ ▒░ ░░ ▒░   ▒ ▒ ▒▓▒░ ░  ░
░ ░▒ ▒░ ░ ░  ░░ ░░   ░ ▒░░▒ ░
░ ░░ ░    ░      ░   ░ ░ ░░
░  ░      ░  ░         ░
\s \r \v
Hostname: \n
TTY: \l
Date: \d \t
════════════════════════════════════════════════════════
EOL

# Terminus font paketini kur (eğer yüklü değilse)
if ! pacman -Qq terminus-font >/dev/null 2>&1; then
	pacman -S --noconfirm terminus-font
fi

# Servisleri yeniden başlat
systemctl daemon-reload
systemctl restart systemd-vconsole-setup
systemctl restart getty@tty1.service

echo "Yapılandırma tamamlandı!"
echo "TTY1'de kullanıcı adı '$CURRENT_USER' olarak görünecek."
echo "Konsol fontu, klavye düzeni ve login ekranı özelleştirildi."
echo "Herhangi bir sorun olursa /etc/systemd/logind.conf.backup dosyasından eski ayarlara dönebilirsiniz."
