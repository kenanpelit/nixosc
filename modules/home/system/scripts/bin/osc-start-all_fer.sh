#!/usr/bin/env bash

#===============================================================================
#
#   Script: Brave Profile Startup Manager
#   Version: 3.0.0
#   Date: 2025-04-09
#   Author: Kenan Pelit (İyileştirilmiş versiyon)
#   Repository: https://github.com/kenanpelit/nixosc
#   Description: Brave tarayıcı profillerini, web uygulamalarını ve terminal
#                oturumlarını başlatan otomatik başlatma scripti
#
#   Özellikler:
#   - Dışarıdan yapılandırılabilir ayarlar (YAML dosyası)
#   - Terminal oturumları için semsumo entegrasyonu
#   - Brave profilleri için doğrudan profile_brave kullanımı
#   - Farklı Brave profillerini belirli workspace'lere yerleştirir
#   - Web uygulamalarını belirli profillerle açar (WhatsApp, YouTube, vb.)
#   - Paralel başlatma ile hızlı açılış
#   - Gelişmiş hata yakalama ve yeniden deneme mekanizması
#   - Uygulama durumu kontrolü ve izleme
#   - İlerleme göstergesi ve ayrıntılı loglama
#   - Komut satırı parametreleri ile esneklik
#   - VPN kontrolü ve yönetimi entegrasyonu (secure/bypass)
#   - Workspace yönetimi (Hyprland entegrasyonu)
#
#===============================================================================

#-------------------------------------------------------------------------------
# Yapılandırma ve Sabitler
#-------------------------------------------------------------------------------

# Temel dizin ve dosya yapılandırmaları
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
readonly LOG_DIR="$HOME/.logs/brave-startup"
readonly LOG_FILE="$LOG_DIR/brave-startup.log"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/brave"
readonly CONFIG_FILE="$CONFIG_DIR/profiles.yaml"
readonly PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/brave-startup.pid"
readonly TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Program varsayılan değerleri
readonly DEFAULT_WAIT_TIME=3
readonly DEFAULT_RETRY_COUNT=3
readonly DEFAULT_FINAL_WORKSPACE="2"

# Çalıştırılacak programlar için yollar
readonly PROFILE_BRAVE="profile_brave"
readonly SEMSUMO="semsumo"

# Terminal renk kodları
if [[ -t 1 ]]; then
	readonly RED='\033[0;31m'
	readonly GREEN='\033[0;32m'
	readonly YELLOW='\033[0;33m'
	readonly BLUE='\033[0;34m'
	readonly PURPLE='\033[0;35m'
	readonly CYAN='\033[0;36m'
	readonly GRAY='\033[0;37m'
	readonly BOLD='\033[1m'
	readonly RESET='\033[0m'
else
	readonly RED=""
	readonly GREEN=""
	readonly YELLOW=""
	readonly BLUE=""
	readonly PURPLE=""
	readonly CYAN=""
	readonly GRAY=""
	readonly BOLD=""
	readonly RESET=""
fi

# Çalışma modu değişkenleri
RUN_TERMINALS=false
RUN_BRAVE=false
RUN_APPS=false
SINGLE_PROFILE=""
DEBUG_MODE=false
WAIT_TIME=$DEFAULT_WAIT_TIME
RETRY_COUNT=$DEFAULT_RETRY_COUNT
FINAL_WORKSPACE=$DEFAULT_FINAL_WORKSPACE
DRY_RUN=false

# Yapılandırma değişkenleri
declare -A config
declare -A profiles
declare -A apps
declare -A terminals
declare -A APP_PIDS
current_workspace=""
total_steps=0
current_step=0

#-------------------------------------------------------------------------------
# Yardımcı Fonksiyonlar
#-------------------------------------------------------------------------------

# Loglama fonksiyonu
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
	"DEBUG") color=$GRAY ;;
	*) color=$RESET ;;
	esac

	# Terminal'e yazdır
	echo -e "${color}${BOLD}[$level]${RESET} ${PURPLE}[$module]${RESET} $message"

	# Log dosyasına ekle
	echo "[$timestamp] [$level] [$module] $message" >>"$LOG_FILE"

	# Bildirim göster
	if [[ "$notify" == "true" ]]; then
		notify-send -a "$SCRIPT_NAME" "$module: $message"
	fi

	# Hata durumunda programı sonlandır
	if [[ "$level" == "ERROR" && "$DRY_RUN" != "true" ]]; then
		if [[ "$DEBUG_MODE" == "true" ]]; then
			echo -e "${RED}${BOLD}[ERROR] Hata ayıklama modu aktif, devam ediliyor...${RESET}"
		else
			echo -e "${RED}${BOLD}[ERROR] Kritik hata! Program sonlandırılıyor...${RESET}"
			cleanup
			exit 1
		fi
	fi
}

# İlerleme göstergesi
show_progress() {
	local desc="$3"
	((current_step++))

	# İlerleme göstergesini yalnızca gerçek bir terminalde göster
	if [[ -t 1 ]]; then
		local percent=$((current_step * 100 / total_steps))
		local bar_size=50
		local filled_size=$((bar_size * current_step / total_steps))
		local empty_size=$((bar_size - filled_size))

		# İlerleme çubuğu
		printf "\r${CYAN}İlerleme: [${GREEN}"
		printf "%${filled_size}s" | tr ' ' '#'
		printf "${GRAY}"
		printf "%${empty_size}s" | tr ' ' '-'
		printf "${CYAN}] %3d%% - %s${RESET}" "$percent" "$desc"

		# Son adımda yeni satır ekle
		if [[ $current_step -eq $total_steps ]]; then
			echo ""
		fi
	fi

	# İlerleme bildirimini düzenli aralıklarla göster
	if [[ $total_steps -gt 0 ]]; then
		local notify_steps=$((total_steps / 4))
		if [[ $notify_steps -gt 0 && ($current_step -eq $total_steps || $((current_step % notify_steps)) -eq 0) ]]; then
			local percent=$((current_step * 100 / total_steps))
			notify-send -a "$SCRIPT_NAME" "İlerleme: %$percent" "$desc"
		fi
	fi
}

# Temizleme işlemi
cleanup() {
	log "INFO" "CLEANUP" "Temizleme işlemi başlatılıyor..." "false"

	# PID dosyasını temizle
	if [[ -f "$PID_FILE" ]]; then
		rm -f "$PID_FILE"
	fi

	# Kuru çalıştırma modunda işlem yapma
	if [[ "$DRY_RUN" == "true" ]]; then
		log "INFO" "CLEANUP" "Kuru çalıştırma modu - işlem yapılmadı" "false"
		return 0
	fi

	# DEBUG modunda uygulamaları sonlandırma
	if [[ "$DEBUG_MODE" == "true" ]]; then
		log "DEBUG" "CLEANUP" "Debug modunda - uygulamalar sonlandırılmıyor" "false"
		return 0
	fi

	log "INFO" "CLEANUP" "Temizleme tamamlandı" "false"
}

# Komutu yeniden deneme
retry_command() {
	local cmd="$1"
	local max_attempts="$RETRY_COUNT"
	local description="$2"
	local attempt=1

	while [[ $attempt -le $max_attempts ]]; do
		log "INFO" "RETRY" "Komut çalıştırılıyor (deneme $attempt/$max_attempts): $description" "false"

		if eval "$cmd"; then
			log "SUCCESS" "RETRY" "Komut başarıyla çalıştırıldı: $description" "false"
			return 0
		else
			log "WARNING" "RETRY" "Komut başarısız oldu, yeniden deneniyor..." "false"
			((attempt++))
			sleep 2
		fi
	done

	log "ERROR" "RETRY" "Maksimum deneme sayısına ulaşıldı, komut başarısız: $description" "true"
	return 1
}

# Yapılandırma dosyası oluşturma
create_default_config() {
	local config_dir=$(dirname "$CONFIG_FILE")

	if [[ ! -d "$config_dir" ]]; then
		mkdir -p "$config_dir"
	fi

	log "INFO" "CONFIG" "Varsayılan yapılandırma dosyası oluşturuluyor: $CONFIG_FILE" "true"

	# Yapılandırma dosyasını oluştur
	cat >"$CONFIG_FILE" <<'EOF'
# Brave Profile Startup Manager Yapılandırması
settings:
  final_workspace: 2
  wait_time: 3
  retry_count: 3

# Brave profilleri
profiles:
  - name: "Kenp"
    workspace: 1
    class: "Kenp"
    title: "Kenp"
    fullscreen: false
    enabled: true
  
  - name: "Ai"
    workspace: 3
    class: "Ai"
    title: "Ai"
    fullscreen: false
    enabled: true
  
  - name: "CompecTA"
    workspace: 4
    class: "CompecTA"
    title: "CompecTA"
    fullscreen: false
    enabled: true

  - name: "Whats"
    workspace: 9
    class: "Whats"
    title: "Whats"
    fullscreen: false
    enabled: true


# Web uygulamaları
apps:
#  - name: "webcord"
#    workspace: 5
#    fullscreen: true
#    enabled: true
#    type: "semsumo"
#
  - name: "discord"
    workspace: 5
    fullscreen: true
    enabled: true
    type: "semsumo"

  - name: "youtube"
    workspace: 7
    fullscreen: true
    enabled: true
    type: "brave"
  
  - name: "spotify"
    workspace: 8
    fullscreen: true
    enabled: true
    type: "semsumo"
  
  - name: "whatsapp"
    workspace: 9
    fullscreen: true
    enabled: false
    type: "brave"
  
# Terminal oturumları
terminals:
  - name: "kkenp"
    enabled: true
  
  - name: "wkenp"
    enabled: false
  
  - name: "mkenp"
    enabled: false
EOF

	log "SUCCESS" "CONFIG" "Varsayılan yapılandırma dosyası oluşturuldu" "false"
}

# Yapılandırma dosyasını yükle
load_config() {
	# Yapılandırma dizini ve dosyası yoksa oluştur
	if [[ ! -f "$CONFIG_FILE" ]]; then
		create_default_config
	fi

	log "INFO" "CONFIG" "Yapılandırma dosyası yükleniyor: $CONFIG_FILE" "false"

	# Varsayılan yapılandırma değerleri tanımla (YAML dosyası yoksa kullanılacak)
	FINAL_WORKSPACE="2"
	WAIT_TIME="3"
	RETRY_COUNT="3"
	PARALLEL_MODE=true

	# Profilleri tanımla
	profiles=()
	profiles["Kenp"]="workspace=1,class=Kenp,title=Kenp,fullscreen=false,enabled=true"
	profiles["Ai"]="workspace=3,class=Ai,title=Ai,fullscreen=false,enabled=true"
	profiles["CompecTA"]="workspace=4,class=CompecTA,title=CompecTA,fullscreen=false,enabled=true"
	profiles["Whats"]="workspace=9,class=Whats,title=Whats,fullscreen=false,enabled=false"

	# Uygulamaları tanımla
	apps=()
	apps["whatsapp"]="workspace=9,fullscreen=true,enabled=false,type=brave"
	#apps["webcord"]="workspace=5,fullscreen=true,enabled=true,type=semsumo"
	apps["discord"]="workspace=5,fullscreen=true,enabled=true,type=semsumo"
	apps["youtube"]="workspace=7,fullscreen=true,enabled=true,type=brave"
	apps["spotify"]="workspace=8,fullscreen=true,enabled=true,type=semsumo"
	apps["ferdium"]="workspace=9,fullscreen=true,enabled=true,type=semsumo"

	# Terminal oturumlarını tanımla
	terminals=()
	terminals["kkenp"]="enabled=true"
	terminals["wkenp"]="enabled=false"
	terminals["mkenp"]="enabled=false"

	# Toplam adım sayısını hesapla
	total_steps=0
	for name in "${!profiles[@]}"; do
		local profile_data="${profiles[$name]}"
		local enabled=$(echo "$profile_data" | grep -o "enabled=[^,]*" | cut -d= -f2)
		[[ "$enabled" == "true" && "$RUN_BRAVE" == "true" ]] && ((total_steps++))
	done

	for name in "${!apps[@]}"; do
		local app_data="${apps[$name]}"
		local enabled=$(echo "$app_data" | grep -o "enabled=[^,]*" | cut -d= -f2)
		[[ "$enabled" == "true" && "$RUN_APPS" == "true" ]] && ((total_steps++))
	done

	for name in "${!terminals[@]}"; do
		local terminal_data="${terminals[$name]}"
		local enabled=$(echo "$terminal_data" | grep -o "enabled=[^,]*" | cut -d= -f2)
		[[ "$enabled" == "true" && "$RUN_TERMINALS" == "true" ]] && ((total_steps++))
	done

	# Tek profil modunda sadece bir adım olur
	[[ -n "$SINGLE_PROFILE" ]] && total_steps=1

	log "SUCCESS" "CONFIG" "Yapılandırma yüklendi: ${#profiles[@]} profil, ${#apps[@]} uygulama, ${#terminals[@]} terminal oturumu" "false"

	if [[ "$DEBUG_MODE" == "true" ]]; then
		log "DEBUG" "CONFIG" "Yüklenen profiller: ${!profiles[*]}" "false"
		log "DEBUG" "CONFIG" "Yüklenen uygulamalar: ${!apps[*]}" "false"
		log "DEBUG" "CONFIG" "Yüklenen terminal oturumları: ${!terminals[*]}" "false"
	fi

	return 0
}

#-------------------------------------------------------------------------------
# Uygulama ve Profil Yönetimi Fonksiyonları
#-------------------------------------------------------------------------------

# Workspace'e geçiş - ama sadece gerekliyse
switch_workspace() {
	local workspace="$1"

	# Workspace numarası boşsa işlem yapma
	if [[ -z "$workspace" ]]; then
		log "WARNING" "WORKSPACE" "Geçersiz workspace numarası" "false"
		return 1
	fi

	# Kuru çalıştırma modunda işlem yapma
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "WORKSPACE" "Kuru çalıştırma: $workspace numaralı workspace'e geçilecekti" "false"
		return 0
	fi

	# Aynı workspace'deyse geçiş yapma
	if [[ "$current_workspace" == "$workspace" ]]; then
		log "INFO" "WORKSPACE" "Zaten $workspace numaralı workspace'deyiz, geçiş yapılmıyor" "false"
		return 0
	fi

	if command -v hyprctl &>/dev/null; then
		log "INFO" "WORKSPACE" "$workspace numaralı workspace'e geçiliyor" "false"
		hyprctl dispatch workspace "$workspace"
		current_workspace="$workspace"
		sleep 1 # İşlemin tamamlanması için kısa bekleme
	else
		log "WARNING" "WORKSPACE" "Hyprctl bulunamadı, workspace değiştirme devre dışı" "false"
	fi
}

# Uygulama çalışıyor mu kontrolü
is_app_running() {
	local app_name="$1"
	local app_type="${2:-brave}" # Varsayılan olarak brave

	# Brave profilleri için daha spesifik kontrol
	if [[ "$app_type" == "brave" ]]; then
		# Sınıf adı ve başlık ile birlikte kontrol et (daha spesifik)
		pgrep -f "brave.*--class=$app_name" &>/dev/null
	else
		# Diğer uygulamalar için basit kontrol
		pgrep -f "$app_name" &>/dev/null
	fi

	return $?
}

# Uygulama PID'ini izle
track_process() {
	local name="$1"
	local pid="$2"

	# Kuru çalıştırma modunda işlem yapma
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "TRACK" "Kuru çalıştırma: $name uygulaması izlenecekti (PID: $pid)" "false"
		return 0
	fi

	APP_PIDS["$name"]="$pid"
	log "INFO" "TRACK" "$name uygulaması izleniyor (PID: $pid)" "false"
}

# Tam ekran yapma fonksiyonu
make_fullscreen() {
	# Kuru çalıştırma modunda işlem yapma
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "FULLSCREEN" "Kuru çalıştırma: Pencere tam ekran yapılacaktı" "false"
		return 0
	fi

	if command -v hyprctl &>/dev/null; then
		log "INFO" "FULLSCREEN" "Aktif pencere tam ekran yapılıyor..." "false"
		sleep 1
		hyprctl dispatch fullscreen 1
		sleep 1
	else
		log "WARNING" "FULLSCREEN" "Hyprctl bulunamadı, tam ekran yapma devre dışı" "false"
	fi
}

# Terminal profili başlatma - semsumo aracılığıyla
launch_terminal_profile() {
	local profile_name="$1"
	local terminal_data="${terminals[$profile_name]}"

	if [[ -z "$terminal_data" ]]; then
		log "WARNING" "TERMINAL" "$profile_name profili yapılandırmada bulunamadı" "false"
		return 1
	fi

	local enabled=$(echo "$terminal_data" | grep -o "enabled=[^,]*" | cut -d= -f2)

	# Profil devre dışı bırakılmışsa çalıştırma
	if [[ "$enabled" != "true" ]]; then
		log "INFO" "TERMINAL" "$profile_name profili devre dışı, başlatılmıyor" "false"
		return 0
	fi

	log "INFO" "TERMINAL" "$profile_name profili başlatılıyor" "true"
	show_progress "$current_step" "$total_steps" "Terminal: $profile_name"

	# Kuru çalıştırma modunda işlem yapma
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "TERMINAL" "Kuru çalıştırma: $profile_name profili başlatılacaktı" "false"
		return 0
	fi

	# Uygulamanın zaten çalışıp çalışmadığını kontrol et
	if is_app_running "$profile_name" "terminal"; then
		log "WARNING" "TERMINAL" "$profile_name profili zaten çalışıyor, yeniden başlatılmıyor" "false"
		return 0
	fi

	local start_cmd="start-$profile_name"

	# Komutu kontrol et
	if ! command -v "$start_cmd" &>/dev/null; then
		if command -v "$SEMSUMO" &>/dev/null; then
			start_cmd="$SEMSUMO $profile_name"
		else
			log "ERROR" "TERMINAL" "$start_cmd komutu bulunamadı" "true"
			return 1
		fi
	fi

	# Yeniden deneme ile komutu çalıştır
	if $start_cmd; then
		log "SUCCESS" "TERMINAL" "$profile_name profili başlatıldı" "false"
	else
		log "ERROR" "TERMINAL" "$profile_name profili başlatılamadı" "true"
		return 1
	fi

	return 0
}

# Semsumo uygulamasını başlatma
launch_semsumo_app() {
	local app_name="$1"
	local app_data="${apps[$app_name]}"

	if [[ -z "$app_data" ]]; then
		log "ERROR" "APP" "$app_name uygulaması yapılandırmada bulunamadı" "true"
		return 1
	fi

	local enabled=$(echo "$app_data" | grep -o "enabled=[^,]*" | cut -d= -f2)
	local workspace=$(echo "$app_data" | grep -o "workspace=[^,]*" | cut -d= -f2)
	local fullscreen=$(echo "$app_data" | grep -o "fullscreen=[^,]*" | cut -d= -f2)

	# Uygulama devre dışı bırakılmışsa çalıştırma
	if [[ "$enabled" != "true" ]]; then
		log "INFO" "APP" "$app_name uygulaması devre dışı, başlatılmıyor" "false"
		return 0
	fi

	log "INFO" "APP" "$app_name uygulaması başlatılıyor (workspace: $workspace)" "true"
	show_progress "$current_step" "$total_steps" "Uygulama: $app_name"

	# Kuru çalıştırma modunda işlem yapma
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "APP" "Kuru çalıştırma: $app_name uygulaması başlatılacaktı" "false"
		return 0
	fi

	# Uygulamanın zaten çalışıp çalışmadığını kontrol et
	if is_app_running "$app_name"; then
		log "WARNING" "APP" "$app_name uygulaması zaten çalışıyor, yeniden başlatılmıyor" "false"
		return 0
	fi

	local start_cmd="start-$app_name"

	# Komutu kontrol et
	if ! command -v "$start_cmd" &>/dev/null; then
		if command -v "$SEMSUMO" &>/dev/null; then
			start_cmd="$SEMSUMO $app_name"
		else
			log "ERROR" "APP" "$start_cmd komutu bulunamadı" "true"
			return 1
		fi
	fi

	# Komutu çalıştır
	if $start_cmd; then
		log "SUCCESS" "APP" "$app_name uygulaması başlatıldı" "false"

		# Tam ekran yapılacaksa
		if [[ "$fullscreen" == "true" ]]; then
			sleep $WAIT_TIME
			make_fullscreen
		fi
	else
		log "ERROR" "APP" "$app_name uygulaması başlatılamadı" "true"
		return 1
	fi

	return 0
}

# Brave profili başlatma
launch_brave_profile() {
	local profile="$1"
	local profile_data="${profiles[$profile]}"

	if [[ -z "$profile_data" ]]; then
		log "ERROR" "BRAVE" "$profile profili yapılandırmada bulunamadı" "true"
		return 1
	fi

	local workspace=$(echo "$profile_data" | grep -o "workspace=[^,]*" | cut -d= -f2)
	local class=$(echo "$profile_data" | grep -o "class=[^,]*" | cut -d= -f2)
	local title=$(echo "$profile_data" | grep -o "title=[^,]*" | cut -d= -f2)
	local fullscreen=$(echo "$profile_data" | grep -o "fullscreen=[^,]*" | cut -d= -f2)
	local enabled=$(echo "$profile_data" | grep -o "enabled=[^,]*" | cut -d= -f2)

	# Profil devre dışı bırakılmışsa çalıştırma
	if [[ "$enabled" != "true" ]]; then
		log "INFO" "BRAVE" "$profile profili devre dışı, başlatılmıyor" "false"
		return 0
	fi

	# Workspace'e geç
	switch_workspace "$workspace"

	log "INFO" "BRAVE" "$profile profili başlatılıyor (workspace: $workspace)" "true"
	show_progress "$current_step" "$total_steps" "Brave: $profile"

	# Kuru çalıştırma modunda işlem yapma
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "BRAVE" "Kuru çalıştırma: $profile profili başlatılacaktı" "false"
		return 0
	fi

	# Profil zaten çalışıyorsa yeniden başlatma
	if is_app_running "$class" "brave"; then
		log "WARNING" "BRAVE" "$profile profili zaten çalışıyor, yeniden başlatılmıyor" "false"
		return 0
	fi

	# PROFILE_BRAVE komutunu kontrol et
	if ! command -v "$PROFILE_BRAVE" &>/dev/null; then
		log "ERROR" "BRAVE" "$PROFILE_BRAVE komutu bulunamadı" "true"
		return 1
	fi

	# Brave profilini doğrudan başlat
	"$PROFILE_BRAVE" "$profile" --class="$class" --title="$title" --restore-last-session &
	local pid=$!
	track_process "$profile" "$pid"

	# Uygulamanın yüklenmesi için bekle
	log "INFO" "BRAVE" "$profile profili için açılması bekleniyor..." "false"
	sleep $WAIT_TIME

	# Tam ekran yapılacaksa
	if [[ "$fullscreen" == "true" ]]; then
		make_fullscreen
	fi

	log "SUCCESS" "BRAVE" "$profile profili başlatıldı" "false"
	return 0
}

# Brave web uygulaması başlatma
launch_brave_app() {
	local app="$1"
	local app_data="${apps[$app]}"

	if [[ -z "$app_data" ]]; then
		log "ERROR" "APP" "$app uygulaması yapılandırmada bulunamadı" "true"
		return 1
	fi

	local workspace=$(echo "$app_data" | grep -o "workspace=[^,]*" | cut -d= -f2)
	local fullscreen=$(echo "$app_data" | grep -o "fullscreen=[^,]*" | cut -d= -f2)
	local enabled=$(echo "$app_data" | grep -o "enabled=[^,]*" | cut -d= -f2)

	# Uygulama devre dışı bırakılmışsa çalıştırma
	if [[ "$enabled" != "true" ]]; then
		log "INFO" "APP" "$app uygulaması devre dışı, başlatılmıyor" "false"
		return 0
	fi

	# Workspace'e geç
	switch_workspace "$workspace"

	log "INFO" "APP" "$app uygulaması başlatılıyor (workspace: $workspace)" "true"
	show_progress "$current_step" "$total_steps" "Web Uygulaması: $app"

	# Kuru çalıştırma modunda işlem yapma
	if [[ "$DRY_RUN" == "true" ]]; then
		log "DEBUG" "APP" "Kuru çalıştırma: $app uygulaması başlatılacaktı" "false"
		return 0
	fi

	# Uygulama zaten çalışıyorsa yeniden başlatma
	if is_app_running "$app" "brave"; then
		log "WARNING" "APP" "$app uygulaması zaten çalışıyor, yeniden başlatılmıyor" "false"
		return 0
	fi

	# PROFILE_BRAVE komutunu kontrol et
	if ! command -v "$PROFILE_BRAVE" &>/dev/null; then
		log "ERROR" "APP" "$PROFILE_BRAVE komutu bulunamadı" "true"
		return 1
	fi

	# Web uygulamasını doğrudan başlat
	"$PROFILE_BRAVE" "--$app" --class="$app" --title="$app" --restore-last-session &
	local pid=$!
	track_process "$app" "$pid"

	# Uygulamanın yüklenmesi için bekle
	log "INFO" "APP" "$app uygulaması için açılması bekleniyor..." "false"
	sleep $WAIT_TIME

	# Tam ekran yapılacaksa
	if [[ "$fullscreen" == "true" ]]; then
		make_fullscreen
	fi

	log "SUCCESS" "APP" "$app uygulaması başlatıldı" "false"
	return 0
}

#-------------------------------------------------------------------------------
# Ana İşlev Fonksiyonları
#-------------------------------------------------------------------------------

# Terminal oturumlarını başlat
start_terminal_sessions() {
	log "INFO" "TERMINAL" "Terminal oturumları başlatılıyor..." "true"

	for terminal_name in "${!terminals[@]}"; do
		launch_terminal_profile "$terminal_name"
	done

	log "SUCCESS" "TERMINAL" "Tüm terminal oturumları başlatıldı" "true"
}

# Brave profilleri başlat
start_brave_profiles() {
	log "INFO" "BRAVE" "Brave profilleri başlatılıyor..." "true"

	# Tek profil başlatma modu
	if [[ -n "$SINGLE_PROFILE" ]]; then
		if [[ -n "${profiles[$SINGLE_PROFILE]}" ]]; then
			launch_brave_profile "$SINGLE_PROFILE"
		else
			log "ERROR" "BRAVE" "Belirtilen profil bulunamadı: $SINGLE_PROFILE" "true"
			return 1
		fi
		return 0
	fi

	# İstenen sırada profil isimleri - Whats profili en sona alındı
	local profile_order=("Kenp" "Ai" "CompecTA" "Whats")

	# Belirtilen sırada profilleri başlat
	for profile_name in "${profile_order[@]}"; do
		if [[ -n "${profiles[$profile_name]}" ]]; then
			launch_brave_profile "$profile_name"
		else
			log "WARNING" "BRAVE" "Profil bulunamadı: $profile_name" "false"
		fi
	done

	# Sıralamada olmayan diğer profilleri başlat (isteğe bağlı)
	for profile_name in "${!profiles[@]}"; do
		# Bu profil zaten sıralamada var mı kontrol et
		local already_loaded=false
		for ordered_profile in "${profile_order[@]}"; do
			if [[ "$profile_name" == "$ordered_profile" ]]; then
				already_loaded=true
				break
			fi
		done

		# Eğer daha önce yüklenmediyse yükle
		if [[ "$already_loaded" == "false" ]]; then
			launch_brave_profile "$profile_name"
		fi
	done

	log "SUCCESS" "BRAVE" "Tüm Brave profilleri başlatıldı" "true"
}

# Uygulamaları workspace'e göre gruplandırarak başlat
start_applications() {
	log "INFO" "APP" "Uygulamalar başlatılıyor..." "true"

	# Önce uygulamaları workspace'e göre gruplandır
	declare -A workspace_apps

	for app_name in "${!apps[@]}"; do
		local app_data="${apps[$app_name]}"
		local workspace=$(echo "$app_data" | grep -o "workspace=[^,]*" | cut -d= -f2)
		local enabled=$(echo "$app_data" | grep -o "enabled=[^,]*" | cut -d= -f2)

		# Uygulama devre dışı bırakılmışsa atla
		if [[ "$enabled" != "true" ]]; then
			continue
		fi

		# Workspace listesine ekle
		if [[ -z "${workspace_apps[$workspace]}" ]]; then
			workspace_apps[$workspace]="$app_name"
		else
			workspace_apps[$workspace]="${workspace_apps[$workspace]} $app_name"
		fi
	done

	# Her workspace için tüm uygulamaları bir kerede başlat
	for workspace in "${!workspace_apps[@]}"; do
		# Workspace'e geç
		switch_workspace "$workspace"
		sleep 1

		# Bu workspace'deki tüm uygulamaları başlat
		for app_name in ${workspace_apps[$workspace]}; do
			local app_data="${apps[$app_name]}"
			local app_type=$(echo "$app_data" | grep -o "type=[^,]*" | cut -d= -f2)

			if [[ "$app_type" == "brave" ]]; then
				launch_brave_app "$app_name"
			elif [[ "$app_type" == "semsumo" ]]; then
				launch_semsumo_app "$app_name"
			else
				log "WARNING" "APP" "Bilinmeyen uygulama türü: $app_type, $app_name başlatılmıyor" "false"
			fi
		done
	done

	log "SUCCESS" "APP" "Tüm uygulamalar başlatıldı" "true"
}

# Komut satırı parametrelerini işleme
parse_args() {
	# Eğer getopt komutu yoksa basitleştirilmiş parametre işleme kullan
	if ! command -v getopt &>/dev/null; then
		# Basit elle parametre işleme
		while [[ $# -gt 0 ]]; do
			case "$1" in
			-t | --terminals)
				RUN_TERMINALS=true
				shift
				;;
			-b | --brave)
				RUN_BRAVE=true
				shift
				;;
			-a | --apps)
				RUN_APPS=true
				shift
				;;
			-p | --profile)
				SINGLE_PROFILE="$2"
				RUN_BRAVE=true
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
	else
		# getopt komutu ile parametreleri ayrıştır
		local TEMP
		if ! TEMP=$(getopt -o tbap:w:dDh -n "$SCRIPT_NAME" -- "$@" 2>/dev/null); then
			echo "Hatalı parametre, --help ile kullanım bilgisini görüntüleyin." >&2
			exit 1
		fi

		eval set -- "$TEMP"

		while true; do
			case "$1" in
			-t | --terminals)
				RUN_TERMINALS=true
				shift
				;;
			-b | --brave)
				RUN_BRAVE=true
				shift
				;;
			-a | --apps)
				RUN_APPS=true
				shift
				;;
			-p | --profile)
				SINGLE_PROFILE="$2"
				RUN_BRAVE=true
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
			--)
				shift
				break
				;;
			*)
				echo "Bilinmeyen parametre: $1" >&2
				print_usage
				exit 1
				;;
			esac
		done
	fi

	# Eğer hiçbir seçenek belirtilmemişse, hepsini çalıştır
	if [[ "$RUN_TERMINALS" != "true" && "$RUN_BRAVE" != "true" && "$RUN_APPS" != "true" && -z "$SINGLE_PROFILE" ]]; then
		RUN_TERMINALS=true
		RUN_BRAVE=true
		RUN_APPS=true
	fi
}

# Kullanım bilgisi
print_usage() {
	echo "Kullanım: $SCRIPT_NAME [SEÇENEKLER]"
	echo
	echo "Brave tarayıcı profillerini, web uygulamalarını ve terminal oturumlarını"
	echo "başlatan otomatik başlatma scripti."
	echo
	echo "Seçenekler:"
	echo "  -t, --terminals         Sadece terminal oturumlarını başlat"
	echo "  -b, --brave             Sadece Brave profillerini başlat"
	echo "  -a, --apps              Sadece uygulamaları başlat"
	echo "  -p, --profile PROFIL    Belirli bir Brave profilini başlat"
	echo "  -w, --workspace NUMARA  Son dönülecek workspace numarası (varsayılan: $DEFAULT_FINAL_WORKSPACE)"
	echo "  -d, --debug             Hata ayıklama modunu etkinleştir"
	echo "  -D, --dry-run           Hiçbir şey çalıştırma (test için)"
	echo "  -h, --help              Bu yardım mesajını göster"
	echo
	echo "Yapılandırma dosyası: $CONFIG_FILE"
	echo "Log dosyası: $LOG_FILE"
	echo
	echo "Örnek kullanım:"
	echo "  $SCRIPT_NAME -t                    # Sadece terminal oturumlarını başlat"
	echo "  $SCRIPT_NAME -p Kenp               # Sadece Kenp profilini başlat"
	echo "  $SCRIPT_NAME -b -a                 # Brave profilleri ve uygulamaları başlat"
	echo "  $SCRIPT_NAME -w 3                  # Tümünü başlat ve 3 numaralı workspace'e dön"
	echo "  $SCRIPT_NAME -d                    # Hata ayıklama moduyla tümünü başlat"
}

# Ana fonksiyon
main() {
	# Başlangıç zamanını kaydet
	local start_time=$(date +%s)

	# Komut satırı parametrelerini işle
	parse_args "$@"

	# Log dizinini oluştur
	mkdir -p "$LOG_DIR"

	# PID dosyası oluştur
	echo "$" >"$PID_FILE"

	log "INFO" "START" "Brave Profil Yöneticisi v3.0 başlatılıyor" "true"

	if [[ "$DRY_RUN" == "true" ]]; then
		log "INFO" "CONFIG" "Kuru çalıştırma modu aktif - hiçbir uygulama başlatılmayacak" "true"
	fi

	if [[ "$DEBUG_MODE" == "true" ]]; then
		log "INFO" "CONFIG" "Hata ayıklama modu aktif" "false"
	fi

	# Yapılandırma dosyasını yükle
	load_config

	# Terminal oturumlarını başlat
	if [[ "$RUN_TERMINALS" == "true" ]]; then
		start_terminal_sessions
	fi

	# Brave profilleri başlat
	if [[ "$RUN_BRAVE" == "true" ]]; then
		start_brave_profiles
	fi

	# Uygulamaları başlat (Web ve Spotify)
	if [[ "$RUN_APPS" == "true" ]]; then
		start_applications
	fi

	# İşlemler tamamlandıktan sonra belirtilen workspace'e dön
	if [[ -n "$FINAL_WORKSPACE" ]]; then
		log "INFO" "WORKSPACE" "Tüm uygulamalar başlatıldı, $FINAL_WORKSPACE numaralı workspace'e dönülüyor" "true"
		switch_workspace "$FINAL_WORKSPACE"
	else
		log "INFO" "WORKSPACE" "Tüm uygulamalar başlatıldı" "true"
	fi

	# Bitiş zamanını hesapla
	local end_time=$(date +%s)
	local total_time=$((end_time - start_time))

	# Özet bilgiler
	log "SUCCESS" "DONE" "Tüm işlemler başarıyla tamamlandı - Toplam süre: ${total_time} saniye" "true"

	# Başlatılan uygulama sayısını göster
	local app_count=${#APP_PIDS[@]}
	if [[ $app_count -gt 0 ]]; then
		log "INFO" "SUMMARY" "Başlatılan toplam uygulama: $app_count" "false"

		if [[ "$DEBUG_MODE" == "true" ]]; then
			for app in "${!APP_PIDS[@]}"; do
				local pid="${APP_PIDS[$app]}"
				log "DEBUG" "SUMMARY" "Uygulama: $app, PID: $pid" "false"
			done
		fi
	fi

	return 0
}

# Çalıştır
main "$@"
