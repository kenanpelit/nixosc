#!/usr/bin/env bash
#===============================================================================
#
#   Script: Brave Profile Launcher
#   Description: Brave tarayıcısı için profil bazlı başlatma aracı
#
#   Özellikler:
#   - Profil bazlı Brave başlatma
#   - Özel pencere sınıfı ve başlık ayarlama
#   - Komut satırı argümanlarını destekleme
#   - Profil listeleme
#   - Hazır uygulama kısayolları (whatsapp, youtube, tiktok)
#
#===============================================================================

set -euo pipefail

# Renk tanımlamaları
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Konfigürasyon
BRAVE_CMD="brave"
LOCAL_STATE_PATH="${HOME}/.config/BraveSoftware/Brave-Browser/Local State"

# Kullanım bilgisi
usage() {
	echo -e "${BOLD}Brave Profil Başlatıcı${RESET}"
	echo
	echo -e "Kullanım: $0 ${BOLD}<profil_ismi>${RESET} [--class=SINIF] [--title=BASLIK] [brave_parametreleri]"
	echo -e "       veya: $0 ${BOLD}--whatsapp${RESET} [brave_parametreleri]"
	echo -e "       veya: $0 ${BOLD}--youtube${RESET} [brave_parametreleri]"
	echo -e "       veya: $0 ${BOLD}--tiktok${RESET} [brave_parametreleri]"
	echo
	echo -e "${BOLD}Parametreler:${RESET}"
	echo "  --class=SINIF     Pencere sınıfını ayarlar (window manager entegrasyonu için)"
	echo "  --title=BASLIK    Pencere başlığını ayarlar"
	echo "  --whatsapp        WhatsApp uygulamasını başlatır (Whats profili ile)"
	echo "  --youtube         YouTube uygulamasını başlatır (Kenp profili ile)"
	echo "  --tiktok          TikTok uygulamasını başlatır (Kenp profili ile)"
	echo
	list_profiles
	exit "${1:-0}"
}

# Profil listesi
list_profiles() {
	echo -e "${BOLD}Mevcut profiller:${RESET}"

	if [ ! -f "$LOCAL_STATE_PATH" ]; then
		echo -e "${RED}Hata: Brave profil bilgisi bulunamadı!${RESET}"
		return 1
	fi

	# Profilleri listele ve formatla
	jq -r '.profile.info_cache | to_entries | map("  " + .key + ": " + .value.name) | .[]' <"$LOCAL_STATE_PATH" 2>/dev/null |
		sort -k1,1 -k2,2n ||
		echo -e "${RED}Hata: Brave profil bilgisi okunamadı!${RESET}"
}

# Önceden tanımlanmış uygulamalar
launch_whatsapp() {
	echo -e "${GREEN}WhatsApp başlatılıyor...${RESET}"
	exec "$0" "Whats" --app="https://web.whatsapp.com" --class=Whats --title=Whats "$@"
}

launch_youtube() {
	echo -e "${GREEN}YouTube başlatılıyor...${RESET}"
	exec "$0" "Kenp" --app="https://youtube.com" --class=Youtube --title=Youtube "$@"
}

launch_tiktok() {
	echo -e "${GREEN}TikTok başlatılıyor...${RESET}"
	exec "$0" "Kenp" --app="https://tiktok.com" --class=Tiktok --title=Tiktok "$@"
}

# Ana işlev
main() {
	# Parametre kontrolü
	[ $# -eq 0 ] && usage 0

	# Özel uygulama kısayolları
	case "$1" in
	--whatsapp)
		shift
		launch_whatsapp "$@"
		;;
	--youtube)
		shift
		launch_youtube "$@"
		;;
	--tiktok)
		shift
		launch_tiktok "$@"
		;;
	esac

	# İlk parametre profil adı
	profile_name="$1"
	shift

	# Varsayılan değerler
	window_class=""
	window_title=""
	brave_args=()

	# Parametreleri işle
	while [ $# -gt 0 ]; do
		case "$1" in
		--class=*)
			window_class="${1#*=}"
			;;
		--title=*)
			window_title="${1#*=}"
			;;
		--help | -h)
			usage 0
			;;
		*)
			brave_args+=("$1")
			;;
		esac
		shift
	done

	# Local State dosyasının varlığını kontrol et
	if [ ! -f "$LOCAL_STATE_PATH" ]; then
		echo -e "${RED}Hata: Brave profil dosyası bulunamadı: $LOCAL_STATE_PATH${RESET}"
		exit 1
	fi

	# Profil anahtarını bul
	profile_key=$(jq -r --arg name "$profile_name" \
		'.profile.info_cache | to_entries | .[] | 
        select(.value.name == $name) | .key' <"$LOCAL_STATE_PATH")

	# Profil anahtarı bulunamazsa hata ver
	if [ -z "$profile_key" ]; then
		echo -e "${RED}Hata: '$profile_name' isimli profil bulunamadı.${RESET}"
		list_profiles
		exit 1
	fi

	# Brave komut satırı argümanlarını oluştur
	cmd=("$BRAVE_CMD" "--profile-directory=$profile_key")

	# Class ve title parametrelerini ekle
	[ -n "$window_class" ] && cmd+=("--class=$window_class")
	[ -n "$window_title" ] && cmd+=("--window-name=$window_title")

	# Diğer Brave parametrelerini ekle
	[ ${#brave_args[@]} -gt 0 ] && cmd+=("${brave_args[@]}")

	# Başlatılacak komutu göster (isteğe bağlı)
	echo -e "${BLUE}Başlatılıyor: ${RESET}${cmd[*]}"

	# Brave'i başlat
	exec "${cmd[@]}"
}

# Scripti çalıştır
main "$@"
