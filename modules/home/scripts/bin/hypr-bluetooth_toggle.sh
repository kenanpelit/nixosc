#!/usr/bin/env bash
#######################################
#
# Version: 1.2.0
# Date: 2025-07-16
# Original Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprFlow - Enhanced Bluetooth Connection Manager
#
# License: MIT
#
#######################################

# Bluetooth cihaz bilgileri
DEFAULT_DEVICE_ADDRESS="F4:9D:8A:3D:CB:30"
DEFAULT_DEVICE_NAME="SL4P"
ALTERNATIVE_DEVICE_ADDRESS="E8:EE:CC:4D:29:00"
ALTERNATIVE_DEVICE_NAME="SL4"

# Ses ayarları
BT_VOLUME_LEVEL=40
BT_MIC_LEVEL=5
DEFAULT_VOLUME_LEVEL=15
DEFAULT_MIC_LEVEL=0

# Timeout ayarları
BLUETOOTH_TIMEOUT=10
AUDIO_WAIT_TIME=3
MAX_RETRY_COUNT=3

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Loglama fonksiyonu
log() {
	local level="${2:-INFO}"
	local color=""

	case $level in
	"ERROR") color=$RED ;;
	"SUCCESS") color=$GREEN ;;
	"WARNING") color=$YELLOW ;;
	"INFO") color=$BLUE ;;
	esac

	echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $1${NC}"
}

# Hata kontrolü fonksiyonu
check_command() {
	command -v $1 >/dev/null 2>&1 || {
		log "Hata: $1 komutu bulunamadı. Lütfen yükleyin." "ERROR"
		exit 1
	}
}

# Bildirim gönderme fonksiyonu
send_notification() {
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -t 5000 "$1" "$2"
	fi
}

# Bluetooth cihazının mevcut olup olmadığını kontrol etme
check_device_availability() {
	local device_address=$1

	if ! bluetoothctl info "$device_address" >/dev/null 2>&1; then
		log "Cihaz $device_address bulunamadı veya eşleştirilmemiş." "ERROR"
		return 1
	fi
	return 0
}

# Bluetooth servisinin durumunu kontrol etme
check_bluetooth_service() {
	if ! systemctl is-active --quiet bluetooth; then
		log "Bluetooth servisi aktif değil. Başlatılıyor..." "WARNING"
		sudo systemctl start bluetooth
		sleep 2
	fi
}

# Güvenli ses ayarları fonksiyonu
configure_audio() {
	local mode=$1
	local retry_count=0

	if [ "$mode" = "bluetooth" ]; then
		log "Bluetooth ses cihazı bekleniyor..." "INFO"
		sleep $AUDIO_WAIT_TIME

		# Bluetooth sink ayarları
		while [ $retry_count -lt $MAX_RETRY_COUNT ]; do
			bluetooth_sink=$(pactl list short sinks | grep -i "bluez" | head -n1 | awk '{print $2}')
			if [ -n "$bluetooth_sink" ]; then
				if pactl set-default-sink "$bluetooth_sink" 2>/dev/null; then
					pactl set-sink-volume @DEFAULT_SINK@ ${BT_VOLUME_LEVEL}% 2>/dev/null
					log "Ses çıkışı Bluetooth cihazına ayarlandı: $bluetooth_sink (%${BT_VOLUME_LEVEL})" "SUCCESS"
					break
				fi
			fi
			retry_count=$((retry_count + 1))
			log "Bluetooth sink bulunamadı, tekrar deneniyor... ($retry_count/$MAX_RETRY_COUNT)" "WARNING"
			sleep 1
		done

		# Bluetooth source ayarları
		retry_count=0
		while [ $retry_count -lt $MAX_RETRY_COUNT ]; do
			bluetooth_source=$(pactl list short sources | grep -i "bluez.*input" | head -n1 | awk '{print $2}')
			if [ -n "$bluetooth_source" ]; then
				if pactl set-default-source "$bluetooth_source" 2>/dev/null; then
					pactl set-source-volume @DEFAULT_SOURCE@ ${BT_MIC_LEVEL}% 2>/dev/null
					log "Ses girişi Bluetooth cihazına ayarlandı: $bluetooth_source (%${BT_MIC_LEVEL})" "SUCCESS"
					break
				fi
			fi
			retry_count=$((retry_count + 1))
			log "Bluetooth source bulunamadı, tekrar deneniyor... ($retry_count/$MAX_RETRY_COUNT)" "WARNING"
			sleep 1
		done

		if [ $retry_count -eq $MAX_RETRY_COUNT ]; then
			log "Bluetooth mikrofon ayarlanamadı, sadece hoparlör kullanılabilir." "WARNING"
		fi
	else
		# Varsayılan ses ayarlarına dönme
		if pactl set-sink-volume @DEFAULT_SINK@ ${DEFAULT_VOLUME_LEVEL}% 2>/dev/null &&
			pactl set-source-volume @DEFAULT_SOURCE@ ${DEFAULT_MIC_LEVEL}% 2>/dev/null; then
			log "Varsayılan ses çıkışı %${DEFAULT_VOLUME_LEVEL}, ses girişi %${DEFAULT_MIC_LEVEL} seviyesine ayarlandı." "SUCCESS"
		else
			log "Varsayılan ses ayarları yapılandırılırken hata oluştu." "WARNING"
		fi
	fi
}

# Bluetooth bağlantı yönetimi fonksiyonu
manage_bluetooth_connection() {
	local device_address=$1
	local device_name=$2

	# Cihaz kullanılabilirliğini kontrol et
	check_device_availability "$device_address" || return 1

	# Cihazın bağlantı durumunu alıyoruz
	local connection_status
	if ! connection_status=$(bluetoothctl info "$device_address" 2>/dev/null | grep "Connected:" | awk '{print $2}'); then
		log "Bluetooth cihaz bilgisi alınamadı." "ERROR"
		return 1
	fi

	# Duruma göre bağlantı durumunu belirliyoruz
	if [ "$connection_status" == "yes" ]; then
		log "Cihaz $device_name ($device_address) şu anda bağlı" "INFO"
		log "Bağlantı kesiliyor..." "INFO"

		# Timeout ile bağlantı kesme
		if timeout $BLUETOOTH_TIMEOUT bluetoothctl disconnect "$device_address" >/dev/null 2>&1; then
			log "Bağlantı başarıyla kesildi." "SUCCESS"
			send_notification "$device_name Bağlantısı Kesildi" "$device_name ($device_address) bağlantısı kesildi."
			configure_audio "default"
			log "Cihaz $device_name ($device_address) şimdi bağlantı kesildi" "INFO"
		else
			log "Bağlantı kesilirken timeout oluştu veya bir sorun oluştu." "ERROR"
			return 1
		fi
	else
		log "Cihaz $device_name ($device_address) şu anda bağlı değil" "INFO"
		log "Bağlanılıyor..." "INFO"

		# Timeout ile bağlantı kurma
		if timeout $BLUETOOTH_TIMEOUT bluetoothctl connect "$device_address" >/dev/null 2>&1; then
			log "Bağlantı başarıyla kuruldu." "SUCCESS"
			send_notification "$device_name Bağlandı" "$device_name ($device_address) bağlantısı kuruldu."
			configure_audio "bluetooth"
			log "Cihaz $device_name ($device_address) şimdi bağlandı" "INFO"
		else
			log "Bağlanırken timeout oluştu veya bir sorun oluştu." "ERROR"
			return 1
		fi
	fi

	return 0
}

# Bluetooth durumunu kontrol etme
check_bluetooth_power() {
	if ! bluetoothctl show | grep -q "Powered: yes"; then
		log "Bluetooth etkin değil. Etkinleştiriliyor..." "WARNING"
		if bluetoothctl power on >/dev/null 2>&1; then
			sleep 2
			log "Bluetooth başarıyla etkinleştirildi." "SUCCESS"
		else
			log "Bluetooth etkinleştirilemedi." "ERROR"
			return 1
		fi
	fi
	return 0
}

# Yardım mesajı
show_help() {
	cat <<EOF
Kullanım: $0 [SEÇENEKLER] [MAC_ADRESI] [CİHAZ_ADI]

Seçenekler:
  -h, --help     Bu yardım mesajını göster
  -v, --verbose  Detaylı çıktı ver
  -q, --quiet    Sadece hata mesajlarını göster

Örnekler:
  $0                                    # Varsayılan cihazı kullan
  $0 F4:9D:8A:3D:CB:30 "SL4P"         # Belirli cihazı kullan
  $0 -v                                # Detaylı modda çalıştır

Varsayılan cihaz: $DEFAULT_DEVICE_NAME ($DEFAULT_DEVICE_ADDRESS)
EOF
}

# Komut satırı argümanlarını işleme
parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			show_help
			exit 0
			;;
		-v | --verbose)
			set -x
			shift
			;;
		-q | --quiet)
			exec 2>/dev/null
			shift
			;;
		-*)
			log "Bilinmeyen seçenek: $1" "ERROR"
			show_help
			exit 1
			;;
		*)
			if [ -z "$DEVICE_ADDRESS" ]; then
				DEVICE_ADDRESS=$1
			elif [ -z "$DEVICE_NAME" ]; then
				DEVICE_NAME=$1
			else
				log "Çok fazla argüman." "ERROR"
				show_help
				exit 1
			fi
			shift
			;;
		esac
	done
}

# Temizlik fonksiyonu
cleanup() {
	log "Script sonlandırılıyor..." "INFO"
	exit 0
}

# Signal handler
trap cleanup SIGINT SIGTERM

# Ana işlem
main() {
	# Komut satırı argümanlarını işle
	parse_arguments "$@"

	# Varsayılan değerleri ayarla
	DEVICE_ADDRESS="${DEVICE_ADDRESS:-$DEFAULT_DEVICE_ADDRESS}"
	DEVICE_NAME="${DEVICE_NAME:-$DEFAULT_DEVICE_NAME}"

	# Gerekli komutları kontrol et
	check_command bluetoothctl
	check_command pactl
	check_command timeout

	# Bluetooth servisini kontrol et
	check_bluetooth_service

	# Bluetooth gücünü kontrol et
	check_bluetooth_power || exit 1

	# Bilgi göster
	log "Bluetooth cihazı: $DEVICE_NAME ($DEVICE_ADDRESS)" "INFO"

	# Bluetooth bağlantısını yönet
	if manage_bluetooth_connection "$DEVICE_ADDRESS" "$DEVICE_NAME"; then
		log "İşlem başarıyla tamamlandı." "SUCCESS"
		exit 0
	else
		log "İşlem sırasında hata oluştu." "ERROR"
		exit 1
	fi
}

# Scripti çalıştır
main "$@"
