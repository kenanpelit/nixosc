#!/usr/bin/env bash
#######################################
#
# Version: 1.1.1
# Date: 2025-04-26
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

# Loglama fonksiyonu
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Hata kontrolü fonksiyonu
check_command() {
	command -v $1 >/dev/null 2>&1 || {
		log "Hata: $1 komutu bulunamadı. Lütfen yükleyin."
		exit 1
	}
}

# Bildirim gönderme fonksiyonu
send_notification() {
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -t 5000 "$1" "$2"
	fi
}

# Ses ayarlarını yapılandırma fonksiyonu
configure_audio() {
	local mode=$1
	if [ "$mode" = "bluetooth" ]; then
		# Bluetooth cihazının tanımlanması için kısa bir bekleme süresi
		log "Bluetooth ses cihazı bekleniyor..."
		sleep 3
		# PulseAudio/PipeWire Bluetooth ses çıkışını ayarlama
		bluetooth_sink=$(pactl list short sinks | grep -i "bluez" | awk '{print $2}')
		if [ -n "$bluetooth_sink" ]; then
			pactl set-default-sink "$bluetooth_sink"
			pactl set-sink-volume @DEFAULT_SINK@ ${BT_VOLUME_LEVEL}%
			log "Ses çıkışı Bluetooth cihazına ayarlandı: $bluetooth_sink (%${BT_VOLUME_LEVEL})"
		else
			log "Uyarı: Bluetooth cihazı ses çıkışı olarak bulunamadı."
		fi
		# PulseAudio/PipeWire Bluetooth ses girişini ayarlama
		bluetooth_source=$(pactl list short sources | grep -i "bluez" | awk '{print $2}')
		if [ -n "$bluetooth_source" ]; then
			pactl set-default-source "$bluetooth_source"
			pactl set-source-volume @DEFAULT_SOURCE@ ${BT_MIC_LEVEL}%
			log "Ses girişi Bluetooth cihazına ayarlandı: $bluetooth_source (%${BT_MIC_LEVEL})"
		else
			log "Uyarı: Bluetooth cihazı ses girişi olarak bulunamadı."
		fi
	else
		# Varsayılan ses ayarlarına dönme
		pactl set-sink-volume @DEFAULT_SINK@ ${DEFAULT_VOLUME_LEVEL}%
		pactl set-source-volume @DEFAULT_SOURCE@ ${DEFAULT_MIC_LEVEL}%
		log "Varsayılan ses çıkışı %${DEFAULT_VOLUME_LEVEL}, ses girişi %${DEFAULT_MIC_LEVEL} seviyesine ayarlandı."
	fi
}

# Bluetooth bağlantı yönetimi fonksiyonu
manage_bluetooth_connection() {
	local device_address=$1
	local device_name=$2

	# Cihazın bağlantı durumunu alıyoruz
	if ! connection_status=$(bluetoothctl info "$device_address" | grep "Connected:" | awk '{print $2}'); then
		log "Hata: Bluetooth cihaz bilgisi alınamadı."
		exit 1
	fi

	# Duruma göre bağlantı durumunu belirliyoruz
	if [ "$connection_status" == "yes" ]; then
		current_status="bağlı"
		log "Cihaz $device_name ($device_address) şu anda $current_status"
		log "Bağlantı kesiliyor..."
		if bluetoothctl disconnect "$device_address"; then
			log "Bağlantı başarıyla kesildi."
			send_notification "$device_name Bağlantısı Kesildi" "$device_name ($device_address) bağlantısı kesildi."
			configure_audio "default"
			new_status="bağlantı kesildi"
		else
			log "Hata: Bağlantı kesilirken bir sorun oluştu."
			exit 1
		fi
	else
		current_status="bağlı değil"
		log "Cihaz $device_name ($device_address) şu anda $current_status"
		log "Bağlanılıyor..."
		if bluetoothctl connect "$device_address"; then
			log "Bağlantı başarıyla kuruldu."
			send_notification "$device_name Bağlandı" "$device_name ($device_address) bağlantısı kuruldu."
			configure_audio "bluetooth"
			new_status="bağlandı"
		else
			log "Hata: Bağlanırken bir sorun oluştu."
			exit 1
		fi
	fi

	log "Cihaz $device_name ($device_address) şimdi $new_status"
}

# Ana işlem
main() {
	# Gerekli komutları kontrol et
	check_command bluetoothctl
	check_command pactl

	# Komut satırı parametrelerini işle
	device_address="${1:-$DEFAULT_DEVICE_ADDRESS}"
	device_name="${2:-$DEFAULT_DEVICE_NAME}"

	# Bilgi göster
	log "Bluetooth cihazı: $device_name ($device_address)"

	# Bluetooth etkin mi kontrol et
	if ! bluetoothctl show | grep -q "Powered: yes"; then
		log "Bluetooth etkin değil. Etkinleştiriliyor..."
		bluetoothctl power on
		sleep 2
	fi

	# Bluetooth bağlantısını yönet
	manage_bluetooth_connection "$device_address" "$device_name"
}

# Scripti çalıştır
main "$@"
