#!/usr/bin/env bash
#######################################
#
# Version: 1.0.0
# Date: 2024-12-12
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: TransmissionSetup - Transmission BitTorrent İstemci Kurulum Scripti
#
# Bu script Transmission torrent istemcisinin kurulumu ve yapılandırmasını
# otomatikleştirir. Temel özellikleri:
#
# - Sistem servislerini temizleme
# - XDG uyumlu yapılandırma
# - Otomatik dizin yapısı oluşturma
# - Web arayüzü güvenlik yapılandırması
# - Systemd user servisi kurulumu
# - İndirme/yükleme limitleri ayarlama
# - Watchdir desteği
# - Tamamlanmamış indirmeler için ayrı dizin
# - RPC ve güvenlik ayarları
#
# Dizin Yapısı:
# ~/.config/transmission-daemon/: Yapılandırma
# ~/repo/tor/transmission/: İndirme dizinleri
#  - completed/: Tamamlanan
#  - incomplete/: Devam eden
#  - watchdir/: İzleme dizini
#
# License: MIT
#
#######################################
Color_Off='\e[0m'
Red='\e[0;31m'
Green='\e[0;32m'
Yellow='\e[0;33m'

# Mevcut transmission süreçlerini temizle
pkill -f transmission-daemon
sudo pkill -f transmission-daemon

# Sistem servislerini devre dışı bırak
sudo systemctl disable --now transmission.service 2>/dev/null
sudo systemctl disable --now transmission-daemon.service 2>/dev/null

# Yapılandırma dizinlerini oluştur
CONFIG_DIR="$HOME/.config/transmission-daemon"
mkdir -p "$CONFIG_DIR"

# İndirme dizinlerini oluştur
SAVEDIR="$HOME/repo/tor/transmission"
mkdir -p "$SAVEDIR"/{completed,incomplete,watchdir}

# settings.json dosyasını oluştur
cat >"$CONFIG_DIR/settings.json" <<EOF
{
    "alt-speed-down": 50,
    "alt-speed-enabled": false,
    "alt-speed-time-begin": 540,
    "alt-speed-time-enabled": false,
    "alt-speed-time-end": 1020,
    "alt-speed-time-day": 127,
    "alt-speed-up": 50,
    "bind-address-ipv4": "0.0.0.0",
    "bind-address-ipv6": "::",
    "blocklist-enabled": false,
    "cache-size-mb": 4,
    "dht-enabled": true,
    "download-dir": "$SAVEDIR/completed",
    "download-queue-enabled": true,
    "download-queue-size": 5,
    "encryption": 1,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": false,
    "incomplete-dir": "$SAVEDIR/incomplete",
    "incomplete-dir-enabled": true,
    "lpd-enabled": false,
    "max-peers-global": 200,
    "message-level": 2,
    "peer-congestion-algorithm": "",
    "peer-limit-global": 240,
    "peer-limit-per-torrent": 60,
    "peer-port": 51413,
    "peer-port-random-high": 65535,
    "peer-port-random-low": 49152,
    "peer-port-random-on-start": false,
    "peer-socket-tos": "default",
    "pex-enabled": true,
    "port-forwarding-enabled": true,
    "preallocation": 1,
    "prefetch-enabled": true,
    "queue-stalled-enabled": true,
    "queue-stalled-minutes": 30,
    "ratio-limit": 2,
    "ratio-limit-enabled": false,
    "rename-partial-files": true,
    "rpc-authentication-required": true,
    "rpc-bind-address": "0.0.0.0",
    "rpc-enabled": true,
    "rpc-host-whitelist-enabled": false,
    "rpc-password": "MYPASSWORD",
    "rpc-port": 9091,
    "rpc-url": "/transmission/",
    "rpc-username": "MYUSERNAME",
    "rpc-whitelist-enabled": false,
    "scrape-paused-torrents-enabled": true,
    "script-torrent-done-enabled": false,
    "script-torrent-done-filename": "",
    "seed-queue-enabled": false,
    "seed-queue-size": 10,
    "speed-limit-down": 100,
    "speed-limit-down-enabled": false,
    "speed-limit-up": 100,
    "speed-limit-up-enabled": false,
    "start-added-torrents": true,
    "trash-original-torrent-files": false,
    "umask": "002",
    "upload-slots-per-torrent": 14,
    "utp-enabled": true,
    "watch-dir": "$SAVEDIR/watchdir",
    "watch-dir-enabled": true
}
EOF

# Kullanıcı adı ve şifre ayarla
printf "%b\n" "${Green}Web arayüzü için kullanıcı adı girin (varsayılan: admin):${Color_Off}"
read -r USER_NAME
USER_NAME=${USER_NAME:-"admin"}
sed -i "s/MYUSERNAME/$USER_NAME/g" "$CONFIG_DIR/settings.json"

printf "%b\n" "${Green}Web arayüzü için şifre girin:${Color_Off}"
read -rsp "Şifre: " PASSWORD
printf "\n"
read -rsp "Şifreyi tekrar girin: " PASSWORD_RETYPE
printf "\n"
while [[ "$PASSWORD" != "$PASSWORD_RETYPE" ]]; do
  printf "%b\n" "${Red}Şifreler eşleşmedi, tekrar deneyin${Color_Off}"
  read -rsp "Şifre: " PASSWORD
  printf "\n"
  read -rsp "Şifreyi tekrar girin: " PASSWORD_RETYPE
  printf "\n"
done
sed -i "s/MYPASSWORD/$PASSWORD/g" "$CONFIG_DIR/settings.json"

# Systemd user service dosyasını oluştur
mkdir -p ~/.config/systemd/user/
cat >~/.config/systemd/user/transmission.service <<EOF
[Unit]
Description=Transmission BitTorrent Daemon (User)
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/transmission-daemon --foreground --config-dir %h/.config/transmission-daemon
ExecReload=/bin/kill -s HUP \$MAINPID

[Install]
WantedBy=default.target
EOF

# Servisi etkinleştir ve başlat
systemctl --user daemon-reload
systemctl --user enable transmission.service
systemctl --user start transmission.service

# Bilgi mesajları
MY_IP="$(ip addr | awk '/global/ {print $1,$2}' | cut -d'/' -f1 | cut -d' ' -f2 | head -n 1)"
printf "\n%b\n" "${Yellow}>>> Web arayüzü şu adreste çalışıyor: ${Red}http://$MY_IP:9091/transmission/web/${Color_Off}"
printf "%b\n" "${Yellow}>>> Giriş bilgileri:${Color_Off}"
printf "%b\n" "${Yellow}Kullanıcı adı: ${Green}$USER_NAME${Color_Off}"
printf "%b\n" "${Yellow}Şifre: ${Green}$PASSWORD${Color_Off}"

# Bilgisayar yeniden başlatıldığında otomatik başlatma için
printf "\n%b\n" "${Yellow}>>> Bilgisayar yeniden başlatıldığında otomatik başlatmak için loginctl enable-linger komutunu kullanabilirsiniz:${Color_Off}"
printf "%b\n" "${Green}sudo loginctl enable-linger $USER${Color_Off}"
