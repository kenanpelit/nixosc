#!/usr/bin/env bash

# =================================================================
# Gelişmiş Duvar Kağıdı Değiştirici v2.2 (fd destekli)
# Temiz ve Basit Versiyon
# =================================================================

set -euo pipefail

# =================================================================
# YAPILANDIRMA - Bu değerleri ihtiyacınıza göre değiştirebilirsiniz
# =================================================================

DEFAULT_INTERVAL=300 # 5 dakika (saniye)
WALLPAPER_PATH="$HOME/Pictures/wallpapers"
WALLPAPERS_FOLDER="$WALLPAPER_PATH/others"
WALLPAPER_LINK="$WALLPAPER_PATH/wallpaper"
MAX_HISTORY=15
SUPPORTED_EXTENSIONS=("jpg" "jpeg" "png" "webp" "bmp")

# =================================================================
# SABİT DOSYA YOLLARI
# =================================================================

PID_FILE="/tmp/wallpaper-changer.pid"
SERVICE_LOCK_FILE="/tmp/wallpaper-changer-service.lock"
MANUAL_LOCK_FILE="/tmp/wallpaper-changer-manual.lock"
HISTORY_DIR="$HOME/.cache/wallpapers"
HISTORY_FILE="$HISTORY_DIR/history.txt"
TOTAL_FILE="$HISTORY_DIR/total_wallpapers.txt"
LOG_FILE="/tmp/wallpaper-changer.log"

# =================================================================
# RENKLER VE SABİTLER
# =================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

ANIMATIONS=("outer" "center" "any" "wipe" "fade")
SCRIPT_NAME="$(basename "$0")"

# =================================================================
# GLOBAL DEĞİŞKENLER
# =================================================================

INTERVAL=$DEFAULT_INTERVAL
VERBOSE=false
DRY_RUN=false
USE_FD=false

# =================================================================
# YARDIMCI FONKSİYONLAR
# =================================================================

# Hangi find komutunu kullanacağımızı belirle
detect_find_tool() {
	if command -v fd >/dev/null 2>&1; then
		USE_FD=true
		log DEBUG "fd komutu kullanılacak"
	else
		USE_FD=false
		log DEBUG "find komutu kullanılacak"
	fi
}

# Log fonksiyonu
log() {
	local level="$1"
	shift
	local message="$*"
	local timestamp
	timestamp=$(date '+%Y-%m-%d %H:%M:%S')

	case "$level" in
	ERROR) echo -e "${RED}[ERROR]${NC} $message" >&2 ;;
	WARN) echo -e "${YELLOW}[WARN]${NC} $message" >&2 ;;
	SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
	INFO) echo -e "${BLUE}[INFO]${NC} $message" ;;
	DEBUG) $VERBOSE && echo -e "${CYAN}[DEBUG]${NC} $message" ;;
	esac

	# Log dosyasına yaz
	echo "[$timestamp] [$level] $message" >>"$LOG_FILE" 2>/dev/null || true
}

# Lock dosyası ile güvenli işlem (farklı lock dosyaları kullanır)
acquire_lock() {
	local lock_type="${1:-manual}"
	local timeout=${2:-10}
	local count=0
	local lock_file

	case "$lock_type" in
	"service") lock_file="$SERVICE_LOCK_FILE" ;;
	"manual") lock_file="$MANUAL_LOCK_FILE" ;;
	*) lock_file="$MANUAL_LOCK_FILE" ;;
	esac

	while [ $count -lt $timeout ]; do
		if (
			set -C
			echo $$ >"$lock_file"
		) 2>/dev/null; then
			trap "rm -f \"$lock_file\"" EXIT
			log DEBUG "Lock alındı: $lock_file"
			return 0
		fi
		sleep 1
		((count++))
	done

	if [[ "$lock_type" == "service" ]]; then
		log ERROR "Servis lock'u alınamadı. Başka bir servis çalışıyor olabilir."
	else
		log WARN "Manuel işlem için lock alınamadı. Servis çalışıyor, ancak yine de devam ediliyor."
		# Manuel işlemlerde lock alamasak bile devam edelim
		return 0
	fi
	return 1
}

# Dizin kontrolü ve oluşturma
ensure_directory() {
	local dir="$1"
	local description="${2:-dizin}"

	if [[ ! -d "$dir" ]]; then
		log DEBUG "$description oluşturuluyor: $dir"
		mkdir -p "$dir" || {
			log ERROR "$description oluşturulamadı: $dir"
			return 1
		}
	fi
	return 0
}

# Duvar kağıtlarını listele (fd veya find)
list_wallpapers() {
	if $USE_FD; then
		# fd kullan
		fd -t f -e jpg -e jpeg -e png -e webp -e bmp . "$WALLPAPERS_FOLDER" 2>/dev/null
	else
		# find kullan
		local find_expr=""
		for i in "${!SUPPORTED_EXTENSIONS[@]}"; do
			if [[ $i -eq 0 ]]; then
				find_expr="-iname \"*.${SUPPORTED_EXTENSIONS[$i]}\""
			else
				find_expr="$find_expr -o -iname \"*.${SUPPORTED_EXTENSIONS[$i]}\""
			fi
		done
		eval "find \"$WALLPAPERS_FOLDER\" -type f \\( $find_expr \\)" 2>/dev/null
	fi
}

# Duvar kağıtlarını sadece basename ile listele
list_wallpapers_basename() {
	if $USE_FD; then
		# fd kullan
		fd -t f -e jpg -e jpeg -e png -e webp -e bmp . "$WALLPAPERS_FOLDER" -x basename 2>/dev/null
	else
		# find kullan
		local find_expr=""
		for i in "${!SUPPORTED_EXTENSIONS[@]}"; do
			if [[ $i -eq 0 ]]; then
				find_expr="-iname \"*.${SUPPORTED_EXTENSIONS[$i]}\""
			else
				find_expr="$find_expr -o -iname \"*.${SUPPORTED_EXTENSIONS[$i]}\""
			fi
		done
		eval "find \"$WALLPAPERS_FOLDER\" -type f \\( $find_expr \\) -exec basename {} \\;" 2>/dev/null
	fi
}

# =================================================================
# DUVAR KAĞIDI FONKSİYONLARI
# =================================================================

# Duvar kağıdını ayarla
set_wallpaper() {
	local wallpaper="$1"
	local animation="${2:-}"

	if [[ ! -f "$wallpaper" ]]; then
		log ERROR "Duvar kağıdı dosyası bulunamadı: $wallpaper"
		return 1
	fi

	# swww kontrolü
	if ! command -v swww >/dev/null 2>&1; then
		log ERROR "swww komutu bulunamadı. Lütfen swww'yi yükleyin."
		return 1
	fi

	# Animasyon seç
	if [[ -z "$animation" ]]; then
		animation="${ANIMATIONS[RANDOM % ${#ANIMATIONS[@]}]}"
	fi

	log DEBUG "Duvar kağıdı ayarlanıyor: $(basename "$wallpaper") (animasyon: $animation)"

	if [[ "$DRY_RUN" == "true" ]]; then
		log INFO "[DRY RUN] Duvar kağıdı: $wallpaper"
		return 0
	fi

	# swww komutunu çalıştır
	if [[ "$animation" == "wipe" ]]; then
		swww img --transition-type="wipe" --transition-angle=135 "$wallpaper" 2>/dev/null || {
			log ERROR "swww komutu başarısız"
			return 1
		}
	else
		swww img --transition-type="$animation" "$wallpaper" 2>/dev/null || {
			log ERROR "swww komutu başarısız"
			return 1
		}
	fi

	return 0
}

# Geçmiş dosyalarını hazırla
init_history() {
	ensure_directory "$HISTORY_DIR" "geçmiş dizini"
	touch "$HISTORY_FILE" "$TOTAL_FILE"
}

# Duvar kağıdı cache'ini güncelle
update_wallpaper_cache() {
	init_history

	log DEBUG "Duvar kağıtları taranıyor: $WALLPAPERS_FOLDER"

	# Duvar kağıtlarını bul
	local wallpaper_files
	mapfile -t wallpaper_files < <(list_wallpapers)

	local total=${#wallpaper_files[@]}
	echo "$total" >"$TOTAL_FILE"

	# Listeleri kaydet
	printf '%s\n' "${wallpaper_files[@]}" >"$HISTORY_DIR/available_wallpapers.txt" 2>/dev/null

	log DEBUG "Toplam $total duvar kağıdı bulundu"
	return 0
}

# Geçmişi temizle
cleanup_history() {
	if [[ -f "$HISTORY_FILE" ]]; then
		local line_count
		line_count=$(wc -l <"$HISTORY_FILE" 2>/dev/null || echo "0")

		if [[ $line_count -gt $MAX_HISTORY ]]; then
			log DEBUG "Geçmiş temizleniyor (mevcut: $line_count, maksimum: $MAX_HISTORY)"
			tail -n "$MAX_HISTORY" "$HISTORY_FILE" >"${HISTORY_FILE}.tmp"
			mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
		fi
	fi
}

# Ana duvar kağıdı değiştirme fonksiyonu
change_wallpaper() {
	local lock_type="${1:-manual}"

	# Servis modu dışında lock alma zorunlu değil
	if [[ "$lock_type" == "service" ]]; then
		acquire_lock "service" || return 1
	else
		# Manuel işlemde lock alamasak bile devam et
		acquire_lock "manual" 3 || log DEBUG "Manuel lock alınamadı, devam ediliyor"
	fi

	init_history
	update_wallpaper_cache

	# Duvar kağıtlarını listele
	local wallpaper_list
	mapfile -t wallpaper_list < <(list_wallpapers)

	local wallpaper_count=${#wallpaper_list[@]}

	if [[ $wallpaper_count -eq 0 ]]; then
		log ERROR "Duvar kağıdı bulunamadı: $WALLPAPERS_FOLDER"
		return 1
	fi

	log DEBUG "$wallpaper_count duvar kağıdı bulundu"

	# Son kullanılanları oku
	local recent_wallpapers=()
	if [[ -f "$HISTORY_FILE" ]]; then
		mapfile -t recent_wallpapers < <(tail -n 10 "$HISTORY_FILE" 2>/dev/null)
	fi

	# Yeni duvar kağıdı seç (tekrar etmeyen)
	local selected_wallpaper=""
	local selected_name=""
	local max_attempts=50
	local attempt=0

	while [[ $attempt -lt $max_attempts ]]; do
		selected_wallpaper="${wallpaper_list[RANDOM % wallpaper_count]}"
		selected_name=$(basename "$selected_wallpaper")

		# Son kullanılanlar listesinde var mı?
		local found=false
		for recent in "${recent_wallpapers[@]}"; do
			if [[ "$recent" == "$selected_name" ]]; then
				found=true
				break
			fi
		done

		if [[ "$found" == "false" ]]; then
			break
		fi

		((attempt++))
	done

	# Duvar kağıdını değiştir
	if ! set_wallpaper "$selected_wallpaper"; then
		return 1
	fi

	if [[ "$DRY_RUN" != "true" ]]; then
		# Symlink oluştur
		ln -sf "$selected_wallpaper" "$WALLPAPER_LINK" 2>/dev/null || {
			log WARN "Symlink oluşturulamadı: $WALLPAPER_LINK"
		}

		# Geçmişe ekle
		echo "$selected_name" >>"$HISTORY_FILE"
		cleanup_history
	fi

	log SUCCESS "Duvar kağıdı değiştirildi: $selected_name"
	return 0
}

# =================================================================
# SERVİS YÖNETİMİ
# =================================================================

# Servis durumu kontrol
check_status() {
	local quiet=${1:-false}

	if [[ ! -f "$PID_FILE" ]]; then
		$quiet || log WARN "Servis çalışmıyor"
		return 1
	fi

	local pid
	pid=$(cat "$PID_FILE" 2>/dev/null) || {
		$quiet || log WARN "PID dosyası okunamadı"
		rm -f "$PID_FILE"
		return 1
	}

	if ! kill -0 "$pid" 2>/dev/null; then
		$quiet || log WARN "Servis çalışmıyor (eski PID dosyası temizlendi)"
		rm -f "$PID_FILE"
		return 1
	fi

	$quiet || log SUCCESS "Servis çalışıyor (PID: $pid)"
	return 0
}

# Servisi başlat
start_service() {
	if check_status true; then
		log WARN "Servis zaten çalışıyor"
		return 1
	fi

	# Dizin kontrolü
	if [[ ! -d "$WALLPAPERS_FOLDER" ]]; then
		log ERROR "Duvar kağıdı dizini bulunamadı: $WALLPAPERS_FOLDER"
		return 1
	fi

	ensure_directory "$WALLPAPER_PATH" "ana dizin"

	log INFO "Servis başlatılıyor (aralık: ${INTERVAL}s)"

	# Ana döngü
	(
		while true; do
			if ! change_wallpaper "service"; then
				log ERROR "Duvar kağıdı değiştirilemedi, 60 saniye bekleniyor"
				sleep 60
			else
				sleep "$INTERVAL"
			fi
		done
	) >>"$LOG_FILE" 2>&1 &

	local main_pid=$!
	echo "$main_pid" >"$PID_FILE"

	# Başlatma kontrolü
	sleep 2
	if check_status true; then
		log SUCCESS "Servis başarıyla başlatıldı"
		return 0
	else
		log ERROR "Servis başlatılamadı"
		rm -f "$PID_FILE"
		return 1
	fi
}

# Servisi durdur
stop_service() {
	if [[ ! -f "$PID_FILE" ]]; then
		log WARN "Servis zaten çalışmıyor"
		return 0
	fi

	local pid
	pid=$(cat "$PID_FILE" 2>/dev/null) || {
		log WARN "PID dosyası okunamadı"
		rm -f "$PID_FILE"
		return 0
	}

	if kill -0 "$pid" 2>/dev/null; then
		log INFO "Servis durduruluyor (PID: $pid)"

		# TERM sinyali gönder
		kill -TERM "$pid" 2>/dev/null

		# 5 saniye bekle
		local count=0
		while [[ $count -lt 5 ]] && kill -0 "$pid" 2>/dev/null; do
			sleep 1
			((count++))
		done

		# Hâlâ çalışıyorsa KILL
		if kill -0 "$pid" 2>/dev/null; then
			log WARN "Servis zorla sonlandırılıyor"
			kill -KILL "$pid" 2>/dev/null
		fi

		log SUCCESS "Servis durduruldu"
	else
		log WARN "Servis zaten durmuş"
	fi

	rm -f "$PID_FILE" "$SERVICE_LOCK_FILE"
	return 0
}

# Servisi yeniden başlat
restart_service() {
	log INFO "Servis yeniden başlatılıyor"
	stop_service
	sleep 2
	start_service
}

# =================================================================
# İNTERAKTİF FONKSİYONLAR
# =================================================================

# Rofi ile duvar kağıdı seç
select_wallpaper_rofi() {
	if ! command -v rofi >/dev/null 2>&1; then
		log ERROR "rofi komutu bulunamadı"
		return 1
	fi

	local wallpaper_name
	wallpaper_name=$(list_wallpapers_basename | sort | rofi -dmenu -p "Duvar kağıdı seçin") || {
		log INFO "Seçim iptal edildi"
		return 1
	}

	local wallpaper_path="$WALLPAPERS_FOLDER/$wallpaper_name"

	if [[ -f "$wallpaper_path" ]]; then
		if set_wallpaper "$wallpaper_path"; then
			ln -sf "$wallpaper_path" "$WALLPAPER_LINK" 2>/dev/null || true

			init_history
			echo "$wallpaper_name" >>"$HISTORY_FILE"
			cleanup_history

			log SUCCESS "Duvar kağıdı değiştirildi: $wallpaper_name"
		fi
	else
		log ERROR "Seçilen dosya bulunamadı: $wallpaper_path"
		return 1
	fi
}

# İstatistikleri göster
show_stats() {
	init_history
	update_wallpaper_cache

	local total_wallpapers=0
	if [[ -f "$TOTAL_FILE" ]]; then
		total_wallpapers=$(cat "$TOTAL_FILE" 2>/dev/null || echo "0")
	fi

	local history_count=0
	if [[ -f "$HISTORY_FILE" ]]; then
		history_count=$(wc -l <"$HISTORY_FILE" 2>/dev/null || echo "0")
	fi

	local current_wallpaper="Bilinmiyor"
	if [[ -L "$WALLPAPER_LINK" ]]; then
		current_wallpaper=$(basename "$(readlink "$WALLPAPER_LINK")" 2>/dev/null || echo "Bilinmiyor")
	fi

	local find_tool="find"
	$USE_FD && find_tool="fd"

	echo -e "${CYAN}=== Duvar Kağıdı İstatistikleri ===${NC}"
	echo -e "Toplam duvar kağıdı: ${GREEN}$total_wallpapers${NC}"
	echo -e "Geçmiş kayıt sayısı: ${GREEN}$history_count${NC}"
	echo -e "Mevcut duvar kağıdı: ${GREEN}$current_wallpaper${NC}"
	echo -e "Duvar kağıdı dizini: ${BLUE}$WALLPAPERS_FOLDER${NC}"
	echo -e "Aralık: ${YELLOW}${INTERVAL}s${NC}"
	echo -e "Desteklenen formatlar: ${CYAN}${SUPPORTED_EXTENSIONS[*]}${NC}"
	echo -e "Kullanılan araç: ${CYAN}$find_tool${NC}"

	if check_status true; then
		echo -e "Servis durumu: ${GREEN}Çalışıyor${NC}"
	else
		echo -e "Servis durumu: ${RED}Durduruldu${NC}"
	fi
}

# Manuel duvar kağıdı değiştirme (servis çalışırken bile)
manual_change() {
	log INFO "Manuel duvar kağıdı değişimi başlatılıyor..."
	change_wallpaper "manual"
}

# =================================================================
# YARDIM VE ANA FONKSİYONLAR
# =================================================================

show_usage() {
	cat <<EOF
Duvar Kağıdı Değiştirici v2.2

KULLANIM:
    $SCRIPT_NAME [KOMUT] [SEÇENEKLER]

KOMUTLAR:
    start [süre]     Servisi başlatır (süre saniye cinsinden, varsayılan: $DEFAULT_INTERVAL)
    stop             Servisi durdurur  
    restart          Servisi yeniden başlatır
    status           Servis durumunu gösterir
    stats            İstatistikleri gösterir
    select           Rofi ile duvar kağıdı seç
    test             Tek seferlik test değişimi
    now              Servis çalışırken bile manuel değişim
    (boş)            Tek seferlik rastgele duvar kağıdı değişimi

SEÇENEKLER:
    -v, --verbose    Ayrıntılı çıktı
    -n, --dry-run    Deneme modu (gerçekte değişim yapmaz)
    -h, --help       Bu yardım mesajını gösterir

ÖRNEKLER:
    $SCRIPT_NAME start 300        # 5 dakikada bir değişir
    $SCRIPT_NAME -v start         # Ayrıntılı mod ile başlat
    $SCRIPT_NAME select           # Rofi ile seç
    $SCRIPT_NAME now              # Servis çalışırken manuel değişim
    $SCRIPT_NAME stats            # İstatistikleri göster

DOSYALAR:
    Geçmiş: $HISTORY_FILE
    Log:    $LOG_FILE

YAPILANDIRMA:
    Script içinde şu değişkenleri düzenleyebilirsiniz:
    - WALLPAPERS_FOLDER: $WALLPAPERS_FOLDER
    - MAX_HISTORY: $MAX_HISTORY
    - SUPPORTED_EXTENSIONS: ${SUPPORTED_EXTENSIONS[*]}

NOT:
    Script otomatik olarak 'fd' veya 'find' komutunu algılar ve kullanır.
EOF
}

# Ana fonksiyon
main() {
	# fd veya find'ı tespit et
	detect_find_tool

	# Komut satırı argümanları
	while [[ $# -gt 0 ]]; do
		case $1 in
		-v | --verbose)
			VERBOSE=true
			shift
			;;
		-n | --dry-run)
			DRY_RUN=true
			shift
			;;
		-h | --help)
			show_usage
			exit 0
			;;
		start)
			shift
			if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
				INTERVAL=$1
				shift
			elif [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
				log ERROR "Geçersiz aralık değeri: $1"
				exit 1
			fi
			start_service
			exit $?
			;;
		stop)
			stop_service
			exit $?
			;;
		restart)
			restart_service
			exit $?
			;;
		status)
			check_status
			exit $?
			;;
		stats)
			show_stats
			exit 0
			;;
		select)
			select_wallpaper_rofi
			exit $?
			;;
		now)
			manual_change
			exit $?
			;;
		test)
			if check_status true; then
				log ERROR "Test modu için önce servisi durdurun"
				exit 1
			fi
			change_wallpaper "manual"
			exit $?
			;;
		*)
			if [[ "$1" =~ ^- ]]; then
				log ERROR "Bilinmeyen seçenek: $1"
				show_usage
				exit 1
			else
				log ERROR "Bilinmeyen komut: $1"
				show_usage
				exit 1
			fi
			;;
		esac
	done

	# Parametre yoksa manuel değişim
	manual_change
}

# Script'i çalıştır
main "$@"
