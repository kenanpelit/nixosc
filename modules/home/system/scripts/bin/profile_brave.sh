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
#   - SOCKS5 Proxy Desteği
#   - Wayland ve dokunmatik yüzey desteği
#   - Yeni pencere zorlama özelliği
#   - İnkognito mod desteği
#   - Yeni profil oluşturma
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
BRAVE_PROFILES_DIR="${HOME}/.config/BraveSoftware/Brave-Browser"

# Wayland ve dokunmatik yüzey için varsayılan bayraklar
DEFAULT_FLAGS=(
	"--restore-last-session"
	"--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform"
	"--ozone-platform=wayland"
	"--new-window"
)

# Proxy ayarları
PROXY_ENABLED=false
PROXY_HOST="127.0.0.1"
PROXY_PORT="4999"
PROXY_TYPE="socks5"

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
	echo -e "       veya: $0 ${BOLD}--proxy${RESET} [brave_parametreleri]"
	echo -e "       veya: $0 ${BOLD}--create-profile=ISIM${RESET} [--icon=ICON_PATH]"
	echo
	echo -e "${BOLD}Parametreler:${RESET}"
	echo "  --class=SINIF     Pencere sınıfını ayarlar (window manager entegrasyonu için)"
	echo "  --title=BASLIK    Pencere başlığını ayarlar"
	echo "  --whatsapp        WhatsApp uygulamasını başlatır (Kenp profili ile)"
	echo "  --youtube         YouTube uygulamasını başlatır (Kenp profili ile)"
	echo "  --tiktok          TikTok uygulamasını başlatır (Kenp profili ile)"
	echo "  --spotify         Spotify uygulamasını başlatır (Kenp profili ile)"
	echo "  --discord         Discord uygulamasını başlatır (Kenp profili ile)"
	echo "  --proxy           Proxy ile Brave başlatır (Proxy profili ile)"
	echo "  --proxy-host=HOST Proxy sunucu adresi (varsayılan: 127.0.0.1)"
	echo "  --proxy-port=PORT Proxy sunucu portu (varsayılan: 4999)"
	echo "  --proxy-type=TYPE Proxy türü (socks5, http, https) (varsayılan: socks5)"
	echo "  --kill-profile    Sadece bu profil için çalışan Brave örneklerini kapat"
	echo "  --kill-all        Tüm Brave örneklerini kapat"
	echo "  --incognito       Seçilen profili inkognito modunda başlatır"
	echo "  --create-profile=ISIM  Belirtilen isimde yeni bir profil oluşturur"
	echo "  --icon=ICON_PATH  Yeni oluşturulan profile özel bir simge ekler (--create-profile ile kullanılır)"
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

# Yeni profil oluşturma
create_profile() {
	local profile_name="$1"
	local icon_path="${2:-}"

	echo -e "${BLUE}Yeni profil oluşturuluyor: ${RESET}$profile_name"

	# Profile ismi kontrolü
	if [[ -z "$profile_name" ]]; then
		echo -e "${RED}Hata: Profil ismi boş olamaz!${RESET}"
		return 1
	fi

	# Mevcut profilleri kontrol et
	if [ -f "$LOCAL_STATE_PATH" ]; then
		local existing_profile
		existing_profile=$(jq -r --arg name "$profile_name" \
			'.profile.info_cache | to_entries | .[] | select(.value.name == $name) | .key' <"$LOCAL_STATE_PATH")

		if [ -n "$existing_profile" ]; then
			echo -e "${YELLOW}Uyarı: '$profile_name' isimli profil zaten mevcut.${RESET}"
			echo -e "Profil dizini: $BRAVE_PROFILES_DIR/Profile $existing_profile"
			return 0
		fi
	fi

	# Yeni profil için bir profil numarası oluştur
	local profile_number
	profile_number=$(find "$BRAVE_PROFILES_DIR" -maxdepth 1 -name "Profile *" | wc -l)
	profile_number=$((profile_number + 1))
	local profile_dir="Profile $profile_number"
	local profile_path="$BRAVE_PROFILES_DIR/$profile_dir"

	# Brave'i yeni profil oluşturma modunda başlat
	echo -e "${GREEN}Brave başlatılıyor ve yeni profil oluşturuluyor...${RESET}"

	# Profil dizinini oluştur
	mkdir -p "$profile_path"

	# Özel ikon ayarla (eğer verilmişse)
	if [[ -n "$icon_path" && -f "$icon_path" ]]; then
		echo -e "${BLUE}Profil için özel ikon ayarlanıyor: ${RESET}$icon_path"
		# Özel ikon kopyalanabilir veya yapılandırma dosyasına referans eklenebilir
		cp "$icon_path" "$profile_path/icon.png"
	fi

	# Profili başlat ve kullanıcının yapılandırmasını tamamlamasını sağla
	echo -e "${YELLOW}Profil oluşturma işlemi başlatılıyor. Brave açıldığında profili yapılandırın ve kapatın.${RESET}"
	"$BRAVE_CMD" "--profile-directory=$profile_dir" "--profile-creation-name=$profile_name"

	echo -e "${GREEN}Profil oluşturma tamamlandı: ${RESET}$profile_name"
	echo -e "Yeni profili şu şekilde kullanabilirsiniz: $0 \"$profile_name\""

	return 0
}

# Önceden tanımlanmış uygulamalar
launch_whatsapp() {
	echo -e "${GREEN}WhatsApp başlatılıyor...${RESET}"
	exec "$0" "Kenp" --app="https://web.whatsapp.com" --class=Whats --title=Whats "$@"
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

# Proxy ile başlatma
launch_proxy() {
	echo -e "${GREEN}Proxy ile Brave başlatılıyor...${RESET}"
	PROXY_ENABLED=true
	exec "$0" "Proxy" --class=Proxy --title="Proxy Browser" "$@"
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

	# Önce özel parametreleri işle
	case "$1" in
	--create-profile=*)
		profile_name="${1#*=}"
		shift
		icon_path=""
		if [[ "$1" == --icon=* ]]; then
			icon_path="${1#*=}"
			shift
		fi
		create_profile "$profile_name" "$icon_path"
		exit $?
		;;
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
	--proxy)
		shift
		launch_proxy "$@"
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
	incognito_mode=false

	# Parametreleri işle
	while [ $# -gt 0 ]; do
		case "$1" in
		--class=*)
			window_class="${1#*=}"
			;;
		--title=*)
			window_title="${1#*=}"
			;;
		--proxy-host=*)
			PROXY_HOST="${1#*=}"
			PROXY_ENABLED=true
			;;
		--proxy-port=*)
			PROXY_PORT="${1#*=}"
			PROXY_ENABLED=true
			;;
		--proxy-type=*)
			PROXY_TYPE="${1#*=}"
			PROXY_ENABLED=true
			;;
		--kill-profile)
			kill_profile=true
			;;
		--incognito)
			incognito_mode=true
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

	# "Proxy" profili seçildiyse ve proxy parametresi açıkça verilmediyse otomatik etkinleştir
	if [ "$profile_name" = "Proxy" ] && [ "$PROXY_ENABLED" = false ]; then
		PROXY_ENABLED=true
		echo -e "${YELLOW}Proxy profili seçildi, proxy desteği otomatik olarak etkinleştirildi${RESET}"
	fi

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

	# İnkognito modu etkinse başlık ve sınıfı güncelle
	if $incognito_mode; then
		window_title="$window_title (Inkognito)"
		window_class="${window_class}_incognito"
		echo -e "${BLUE}İnkognito modu etkinleştirildi${RESET}"
	fi

	# Brave komut satırı argümanlarını oluştur
	cmd=("$BRAVE_CMD" "--profile-directory=$profile_key")

	# İnkognito modu etkinse ilgili bayrağı ekle
	if $incognito_mode; then
		cmd+=("--incognito")
	else
		# Varsayılan bayrakları ekle (inkognito modunda son oturumu geri yükleme olmaz)
		cmd+=("${DEFAULT_FLAGS[@]}")
	fi

	# Proxy etkinleştirilmişse proxy bayraklarını ekle
	if [ "$PROXY_ENABLED" = true ]; then
		echo -e "${BLUE}Proxy etkinleştiriliyor: ${PROXY_TYPE}://${PROXY_HOST}:${PROXY_PORT}${RESET}"
		cmd+=("--proxy-server=${PROXY_TYPE}://${PROXY_HOST}:${PROXY_PORT}")
		cmd+=("--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE ${PROXY_HOST}")
		cmd+=("--proxy-bypass-list=<local>")
	fi

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
