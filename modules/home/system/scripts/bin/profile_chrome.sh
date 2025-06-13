#!/usr/bin/env bash
#===============================================================================
#
#   Script: Advanced Chrome Profile Launcher
#   Version: 2.0.0
#   Date: 2025-06-13
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Advanced Google Chrome profile launcher with comprehensive
#                window management, proxy support, and app shortcuts
#
#   Features:
#   - Profile-based Chrome launching
#   - Custom window class and title setting
#   - Profile discovery, validation, and management
#   - Command-line argument passthrough
#   - Chrome state file integration
#   - Profile listing and creation capabilities
#   - App shortcuts (WhatsApp, YouTube, etc.)
#   - Proxy support (SOCKS5, HTTP)
#   - Incognito mode support
#   - Configuration file support
#   - Enhanced logging and error handling
#   - Process management
#
#   License: MIT
#
#===============================================================================

set -eo pipefail

# Script bilgileri
readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_NAME="$(basename "$0")"

# Renk tanımlamaları
readonly BOLD="\033[1m"
readonly RED="\033[31m"
readonly GREEN="\033[32m"
readonly YELLOW="\033[33m"
readonly BLUE="\033[34m"
readonly CYAN="\033[36m"
readonly RESET="\033[0m"

# Semboller
readonly SUCCESS="✓"
readonly ERROR="✗"
readonly WARNING="⚠"
readonly INFO="ℹ"

# Konfigürasyon dosyası
readonly CONFIG_FILE="${HOME}/.config/chrome-launcher/config.conf"
readonly LOG_FILE="${HOME}/.config/chrome-launcher/chrome-launcher.log"

# Varsayılan konfigürasyon
CHROME_CMD="google-chrome-stable"
LOCAL_STATE_PATH="${HOME}/.config/google-chrome/Local State"
CHROME_PROFILES_DIR="${HOME}/.config/google-chrome"

# Varsayılan bayraklar
DEFAULT_FLAGS=(
	"--restore-last-session"
	"--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform,VaapiVideoDecoder"
	"--ozone-platform=wayland"
	"--new-window"
	"--disable-web-security"
	"--disable-features=VizDisplayCompositor"
)

# Proxy ayarları
PROXY_ENABLED=false
PROXY_HOST="127.0.0.1"
PROXY_PORT="4999"
PROXY_TYPE="socks5"

# Loglama
log() {
	local level="$1"
	shift
	local message="$*"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

	# Log dizinini oluştur
	mkdir -p "$(dirname "$LOG_FILE")"

	# Log dosyasına yaz
	echo "[$timestamp] [$level] $message" >>"$LOG_FILE"

	# Terminale de yazdır
	case "$level" in
	"ERROR")
		echo -e "${RED}${ERROR} $message${RESET}" >&2
		;;
	"WARN")
		echo -e "${YELLOW}${WARNING} $message${RESET}"
		;;
	"INFO")
		echo -e "${BLUE}${INFO} $message${RESET}"
		;;
	"SUCCESS")
		echo -e "${GREEN}${SUCCESS} $message${RESET}"
		;;
	*)
		echo "$message"
		;;
	esac
}

# Hata yakalama
error_handler() {
	local line_no=$1
	local error_code=$2

	# Sadece ciddi hataları yakala
	if [[ $error_code -gt 1 ]]; then
		log "ERROR" "Script failed at line $line_no with exit code $error_code"
		exit "$error_code"
	fi
}

trap 'error_handler ${LINENO} $?' ERR

# Konfigürasyon dosyasını yükle
load_config() {
	if [[ -f "$CONFIG_FILE" ]]; then
		# shellcheck source=/dev/null
		source "$CONFIG_FILE"
	else
		create_default_config
	fi
}

# Varsayılan konfigürasyon dosyası oluştur
create_default_config() {
	mkdir -p "$(dirname "$CONFIG_FILE")"
	cat >"$CONFIG_FILE" <<'EOF'
# Chrome Launcher Konfigürasyonu

# Chrome komutu
CHROME_CMD="google-chrome-stable"

# Proxy ayarları
PROXY_HOST="127.0.0.1"
PROXY_PORT="4999"
PROXY_TYPE="socks5"

# Ek Chrome bayrakları
CUSTOM_FLAGS=""

# Varsayılan profil
DEFAULT_PROFILE="Default"

# Debug modu (true/false)
DEBUG_MODE=false
EOF
	log "SUCCESS" "Varsayılan konfigürasyon dosyası oluşturuldu: $CONFIG_FILE"
}

# Debug modu kontrolü
debug() {
	[[ "${DEBUG_MODE:-false}" == "true" ]] && log "DEBUG" "$*"
}

# Gerekli bağımlılıkları kontrol et
check_dependencies() {
	local deps=("jq")
	local missing=()

	for dep in "${deps[@]}"; do
		if ! command -v "$dep" &>/dev/null; then
			missing+=("$dep")
		fi
	done

	# Chrome komutunu kontrol et
	local chrome_found=false
	local chrome_commands=("google-chrome-stable" "google-chrome" "chrome" "/usr/bin/google-chrome-stable" "/usr/bin/google-chrome")

	for chrome_cmd in "${chrome_commands[@]}"; do
		if command -v "$chrome_cmd" &>/dev/null; then
			CHROME_CMD="$chrome_cmd"
			chrome_found=true
			log "INFO" "Chrome bulundu: $chrome_cmd"
			break
		fi
	done

	if [[ "$chrome_found" == false ]]; then
		missing+=("google-chrome")
	fi

	if [[ ${#missing[@]} -gt 0 ]]; then
		log "ERROR" "Eksik bağımlılıklar: ${missing[*]}"
		log "INFO" "Kurulum: sudo apt install ${missing[*]// / }"
		exit 1
	fi
}

# Kullanım bilgisi
usage() {
	echo -e "${BOLD}Chrome Profil Başlatıcı v${SCRIPT_VERSION}${RESET}"
	echo
	echo -e "${BOLD}Kullanım:${RESET}"
	echo -e "  $SCRIPT_NAME ${BOLD}<profil_ismi>${RESET} [seçenekler] [chrome_parametreleri]"
	echo -e "  $SCRIPT_NAME ${BOLD}--whatsapp${RESET} [seçenekler]"
	echo -e "  $SCRIPT_NAME ${BOLD}--youtube${RESET} [seçenekler]"
	echo -e "  $SCRIPT_NAME ${BOLD}--gmail${RESET} [seçenekler]"
	echo -e "  $SCRIPT_NAME ${BOLD}--drive${RESET} [seçenekler]"
	echo
	echo -e "${BOLD}Seçenekler:${RESET}"
	echo "  --class=SINIF              Pencere sınıfını ayarlar"
	echo "  --title=BASLIK             Pencere başlığını ayarlar"
	echo "  --proxy[=host:port]        Proxy ile başlatır"
	echo "  --proxy-type=TYPE          Proxy türü (socks5, http, https)"
	echo "  --incognito                İnkognito modunda başlatır"
	echo "  --kill-profile             Bu profil için çalışan örnekleri kapat"
	echo "  --kill-all                 Tüm Chrome örneklerini kapat"
	echo "  --create-profile=ISIM      Yeni profil oluştur"
	echo "  --delete-profile=ISIM      Profil sil"
	echo "  --list-profiles            Profilleri listele"
	echo "  --config                   Konfigürasyon dosyasını düzenle"
	echo "  --version                  Sürüm bilgisini göster"
	echo "  --help, -h                 Bu yardımı göster"
	echo
	echo -e "${BOLD}Hazır Uygulamalar:${RESET}"
	echo "  --whatsapp                 WhatsApp Web"
	echo "  --youtube                  YouTube"
	echo "  --gmail                    Gmail"
	echo "  --drive                    Google Drive"
	echo "  --docs                     Google Docs"
	echo "  --sheets                   Google Sheets"
	echo
	echo -e "${BOLD}Örnekler:${RESET}"
	echo "  $SCRIPT_NAME \"İş Profili\" --class=WorkChrome"
	echo "  $SCRIPT_NAME Default --incognito"
	echo "  $SCRIPT_NAME --whatsapp"
	echo "  $SCRIPT_NAME Personal --proxy=127.0.0.1:9050"
	echo
	list_profiles
	exit "${1:-0}"
}

# Profil listesi
list_profiles() {
	echo -e "${BOLD}Mevcut profiller:${RESET}"

	if [[ ! -f "$LOCAL_STATE_PATH" ]]; then
		log "ERROR" "Chrome profil bilgisi bulunamadı: $LOCAL_STATE_PATH"
		return 1
	fi

	# Profilleri listele ve formatla
	local profiles
	if ! profiles=$(jq -r '.profile.info_cache | to_entries | 
		map("  " + .key + ": " + .value.name) | 
		.[]' "$LOCAL_STATE_PATH" 2>/dev/null | sort); then
		log "ERROR" "Chrome profil bilgisi okunamadı"
		return 1
	fi

	if [[ -z "$profiles" ]]; then
		echo -e "${YELLOW}  Henüz profil oluşturulmamış${RESET}"
	else
		echo "$profiles"
	fi

	echo
}

# Yeni profil oluşturma
create_profile() {
	local profile_name="$1"

	if [[ -z "$profile_name" ]]; then
		log "ERROR" "Profil ismi boş olamaz"
		return 1
	fi

	# Profil ismi kontrolü
	if [[ "$profile_name" =~ [^a-zA-Z0-9\ \-\_] ]]; then
		log "ERROR" "Profil ismi sadece harf, rakam, boşluk, tire ve alt çizgi içerebilir"
		return 1
	fi

	log "INFO" "Yeni profil oluşturuluyor: $profile_name"

	# Mevcut profilleri kontrol et
	if [[ -f "$LOCAL_STATE_PATH" ]]; then
		local existing_profile
		if existing_profile=$(jq -r --arg name "$profile_name" \
			'.profile.info_cache | to_entries | .[] | 
			select(.value.name == $name) | .key' "$LOCAL_STATE_PATH" 2>/dev/null) && [[ -n "$existing_profile" ]]; then
			log "WARN" "Profil zaten mevcut: $profile_name"
			return 0
		fi
	fi

	# Chrome'u profil oluşturma modunda başlat
	log "INFO" "Chrome başlatılıyor, profili yapılandırın ve kapatın"
	"$CHROME_CMD" --no-first-run --profile-directory="Profile $(date +%s)" &

	local chrome_pid=$!

	# Chrome'in başlamasını bekle
	sleep 3

	# Chrome kapanana kadar bekle
	wait "$chrome_pid" 2>/dev/null || true

	log "SUCCESS" "Profil oluşturma tamamlandı"
	log "INFO" "Profili manuel olarak yapılandırmanız gerekebilir"

	return 0
}

# Profil silme
delete_profile() {
	local profile_name="$1"

	if [[ -z "$profile_name" ]]; then
		log "ERROR" "Profil ismi belirtilmedi"
		return 1
	fi

	# Profil anahtarını bul
	local profile_key
	if ! profile_key=$(jq -r --arg name "$profile_name" \
		'.profile.info_cache | to_entries | .[] | 
		select(.value.name == $name) | .key' "$LOCAL_STATE_PATH" 2>/dev/null); then
		log "ERROR" "Profil bilgisi okunamadı"
		return 1
	fi

	if [[ -z "$profile_key" ]]; then
		log "ERROR" "Profil bulunamadı: $profile_name"
		return 1
	fi

	# Onay al
	echo -e "${YELLOW}${WARNING} '$profile_name' profili silinecek. Emin misiniz? [y/N]${RESET}"
	read -r confirmation

	if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
		log "INFO" "İşlem iptal edildi"
		return 0
	fi

	# Profil dizinini sil
	local profile_path="$CHROME_PROFILES_DIR/$profile_key"
	if [[ -d "$profile_path" ]]; then
		rm -rf "$profile_path"
		log "SUCCESS" "Profil dizini silindi: $profile_path"
	fi

	log "SUCCESS" "Profil '$profile_name' başarıyla silindi"
}

# Uygulama başlatıcıları
launch_app() {
	local app_name="$1"
	local app_url="$2"
	local profile="${3:-Default}"
	shift 3

	log "SUCCESS" "$app_name başlatılıyor..."
	"$0" "$profile" --app="$app_url" \
		--class="$app_name" --title="$app_name" "$@"
}

launch_whatsapp() { launch_app "WhatsApp" "https://web.whatsapp.com" "Default" "$@"; }
launch_youtube() { launch_app "YouTube" "https://youtube.com" "Default" "$@"; }
launch_gmail() { launch_app "Gmail" "https://gmail.com" "Default" "$@"; }
launch_drive() { launch_app "GoogleDrive" "https://drive.google.com" "Default" "$@"; }
launch_docs() { launch_app "GoogleDocs" "https://docs.google.com" "Default" "$@"; }
launch_sheets() { launch_app "GoogleSheets" "https://sheets.google.com" "Default" "$@"; }

# Profil için çalışan Chrome örneklerini kapat
kill_profile_chrome() {
	local profile_dir="$1"
	log "INFO" "Profil '$profile_dir' için çalışan Chrome örnekleri aranıyor"

	local pids
	pids=$(pgrep -f "chrome.*profile-directory=$profile_dir" || true)

	if [[ -n "$pids" ]]; then
		log "WARN" "Profil için çalışan Chrome örnekleri bulundu, kapatılıyor"
		echo "$pids" | xargs kill -TERM 2>/dev/null || true
		sleep 2

		# Hala çalışan varsa zorla kapat
		pids=$(pgrep -f "chrome.*profile-directory=$profile_dir" || true)
		if [[ -n "$pids" ]]; then
			echo "$pids" | xargs kill -KILL 2>/dev/null || true
		fi

		log "SUCCESS" "Profil örnekleri kapatıldı"
	else
		log "INFO" "Profil için çalışan Chrome örneği bulunamadı"
	fi
}

# Tüm Chrome örneklerini kapat
kill_all_chrome() {
	log "WARN" "Tüm Chrome örnekleri kapatılıyor"
	pkill -TERM chrome 2>/dev/null || true
	sleep 2
	pkill -KILL chrome 2>/dev/null || true
	log "SUCCESS" "Tüm Chrome örnekleri kapatıldı"
}

# Konfigürasyon düzenleme
edit_config() {
	local editor="${EDITOR:-nano}"
	log "INFO" "Konfigürasyon dosyası düzenleniyor: $CONFIG_FILE"
	"$editor" "$CONFIG_FILE"
}

# Profil doğrulama
validate_profile() {
	local profile_name="$1"

	if [[ ! -f "$LOCAL_STATE_PATH" ]]; then
		log "ERROR" "Chrome profil dosyası bulunamadı: $LOCAL_STATE_PATH"
		return 1
	fi

	local profile_key
	if ! profile_key=$(jq -r --arg name "$profile_name" \
		'.profile.info_cache | to_entries | .[] | 
		select(.value.name == $name) | .key' "$LOCAL_STATE_PATH" 2>/dev/null); then
		log "ERROR" "Profil bilgisi okunamadı"
		return 1
	fi

	if [[ -z "$profile_key" ]]; then
		log "ERROR" "Profil bulunamadı: $profile_name"
		list_profiles
		return 1
	fi

	echo "$profile_key"
}

# Ana işlev
main() {
	# Konfigürasyonu yükle
	load_config

	# Bağımlılıkları kontrol et
	check_dependencies

	# Parametre kontrolü
	[[ $# -eq 0 ]] && usage 0

	# Özel parametreleri işle
	case "$1" in
	--version)
		echo "Chrome Launcher v$SCRIPT_VERSION"
		exit 0
		;;
	--config)
		edit_config
		exit 0
		;;
	--list-profiles)
		list_profiles
		exit 0
		;;
	--create-profile=*)
		profile_name="${1#*=}"
		shift
		create_profile "$profile_name"
		exit $?
		;;
	--delete-profile=*)
		profile_name="${1#*=}"
		delete_profile "$profile_name"
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
	--gmail)
		shift
		launch_gmail "$@"
		;;
	--drive)
		shift
		launch_drive "$@"
		;;
	--docs)
		shift
		launch_docs "$@"
		;;
	--sheets)
		shift
		launch_sheets "$@"
		;;
	--kill-all)
		kill_all_chrome
		exit 0
		;;
	--help | -h)
		usage 0
		;;
	esac

	# İlk parametre profil adı
	local profile_name="$1"
	shift

	# Varsayılan değerler
	local window_class=""
	local window_title=""
	local chrome_args=()
	local kill_profile=false
	local incognito_mode=false

	# Parametreleri güvenli şekilde işle
	while [[ $# -gt 0 ]]; do
		case "${1:-}" in
		--class=*) window_class="${1#*=}" ;;
		--title=*) window_title="${1#*=}" ;;
		--proxy=*)
			IFS=':' read -r PROXY_HOST PROXY_PORT <<<"${1#*=}"
			PROXY_ENABLED=true
			;;
		--proxy) PROXY_ENABLED=true ;;
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
		--kill-profile) kill_profile=true ;;
		--incognito) incognito_mode=true ;;
		--help | -h) usage 0 ;;
		*)
			if [[ -n "${1:-}" ]]; then
				chrome_args+=("$1")
			fi
			;;
		esac
		shift
	done

	# Profili doğrula
	local profile_key
	if ! profile_key=$(validate_profile "$profile_name"); then
		exit 1
	fi

	# Profil örneklerini kapat
	if $kill_profile; then
		kill_profile_chrome "$profile_key"
	fi

	# Pencere ayarları
	[[ -z "$window_class" ]] && window_class="$profile_name"
	[[ -z "$window_title" ]] && window_title="$profile_name Chrome"

	# İnkognito modu
	if $incognito_mode; then
		window_title="$window_title (İnkognito)"
		window_class="${window_class}_incognito"
		log "INFO" "İnkognito modu etkinleştirildi"
	fi

	# Komut oluştur
	local cmd=("$CHROME_CMD" "--profile-directory=$profile_key")

	# İnkognito modu
	if $incognito_mode; then
		cmd+=("--incognito")
	else
		cmd+=("${DEFAULT_FLAGS[@]}")
	fi

	# Özel bayraklar
	if [[ -n "${CUSTOM_FLAGS:-}" ]]; then
		# shellcheck disable=SC2086
		cmd+=($CUSTOM_FLAGS)
	fi

	# Proxy ayarları
	if [[ "$PROXY_ENABLED" == true ]]; then
		log "INFO" "Proxy etkinleştiriliyor: ${PROXY_TYPE}://${PROXY_HOST}:${PROXY_PORT}"
		cmd+=("--proxy-server=${PROXY_TYPE}://${PROXY_HOST}:${PROXY_PORT}")
		cmd+=("--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE ${PROXY_HOST}")
		cmd+=("--proxy-bypass-list=<local>")
	fi

	# Pencere ayarları
	cmd+=("--class=$window_class")
	cmd+=("--window-name=$window_title")

	# Ek parametreler
	[[ ${#chrome_args[@]} -gt 0 ]] && cmd+=("${chrome_args[@]}")

	# Debug bilgisi
	[[ "${DEBUG_MODE:-false}" == "true" ]] && debug "Komut: ${cmd[*]}"
	log "INFO" "Kullanılan Chrome komutu: $CHROME_CMD"

	# Chrome'i başlat
	log "SUCCESS" "Chrome başlatılıyor: $profile_name"

	# Önce komutu test et
	if ! command -v "$CHROME_CMD" &>/dev/null; then
		log "ERROR" "Chrome komutu bulunamadı: $CHROME_CMD"
		exit 1
	fi

	# Komutu çalıştır
	if "${cmd[@]}" &>/dev/null & then
		local chrome_pid=$!
		log "INFO" "Chrome başlatıldı (PID: $chrome_pid)"

		# Chrome'in başlamasını bekle
		sleep 1

		# Chrome'in hala çalışıp çalışmadığını kontrol et
		if kill -0 "$chrome_pid" 2>/dev/null; then
			log "SUCCESS" "Chrome başarıyla çalışıyor (PID: $chrome_pid)"
		else
			log "SUCCESS" "Chrome başlatıldı"
		fi
	else
		log "ERROR" "Chrome başlatılamadı"
		return 1
	fi
}

# Scripti çalıştır
main "$@"
