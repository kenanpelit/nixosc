#!/usr/bin/env bash

# ==============================================================================
# NixOS Installation Script - Balanced Optimization
# Author: kenanpelit
# Version: 2.4.1 (Balanced)
# ==============================================================================

VERSION="2.4.1"
SCRIPT_NAME=$(basename "$0")

# Sistem Konfigürasyonu
CURRENT_USERNAME='kenan'
DEFAULT_USERNAME='kenan'
CONFIG_DIR="$HOME/.config/nixos"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
BUILD_CORES=$(nproc)
NIX_CONF_DIR="$HOME/.config/nix"
NIX_CONF_FILE="$NIX_CONF_DIR/nix.conf"
BACKUP_DIR="$HOME/.nixosb"
FLAKE_LOCK="flake.lock"
LOG_FILE="$BACKUP_DIR/nixos-install.log"

# Önbellekleme
CACHE_DIR="$HOME/.nixos-cache"
CACHE_ENABLED=true
CACHE_EXPIRY=604800 # 7 gün
MAX_CACHE_SIZE=5120 # 5GB

# Flagler
DEBUG=false
SILENT=false
AUTO=false
UPDATE_FLAKE=false
UPDATE_MODULE=""
BACKUP_ONLY=false
PROFILE_NAME=""
PRE_INSTALL=false

# ==============================================================================
# Terminal Renkleri
# ==============================================================================
init_colors() {
	if [[ -t 1 ]]; then
		NORMAL=$(tput sgr0)
		RED=$(tput setaf 1)
		GREEN=$(tput setaf 2)
		YELLOW=$(tput setaf 3)
		BLUE=$(tput setaf 4)
		MAGENTA=$(tput setaf 5)
		CYAN=$(tput setaf 6)
		BRIGHT=$(tput bold)
	else
		NORMAL="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" BRIGHT=""
	fi
}

# ==============================================================================
# Loglama
# ==============================================================================
setup_logging() {
	mkdir -p "$(dirname "$LOG_FILE")"
	touch "$LOG_FILE"
	log "INFO" "🚀 NixOS kurulum betiği v$VERSION başlatılıyor"
}

log() {
	local level=$1
	shift
	local message=$*
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local symbol color

	case "$level" in
	"INFO")
		symbol="ℹ"
		color=$CYAN
		;;
	"WARN")
		symbol="⚠"
		color=$YELLOW
		;;
	"ERROR")
		symbol="✖"
		color=$RED
		;;
	"OK")
		symbol="✔"
		color=$GREEN
		;;
	"STEP")
		symbol="→"
		color=$MAGENTA
		;;
	"DEBUG")
		[[ $DEBUG != true ]] && return
		symbol="🔍"
		color=$BLUE
		;;
	esac

	printf "%b%s %-7s%b %s - %s\n" "$color" "$symbol" "$level" "$NORMAL" "$timestamp" "$message"
	echo "[$level] $timestamp - $message" >>"$LOG_FILE"
}

# ==============================================================================
# İlerleme Göstergeleri
# ==============================================================================
show_progress() {
	local current=$1 total=$2 message="${3:-İşlem yapılıyor...}"
	local percentage=$((current * 100 / total))
	local width=30
	local completed=$((percentage * width / 100))

	printf "\r[" >&2
	[[ $completed -gt 0 ]] && printf "%${completed}s" | tr ' ' '█' >&2
	[[ $((width - completed)) -gt 0 ]] && printf "%$((width - completed))s" | tr ' ' '░' >&2
	printf "] %3d%% %s" "$percentage" "$message" >&2

	[[ $current -eq $total ]] && echo "" >&2
}

show_spinner() {
	local pid=$1 message="${2:-İşlem yapılıyor...}"
	local frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
	local start_time=$(date +%s)

	while kill -0 $pid 2>/dev/null; do
		for frame in "${frames[@]}"; do
			local elapsed=$(($(date +%s) - start_time))
			printf "\r${frame} ${message} [${elapsed}s]" >&2
			sleep 0.1
		done
	done
	printf "\r✓ ${message} tamamlandı\n" >&2
}

# ==============================================================================
# Önbellekleme Sistemi
# ==============================================================================
init_cache() {
	[[ $CACHE_ENABLED != true ]] && return 0

	mkdir -p "$CACHE_DIR/packages" "$CACHE_DIR/downloads" "$CACHE_DIR/metadata"

	if [[ ! -f "$CACHE_DIR/metadata/info.json" ]]; then
		cat >"$CACHE_DIR/metadata/info.json" <<EOL
{
  "created": "$(date +%s)",
  "version": "$VERSION",
  "last_cleaned": "$(date +%s)"
}
EOL
	fi

	log "DEBUG" "Önbellekleme sistemi başlatıldı: $CACHE_DIR"
}

get_from_cache() {
	local cache_key=$1 destination=$2
	[[ $CACHE_ENABLED != true ]] && return 1

	local cache_file="$CACHE_DIR/packages/${cache_key}.tar.gz"

	if [[ -f "$cache_file" ]]; then
		local file_time=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file")
		local current_time=$(date +%s)

		if [[ $((current_time - file_time)) -gt $CACHE_EXPIRY ]]; then
			rm -f "$cache_file"
			return 1
		fi

		tar -xzf "$cache_file" -C "$(dirname "$destination")"
		touch "$cache_file"
		return 0
	fi
	return 1
}

save_to_cache() {
	local cache_key=$1 source=$2
	[[ $CACHE_ENABLED != true || ! -e "$source" ]] && return 1

	local cache_file="$CACHE_DIR/packages/${cache_key}.tar.gz"
	mkdir -p "$(dirname "$cache_file")"

	if [[ -d "$source" ]]; then
		tar -czf "$cache_file" -C "$(dirname "$source")" "$(basename "$source")"
	else
		tar -czf "$cache_file" -C "$(dirname "$source")" "$(basename "$source")"
	fi

	check_cache_size
}

generate_cache_key() {
	echo "$1" | sha256sum | cut -d' ' -f1
}

check_cache_size() {
	[[ $CACHE_ENABLED != true ]] && return 0

	local cache_size=$(du -sm "$CACHE_DIR" 2>/dev/null | cut -f1)
	[[ $cache_size -gt $MAX_CACHE_SIZE ]] && clean_cache
}

clean_cache() {
	[[ $CACHE_ENABLED != true ]] && return 0

	log "STEP" "Önbellek temizleniyor"
	find "$CACHE_DIR/packages" -type f -atime +$((CACHE_EXPIRY / 86400)) -delete
	log "OK" "Önbellek temizlendi"
}

show_cache_usage() {
	[[ $CACHE_ENABLED != true ]] && {
		echo "Önbellekleme devre dışı."
		return 0
	}

	local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
	local pkg_count=$(find "$CACHE_DIR/packages" -type f | wc -l)

	echo -e "${BLUE}=== Önbellek Kullanımı ===${NORMAL}"
	echo -e "Dizin: $CACHE_DIR"
	echo -e "Boyut: $cache_size"
	echo -e "Paket sayısı: $pkg_count"
	echo -e "Maksimum boyut: $MAX_CACHE_SIZE MB"
}

# ==============================================================================
# Yardımcı Fonksiyonlar
# ==============================================================================
print_header() {
	[[ $SILENT == true ]] && return
	echo -e "$CYAN
 ═══════════════════════════════════════
   ███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗
   ████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝
   ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗
   ██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║
   ██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║
   ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
 ═══════════════════════════════════════
 $BLUE Kurulum Betiği v$VERSION $NORMAL"
}

print_help() {
	cat <<EOF
${BRIGHT}${GREEN}NixOS Kurulum Betiği${NORMAL} - v$VERSION

${BRIGHT}Kullanım:${NORMAL}
    $SCRIPT_NAME [seçenekler]

${BRIGHT}Seçenekler:${NORMAL}
    -h, --help              Bu yardım mesajını göster
    -v, --version           Betik sürümünü göster
    -s, --silent            Sessiz modda çalıştır
    -d, --debug             Debug modunda çalıştır
    -a, --auto HOST         Otomatik mod (hay/vhay)
    -u, --update-flake      flake.lock dosyasını güncelle
    -m, --update-module     Belirli bir modülü güncelle
    -b, --backup            Sadece yedekleme yap
    -r, --restore           Yedekten geri yükle
    -p, --profile NAME      Profil adı belirt
    --pre-install           İlk sistem kurulumu
    --health-check          Sistem sağlık kontrolü
    --list-profiles         Profilleri listele
    --list-modules          Modülleri listele
    --cache-status          Önbellek durumunu göster
    --cache-clear           Önbelleği temizle
    --no-cache              Önbelleklemeyi devre dışı bırak

${BRIGHT}Örnekler:${NORMAL}
    $SCRIPT_NAME -a hay      # Otomatik dizüstü kurulumu
    $SCRIPT_NAME -u          # Flake güncelle
    $SCRIPT_NAME --list-profiles # Profilleri listele
EOF
}

confirm() {
	[[ $SILENT == true || $AUTO == true ]] && return 0
	echo -en "${BRIGHT}[${GREEN}y${NORMAL}/${RED}n${NORMAL}]${NORMAL} "
	read -r -n 1
	echo
	[[ $REPLY =~ ^[Yy]$ ]]
}

check_root() {
	if [[ $EUID -eq 0 ]]; then
		log "ERROR" "Bu betik root olarak çalıştırılmamalıdır!"
		exit 1
	fi
}

# ==============================================================================
# Sistem Kontrolü
# ==============================================================================
check_system_health() {
	log "STEP" "Sistem sağlık kontrolü"

	local total_mem=$(free -m | awk '/^Mem:/{print $2}')
	local used_mem=$(free -m | awk '/^Mem:/{print $3}')
	local mem_percent=$((used_mem * 100 / total_mem))

	log "INFO" "Bellek Kullanımı: ${mem_percent}%"
	[[ $mem_percent -gt 90 ]] && log "WARN" "Yüksek bellek kullanımı"

	local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')
	log "INFO" "CPU Yükü: $cpu_load"
	log "INFO" "CPU Çekirdekleri: $BUILD_CORES"

	log "OK" "Sistem sağlık kontrolü tamamlandı"
}

# ==============================================================================
# Yedekleme
# ==============================================================================
backup_flake() {
	local backup_file="$BACKUP_DIR/flake.lock.$(date +%Y%m%d_%H%M%S)"
	mkdir -p "$BACKUP_DIR"

	if [[ -f "$FLAKE_LOCK" ]]; then
		cp "$FLAKE_LOCK" "$backup_file"
		log "OK" "Yedekleme oluşturuldu: $backup_file"
		ls -t "$BACKUP_DIR"/flake.lock.* 2>/dev/null | tail -n +6 | xargs -r rm
		return 0
	else
		log "ERROR" "flake.lock bulunamadı"
		return 1
	fi
}

restore_flake_backup() {
	local latest_backup=$(ls -t "$BACKUP_DIR"/flake.lock.* 2>/dev/null | head -n1)

	if [[ -n "$latest_backup" ]]; then
		cp "$latest_backup" "$FLAKE_LOCK"
		log "OK" "Yedekten geri yüklendi: $latest_backup"
		return 0
	else
		log "ERROR" "Geri yüklenecek yedek bulunamadı"
		return 1
	fi
}

# ==============================================================================
# Flake Yönetimi
# ==============================================================================
setup_nix_conf() {
	if [[ ! -f "$NIX_CONF_FILE" ]]; then
		mkdir -p "$NIX_CONF_DIR"
		echo "experimental-features = nix-command flakes" >"$NIX_CONF_FILE"
		log "OK" "nix.conf oluşturuldu"
	else
		if ! grep -q "experimental-features.*=.*flakes" "$NIX_CONF_FILE"; then
			echo "experimental-features = nix-command flakes" >>"$NIX_CONF_FILE"
			log "OK" "nix.conf güncellendi"
		fi
	fi
}

update_flake() {
	if [[ $UPDATE_FLAKE == true ]]; then
		log "STEP" "Flake güncelleniyor"
		backup_flake
		setup_nix_conf

		local cache_key=$(generate_cache_key "flake-$(date +%Y%m%d)")

		if [[ $CACHE_ENABLED == true ]] && get_from_cache "$cache_key" "flake.json"; then
			log "INFO" "Günlük flake önbelleği kullanılıyor"
		else
			nix flake update &
			show_spinner $! "Flake güncelleniyor"
			wait $!

			if [[ $? -eq 0 ]]; then
				log "OK" "Flake güncellemesi tamamlandı"
				[[ $CACHE_ENABLED == true ]] && {
					nix flake metadata --json >"flake.json"
					save_to_cache "$cache_key" "flake.json"
					rm -f "flake.json"
				}
				return 0
			else
				log "ERROR" "Flake güncellemesi başarısız"
				return 1
			fi
		fi
	fi
	return 0
}

update_single_module() {
	if [[ -z "$UPDATE_MODULE" ]]; then
		log "ERROR" "Güncelleme için modül belirtilmedi"
		return 1
	fi

	log "STEP" "Modül güncelleniyor: $UPDATE_MODULE"
	backup_flake

	if nix flake lock --update-input "$UPDATE_MODULE"; then
		log "OK" "Modül güncellendi: $UPDATE_MODULE"
		return 0
	else
		log "ERROR" "Modül güncellemesi başarısız: $UPDATE_MODULE"
		return 1
	fi
}

list_available_modules() {
	log "INFO" "Flake içindeki kullanılabilir modüller:"
	if nix flake metadata 2>/dev/null | grep -A 100 "Inputs:" | grep -v "Inputs:" | awk '{print $1}' | grep -v "^$" | sort; then
		return 0
	else
		log "ERROR" "Modüller listelenirken hata oluştu"
		return 1
	fi
}

# ==============================================================================
# Profil Yönetimi
# ==============================================================================
list_profiles() {
	log "STEP" "NixOS profilleri listeleniyor"
	if output=$(nix profile list 2>/dev/null); then
		echo "$output"
		local count=$(echo "$output" | wc -l)
		log "INFO" "$count profil bulundu"
	else
		log "ERROR" "Profiller listelenirken hata oluştu"
		return 1
	fi
}

delete_profile() {
	local profile_id=$1
	[[ -z "$profile_id" ]] && {
		log "ERROR" "Profil ID belirtilmedi"
		return 1
	}

	log "STEP" "Profil siliniyor: $profile_id"
	if nix profile remove "$profile_id"; then
		log "OK" "Profil silindi: $profile_id"
		return 0
	else
		log "ERROR" "Profil silinirken hata oluştu: $profile_id"
		return 1
	fi
}

# ==============================================================================
# Kullanıcı ve Host Yönetimi
# ==============================================================================
get_username() {
	if [[ $AUTO == true ]]; then
		username=$DEFAULT_USERNAME
		log "INFO" "Varsayılan kullanıcı: $username"
		return 0
	fi

	log "STEP" "Kullanıcı adı ayarlanıyor"
	echo -en "${GREEN}Kullanıcı adınızı girin: ${YELLOW}"
	read -r username
	echo -en "${NORMAL}"

	echo -en "Kullanıcı adı '$username' olarak ayarlansın mı? "
	if confirm; then
		log "DEBUG" "Kullanıcı adı: $username"
		return 0
	fi
	exit 1
}

set_username() {
	log "STEP" "Konfigürasyon dosyaları güncelleniyor"

	if [[ -z "$CURRENT_USERNAME" || -z "$username" ]]; then
		log "ERROR" "Kullanıcı adları tanımlanmamış"
		return 1
	fi

	# Yedekleme ve güvenli güncelleme
	local backup_timestamp=$(date +%Y%m%d_%H%M%S)
	local backup_path="$BACKUP_DIR/username_changes/$backup_timestamp"
	mkdir -p "$backup_path"

	find . -name "*.nix" -type f -exec grep -l "$CURRENT_USERNAME" {} \; | while read -r file; do
		cp "$file" "$backup_path/$(basename "$file")"
		if sed -i "s/${CURRENT_USERNAME}/${username}/g" "$file"; then
			log "DEBUG" "Güncellendi: $file"
		else
			log "ERROR" "Güncelleme başarısız: $file"
			cp "$backup_path/$(basename "$file")" "$file"
			return 1
		fi
	done

	log "OK" "Kullanıcı adı güncellemesi tamamlandı"
}

get_host() {
	if [[ $AUTO == true ]]; then
		log "INFO" "Ana bilgisayar: $HOST"
		return 0
	fi

	log "STEP" "Ana bilgisayar türü seçiliyor"
	echo -en "Ana bilgisayar türü - [${YELLOW}H${NORMAL}]ay (Dizüstü) / [${YELLOW}V${NORMAL}]hay (VM): "
	read -n 1 -r
	echo

	case ${REPLY,,} in
	h) HOST='hay' ;;
	v) HOST='vhay' ;;
	*)
		log "ERROR" "Geçersiz seçim"
		exit 1
		;;
	esac

	echo -en "Ana bilgisayar '$HOST' olarak ayarlansın mı? "
	if confirm; then
		log "DEBUG" "Ana bilgisayar: $HOST"
		return 0
	fi
	exit 1
}

# ==============================================================================
# Kurulum Fonksiyonları
# ==============================================================================
setup_directories() {
	log "STEP" "Dizinler oluşturuluyor"
	local dirs=(
		"$HOME/Pictures/wallpapers/others"
		"$HOME/Pictures/wallpapers/nixos"
		"$CONFIG_DIR"
	)

	for dir in "${dirs[@]}"; do
		mkdir -p "$dir"
		log "DEBUG" "Oluşturuldu: $dir"
	done
	log "OK" "Dizinler oluşturuldu"
}

copy_wallpapers() {
	log "STEP" "Duvar kağıtları kopyalanıyor"

	local cache_key=$(generate_cache_key "wallpapers-$(date +%Y%m%d)")
	local wallpaper_temp="$HOME/.wallpaper-temp"

	if [[ $CACHE_ENABLED == true ]] && get_from_cache "$cache_key" "$wallpaper_temp"; then
		log "INFO" "Duvar kağıtları önbellekten alınıyor"
		if [[ -d "$wallpaper_temp" ]]; then
			cp -r "$wallpaper_temp/"* "$WALLPAPER_DIR/"
			rm -rf "$wallpaper_temp"
			log "OK" "Duvar kağıtları önbellekten kopyalandı"
			return 0
		fi
	fi

	if [[ -d "wallpapers" ]]; then
		mkdir -p "$wallpaper_temp"
		cp -r wallpapers/* "$wallpaper_temp/" 2>/dev/null || true
		cp -r "$wallpaper_temp/"* "$WALLPAPER_DIR/"

		[[ $CACHE_ENABLED == true ]] && save_to_cache "$cache_key" "$wallpaper_temp"
		rm -rf "$wallpaper_temp"
		log "OK" "Duvar kağıtları kopyalandı"
	else
		log "WARN" "Duvar kağıdı dizini bulunamadı"
	fi
}

copy_hardware_config() {
	local source="/etc/nixos/hardware-configuration.nix"
	local target="hosts/${HOST}/hardware-configuration.nix"

	if [[ ! -f "$source" ]]; then
		log "ERROR" "Donanım konfigürasyonu bulunamadı: $source"
		return 1
	fi

	log "STEP" "Donanım konfigürasyonu kopyalanıyor"

	if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
		log "INFO" "Donanım konfigürasyonu güncel"
		return 0
	fi

	cp "$source" "$target"
	log "OK" "Donanım konfigürasyonu kopyalandı"
}

get_profile_name() {
	if [[ -z "$PROFILE_NAME" && $SILENT == false && $AUTO == false ]]; then
		echo -en "Profil adı belirtmek ister misiniz? "
		if confirm; then
			echo -en "Profil adı: "
			read -r PROFILE_NAME
			log "DEBUG" "Profil adı: $PROFILE_NAME"
		fi
	fi
}

build_system() {
	log "STEP" "Sistem derlemesi başlatılıyor"
	echo -en "Sistem derlemesi başlasın mı? "
	if confirm; then
		local build_cmd="sudo nixos-rebuild switch --cores $BUILD_CORES --flake \".#${HOST}\" --accept-flake-config"
		[[ -n "$PROFILE_NAME" ]] && build_cmd+=" --profile-name \"$PROFILE_NAME\""

		log "INFO" "Derleme başlatılıyor..."

		eval "$build_cmd" &
		show_spinner $! "Sistem derleniyor"
		wait $!

		if [[ $? -eq 0 ]]; then
			log "OK" "Sistem başarıyla derlendi"
			[[ -n "$PROFILE_NAME" ]] && log "OK" "Profil oluşturuldu: $PROFILE_NAME"
			return 0
		else
			log "ERROR" "Derleme başarısız"
			return 1
		fi
	else
		log "ERROR" "Derleme iptal edildi"
		exit 1
	fi
}

# ==============================================================================
# Ön Kurulum
# ==============================================================================
pre_install() {
	local host_type=$1
	log "STEP" "Ön kurulum: $host_type"

	local template="hosts/${host_type}/templates/initial-configuration.nix"
	local config="/etc/nixos/configuration.nix"

	if [[ ! -f "$template" ]]; then
		log "ERROR" "Şablon bulunamadı: $template"
		return 1
	fi

	if sudo cp "$template" "$config"; then
		log "OK" "İlk konfigürasyon ayarlandı"

		if sudo nixos-rebuild switch --profile-name start; then
			log "OK" "Ön kurulum tamamlandı"
			echo -e "\n${GREEN}Yeniden başlatın ve ana kurulumu çalıştırın${NORMAL}"
			return 0
		fi
	fi

	log "ERROR" "Ön kurulum başarısız"
	return 1
}

# ==============================================================================
# Ana Menü
# ==============================================================================
main_menu() {
	local options=(
		"1) Sistem kur"
		"2) Flake güncelle"
		"3) Modül güncelle"
		"4) Yedekleme yap"
		"5) Profilleri listele"
		"6) Modülleri listele"
		"7) Önbellek durumu"
		"8) Önbelleği temizle"
		"0) Çıkış"
	)

	echo -e "\n${CYAN}NixOS Kurulum Aracı${NORMAL}"
	echo -e "${BLUE}================${NORMAL}\n"

	# Menü seçeneklerini göster
	for opt in "${options[@]}"; do
		echo -e "$opt"
	done

	# Kullanıcı seçimini al
	echo -en "\nSeçiminiz: "
	read -r choice

	# Seçime göre işlem yap
	case $choice in
	1) install ;;
	2)
		UPDATE_FLAKE=true
		update_flake
		;;
	3)
		echo -en "Güncellenecek modül adı: "
		read -r UPDATE_MODULE
		update_single_module
		;;
	4) backup_flake ;;
	5) list_profiles ;;
	6) list_available_modules ;;
	7) show_cache_usage ;;
	8) clean_cache ;;
	0) exit 0 ;;
	*) echo "Geçersiz seçim" ;;
	esac
}

# ==============================================================================
# Ana Kurulum
# ==============================================================================
install() {
	# Özel işlemler
	[[ $BACKUP_ONLY == true ]] && {
		backup_flake
		exit $?
	}
	[[ -n "$UPDATE_MODULE" ]] && {
		update_single_module
		exit $?
	}
	[[ $PRE_INSTALL == true ]] && {
		pre_install "$HOST"
		exit $?
	}

	# Önbellekleme sistemini başlat
	init_cache

	# Ana kurulum adımları
	local steps=(
		"setup_directories"
		"copy_wallpapers"
		"copy_hardware_config"
		"get_profile_name"
	)

	[[ $UPDATE_FLAKE == true ]] && steps+=("update_flake")
	steps+=("build_system")

	echo -e "\n${CYAN}Kurulum başlatılıyor...${NORMAL}\n"

	local total=${#steps[@]}
	for i in "${!steps[@]}"; do
		local step=${steps[$i]}
		show_progress $((i + 1)) $total "$(echo $step | tr '_' ' ')"

		if ! $step; then
			log "ERROR" "$step adımında hata"
			exit 1
		fi
		sleep 0.5
	done

	echo -e "\n${GREEN}Kurulum tamamlandı!${NORMAL}\n"
}

show_summary() {
	log "INFO" "Kurulum Özeti"
	local items=(
		"Kullanıcı Adı|$username"
		"Ana Bilgisayar|$HOST"
		"Konfigürasyon|/etc/nixos"
		"Ev Dizini|$HOME"
	)

	[[ -n "$PROFILE_NAME" ]] && items+=("Profil Adı|$PROFILE_NAME")
	[[ $UPDATE_FLAKE == true ]] && items+=("Flake Durumu|Güncellendi")
	[[ -n "$UPDATE_MODULE" ]] && items+=("Güncellenen Modül|$UPDATE_MODULE")
	[[ $CACHE_ENABLED == true ]] && items+=("Önbellekleme|Etkin")

	for item in "${items[@]}"; do
		local key=${item%|*}
		local value=${item#*|}
		echo -e "${GREEN}✓${NORMAL} ${key}: ${YELLOW}${value}${NORMAL}"
	done

	log "OK" "Kurulum başarıyla tamamlandı!"
}

# ==============================================================================
# Komut Satırı Argümanları
# ==============================================================================
process_args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			print_help
			exit
			;;
		-v | --version)
			echo "v$VERSION"
			exit
			;;
		-s | --silent) SILENT=true ;;
		-d | --debug) DEBUG=true ;;
		-a | --auto)
			AUTO=true
			SILENT=true
			shift
			[[ "$1" =~ ^(hay|vhay)$ ]] && HOST="$1" || {
				log "ERROR" "Geçersiz host"
				exit 1
			}
			;;
		-u | --update-flake) UPDATE_FLAKE=true ;;
		-m | --update-module)
			shift
			UPDATE_MODULE="$1"
			;;
		-b | --backup) BACKUP_ONLY=true ;;
		-r | --restore)
			restore_flake_backup
			exit
			;;
		-p | --profile)
			shift
			PROFILE_NAME="$1"
			;;
		--pre-install) PRE_INSTALL=true ;;
		--health-check)
			check_system_health
			exit
			;;
		--list-profiles)
			list_profiles
			exit
			;;
		--list-modules)
			list_available_modules
			exit
			;;
		--delete-profile)
			shift
			delete_profile "$1"
			exit
			;;
		--cache-status)
			show_cache_usage
			exit
			;;
		--cache-clear)
			clean_cache
			exit
			;;
		--no-cache) CACHE_ENABLED=false ;;
		*)
			log "ERROR" "Bilinmeyen seçenek: $1"
			exit 1
			;;
		esac
		shift
	done
}

# ==============================================================================
# Ana Fonksiyon
# ==============================================================================
main() {
	init_colors
	setup_logging
	process_args "$@"
	check_root
	check_system_health

	[[ $AUTO == false && $SILENT == false ]] && print_header

	# Interaktif veya otomatik mod
	if [[ $AUTO == false && $SILENT == false && -z "$UPDATE_FLAKE" && -z "$UPDATE_MODULE" && $BACKUP_ONLY == false && $PRE_INSTALL == false ]]; then
		main_menu
	else
		# Otomatik mod için zorunlu işlemler
		get_username
		set_username
		get_host
		install
		show_summary
	fi
}

main "$@"
