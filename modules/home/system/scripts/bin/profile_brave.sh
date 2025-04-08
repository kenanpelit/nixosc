#!/usr/bin/env bash
#set -x
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
#   - Hazır uygulama kısayolları (whatsapp, youtube, tiktok, spotify, discord)
#   - Wayland ve dokunmatik yüzey desteği
#   - Yeni pencere zorlama özelliği
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

# Wayland ve dokunmatik yüzey için varsayılan bayraklar
DEFAULT_FLAGS=(
	"--restore-last-session"
	"--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform"
	"--ozone-platform=wayland"
	"--new-window"
)

# Kullanım bilgisi
usage() {
	echo -e "${BOLD}Brave Profil Başlatıcı${RESET}"
	echo
	echo -e "Kullanım: $0 ${BOLD}<profil_ismi>${RESET} [--class=SINIF] [--title=BASLIK] [brave_parametreleri]"
	echo -e "       veya: $0 ${BOLD}--whatsapp${RESET} [brave_parametreleri]"
	echo -e "       veya: $0 ${BOLD}--youtube${RESET} [brave_parametreleri]"
	echo -e "       veya: $0 ${BOLD}--tiktok${RESET} [brave_parametreleri]"
	echo -e "       veya: $0 ${BOLD}--spotify${RESET} [brave_parametreleri]"
	echo -e "       veya: $0 ${BOLD}--discord${RESET} [brave_parametreleri]"
	echo
	echo -e "${BOLD}Parametreler:${RESET}"
	echo "  --class=SINIF     Pencere sınıfını ayarlar (window manager entegrasyonu için)"
	echo "  --title=BASLIK    Pencere başlığını ayarlar"
	echo "  --whatsapp        WhatsApp uygulamasını başlatır (Whats profili ile)"
	echo "  --youtube         YouTube uygulamasını başlatır (Kenp profili ile)"
	echo "  --tiktok          TikTok uygulamasını başlatır (Kenp profili ile)"
	echo "  --spotify         Spotify uygulamasını başlatır (Kenp profili ile)"
	echo "  --discord         Discord uygulamasını başlatır (Kenp profili ile)"
	echo "  --kill-profile    Sadece bu profil için çalışan Brave örneklerini kapat"
	echo "  --kill-all        Tüm Brave örneklerini kapat"
	echo
	echo -e "${BOLD}Varsayılan Bayraklar:${RESET}"
	echo "  --restore-last-session                             Son oturumu geri yükler"
	echo "  --enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform   İki parmakla gezinme hareketleri"
	echo "  --ozone-platform=wayland                           Wayland desteği"
	echo "  --new-window                                       Yeni pencere zorlama"
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

launch_spotify() {
	echo -e "${GREEN}Spotify başlatılıyor...${RESET}"
	exec "$0" "Kenp" --app="https://open.spotify.com/" --class=Spotify --title=Spotify "$@"
}

launch_discord() {
	echo -e "${GREEN}Discord başlatılıyor...${RESET}"
	# pass komutunu kullanarak Discord kanalı URL'sini al
	local discord_url
	discord_url=$(pass discord-channels 2>/dev/null || echo "https://discord.com/app")
	exec "$0" "Kenp" --app="$discord_url" --class=Discord --title=Discord "$@"
}

# Belirli bir profil için çalışan Brave örneklerini kapat
kill_profile_brave() {
	local profile_dir="$1"
	echo -e "${YELLOW}Profil '$profile_dir' için çalışan Brave örnekleri aranıyor...${RESET}"

	# Tek tırnak kullanarak oluşabilecek sorunları önlüyoruz
	pids=$(ps aux | grep "brave.*profile-directory=$profile_dir" | grep -v grep | awk '{print $2}')

	if [ -n "$pids" ]; then
		echo -e "${YELLOW}Profil için çalışan Brave örnekleri bulundu. Kapatılıyor...${RESET}"
		echo "$pids" | xargs kill 2>/dev/null || true
		sleep 0.5
	else
		echo -e "${GREEN}Profil için çalışan Brave örneği bulunamadı.${RESET}"
	fi
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
	--spotify)
		shift
		launch_spotify "$@"
		;;
	--discord)
		shift
		launch_discord "$@"
		;;
	--kill-all)
		echo -e "${YELLOW}Tüm Brave örnekleri kapatılıyor...${RESET}"
		killall brave 2>/dev/null || true
		exit 0
		;;
	esac

	# İlk parametre profil adı
	profile_name="$1"
	shift

	# Varsayılan değerler
	window_class=""
	window_title=""
	brave_args=()
	kill_profile=false

	# Parametreleri işle
	while [ $# -gt 0 ]; do
		case "$1" in
		--class=*)
			window_class="${1#*=}"
			;;
		--title=*)
			window_title="${1#*=}"
			;;
		--kill-profile)
			kill_profile=true
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

	# Profil için çalışan örnekleri kapat (isteğe bağlı)
	if $kill_profile; then
		kill_profile_brave "$profile_key"
	fi

	# Class belirtilmemişse, profil adını kullan
	if [ -z "$window_class" ]; then
		window_class="$profile_name"
		echo -e "${YELLOW}Sınıf belirtilmedi, profil adı '$window_class' sınıf olarak kullanılacak${RESET}"
	fi

	# Title belirtilmemişse, profil adını kullan
	if [ -z "$window_title" ]; then
		window_title="$profile_name Browser"
		echo -e "${YELLOW}Başlık belirtilmedi, '$window_title' başlık olarak kullanılacak${RESET}"
	fi

	# Brave komut satırı argümanlarını oluştur
	cmd=("$BRAVE_CMD" "--profile-directory=$profile_key")

	# Varsayılan bayrakları ekle
	cmd+=("${DEFAULT_FLAGS[@]}")

	# Class ve title parametrelerini her zaman ekle
	cmd+=("--class=$window_class")
	cmd+=("--window-name=$window_title")

	# Diğer Brave parametrelerini ekle
	[ ${#brave_args[@]} -gt 0 ] && cmd+=("${brave_args[@]}")

	# Başlatılacak komutu göster
	echo -e "${BLUE}Başlatılıyor: ${RESET}${cmd[*]}"

	# Brave'i başlat
	"${cmd[@]}"
}

# Scripti çalıştır
main "$@"
