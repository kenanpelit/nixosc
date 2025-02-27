#!/usr/bin/env bash

# ==============================================================================
# NixOS Installation Script
# Author: kenanpelit (Enhanced version)
# Description: Complete script for NixOS installation and management
# Features:
#   - Automated installation for both laptop and VM configurations
#   - Multi-monitor wallpaper management
#   - Profile-based system management
#   - Advanced backup and restore capabilities
#   - Enhanced error handling and logging
#   - Progress visualization
#   - System health monitoring
# ==============================================================================

VERSION="2.3.0"
SCRIPT_NAME=$(basename "$0")

# Konfigürasyon Flagleri
DEBUG=false
SILENT=false
AUTO=false
UPDATE_FLAKE=false
UPDATE_MODULE=""
BACKUP_ONLY=false
PROFILE_NAME=""
PRE_INSTALL=false

# Sistem Konfigürasyonu
CURRENT_USERNAME='kenan'
DEFAULT_USERNAME='kenan'
CONFIG_DIR="$HOME/.config/nixos"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
BUILD_CORES=0 # CPU çekirdeklerini otomatik algıla
NIX_CONF_DIR="$HOME/.config/nix"
NIX_CONF_FILE="$NIX_CONF_DIR/nix.conf"
BACKUP_DIR="$HOME/.nixosb"
FLAKE_LOCK="flake.lock"
LOG_FILE="$HOME/.nixosb/nixos-install.log"

# Önbellekleme Konfigürasyonu
CACHE_DIR="$HOME/.nixos-cache" # Önbellek dizini
CACHE_ENABLED=true             # Önbellekleme açık/kapalı
CACHE_EXPIRY=604800            # 7 gün (saniye cinsinden)
MAX_CACHE_SIZE=10240           # 10GB (MB cinsinden)

# ==============================================================================
# Terminal Renk Desteği
# ==============================================================================
init_colors() {
	if [[ -t 1 ]]; then
		NORMAL=$(tput sgr0)
		WHITE=$(tput setaf 7)
		BLACK=$(tput setaf 0)
		RED=$(tput setaf 1)
		GREEN=$(tput setaf 2)
		YELLOW=$(tput setaf 3)
		BLUE=$(tput setaf 4)
		MAGENTA=$(tput setaf 5)
		CYAN=$(tput setaf 6)
		BRIGHT=$(tput bold)
		UNDERLINE=$(tput smul)
		BG_BLACK=$(tput setab 0)
		BG_GREEN=$(tput setab 2)
	else
		NORMAL=""
		WHITE=""
		BLACK=""
		RED=""
		GREEN=""
		YELLOW=""
		BLUE=""
		MAGENTA=""
		CYAN=""
		BRIGHT=""
		UNDERLINE=""
		BG_BLACK=""
		BG_GREEN=""
	fi
}

# ==============================================================================
# Loglama Sistemi
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
	local symbol=""
	local color=""

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
	"DEBUG")
		[[ $DEBUG != true ]] && return
		symbol="🔍"
		color=$BLUE
		;;
	"OK")
		symbol="✔"
		color=$GREEN
		;;
	"STEP")
		symbol="→"
		color=$MAGENTA
		;;
	esac

	printf "%b%s %-7s%b %s - %s\n" "$color" "$symbol" "$level" "$NORMAL" "$timestamp" "$message"
	echo "[$level] $timestamp - $message" >>"$LOG_FILE"
}

# ==============================================================================
# Gelişmiş İlerleme Göstergesi Fonksiyonları
# ==============================================================================
# Terminal genişliğini alarak ilerleme çubuğunun ekrana sığmasını sağlar
get_terminal_width() {
	if command -v tput >/dev/null 2>&1; then
		tput cols
	else
		echo 80 # Varsayılan değer
	fi
}

# Gelişmiş ilerleme göstergesi - hem görsel hem de bilgilendirici
# Kullanım: show_progress 3 10 "Paketler kuruluyor"
show_progress() {
	local current=$1
	local total=$2
	local message="${3:-"İşlem yapılıyor..."}"
	local percentage=$((current * 100 / total))
	local term_width=$(get_terminal_width)
	local progress_width=$((term_width > 60 ? 40 : term_width / 2))
	local completed_width=$((percentage * progress_width / 100))
	local spinner_chars=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
	local spinner=${spinner_chars[current % ${#spinner_chars[@]}]}

	# Kalan süre tahmini için zaman başlangıcını kaydet
	if [[ -z "$progress_start_time" && $current -eq 1 ]]; then
		progress_start_time=$(date +%s)
	fi

	# Kalan süreyi hesapla ve formatla
	local time_estimate=""
	if [[ $current -gt 1 && $percentage -lt 100 ]]; then
		local current_time=$(date +%s)
		local elapsed=$((current_time - progress_start_time))
		local estimated_total=$((elapsed * total / current))
		local remaining=$((estimated_total - elapsed))

		if [[ $remaining -gt 0 ]]; then
			if [[ $remaining -ge 60 ]]; then
				time_estimate="(~$((remaining / 60))m kaldı)"
			else
				time_estimate="(~${remaining}s kaldı)"
			fi
		fi
	fi

	# İlerleme çubuğunu oluştur
	printf "\r${spinner} [" >&2
	printf "%${completed_width}s" | tr ' ' '█' >&2
	printf "%$((progress_width - completed_width))s" | tr ' ' '░' >&2
	printf "] %3d%% %-30s %s" "$percentage" "${message:0:30}" "$time_estimate" >&2

	# İşlem tamamlandıysa yeni satır ve zaman değişkenini temizle
	if [[ $current -eq $total ]]; then
		echo "" >&2
		unset progress_start_time
	fi
}

# Alt adımlar için ilerleme çubuğu - ana ilerleme çubuğu altında gösterilir
show_substep_progress() {
	local current=$1
	local total=$2
	local message="${3:-"Alt işlem..."}"
	local term_width=$(get_terminal_width)
	local max_message_width=$((term_width > 80 ? 50 : term_width / 2))

	# Mesajı kısalt (çok uzunsa)
	if [[ ${#message} -gt $max_message_width ]]; then
		message="${message:0:$((max_message_width - 3))}..."
	fi

	# Alt adım ilerleme çubuğu
	printf "\r  ↳ %-${max_message_width}s [" "$message" >&2
	for ((i = 0; i < current; i++)); do
		printf "#" >&2
	done
	for ((i = current; i < total; i++)); do
		printf "." >&2
	done
	printf "] %d/%d" "$current" "$total" >&2

	# İşlem tamamlandıysa yeni satır
	if [[ $current -eq $total ]]; then
		echo "" >&2
	fi
}

# Uzun süren işlemler için animasyonlu gösterge
# Kullanım:
#   sleep 10 & # Arka planda çalışacak işlem
#   show_animated_progress $! "Yükleniyor"
show_animated_progress() {
	local pid=$1
	local message="${2:-"İşlem yapılıyor..."}"
	local frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
	local start_time=$(date +%s)

	echo -en "\n" >&2

	# İşlem bitene kadar dönen animasyon göster
	while kill -0 $pid 2>/dev/null; do
		for frame in "${frames[@]}"; do
			local current_time=$(date +%s)
			local elapsed=$((current_time - start_time))

			# Geçen süreyi dakika:saniye formatında göster
			if [[ $elapsed -ge 60 ]]; then
				local minutes=$((elapsed / 60))
				local seconds=$((elapsed % 60))
				time_display=$(printf "%02d:%02d" $minutes $seconds)
			else
				time_display=$(printf "%02ds" $elapsed)
			fi

			printf "\r${frame} ${message} [${time_display}]" >&2
			sleep 0.1
		done
	done

	# İşlem tamamlandığında checkmark göster
	printf "\r✓ ${message} tamamlandı [${time_display}]     \n" >&2
}

# ==============================================================================
# Önbellekleme Sistemi Desteği
# ==============================================================================
# Önbellekleme sistemini başlat ve gerekli dizinleri oluştur
init_cache() {
	[[ $CACHE_ENABLED != true ]] && return 0

	# Önbellek dizinlerini oluştur
	mkdir -p "$CACHE_DIR/packages"  # Paket önbelleği
	mkdir -p "$CACHE_DIR/downloads" # İndirme önbelleği
	mkdir -p "$CACHE_DIR/metadata"  # Meta veri önbelleği

	# Önbellek boyutunu kontrol et ve gerekirse temizle
	check_cache_size

	# Önbellek meta bilgisini oluştur (yoksa)
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
	return 0
}

# Önbellekten veri al - belirtilen anahtarla eşleşen dosyayı belirtilen hedefe kopyala
# Kullanım: get_from_cache "paket-adı-v1.2.3" "/hedef/dizin/paket"
get_from_cache() {
	local cache_key=$1
	local destination=$2

	[[ $CACHE_ENABLED != true ]] && return 1

	local cache_file="$CACHE_DIR/packages/${cache_key}.tar.gz"

	if [[ -f "$cache_file" ]]; then
		# Önbellek öğesi var mı kontrol et
		local file_time=$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file")
		local current_time=$(date +%s)

		# Öğe süresi dolmuş mu?
		if [[ $((current_time - file_time)) -gt $CACHE_EXPIRY ]]; then
			log "DEBUG" "Önbellek süresi dolmuş: $cache_key"
			rm -f "$cache_file"
			return 1
		fi

		# Dosyayı önbellekten çıkar hedef konuma
		log "DEBUG" "Önbellekten alınıyor: $cache_key"
		tar -xzf "$cache_file" -C "$(dirname "$destination")"
		touch "$cache_file" # Erişim zamanını güncelle
		return 0
	fi

	return 1
}

# Veriyi önbelleğe kaydet - belirtilen kaynağı sıkıştırarak önbellekte sakla
# Kullanım: save_to_cache "paket-adı-v1.2.3" "/kaynak/dosya/veya/dizin"
save_to_cache() {
	local cache_key=$1
	local source=$2

	[[ $CACHE_ENABLED != true ]] && return 1
	[[ ! -e "$source" ]] && return 1

	local cache_file="$CACHE_DIR/packages/${cache_key}.tar.gz"

	# Önbellekleme dizini oluştur
	mkdir -p "$(dirname "$cache_file")"

	# Dosyayı önbelleğe al (sıkıştırarak)
	if [[ -d "$source" ]]; then
		tar -czf "$cache_file" -C "$(dirname "$source")" "$(basename "$source")"
	else
		# Tek dosya
		tar -czf "$cache_file" -C "$(dirname "$source")" "$(basename "$source")"
	fi

	log "DEBUG" "Önbelleğe kaydedildi: $cache_key"

	# Önbellek boyutunu kontrol et ve gerekirse temizle
	check_cache_size

	return 0
}

# Önbellek anahtar değeri oluştur - tutarlı ve benzersiz anahtarlar için
# Kullanım: key=$(generate_cache_key "paket-adı-v1.2.3")
generate_cache_key() {
	local input=$1
	echo "$input" | sha256sum | cut -d' ' -f1
}

# Önbellek boyutunu kontrol et ve gerekirse temizle
check_cache_size() {
	[[ $CACHE_ENABLED != true ]] && return 0

	# Önbellek boyutunu hesapla (MB cinsinden)
	local cache_size=$(du -sm "$CACHE_DIR" 2>/dev/null | cut -f1)

	if [[ $cache_size -gt $MAX_CACHE_SIZE ]]; then
		log "WARN" "Önbellek boyutu limiti aştı: ${cache_size}MB/${MAX_CACHE_SIZE}MB"
		clean_cache
	fi

	return 0
}

# Önbelleği temizle - eski ve kullanılmayan dosyaları sil
clean_cache() {
	[[ $CACHE_ENABLED != true ]] && return 0

	log "STEP" "Önbellek temizleniyor"
	show_animated_progress "$$" "Önbellek temizleniyor" &
	local animation_pid=$!

	# İlk adım: Eski dosyaları bul ve sil (son erişim zamanına göre)
	find "$CACHE_DIR/packages" -type f -atime +$((CACHE_EXPIRY / 86400)) -delete

	# İkinci adım: Boyut hala limitin üzerindeyse, en eski dosyaları sil
	local cache_size=$(du -sm "$CACHE_DIR" 2>/dev/null | cut -f1)
	if [[ $cache_size -gt $MAX_CACHE_SIZE ]]; then
		log "INFO" "Eski önbellek öğeleri siliniyor"
		find "$CACHE_DIR/packages" -type f -printf '%T@ %p\n' |
			sort -n |
			head -n 100 |
			cut -d' ' -f2- |
			xargs rm -f
	fi

	# Önbellek meta bilgisini güncelle
	local metadata_file="$CACHE_DIR/metadata/info.json"
	if [[ -f "$metadata_file" ]]; then
		tmp=$(mktemp)
		jq ".last_cleaned = $(date +%s)" "$metadata_file" >"$tmp" && mv "$tmp" "$metadata_file"
	fi

	# Animasyon işlemini sonlandır
	kill $animation_pid 2>/dev/null
	log "OK" "Önbellek temizlendi"

	return 0
}

# Önbellek kullanımını göster - önbellekle ilgili bilgileri ekrana yazdır
show_cache_usage() {
	[[ $CACHE_ENABLED != true ]] && {
		echo "Önbellekleme devre dışı."
		return 0
	}

	# Önbellek istatistiklerini hesapla
	local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
	local pkg_count=$(find "$CACHE_DIR/packages" -type f | wc -l)
	local last_cleaned="Hiç"

	# Son temizleme zamanını oku
	local metadata_file="$CACHE_DIR/metadata/info.json"
	if [[ -f "$metadata_file" ]]; then
		if command -v jq >/dev/null 2>&1; then
			local cleaned_ts=$(jq -r ".last_cleaned" "$metadata_file")
			last_cleaned=$(date -d "@$cleaned_ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null ||
				date -r "$cleaned_ts" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
		fi
	fi

	# İstatistikleri göster
	echo -e "${BLUE}=== Önbellek Kullanımı ===${NORMAL}"
	echo -e "Dizin: $CACHE_DIR"
	echo -e "Boyut: $cache_size"
	echo -e "Paket sayısı: $pkg_count"
	echo -e "Son temizleme: $last_cleaned"
	echo -e "Maksimum boyut: $MAX_CACHE_SIZE MB"
	echo -e "Süre aşımı: $((CACHE_EXPIRY / 86400)) gün"

	return 0
}

# ==============================================================================
# Yardımcı Fonksiyonlar
# ==============================================================================
print_header() {
	echo -E "$CYAN
 ═══════════════════════════════════════
   ███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗
   ████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝
   ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗
   ██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║
   ██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║
   ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
 ═══════════════════════════════════════

 $BLUE Kurulum Betiği v$VERSION $RED
  ! Düzgün kurulum için root olarak çalıştırmayın !$GREEN
  → $SCRIPT_NAME $NORMAL
    "
}

print_help() {
	cat <<EOF
${BRIGHT}${GREEN}NixOS Kurulum Betiği${NORMAL}
Sürüm: $VERSION

${BRIGHT}Kullanım:${NORMAL}
    $SCRIPT_NAME [seçenekler]

${BRIGHT}Seçenekler:${NORMAL}
    -h, --help              Bu yardım mesajını göster
    -v, --version           Betik sürümünü göster
    -s, --silent            Sessiz modda çalıştır
    -d, --debug             Hata ayıklama modunda çalıştır
    -a, --auto HOST         Varsayılanlarla çalıştır (hay/vhay)
    -u, --update-flake      flake.lock dosyasını güncelle
    -m, --update-module     Belirli bir modülü güncelle
    -b, --backup            Sadece flake.lock dosyasını yedekle
    -r, --restore           Son yedekten geri yükle
    -p, --profile NAME      Profil adı belirt
    --pre-install           İlk sistem kurulumu
    -hc, --health-check     Sistem sağlık kontrolü
    
    # Önbellekleme seçenekleri
    --cache                 Önbelleklemeyi etkinleştir (varsayılan)
    --no-cache              Önbelleklemeyi devre dışı bırak
    --cache-dir DIR         Önbellek dizinini ayarla
    --cache-clear           Önbelleği temizle
    --cache-status          Önbellek durumunu göster
    
${BRIGHT}Örnekler:${NORMAL}
    $SCRIPT_NAME -a hay    # Otomatik dizüstü kurulumu
    $SCRIPT_NAME -p S1     # S1 profili ile derleme
    $SCRIPT_NAME --cache-status # Önbellek durumunu göster
    $SCRIPT_NAME --no-cache -u # Önbellekleme olmadan flake güncelle
EOF
}

confirm() {
	[[ $SILENT == true || $AUTO == true ]] && return 0
	echo -en "${BRIGHT}[${GREEN}y${NORMAL}/${RED}n${NORMAL}]${NORMAL} "
	read -r -n 1
	echo
	[[ $REPLY =~ ^[Yy]$ ]]
}

# ==============================================================================
# Sistem Kontrol Fonksiyonları
# ==============================================================================
check_root() {
	if [[ $EUID -eq 0 ]]; then
		log "ERROR" "Bu betik root olarak çalıştırılmamalıdır!"
		exit 1
	fi
}

check_system_health() {
	log "STEP" "Sistem sağlık kontrolü yapılıyor"

	# Bellek kontrolü
	local total_mem=$(free -m | awk '/^Mem:/{print $2}')
	local used_mem=$(free -m | awk '/^Mem:/{print $3}')
	local mem_percent=$((used_mem * 100 / total_mem))

	log "INFO" "Bellek Kullanımı: ${mem_percent}%"
	[[ $mem_percent -gt 90 ]] && log "WARN" "Yüksek bellek kullanımı tespit edildi"

	# CPU yük kontrolü
	local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1)
	log "INFO" "CPU Yükü: $cpu_load"
	[[ $(echo "$cpu_load > 2" | bc) -eq 1 ]] && log "WARN" "Yüksek CPU yükü"

	log "OK" "Sistem sağlık kontrolü tamamlandı"
}

# ==============================================================================
# Yedekleme Yönetimi
# ==============================================================================
backup_flake() {
	local backup_file="$BACKUP_DIR/flake.lock.$(date +%Y%m%d_%H%M%S)"
	mkdir -p "$BACKUP_DIR"

	if [[ -f $FLAKE_LOCK ]]; then
		cp "$FLAKE_LOCK" "$backup_file"
		log "OK" "flake.lock yedeklemesi oluşturuldu: $backup_file"

		# Sadece son 5 yedeği tut
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
		log "OK" "flake.lock yedekten geri yüklendi: $latest_backup"
		return 0
	else
		log "ERROR" "Geri yüklenecek yedek bulunamadı"
		return 1
	fi
}

# ==============================================================================
# Flake Yönetimi
# ==============================================================================
update_single_module() {
	if [[ -z "$UPDATE_MODULE" ]]; then
		log "ERROR" "Güncelleme için modül belirtilmedi"
		return 1
	fi

	log "STEP" "Modül güncelleniyor: $UPDATE_MODULE"
	backup_flake

	if nix flake lock --update-input "$UPDATE_MODULE"; then
		log "OK" "Modül başarıyla güncellendi: $UPDATE_MODULE"
		return 0
	else
		log "ERROR" "Modül güncellemesi başarısız oldu: $UPDATE_MODULE"
		return 1
	fi
}

list_available_modules() {
	log "INFO" "Flake içindeki kullanılabilir modüller:"
	if ! nix flake metadata 2>/dev/null | grep -A 100 "Inputs:" | grep -v "Inputs:" | awk '{print $1}' | grep -v "^$" | sort; then
		log "ERROR" "Modüller listelenirken hata oluştu"
		exit 1
	fi
}

setup_nix_conf() {
	if [[ ! -f "$NIX_CONF_FILE" ]]; then
		mkdir -p "$NIX_CONF_DIR"
		echo "experimental-features = nix-command flakes" >"$NIX_CONF_FILE"
		log "OK" "flakes desteği ile nix.conf oluşturuldu"
	else
		if ! grep -q "experimental-features.*=.*flakes" "$NIX_CONF_FILE"; then
			echo "experimental-features = nix-command flakes" >>"$NIX_CONF_FILE"
			log "OK" "Mevcut nix.conf dosyasına flakes desteği eklendi"
		fi
	fi
}

# Önbellekli flake güncelleme
update_flake_with_cache() {
	if [[ $UPDATE_FLAKE == true ]]; then
		log "STEP" "Flake yapılandırması güncelleniyor"
		backup_flake
		setup_nix_conf

		# Günlük önbellek anahtarı oluştur
		local cache_key=$(generate_cache_key "flake-$(date +%Y%m%d)")
		local flake_json="flake.json"

		# Günlük bir önbellek var mı kontrol et
		if [[ $CACHE_ENABLED == true ]] && get_from_cache "$cache_key" "$flake_json"; then
			log "INFO" "Günlük flake önbelleği kullanılıyor"
			if nix flake update; then
				log "OK" "Flake güncellemesi tamamlandı"
				return 0
			fi
		else
			# Önbellekte yoksa güncelleme işlemini göster
			show_animated_progress "$$" "Flake güncelleniyor" &
			local animation_pid=$!

			if nix flake update; then
				kill $animation_pid 2>/dev/null
				log "OK" "Flake güncellemesi tamamlandı"

				if [[ $CACHE_ENABLED == true ]]; then
					# Günlük flake durumunu önbelleğe al
					nix flake metadata --json >"$flake_json"
					save_to_cache "$cache_key" "$flake_json"
					rm -f "$flake_json"
				fi

				return 0
			else
				kill $animation_pid 2>/dev/null
				log "ERROR" "Flake güncellemesi başarısız oldu"
				return 1
			fi
		fi
	fi

	return 0
}

# ==============================================================================
# Kullanıcı ve Ana Bilgisayar Yönetimi
# ==============================================================================
print_question() {
	local question=$1
	echo
	echo -e "${BLUE}┌─────────────────────────── ? ───────────────────────────┐${NORMAL}"
	echo -e "${BLUE}│${NORMAL} $question"
	echo -e "${BLUE}└──────────────────────────────────────────────────────────┘${NORMAL}"
}

get_username() {
	if [[ $AUTO == true ]]; then
		username=$DEFAULT_USERNAME
		log "INFO" "Varsayılan kullanıcı adı kullanılıyor: $username"
		return 0
	fi

	log "STEP" "Kullanıcı adı ayarlanıyor"
	print_question "${GREEN}Kullanıcı adınızı${NORMAL} girin: ${YELLOW}"
	read -r username
	echo -en "${NORMAL}"

	print_question "${GREEN}Kullanıcı adı${NORMAL} olarak ${YELLOW}$username${NORMAL} kullanılsın mı?"
	if confirm; then
		log "DEBUG" "Kullanıcı adı ayarlandı: $username"
		return 0
	fi
	exit 1
}

# Kullanıcı adı değişikliği için yeni yedekleme yönetimi
set_username() {
	log "STEP" "Konfigürasyon dosyaları kullanıcı adı ile güncelleniyor"

	# Güvenli dosya uzantıları ve dizinler
	local safe_files=("*.nix" "configuration.yml" "config.toml" "*.conf")
	local exclude_dirs=(".git" "result" ".direnv" "*.cache")

	# Kullanıcı adı formatı kontrolü
	if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
		log "ERROR" "Geçersiz kullanıcı adı formatı - Küçük harfler, sayılar, - ve _ kullanın"
		return 1
	fi

	# Mevcut kullanıcı adı kontrolü
	if [[ -z "$CURRENT_USERNAME" ]]; then
		log "ERROR" "Mevcut kullanıcı adı tanımlanmamış"
		return 1
	fi

	# Yedekleme dizini ve log dosyası hazırlama
	local backup_timestamp=$(date +%Y%m%d_%H%M%S)
	local backup_path="$BACKUP_DIR/username_changes/$backup_timestamp"
	local backup_log="$backup_path/backup.log"

	mkdir -p "$backup_path"

	# Değiştirilecek dosyaları bul
	local files_to_change=()
	for ext in "${safe_files[@]}"; do
		while IFS= read -r -d $'\0' file; do
			if grep -q "$CURRENT_USERNAME" "$file"; then
				files_to_change+=("$file")
			fi
		done < <(find . -type f -name "$ext" $(printf "! -path '*/%s/*' " "${exclude_dirs[@]}") -print0)
	done

	# Dosya kontrolü
	if [ ${#files_to_change[@]} -eq 0 ]; then
		log "WARN" "Güncellenecek dosya bulunamadı"
		return 0
	fi

	# Değiştirilecek dosyaları göster
	log "INFO" "Güncellenecek dosyalar:"
	printf '%s\n' "${files_to_change[@]}"

	# Onay al
	echo -en "\n'${CURRENT_USERNAME}' kullanıcı adını '${username}' olarak değiştir? "
	if ! confirm; then
		log "INFO" "İşlem kullanıcı tarafından iptal edildi"
		return 1
	fi

	# Yedekleme log başlangıcı
	{
		echo "Kullanıcı Adı Değişikliği Yedekleme Logu"
		echo "=========================="
		echo "Zaman: $backup_timestamp"
		echo "Eski Kullanıcı Adı: $CURRENT_USERNAME"
		echo "Yeni Kullanıcı Adı: $username"
		echo -e "\nYedeklenen dosyalar:"
	} >"$backup_log"

	# Dosyaları yedekle ve güncelle
	local success=0
	for file in "${files_to_change[@]}"; do
		# Yedekleme dizin yapısını oluştur
		local relative_path=${file#./}
		local backup_file="$backup_path/$relative_path"
		mkdir -p "$(dirname "$backup_file")"

		# Dosyayı yedekle
		if cp "$file" "$backup_file"; then
			# Yedekleme loguna kaydet
			echo "- $relative_path" >>"$backup_log"

			# Dosyayı güncelle
			if sed -i "s/${CURRENT_USERNAME}/${username}/g" "$file"; then
				log "DEBUG" "Güncellendi ve yedeklendi: $file → $backup_file"
			else
				log "ERROR" "Güncelleme başarısız: $file"
				cp "$backup_file" "$file" # Hata durumunda geri al
				success=1
			fi
		else
			log "ERROR" "Yedekleme başarısız: $file"
			success=1
		fi
	done

	# Yedekleme özeti loguna ekle
	{
		echo -e "\nİşlem Özeti"
		echo "================="
		echo "Toplam işlenen dosya: ${#files_to_change[@]}"
		echo "Durum: $([[ $success -eq 0 ]] && echo "BAŞARILI" || echo "BAŞARISIZ")"
		echo "Yedekleme konumu: $backup_path"
	} >>"$backup_log"

	if [ $success -eq 0 ]; then
		log "OK" "Kullanıcı adı güncellemesi tamamlandı - Yedek: $backup_path"
	else
		log "ERROR" "Kullanıcı adı güncellemesi başarısız oldu - Yedek: $backup_path"
	fi

	return $success
}

get_host() {
	if [[ $AUTO == true ]]; then
		log "INFO" "Belirtilen ana bilgisayar kullanılıyor: $HOST"
		return 0
	fi

	log "STEP" "Ana bilgisayar türü seçiliyor"
	print_question "Ana bilgisayar türünü seçin - [${YELLOW}H${NORMAL}]ay (Dizüstü) veya [${YELLOW}V${NORMAL}]hay (VM): "
	read -n 1 -r
	echo

	case ${REPLY,,} in
	h) HOST='hay' ;;
	v) HOST='vhay' ;;
	*)
		log "ERROR" "Geçersiz ana bilgisayar türü"
		exit 1
		;;
	esac

	print_question "${GREEN}Ana bilgisayar${NORMAL} olarak ${YELLOW}$HOST${NORMAL} kullanılsın mı?"
	if confirm; then
		log "DEBUG" "Ana bilgisayar türü ayarlandı: $HOST"
		return 0
	fi
	exit 1
}

# Önbellekleme Destekli Sistem Derlemesi
build_system_with_cache() {
	log "STEP" "Sistem derlemesi başlatılıyor"
	echo -en "Sistem derlemesi başlasın mı? "
	if confirm; then
		local build_command="sudo nixos-rebuild switch --cores $BUILD_CORES --flake \".#${HOST}\" --option warn-dirty false"

		[[ -n "$PROFILE_NAME" ]] && {
			build_command+=" --profile-name \"$PROFILE_NAME\""
			log "INFO" "Profil kullanılıyor: $PROFILE_NAME"
		}

		# Önbellekleme için ek flagler
		[[ $CACHE_ENABLED == true ]] && {
			build_command+=" --option use-substitutes true"
			build_command+=" --option substitutes \"https://cache.nixos.org/ file://$CACHE_DIR\""
		}

		log "INFO" "Çalıştırılıyor: $build_command"

		# Derleme işlemi animasyonu
		show_animated_progress "$$" "Sistem derleniyor" &
		local animation_pid=$!

		if eval "$build_command"; then
			kill $animation_pid 2>/dev/null
			log "OK" "Sistem başarıyla derlendi"
			[[ -n "$PROFILE_NAME" ]] && log "OK" "Profil oluşturuldu: $PROFILE_NAME"

			# Derleme sonrası önbellekleme işlemleri
			if [[ $CACHE_ENABLED == true ]]; then
				log "DEBUG" "Derleme çıktıları önbelleğe alınıyor"
				local build_cache_key=$(generate_cache_key "build-${HOST}-$(date +%Y%m%d)")
				save_to_cache "$build_cache_key" "/nix/var/nix/profiles/system"
			fi

			return 0
		else
			kill $animation_pid 2>/dev/null
			log "ERROR" "Derleme başarısız oldu"
			return 1
		fi
	else
		log "ERROR" "Derleme kullanıcı tarafından iptal edildi"
		exit 1
	fi
}

# ==============================================================================
# Kurulum Fonksiyonları
# ==============================================================================
# Gelişmiş Dizin Oluşturma - önbellekleme uyumlu
setup_directories() {
	log "STEP" "Gerekli dizinler oluşturuluyor"
	local dirs=(
		"$HOME/Pictures/wallpapers/others"
		"$HOME/Pictures/wallpapers/nixos"
		"$CONFIG_DIR"
	)

	# Her bir dizin için alt ilerleme göstergesi
	local total=${#dirs[@]}
	local current=0

	for dir in "${dirs[@]}"; do
		((current++))
		echo "Dizin oluşturuluyor: $dir" # Alt ilerleme için çıktı
		mkdir -p "$dir"
		log "DEBUG" "Oluşturuldu: $dir"
	done
}

# Önbellekleme Destekli Duvar Kağıdı Kopyalama
copy_wallpapers() {
	log "STEP" "Duvar kağıtları ayarlanıyor"

	# Duvar kağıdı önbelleği için anahtar
	local cache_key=$(generate_cache_key "wallpapers-$(date +%Y%m%d)")
	local wallpaper_temp="$HOME/.wallpaper-temp"

	# Duvar kağıtları önbellekten alınabilir mi?
	if [[ $CACHE_ENABLED == true ]] && get_from_cache "$cache_key" "$wallpaper_temp"; then
		log "INFO" "Duvar kağıtları önbellekten alınıyor"

		# Önbellekten alınan duvar kağıtlarını kopyala
		if [[ -d "$wallpaper_temp" ]]; then
			cp -r "$wallpaper_temp/"* "$WALLPAPER_DIR/"
			log "OK" "Duvar kağıtları önbellekten kopyalandı"
			rm -rf "$wallpaper_temp"
			return 0
		fi
	fi

	# Önbellekte yoksa normal kopyalama yap
	mkdir -p "$wallpaper_temp/others" "$wallpaper_temp/nixos"
	cp -r wallpapers/wallpaper.png "$wallpaper_temp/"
	cp -r wallpapers/others/* "$wallpaper_temp/others/"
	cp -r wallpapers/nixos/* "$wallpaper_temp/nixos/"

	# Duvar kağıtlarını hedef dizine kopyala
	cp -r "$wallpaper_temp/"* "$WALLPAPER_DIR/"

	# Önbelleğe kaydet
	if [[ $CACHE_ENABLED == true ]]; then
		save_to_cache "$cache_key" "$wallpaper_temp"
	fi

	# Geçici dizini temizle
	rm -rf "$wallpaper_temp"

	log "OK" "Duvar kağıtları başarıyla kopyalandı"
	return 0
}

# Donanım Konfigürasyonu Kopyalama - önbellekleme uyumlu
copy_hardware_config() {
	local source="/etc/nixos/hardware-configuration.nix"
	local target="hosts/${HOST}/hardware-configuration.nix"

	if [[ ! -f "$source" ]]; then
		log "ERROR" "Donanım konfigürasyonu bulunamadı: $source"
		exit 1
	fi

	log "STEP" "Donanım konfigürasyonu kopyalanıyor"

	# Değişiklik var mı kontrol et
	if [[ -f "$target" ]] && cmp -s "$source" "$target"; then
		log "INFO" "Donanım konfigürasyonu güncel, kopyalamaya gerek yok"
		return 0
	fi

	# Değişiklik varsa kopyala
	cp "$source" "$target"
	log "OK" "Donanım konfigürasyonu kopyalandı: $HOST"

	return 0
}

# ==============================================================================
# Profil Yönetimi
# ==============================================================================
list_profiles() {
	log "STEP" "NixOS profilleri listeleniyor"
	if output=$(nix profile list); then
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

get_profile_name() {
	if [[ -z "$PROFILE_NAME" && $SILENT == false ]]; then
		echo # Yeni satır
		print_question "Bir profil adı belirtmek ister misiniz?"
		if confirm; then
			print_question "Profil adını girin: ${YELLOW}"
			read -r PROFILE_NAME
			echo -en "$NORMAL"
			log "DEBUG" "Profil adı: $PROFILE_NAME"
		fi
	fi
}

# ==============================================================================
# Ön Kurulum Ayarları
# ==============================================================================
setup_initial_config() {
	local host_type=$1
	log "STEP" "$host_type için ilk konfigürasyon ayarlanıyor"

	local template="hosts/${host_type}/templates/initial-configuration.nix"
	local config="/etc/nixos/configuration.nix"

	# Önkoşulları doğrula
	[[ ! -f "$template" ]] && {
		log "ERROR" "Şablon bulunamadı: $template"
		return 1
	}

	groups | grep -q '\bwheel\b' || {
		log "ERROR" "Mevcut kullanıcı wheel grubunda olmalıdır"
		return 1
	}

	# Mevcut konfigürasyonu yedekle
	[[ -f "$config" ]] && {
		local backup="${config}.backup-$(date +%Y%m%d_%H%M%S)"
		log "INFO" "Yedekleniyor: $config → $backup"
		command sudo cp "$config" "$backup"
	}

	# Yeni konfigürasyonu uygula
	if command sudo cp "$template" "$config" &&
		command sudo chown root:root "$config" &&
		command sudo chmod 644 "$config"; then
		log "OK" "İlk konfigürasyon tamamlandı"
		return 0
	else
		log "ERROR" "Konfigürasyon ayarlaması başarısız oldu"
		return 1
	fi
}

pre_install() {
	local host_type=$1
	log "STEP" "$host_type için ön kurulum başlatılıyor"

	setup_initial_config "$host_type" || {
		log "ERROR" "İlk konfigürasyon başarısız oldu"
		return 1
	}

	log "STEP" "Sistem yeniden derleniyor"
	if sudo nixos-rebuild switch --profile-name start; then
		log "OK" "Ön kurulum tamamlandı"
		echo -e "\n${GREEN}İlk kurulum tamamlandı.${NORMAL}"
		echo -e "Lütfen ${YELLOW}yeniden başlatın${NORMAL} ve şu komutu çalıştırın:"
		echo -e "${BLUE}$SCRIPT_NAME${NORMAL} ana kurulum için"
		return 0
	else
		log "ERROR" "Sistem derlemesi başarısız oldu"
		return 1
	fi
}

# ==============================================================================
# Ana Kurulum Süreci ve İlerleme Göstergeleri
# ==============================================================================
install() {
	# Sadece belirli işlemler istenmişse onları yap ve çık
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

	# Ana kurulum adımları ve görüntülenecek mesajlar
	local steps=(
		"Dizin yapısı oluşturuluyor"          # 1. adım
		"Duvar kağıtları kopyalanıyor"        # 2. adım
		"Donanım konfigürasyonu kopyalanıyor" # 3. adım
		"Profil adı alınıyor"                 # 4. adım
	)

	# Flake güncellemesi isteniyorsa ekle
	[[ $UPDATE_FLAKE == true ]] && steps+=("Flake yapılandırması güncelleniyor")
	# Son adım her zaman sistem derlemesi
	steps+=("Sistem derleniyor")

	# Adımlara karşılık gelen fonksiyonlar
	local total=${#steps[@]}
	local current=0
	local step_functions=(
		"setup_directories"
		"copy_wallpapers"
		"copy_hardware_config"
		"get_profile_name"
	)

	# Flake güncellemesi isteniyorsa fonksiyonu da ekle
	[[ $UPDATE_FLAKE == true ]] && step_functions+=("update_flake_with_cache")
	# Son fonksiyon her zaman sistem derlemesi
	step_functions+=("build_system_with_cache")

	# İlerleme göstergesi için başlangıç zamanı
	progress_start_time=$(date +%s)

	echo -e "\n${CYAN}Kurulum başlatılıyor...${NORMAL}\n"

	# Tüm adımları sırayla işle
	for i in "${!step_functions[@]}"; do
		local step=${step_functions[$i]}
		local step_name=${steps[$i]}
		((current++))

		# Ana ilerleme göstergesini göster
		show_progress $current $total "$step_name"

		# Her adım için özel işlem
		case "$step" in
		# Dizin yapısı oluşturma adımı için alt ilerleme göstergesi
		"setup_directories")
			setup_directories | while read -r line; do
				show_substep_progress $((++substep_count)) 3 "$line"
				sleep 0.2
			done
			substep_count=0
			;;
		# Flake güncellemesi için önbellekli versiyonu kullan
		"update_flake_with_cache")
			update_flake_with_cache
			;;
		# Derleme için önbellekli versiyonu kullan
		"build_system_with_cache")
			build_system_with_cache
			;;
		# Diğer adımlar için normal fonksiyonları çağır
		*)
			$step || {
				log "ERROR" "$step adımında hata oluştu"
				exit 1
			}
			;;
		esac
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
# Ana Menü ve Kullanıcı Arayüzü
# ==============================================================================
main_menu() {
	local options=(
		"1) Sistem kur"
		"2) Flake güncelle"
		"3) Modül güncelle"
		"4) Yedekleme yap"
		"5) Önbellek durumunu göster"
		"6) Önbelleği temizle"
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
	2) update_flake_with_cache ;;
	3)
		echo -en "Güncellenecek modül adı: "
		read -r UPDATE_MODULE
		update_single_module
		;;
	4) backup_flake ;;
	5) show_cache_usage ;;
	6) clean_cache ;;
	0) exit 0 ;;
	*) echo "Geçersiz seçim" ;;
	esac
}

# ==============================================================================
# Komut Satırı Argümanlarını İşleme
# ==============================================================================
process_args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		--pre-install) PRE_INSTALL=true ;;
		--list-profiles)
			list_profiles
			exit
			;;
		--delete-profile)
			shift
			delete_profile "$1"
			exit
			;;
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
		-p | --profile)
			shift
			PROFILE_NAME="$1"
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
		-l | --list-modules)
			list_available_modules
			exit
			;;
		-hc | --health-check)
			check_system_health
			exit
			;;
		-a | --auto)
			AUTO=true
			SILENT=true
			shift
			if [[ -n "$1" && "$1" =~ ^(hay|vhay)$ ]]; then
				HOST="$1"
			else
				log "ERROR" "Geçersiz ana bilgisayar (hay/vhay kullanın)"
				exit 1
			fi
			;;
		--cache)
			CACHE_ENABLED=true
			;;
		--no-cache)
			CACHE_ENABLED=false
			;;
		--cache-dir)
			shift
			CACHE_DIR="$1"
			;;
		--cache-clear)
			clean_cache
			exit
			;;
		--cache-status)
			show_cache_usage
			exit
			;;
		*)
			log "ERROR" "Bilinmeyen seçenek: $1"
			print_help
			exit 1
			;;
		esac
		shift
	done
}

# ==============================================================================
# Ana Giriş Noktası
# ==============================================================================
main() {
	init_colors         # Terminal renk desteğini başlat
	setup_logging       # Loglama sistemini kur
	process_args "$@"   # Komut satırı argümanlarını işle
	check_root          # Root kullanıcısı kontrolü
	check_system_health # Sistem sağlık kontrolü

	# Auto mod değilse başlık göster
	[[ $AUTO == false ]] && print_header

	# Interaktif veya otomatik mod
	if [[ $AUTO == false && $SILENT == false ]]; then
		main_menu
	else
		# Otomatik mod için zorunlu işlemler
		get_username
		set_username
		get_host
		install
	fi

	# Kurulum sonrası özet
	show_summary
}

# Betiğin çalıştırılması
main "$@"
exit 0
