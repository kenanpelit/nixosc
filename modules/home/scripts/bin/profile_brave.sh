#!/usr/bin/env bash
#===============================================================================
#
#   Script: Brave Profile Launcher (İyileştirilmiş)
#   Description: Brave tarayıcısı için profil bazlı başlatma aracı
#   Version: 2.0
#
#   Özellikler:
#   - Profil bazlı Brave başlatma
#   - Özel pencere sınıfı ve başlık ayarlama
#   - Komut satırı argümanlarını destekleme
#   - Profil listeleme ve yönetimi
#   - Hazır uygulama kısayolları (whatsapp, youtube, tiktok, spotify, discord)
#   - SOCKS5/HTTP Proxy Desteği
#   - Wayland ve dokunmatik yüzey desteği
#   - Yeni pencere zorlama özelliği
#   - İnkognito mod desteği
#   - Yeni profil oluşturma ve silme
#   - Yapılandırma dosyası desteği
#   - Gelişmiş hata yönetimi ve loglama
#
#===============================================================================

set -eo pipefail

# Script sürümü
readonly SCRIPT_VERSION="2.0"
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
readonly CONFIG_FILE="${HOME}/.config/brave-launcher/config.conf"
readonly LOG_FILE="${HOME}/.config/brave-launcher/brave-launcher.log"

	# Varsayılan konfigürasyon
	BRAVE_CMD="brave"
	# Brave'in varsayılan user-data-dir'i (profil/Local State burada)
	LOCAL_STATE_PATH="${HOME}/.config/BraveSoftware/Brave-Browser/Local State"
	BRAVE_PROFILES_DIR="${HOME}/.config/BraveSoftware/Brave-Browser"
	# Niri/Hyprland'da farklı profilleri ayrı process + ayrı app-id ile açabilmek için
	# profile bazlı ayrı user-data-dir kullanırız; profil dizinini symlink'leyerek veri çoğaltmayız.
	# Not: v2 ile önceki denemelerde oluşan bozuk isolated dizinlerden ayrıştırıyoruz.
	ISOLATED_ROOT="${HOME}/.local/state/brave-isolated-v2"

# Wayland ve dokunmatik yüzey için varsayılan bayraklar
	DEFAULT_FLAGS=(
		"--restore-last-session"
		"--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform,VaapiVideoDecoder"
		"--ozone-platform=wayland"
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

# Hata yakalama - sadece kritik hatalar için
error_handler() {
	local line_no=$1
	local error_code=$2

	# Sadece ciddi hataları yakala (1'den büyük çıkış kodları)
	if [[ $error_code -gt 1 ]]; then
		log "ERROR" "Script failed at line $line_no with exit code $error_code"
		exit "$error_code"
	fi
}

# Sadece ciddi hatalar için trap kur
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
# Brave Launcher Konfigürasyonu

# Brave komutu
BRAVE_CMD="brave"

# Proxy ayarları
PROXY_HOST="127.0.0.1"
PROXY_PORT="4999"
PROXY_TYPE="socks5"

# Ek Brave bayrakları (boşlukla ayrılmış)
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

	# Brave komutunu kontrol et - farklı isimler dene
	local brave_found=false
	local brave_commands=("brave" "brave-browser" "brave-bin" "/usr/bin/brave" "/usr/bin/brave-browser")

	for brave_cmd in "${brave_commands[@]}"; do
		if command -v "$brave_cmd" &>/dev/null; then
			BRAVE_CMD="$brave_cmd"
			brave_found=true
			log "INFO" "Brave bulundu: $brave_cmd"
			break
		fi
	done

	if [[ "$brave_found" == false ]]; then
		missing+=("brave")
	fi

	if [[ ${#missing[@]} -gt 0 ]]; then
		log "ERROR" "Eksik bağımlılıklar: ${missing[*]}"
		log "INFO" "Kurulum: sudo apt install ${missing[*]// / }"
		exit 1
	fi
}

	# Kullanım bilgisi
	usage() {
	echo -e "${BOLD}Brave Profil Başlatıcı v${SCRIPT_VERSION}${RESET}"
	echo
	echo -e "${BOLD}Kullanım:${RESET}"
	echo -e "  $SCRIPT_NAME ${BOLD}<profil_ismi>${RESET} [seçenekler] [brave_parametreleri]"
	echo -e "  $SCRIPT_NAME ${BOLD}--whatsapp${RESET} [seçenekler]"
	echo -e "  $SCRIPT_NAME ${BOLD}--youtube${RESET} [seçenekler]"
	echo -e "  $SCRIPT_NAME ${BOLD}--spotify${RESET} [seçenekler]"
	echo -e "  $SCRIPT_NAME ${BOLD}--discord${RESET} [seçenekler]"
	echo
	echo -e "${BOLD}Seçenekler:${RESET}"
	echo "  --class=SINIF              Pencere sınıfını ayarlar"
	echo "  --title=BASLIK             Pencere başlığını ayarlar"
	echo "  --proxy[=host:port]        Proxy ile başlatır"
	echo "  --Proxy                    Proxy profili ile başlatır"
		echo "  --proxy-type=TYPE          Proxy türü (socks5, http, https)"
		echo "  --separate                 Her profil için ayrı Brave instance (user-data-dir) kullan"
		echo "  --no-separate              Tek instance davranışı (varsayılan Chromium)"
		echo "  --incognito                İnkognito modunda başlatır"
	echo "  --kill-profile             Bu profil için çalışan örnekleri kapat"
	echo "  --kill-all                 Tüm Brave örneklerini kapat"
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
	echo "  --tiktok                   TikTok"
	echo "  --spotify                  Spotify Web Player"
	echo "  --discord                  Discord Web"
	echo
	echo -e "${BOLD}Örnekler:${RESET}"
	echo "  $SCRIPT_NAME \"İş Profili\" --class=WorkBrowser"
	echo "  $SCRIPT_NAME Default --incognito"
	echo "  $SCRIPT_NAME --whatsapp"
	echo "  $SCRIPT_NAME Proxy --proxy=127.0.0.1:9050"
	echo
		list_profiles
		exit "${1:-0}"
	}

	ensure_isolated_userdata() {
		local isolated_dir="$1"
		mkdir -p "$isolated_dir"

		# Local State olmadan Brave bazı profilleri "sıfırdan" açıp uyarı/hata verebiliyor.
		# Symlink yerine kopyalıyoruz: her instance kendi Local State'ini yazabilsin.
		if [[ -f "${BRAVE_PROFILES_DIR}/Local State" && ! -f "${isolated_dir}/Local State" ]]; then
			cp -f "${BRAVE_PROFILES_DIR}/Local State" "${isolated_dir}/Local State" 2>/dev/null || true
		fi

		# First Run yoksa ilk kurulum ekranları/uyarıları çıkabiliyor.
		if [[ -f "${BRAVE_PROFILES_DIR}/First Run" && ! -f "${isolated_dir}/First Run" ]]; then
			cp -f "${BRAVE_PROFILES_DIR}/First Run" "${isolated_dir}/First Run" 2>/dev/null || true
		fi

		# Bazı sürümler "Last Version" dosyasına bakıyor.
		if [[ -f "${BRAVE_PROFILES_DIR}/Last Version" && ! -f "${isolated_dir}/Last Version" ]]; then
			cp -f "${BRAVE_PROFILES_DIR}/Last Version" "${isolated_dir}/Last Version" 2>/dev/null || true
		fi
	}

# Profil listesi (geliştirilmiş)
list_profiles() {
	echo -e "${BOLD}Mevcut profiller:${RESET}"

	if [[ ! -f "$LOCAL_STATE_PATH" ]]; then
		log "ERROR" "Brave profil bilgisi bulunamadı: $LOCAL_STATE_PATH"
		return 1
	fi

	# Profilleri listele ve formatla
	local profiles
	if ! profiles=$(jq -r '.profile.info_cache | to_entries | 
		map("  " + .key + ": " + .value.name) | 
		.[]' "$LOCAL_STATE_PATH" 2>/dev/null | sort); then
		log "ERROR" "Brave profil bilgisi okunamadı"
		return 1
	fi

	if [[ -z "$profiles" ]]; then
		echo -e "${YELLOW}  Henüz profil oluşturulmamış${RESET}"
	else
		echo "$profiles"
	fi

	echo
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
	local profile_path="$BRAVE_PROFILES_DIR/$profile_key"
	if [[ -d "$profile_path" ]]; then
		rm -rf "$profile_path"
		log "SUCCESS" "Profil dizini silindi: $profile_path"
	fi

	log "SUCCESS" "Profil '$profile_name' başarıyla silindi"
}

# Yeni profil oluşturma (geliştirilmiş)
create_profile() {
	local profile_name="$1"
	local icon_path="${2:-}"

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

	# Yeni profil numarası oluştur
	local profile_number=1
	while [[ -d "$BRAVE_PROFILES_DIR/Profile $profile_number" ]]; do
		((profile_number++))
	done

	local profile_dir="Profile $profile_number"
	local profile_path="$BRAVE_PROFILES_DIR/$profile_dir"

	# Profil dizinini oluştur
	mkdir -p "$profile_path"

	# Özel ikon ayarla
	if [[ -n "$icon_path" && -f "$icon_path" ]]; then
		log "INFO" "Profil ikonu ayarlanıyor: $icon_path"
		cp "$icon_path" "$profile_path/icon.png"
	fi

	# Profili başlat
	log "INFO" "Brave başlatılıyor, profili yapılandırın ve kapatın"
	"$BRAVE_CMD" "--profile-directory=$profile_dir" \
		"--profile-creation-name=$profile_name" \
		--no-first-run &

	local brave_pid=$!

	# Brave'in başlamasını bekle
	sleep 3

	# Brave kapanana kadar bekle
	wait "$brave_pid" 2>/dev/null || true

	log "SUCCESS" "Profil oluşturuldu: $profile_name"
	log "INFO" "Kullanım: $SCRIPT_NAME \"$profile_name\""

	return 0
}

# Uygulama başlatıcıları (geliştirilmiş)
	launch_app() {
		local app_name="$1"
		local app_url="$2"
		local profile="${3:-Kenp}"
	shift 3

	log "SUCCESS" "$app_name başlatılıyor..."

	# exec yerine normal çağrı
		"$0" "$profile" --new-window --app="$app_url" \
			--class="$app_name" --title="$app_name" "$@"
	}

launch_whatsapp() { launch_app "WhatsApp" "https://web.whatsapp.com" "Kenp" "$@"; }
launch_youtube() { launch_app "YouTube" "https://youtube.com" "Kenp" "$@"; }
launch_tiktok() { launch_app "TikTok" "https://tiktok.com" "Kenp" "$@"; }
launch_spotify() { launch_app "Spotify" "https://open.spotify.com/" "Kenp" "$@"; }

launch_discord() {
	local discord_url
	discord_url=$(pass discord-channels 2>/dev/null || echo "https://discord.com/app")
	launch_app "Discord" "$discord_url" "Kenp" "$@"
}

# Proxy ile başlatma (geliştirilmiş)
launch_proxy() {
	log "SUCCESS" "Proxy ile Brave başlatılıyor"
	PROXY_ENABLED=true
	"$0" "Proxy" --class=ProxyBrowser --title="Proxy Browser" "$@"
}

# Profil için çalışan Brave örneklerini kapat (geliştirilmiş)
kill_profile_brave() {
	local profile_dir="$1"
	log "INFO" "Profil '$profile_dir' için çalışan Brave örnekleri aranıyor"

	local pids
	pids=$(pgrep -f "brave.*profile-directory=$profile_dir" || true)

	if [[ -n "$pids" ]]; then
		log "WARN" "Profil için çalışan Brave örnekleri bulundu, kapatılıyor"
		echo "$pids" | xargs kill -TERM 2>/dev/null || true
		sleep 2

		# Hala çalışan varsa zorla kapat
		pids=$(pgrep -f "brave.*profile-directory=$profile_dir" || true)
		if [[ -n "$pids" ]]; then
			echo "$pids" | xargs kill -KILL 2>/dev/null || true
		fi

		log "SUCCESS" "Profil örnekleri kapatıldı"
	else
		log "INFO" "Profil için çalışan Brave örneği bulunamadı"
	fi
}

# Tüm Brave örneklerini kapat
kill_all_brave() {
	log "WARN" "Tüm Brave örnekleri kapatılıyor"
	pkill -TERM brave 2>/dev/null || true
	sleep 2
	pkill -KILL brave 2>/dev/null || true
	log "SUCCESS" "Tüm Brave örnekleri kapatıldı"
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
		log "ERROR" "Brave profil dosyası bulunamadı: $LOCAL_STATE_PATH"
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
		echo "Brave Launcher v$SCRIPT_VERSION"
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
		icon_path=""
		# Parametreleri işle
		while [[ $# -gt 0 ]]; do
			case "$1" in
			--icon=*)
				icon_path="${1#*=}"
				shift
				;;
			*)
				break
				;;
			esac
		done
		create_profile "$profile_name" "$icon_path"
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
	--Proxy)
		shift
		launch_proxy "$@"
		;;
	--kill-all)
		kill_all_brave
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
		local brave_args=()
		local kill_profile=false
		local incognito_mode=false
		# Niri/Hyprland'da workspace rule'ların düzgün çalışması için default: ayrı instance
		local separate_mode="auto"

	# Parametreleri güvenli şekilde işle
		while [[ $# -gt 0 ]]; do
			case "${1:-}" in
			--class=*) window_class="${1#*=}" ;;
			--title=*) window_title="${1#*=}" ;;
			--separate) separate_mode="true" ;;
			--no-separate) separate_mode="false" ;;
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
				brave_args+=("$1")
			fi
			;;
		esac
		shift
	done

	# Proxy profili kontrolü
	if [[ "$profile_name" == "Proxy" && "$PROXY_ENABLED" == false ]]; then
		PROXY_ENABLED=true
		log "INFO" "Proxy profili seçildi, proxy otomatik etkinleştirildi"
	fi

	# Profili doğrula
	local profile_key
	if ! profile_key=$(validate_profile "$profile_name"); then
		exit 1
	fi

	# Profil örneklerini kapat
	if $kill_profile; then
		kill_profile_brave "$profile_key"
	fi

		# Pencere ayarları
		[[ -z "$window_class" ]] && window_class="$profile_name"
		[[ -z "$window_title" ]] && window_title="$profile_name Browser"

	# İnkognito modu
	if $incognito_mode; then
		window_title="$window_title (İnkognito)"
		window_class="${window_class}_incognito"
		log "INFO" "İnkognito modu etkinleştirildi"
	fi

		# separate_mode auto: Wayland (niri/hyprland) için aç, X11 için kapalı
		if [[ "$separate_mode" == "auto" ]]; then
			if [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
				separate_mode="true"
			else
				separate_mode="false"
			fi
		fi

		# Komut oluştur
			local cmd=("$BRAVE_CMD")
			if [[ "$separate_mode" == "true" ]]; then
				local isolated_dir="${ISOLATED_ROOT}/${window_class}"
				ensure_isolated_userdata "$isolated_dir"

			# Profil dizinini (Default / Profile X) symlink'le.
			# Not: Aynı profile_key'i iki farklı isolated_dir ile aynı anda açarsan Brave kilitlenir.
			if [[ -e "$isolated_dir/$profile_key" && ! -L "$isolated_dir/$profile_key" ]]; then
				# Bu genelde ilk denemede Brave'in isolated_dir altında yeni/boş bir profil dizini
				# oluşturmasından kaynaklanır. Veriyi kaybetmemek için yedekleyip symlink'e çevir.
				local backup="${isolated_dir}/${profile_key}.bak-$(date +%Y%m%d%H%M%S)"
				log "WARN" "Isolated dizinde '$profile_key' symlink değil; yedeklenip düzeltilecek: $isolated_dir/$profile_key -> $backup"
				mv "$isolated_dir/$profile_key" "$backup" 2>/dev/null || true
			fi
			if [[ ! -e "$isolated_dir/$profile_key" ]]; then
				ln -s "${BRAVE_PROFILES_DIR}/${profile_key}" "$isolated_dir/$profile_key" 2>/dev/null || true
			fi
				if [[ ! -e "$isolated_dir/$profile_key" ]]; then
					log "ERROR" "Profil symlink oluşturulamadı: $isolated_dir/$profile_key"
					exit 1
				fi

				cmd+=("--user-data-dir=$isolated_dir")
			fi
		cmd+=("--profile-directory=$profile_key")

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
	cmd+=("--name=$window_class")
	cmd+=("--window-name=$window_title")

	# Ek parametreler
	[[ ${#brave_args[@]} -gt 0 ]] && cmd+=("${brave_args[@]}")

	# Debug bilgisi (sadece debug modunda göster)
	[[ "${DEBUG_MODE:-false}" == "true" ]] && debug "Komut: ${cmd[*]}"
	log "INFO" "Kullanılan Brave komutu: $BRAVE_CMD"

	# Brave'i başlat
	log "SUCCESS" "Brave başlatılıyor: $profile_name"

	# Önce komutu test et
	if ! command -v "$BRAVE_CMD" &>/dev/null; then
		log "ERROR" "Brave komutu bulunamadı: $BRAVE_CMD"
		exit 1
	fi

	# Komutu çalıştır ve çıktısını yakala
	if "${cmd[@]}" >/dev/null 2> >(tail -n 20 >&2) & then
		local brave_pid=$!
		log "INFO" "Brave başlatıldı (PID: $brave_pid)"

		# Brave'in başlamasını bekle ve daha iyi kontrol et
		sleep 1

		# Brave'in hala çalışıp çalışmadığını kontrol et
		if kill -0 "$brave_pid" 2>/dev/null; then
			log "SUCCESS" "Brave başarıyla çalışıyor (PID: $brave_pid)"
		else
			# Process çoktan başka bir PID'ye geçmiş olabilir (normal)
			log "SUCCESS" "Brave başlatıldı"
		fi
	else
		log "ERROR" "Brave başlatılamadı"

		# Hata durumunda komutu debug için tekrar çalıştır
		log "INFO" "Debug için komut tekrar çalıştırılıyor..."
		"${cmd[@]}" 2>&1 | head -5 | while read -r line; do
			log "ERROR" "$line"
		done
		return 1
	fi
}

# Scripti çalıştır
main "$@"
