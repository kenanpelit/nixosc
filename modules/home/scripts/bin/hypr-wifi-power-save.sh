#!/usr/bin/env bash
#######################################
#
# Version: 3.0.0
# Date: 2025-11-05
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow - WiFi Power Management Toggle
#
# License: MIT
#
#######################################

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# İkon değişkenleri
ICON_WIFI="󰖩"
ICON_ERROR="󰅚"
ICON_INFO="󰋼"
ICON_SUCCESS="󰄬"

# Kullanım bilgisi
usage() {
	cat <<EOF
WiFi Power Save Manager - v3.0.0

KULLANIM:
    $(basename "$0") [KOMUT]

KOMUTLAR:
    on          Güç tasarrufunu aç
    off         Güç tasarrufunu kapat (varsayılan)
    toggle      Durumu tersine çevir (açsa kapat, kapalıysa aç)
    status      Mevcut durumu göster
    -h, --help  Bu yardım mesajını göster

ÖRNEKLER:
    $(basename "$0")         # Güç tasarrufunu kapat (varsayılan)
    $(basename "$0") off     # Güç tasarrufunu kapat
    $(basename "$0") on      # Güç tasarrufunu aç
    $(basename "$0") toggle  # Durumu tersine çevir
    $(basename "$0") status  # Sadece durumu göster

EOF
}

# Bildirim gönder
send_notification() {
	local title="$1"
	local message="$2"
	local icon="$3"
	local urgency="${4:-normal}"

	if command -v notify-send >/dev/null 2>&1; then
		notify-send -t 5000 -u "$urgency" "$icon $title" "$message"
	fi
	echo -e "${BLUE}$icon${NC} $title: $message"
}

# Mevcut durumu kontrol et
check_current_status() {
	local interface="$1"
	local status=$(iw "$interface" get power_save 2>/dev/null | grep "Power save" | awk '{print $NF}')
	echo "$status"
}

# Güç tasarrufunu ayarla
set_power_save() {
	local interface="$1"
	local mode="$2" # on veya off

	if sudo iw "$interface" set power_save "$mode" >/dev/null 2>&1; then
		sleep 0.5
		local new_status=$(check_current_status "$interface")

		if [ "$new_status" = "$mode" ]; then
			local mode_tr=$([ "$mode" = "on" ] && echo "AÇILDI" || echo "KAPATILDI")
			send_notification "Başarılı" "$interface için güç tasarrufu $mode_tr" "$ICON_SUCCESS"
			return 0
		else
			send_notification "Uyarı" "Değişiklik teyit edilemedi." "$ICON_ERROR" "normal"
			return 1
		fi
	else
		send_notification "Hata" "Güç tasarrufu değiştirilemedi." "$ICON_ERROR" "critical"
		return 1
	fi
}

# Ana işlem
main() {
	local command="${1:-off}" # Varsayılan: off

	# Bağlı Wi-Fi arayüzünü bul
	local interface=$(iw dev | awk '$1=="Interface"{print $2}' | head -n1)

	# Eğer arayüz bulunamazsa hata mesajı göster
	if [ -z "$interface" ]; then
		send_notification "Hata" "Wi-Fi arayüzü bulunamadı." "$ICON_ERROR" "critical"
		exit 1
	fi

	# Mevcut durumu kontrol et
	local current_status=$(check_current_status "$interface")

	if [ -z "$current_status" ]; then
		send_notification "Hata" "Güç tasarrufu durumu okunamadı." "$ICON_ERROR" "critical"
		exit 1
	fi

	# Komuta göre işlem yap
	case "$command" in
	on)
		if [ "$current_status" = "on" ]; then
			send_notification "Wi-Fi Güç Tasarrufu" "$interface için güç tasarrufu zaten AÇIK" "$ICON_INFO"
		else
			send_notification "Wi-Fi Güç Tasarrufu" "Mevcut: KAPALI, açılıyor..." "$ICON_INFO"
			set_power_save "$interface" "on"
		fi
		;;

	off)
		if [ "$current_status" = "off" ]; then
			send_notification "Wi-Fi Güç Tasarrufu" "$interface için güç tasarrufu zaten KAPALI" "$ICON_SUCCESS"
		else
			send_notification "Wi-Fi Güç Tasarrufu" "Mevcut: AÇIK, kapatılıyor..." "$ICON_INFO"
			set_power_save "$interface" "off"
		fi
		;;

	toggle)
		if [ "$current_status" = "on" ]; then
			send_notification "Wi-Fi Güç Tasarrufu" "AÇIK durumundan KAPALI durumuna geçiliyor..." "$ICON_INFO"
			set_power_save "$interface" "off"
		else
			send_notification "Wi-Fi Güç Tasarrufu" "KAPALI durumundan AÇIK durumuna geçiliyor..." "$ICON_INFO"
			set_power_save "$interface" "on"
		fi
		;;

	status)
		local status_tr=$([ "$current_status" = "on" ] && echo "AÇIK" || echo "KAPALI")
		send_notification "Wi-Fi Güç Tasarrufu" "$interface durumu: $status_tr" "$ICON_INFO"
		;;

	-h | --help)
		usage
		exit 0
		;;

	*)
		echo -e "${RED}${ICON_ERROR}${NC} Geçersiz komut: $command"
		echo ""
		usage
		exit 1
		;;
	esac
}

# Scripti çalıştır
main "$@"
