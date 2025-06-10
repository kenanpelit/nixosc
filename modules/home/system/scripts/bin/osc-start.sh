#!/usr/bin/env bash

#===============================================================================
#
#   Script: Multi-Browser Profile Startup Manager
#   Version: 5.0.0
#   Date: 2025-06-10
#   Description: Brave/Zen tarayıcı profillerini, web uygulamalarını ve terminal
#                oturumlarını başlatan script
#
#   Özellikler:
#   - Brave ve Zen Browser desteği
#   - Browser seçimi parametre ile yapılabilir
#   - Config dosyası gerektirmez
#   - Workspace yönetimi (Hyprland)
#   - Paralel başlatma ile hızlı açılış
#
#===============================================================================

#-------------------------------------------------------------------------------
# Yapılandırma ve Sabitler
#-------------------------------------------------------------------------------

readonly SCRIPT_NAME=$(basename "$0")
readonly LOG_DIR="$HOME/.logs/browser-startup"
readonly LOG_FILE="$LOG_DIR/browser-startup.log"
readonly DEFAULT_FINAL_WORKSPACE="2"
readonly DEFAULT_WAIT_TIME=3

# Browser komutları
readonly PROFILE_BRAVE="profile_brave"
readonly PROFILE_ZEN="start-zen" # Gerçek zen komutuna göre değiştirildi
readonly SEMSUMO="semsumo"

# Terminal renkleri
if [[ -t 1 ]]; then
	readonly RED='\033[0;31m'
	readonly GREEN='\033[0;32m'
	readonly YELLOW='\033[0;33m'
	readonly BLUE='\033[0;34m'
	readonly PURPLE='\033[0;35m'
	readonly CYAN='\033[0;36m'
	readonly BOLD='\033[1m'
	readonly RESET='\033[0m'
else
	readonly RED="" GREEN="" YELLOW="" BLUE="" PURPLE="" CYAN="" BOLD="" RESET=""
fi

# Çalışma modları
RUN_TERMINALS=false
RUN_BROWSER=false
RUN_APPS=false
SINGLE_PROFILE=""
DEBUG_MODE=false
DRY_RUN=false
WAIT_TIME=$DEFAULT_WAIT_TIME
FINAL_WORKSPACE=$DEFAULT_FINAL_WORKSPACE
BROWSER_TYPE=""

#-------------------------------------------------------------------------------
# Browser Profil ve Uygulama Tanımları
#-------------------------------------------------------------------------------

# Brave Profilleri
declare -A BRAVE_PROFILES=(
	["Kenp"]="workspace=1,fullscreen=false,enabled=true"
	["Ai"]="workspace=3,fullscreen=false,enabled=true"
	["CompecTA"]="workspace=4,fullscreen=false,enabled=true"
	["Whats"]="workspace=9,fullscreen=false,enabled=false"
)

# Zen Profilleri
declare -A ZEN_PROFILES=(
	["Kenp"]="workspace=1,fullscreen=false,enabled=true"
	["NoVpn"]="workspace=3,fullscreen=false,enabled=true"
	["CompecTA"]="workspace=4,fullscreen=false,enabled=true"
	["Whats"]="workspace=9,fullscreen=false,enabled=false"
)

# Brave Web Uygulamaları
declare -A BRAVE_APPS=(
	["youtube"]="workspace=7,fullscreen=true,enabled=true"
	["whatsapp"]="workspace=9,fullscreen=true,enabled=false"
)

# Zen Web Uygulamaları
declare -A ZEN_APPS=(
	["youtube"]="workspace=7,fullscreen=true,enabled=true"
	["whatsapp"]="workspace=9,fullscreen=true,enabled=false"
)

# Semsumo Uygulamaları (Browser'dan bağımsız)
declare -A SEMSUMO_APPS=(
	["discord"]="workspace=5,fullscreen=true,enabled=true"
	["spotify"]="workspace=8,fullscreen=true,enabled=true"
	["ferdium"]="workspace=9,fullscreen=true,enabled=true"
)

# Terminal Oturumları (Browser'dan bağımsız)
declare -A TERMINAL_SESSIONS=(
	["kkenp"]="enabled=true"
	["wkenp"]="enabled=false"
	["mkenp"]="enabled=false"
)

#-------------------------------------------------------------------------------
# Yardımcı Fonksiyonlar
#-------------------------------------------------------------------------------

log() {
	local level="$1"
	local module="$2"
	local message="$3"
	local notify="${4:-false}"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local color=""

	case "$level" in
	"INFO") color=$BLUE ;;
	"SUCCESS") color=$GREEN ;;
	"WARNING") color=$YELLOW ;;
	"ERROR") color=$RED ;;
	"DEBUG") color=$PURPLE ;;
	*) color=$RESET ;;
	esac

	echo -e "${color}${BOLD}[$level]${RESET} ${PURPLE}[$module]${RESET} $message"
	echo "[$timestamp] [$level] [$module] $message" >>"$LOG_FILE"

	if [[ "$notify" == "true" && -x "$(command -v notify-send)" ]]; then
		notify-send -a "$SCRIPT_NAME" "$module: $message"
	fi
}

switch_workspace() {
	local workspace="$1"

	if [[ -z "$workspace" || "$DRY_RUN" == "true" ]]; then
		return 0
	fi

	if command -v hyprctl &>/dev/null; then
		log "INFO" "WORKSPACE" "Workspace $workspace'e geçiliyor"
		hyprctl dispatch workspace "$workspace"
		sleep 1
	fi
}

is_app_running() {
	local app_name="$1"
	local app_type="${2:-browser}"

	if [[ "$app_type" == "browser" ]]; then
		# Hem brave hem zen için kontrol et
		pgrep -f "(brave|zen).*--class=$app_name" &>/dev/null
	else
		pgrep -f "$app_name" &>/dev/null
	fi
}

make_fullscreen() {
	if [[ "$DRY_RUN" == "true" ]]; then
		return 0
	fi

	if command -v hyprctl &>/dev/null; then
		log "INFO" "FULLSCREEN" "Pencere tam ekran yapılıyor"
		sleep 1
		hyprctl dispatch fullscreen 1
		sleep 1
	fi
}

get_config_value() {
	local config_string="$1"
	local key="$2"
	echo "$config_string" | grep -o "${key}=[^,]*" | cut -d= -f2
}

get_browser_command() {
	case "$BROWSER_TYPE" in
	"brave")
		echo "$PROFILE_BRAVE"
		;;
	"zen")
		echo "$PROFILE_ZEN"
		;;
	*)
		log "ERROR" "BROWSER" "Geçersiz browser türü: $BROWSER_TYPE"
		return 1
		;;
	esac
}

get_browser_profiles() {
	case "$BROWSER_TYPE" in
	"brave")
		echo "BRAVE_PROFILES"
		;;
	"zen")
		echo "ZEN_PROFILES"
		;;
	*)
		log "ERROR" "BROWSER" "Geçersiz browser türü: $BROWSER_TYPE"
		return 1
		;;
	esac
}

get_browser_apps() {
	case "$BROWSER_TYPE" in
	"brave")
		echo "BRAVE_APPS"
		;;
	"zen")
		echo "ZEN_APPS"
		;;
	*)
		log "ERROR" "BROWSER" "Geçersiz browser türü: $BROWSER_TYPE"
		return 1
		;;
	esac
}

#-------------------------------------------------------------------------------
# Ana İşlev Fonksiyonları
#-------------------------------------------------------------------------------

launch_browser_profile() {
	local profile="$1"
	local profiles_var=$(get_browser_profiles)
	local browser_cmd=$(get_browser_command)

	# Profil array'ini dinamik olarak al
	local -n profiles_ref=$profiles_var
	local config="${profiles_ref[$profile]}"

	if [[ -z "$config" ]]; then
		log "ERROR" "BROWSER" "Profil bulunamadı: $profile"
		return 1
	fi

	local workspace=$(get_config_value "$config" "workspace")
	local fullscreen=$(get_config_value "$config" "fullscreen")
	local enabled=$(get_config_value "$config" "enabled")

	if [[ "$enabled" != "true" ]]; then
		log "INFO" "BROWSER" "$profile profili devre dışı"
		return 0
	fi

	if is_app_running "$profile" "browser"; then
		log "WARNING" "BROWSER" "$profile profili zaten çalışıyor"
		return 0
	fi

	switch_workspace "$workspace"
	log "INFO" "BROWSER" "$profile profili başlatılıyor ($BROWSER_TYPE - workspace: $workspace)"

	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "BROWSER" "Kuru çalıştırma: $profile başlatılacaktı"
		return 0
	fi

	# Browser tipine göre komut çalıştır
	if [[ "$BROWSER_TYPE" == "zen" ]]; then
		# Zen için start-zen-profil formatını kullan
		local zen_cmd="start-zen-$(echo "$profile" | tr '[:upper:]' '[:lower:]')"
		if ! command -v "$zen_cmd" &>/dev/null; then
			log "ERROR" "BROWSER" "$zen_cmd komutu bulunamadı"
			return 1
		fi
		"$zen_cmd" &
	else
		# Brave için mevcut yapı
		if ! command -v "$browser_cmd" &>/dev/null; then
			log "ERROR" "BROWSER" "$browser_cmd komutu bulunamadı"
			return 1
		fi
		"$browser_cmd" "$profile" --class="$profile" --title="$profile" --restore-last-session &
	fi
	sleep $WAIT_TIME

	if [[ "$fullscreen" == "true" ]]; then
		make_fullscreen
	fi

	log "SUCCESS" "BROWSER" "$profile profili başlatıldı ($BROWSER_TYPE)"
}

launch_browser_app() {
	local app="$1"
	local apps_var=$(get_browser_apps)
	local browser_cmd=$(get_browser_command)

	# App array'ini dinamik olarak al
	local -n apps_ref=$apps_var
	local config="${apps_ref[$app]}"

	if [[ -z "$config" ]]; then
		log "ERROR" "APP" "Browser uygulaması bulunamadı: $app"
		return 1
	fi

	local workspace=$(get_config_value "$config" "workspace")
	local fullscreen=$(get_config_value "$config" "fullscreen")
	local enabled=$(get_config_value "$config" "enabled")

	if [[ "$enabled" != "true" ]]; then
		log "INFO" "APP" "$app uygulaması devre dışı"
		return 0
	fi

	if is_app_running "$app" "browser"; then
		log "WARNING" "APP" "$app uygulaması zaten çalışıyor"
		return 0
	fi

	switch_workspace "$workspace"
	log "INFO" "APP" "$app uygulaması başlatılıyor ($BROWSER_TYPE - workspace: $workspace)"

	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "APP" "Kuru çalıştırma: $app başlatılacaktı"
		return 0
	fi

	# Browser tipine göre komut çalıştır
	if [[ "$BROWSER_TYPE" == "zen" ]]; then
		# Zen için start-zen-app formatını kullan
		local zen_cmd="start-zen-$app"
		if ! command -v "$zen_cmd" &>/dev/null; then
			log "ERROR" "APP" "$zen_cmd komutu bulunamadı"
			return 1
		fi
		"$zen_cmd" &
	else
		# Brave için mevcut yapı
		if ! command -v "$browser_cmd" &>/dev/null; then
			log "ERROR" "APP" "$browser_cmd komutu bulunamadı"
			return 1
		fi
		"$browser_cmd" "--$app" --class="$app" --title="$app" --restore-last-session &
	fi
	sleep $WAIT_TIME

	if [[ "$fullscreen" == "true" ]]; then
		make_fullscreen
	fi

	log "SUCCESS" "APP" "$app uygulaması başlatıldı ($BROWSER_TYPE)"
}

launch_semsumo_app() {
	local app="$1"
	local config="${SEMSUMO_APPS[$app]}"

	if [[ -z "$config" ]]; then
		log "ERROR" "APP" "Semsumo uygulaması bulunamadı: $app"
		return 1
	fi

	local workspace=$(get_config_value "$config" "workspace")
	local fullscreen=$(get_config_value "$config" "fullscreen")
	local enabled=$(get_config_value "$config" "enabled")

	if [[ "$enabled" != "true" ]]; then
		log "INFO" "APP" "$app uygulaması devre dışı"
		return 0
	fi

	if is_app_running "$app"; then
		log "WARNING" "APP" "$app uygulaması zaten çalışıyor"
		return 0
	fi

	switch_workspace "$workspace"
	log "INFO" "APP" "$app uygulaması başlatılıyor (workspace: $workspace)"

	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "APP" "Kuru çalıştırma: $app başlatılacaktı"
		return 0
	fi

	local start_cmd="start-$app"
	if ! command -v "$start_cmd" &>/dev/null; then
		if command -v "$SEMSUMO" &>/dev/null; then
			start_cmd="$SEMSUMO $app"
		else
			log "ERROR" "APP" "$start_cmd komutu bulunamadı"
			return 1
		fi
	fi

	eval "$start_cmd" &
	sleep $WAIT_TIME

	if [[ "$fullscreen" == "true" ]]; then
		make_fullscreen
	fi

	log "SUCCESS" "APP" "$app uygulaması başlatıldı"
}

launch_terminal_session() {
	local session="$1"
	local config="${TERMINAL_SESSIONS[$session]}"

	if [[ -z "$config" ]]; then
		log "ERROR" "TERMINAL" "Terminal oturumu bulunamadı: $session"
		return 1
	fi

	local enabled=$(get_config_value "$config" "enabled")

	if [[ "$enabled" != "true" ]]; then
		log "INFO" "TERMINAL" "$session oturumu devre dışı"
		return 0
	fi

	if is_app_running "$session" "terminal"; then
		log "WARNING" "TERMINAL" "$session oturumu zaten çalışıyor"
		return 0
	fi

	log "INFO" "TERMINAL" "$session oturumu başlatılıyor"

	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "TERMINAL" "Kuru çalıştırma: $session başlatılacaktı"
		return 0
	fi

	local start_cmd="start-$session"
	if ! command -v "$start_cmd" &>/dev/null; then
		if command -v "$SEMSUMO" &>/dev/null; then
			start_cmd="$SEMSUMO $session"
		else
			log "ERROR" "TERMINAL" "$start_cmd komutu bulunamadı"
			return 1
		fi
	fi

	eval "$start_cmd" &
	log "SUCCESS" "TERMINAL" "$session oturumu başlatıldı"
}

#-------------------------------------------------------------------------------
# Ana İşlem Fonksiyonları
#-------------------------------------------------------------------------------

start_browser_profiles() {
	log "INFO" "BROWSER" "$BROWSER_TYPE profilleri başlatılıyor"

	if [[ -n "$SINGLE_PROFILE" ]]; then
		launch_browser_profile "$SINGLE_PROFILE"
		return $?
	fi

	# Sıralı profil başlatma
	local profile_order=("Kenp" "Ai" "CompecTA" "Whats")
	local profiles_var=$(get_browser_profiles)
	local -n profiles_ref=$profiles_var

	for profile in "${profile_order[@]}"; do
		if [[ -n "${profiles_ref[$profile]}" ]]; then
			launch_browser_profile "$profile"
		fi
	done

	log "SUCCESS" "BROWSER" "$BROWSER_TYPE profilleri başlatıldı"
}

start_applications() {
	log "INFO" "APP" "Uygulamalar başlatılıyor"

	# Browser uygulamaları
	local apps_var=$(get_browser_apps)
	local -n apps_ref=$apps_var
	for app in "${!apps_ref[@]}"; do
		launch_browser_app "$app"
	done

	# Semsumo uygulamaları
	for app in "${!SEMSUMO_APPS[@]}"; do
		launch_semsumo_app "$app"
	done

	log "SUCCESS" "APP" "Uygulamalar başlatıldı"
}

start_terminal_sessions() {
	log "INFO" "TERMINAL" "Terminal oturumları başlatılıyor"

	for session in "${!TERMINAL_SESSIONS[@]}"; do
		launch_terminal_session "$session"
	done

	log "SUCCESS" "TERMINAL" "Terminal oturumları başlatıldı"
}

#-------------------------------------------------------------------------------
# Parametre İşleme ve Ana Fonksiyon
#-------------------------------------------------------------------------------

print_usage() {
	echo "Kullanım: $SCRIPT_NAME [BROWSER] [SEÇENEKLER]"
	echo
	echo "Browser Seçimi:"
	echo "  brave                   Brave Browser kullan"
	echo "  zen                     Zen Browser kullan"
	echo
	echo "Seçenekler:"
	echo "  -t, --terminals         Sadece terminal oturumlarını başlat"
	echo "  -b, --browser           Sadece browser profillerini başlat"
	echo "  -a, --apps              Sadece uygulamaları başlat"
	echo "  -p, --profile PROFIL    Belirli bir browser profilini başlat"
	echo "  -w, --workspace NUMARA  Son workspace (varsayılan: $DEFAULT_FINAL_WORKSPACE)"
	echo "  -d, --debug             Hata ayıklama modu"
	echo "  -D, --dry-run           Test modu (hiçbir şey çalıştırma)"
	echo "  -h, --help              Bu yardım mesajı"
	echo
	echo "Örnek kullanım:"
	echo "  $SCRIPT_NAME brave                 # Brave ile tümünü başlat"
	echo "  $SCRIPT_NAME zen -t               # Zen ile sadece terminal oturumları"
	echo "  $SCRIPT_NAME brave -p Kenp        # Brave ile sadece Kenp profili"
	echo "  $SCRIPT_NAME zen -b -a            # Zen ile profiller ve uygulamalar"
	echo "  $SCRIPT_NAME brave -w 3           # Brave ile tümü + workspace 3'e dön"
	echo
	echo "Not: Browser belirtilmezse varsayılan olarak 'brave' kullanılır."
}

detect_browser_from_script_name() {
	# Script adından browser tipini çıkarmaya çalış
	case "$SCRIPT_NAME" in
	*brave*)
		echo "brave"
		;;
	*zen*)
		echo "zen"
		;;
	*)
		echo "brave" # Varsayılan
		;;
	esac
}

parse_args() {
	# İlk parametre browser tipi olabilir
	if [[ $# -gt 0 && ("$1" == "brave" || "$1" == "zen") ]]; then
		BROWSER_TYPE="$1"
		shift
	elif [[ $# -gt 0 && "$1" != "-"* ]]; then
		# İlk parametre seçenek değilse ve brave/zen değilse hata
		echo "Geçersiz browser türü: $1" >&2
		echo "Desteklenen browser türleri: brave, zen" >&2
		exit 1
	else
		# Browser belirtilmemişse script adından çıkarmaya çalış
		BROWSER_TYPE=$(detect_browser_from_script_name)
	fi

	while [[ $# -gt 0 ]]; do
		case "$1" in
		-t | --terminals)
			RUN_TERMINALS=true
			shift
			;;
		-b | --browser)
			RUN_BROWSER=true
			shift
			;;
		-a | --apps)
			RUN_APPS=true
			shift
			;;
		-p | --profile)
			SINGLE_PROFILE="$2"
			RUN_BROWSER=true
			shift 2
			;;
		-w | --workspace)
			FINAL_WORKSPACE="$2"
			shift 2
			;;
		-d | --debug)
			DEBUG_MODE=true
			shift
			;;
		-D | --dry-run)
			DRY_RUN=true
			shift
			;;
		-h | --help)
			print_usage
			exit 0
			;;
		*)
			echo "Bilinmeyen parametre: $1" >&2
			print_usage
			exit 1
			;;
		esac
	done

	# Hiçbir seçenek belirtilmemişse hepsini çalıştır
	if [[ "$RUN_TERMINALS" != "true" && "$RUN_BROWSER" != "true" && "$RUN_APPS" != "true" && -z "$SINGLE_PROFILE" ]]; then
		RUN_TERMINALS=true
		RUN_BROWSER=true
		RUN_APPS=true
	fi
}

main() {
	local start_time=$(date +%s)

	parse_args "$@"

	mkdir -p "$LOG_DIR"

	log "INFO" "START" "Multi-Browser Startup Manager v5.0 başlatılıyor ($BROWSER_TYPE)" "true"

	if [[ "$DRY_RUN" == "true" ]]; then
		log "INFO" "CONFIG" "Test modu - hiçbir uygulama başlatılmayacak" "true"
	fi

	# İşlemleri sırayla çalıştır
	[[ "$RUN_TERMINALS" == "true" ]] && start_terminal_sessions
	[[ "$RUN_BROWSER" == "true" ]] && start_browser_profiles
	[[ "$RUN_APPS" == "true" ]] && start_applications

	# Son workspace'e dön
	if [[ -n "$FINAL_WORKSPACE" ]]; then
		log "INFO" "WORKSPACE" "Workspace $FINAL_WORKSPACE'e dönülüyor"
		switch_workspace "$FINAL_WORKSPACE"
	fi

	local end_time=$(date +%s)
	local total_time=$((end_time - start_time))

	log "SUCCESS" "DONE" "Tüm işlemler tamamlandı ($BROWSER_TYPE) - Süre: ${total_time}s" "true"
}

main "$@"
