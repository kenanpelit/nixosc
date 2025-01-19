#!/usr/bin/env bash

#######################################
#
# Version: 1.0.1
# Date: 2024-12-13
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: HyprSunset Manager
#
# License: MIT
#
#######################################

# Sabit değişkenler ve varsayılan ayarlar
declare -r STATE_FILE="$HOME/.cache/hyprsunset.state"
declare -r PID_FILE="$HOME/.cache/hyprsunset.pid"
declare -r LOG_FILE="/tmp/hyprsunset.log"

# Varsayılan sıcaklık ayarları
TEMP_DAY=4500        # Gündüz sıcaklığı (6000K)
TEMP_EVENING=4300    # Akşam sıcaklığı (5000K)
TEMP_NIGHT=4100      # Gece sıcaklığı (4000K)
TEMP_LATE_NIGHT=4000 # Geç gece sıcaklığı (3500K)

# Varsayılan zaman ayarları
TIME_DAY_START=6         # Gündüz başlangıcı
TIME_EVENING_START=17    # Akşam başlangıcı
TIME_NIGHT_START=20      # Gece başlangıcı
TIME_LATE_NIGHT_START=22 # Geç gece başlangıcı

# Diğer ayarlar
CHECK_INTERVAL=3600 # Kontrol aralığı (saniye)
AUTO_START=false    # Otomatik başlatma

# Kullanım bilgisi
usage() {
	cat <<EOF
Hypr Sunset - Renk Sıcaklığı Yönetim Aracı

KULLANIM:
    $(basename "$0") [KOMUT] [PARAMETRELER]

KOMUTLAR:
    start         Hypr Sunset'i başlat
    stop          Hypr Sunset'i durdur
    toggle        Hypr Sunset'i aç/kapat
    status        Hypr Sunset durumunu göster
    -h, --help    Bu yardım mesajını göster

PARAMETRELER:
    --temp-day VALUE        Gündüz sıcaklığı (Kelvin)
                           (varsayılan: $TEMP_DAY)
    --temp-evening VALUE    Akşam sıcaklığı (Kelvin)
                           (varsayılan: $TEMP_EVENING)
    --temp-night VALUE      Gece sıcaklığı (Kelvin)
                           (varsayılan: $TEMP_NIGHT)
    --temp-late VALUE       Geç gece sıcaklığı (Kelvin)
                           (varsayılan: $TEMP_LATE_NIGHT)
    --day-start VALUE       Gündüz başlangıç saati (0-23)
                           (varsayılan: $TIME_DAY_START)
    --evening-start VALUE   Akşam başlangıç saati (0-23)
                           (varsayılan: $TIME_EVENING_START)
    --night-start VALUE     Gece başlangıç saati (0-23)
                           (varsayılan: $TIME_NIGHT_START)
    --interval VALUE        Kontrol aralığı (saniye)
                           (varsayılan: $CHECK_INTERVAL)
    --auto-start           Otomatik başlatma aktif

ÖRNEKLER:
    # Varsayılan ayarlarla başlatma
    $(basename "$0") start

    # Özel sıcaklık değerleriyle başlatma
    $(basename "$0") start --temp-day 5500 --temp-night 3000

    # Özel zaman ayarlarıyla başlatma
    $(basename "$0") start --day-start 7 --evening-start 16

    # Durumu kontrol etme
    $(basename "$0") status

NOT:
    Renk sıcaklığı değerleri Kelvin cinsindendir.
    Düşük değerler (örn. 3000K) daha sıcak/kırmızımsı,
    yüksek değerler (örn. 6500K) daha soğuk/mavimsi renk verir.

EOF
}

# Bağımlılıkları kontrol et
check_dependencies() {
	if ! command -v hyprsunset &>/dev/null; then
		echo "Error: hyprsunset bulunamadı. Lütfen yükleyin."
		exit 1
	fi
}

# Sıcaklığı ayarla
set_temperature() {
	local temp=$1
	hyprsunset -t $temp
}

# Mevcut saati al
get_current_hour() {
	date +%H
}

# Servisi başlat
start_sunset() {
	if [ ! -f "$STATE_FILE" ]; then
		touch "$STATE_FILE"
		start_daemon
		notify-send -t 2000 "Hypr Sunset" "Başlatıldı"
		return 0
	fi
	return 1
}

# Servisi durdur
stop_sunset() {
	if [ -f "$STATE_FILE" ]; then
		# Önce state dosyasını kaldır
		rm -f "$STATE_FILE"

		# Tüm hyprsunset process'lerini bul ve öldür
		pkill -f hyprsunset || true

		# PID dosyasını kontrol et ve process'i öldür
		if [ -f "$PID_FILE" ]; then
			pid=$(cat "$PID_FILE")
			kill -9 "$pid" 2>/dev/null || true
			rm -f "$PID_FILE"
		fi

		# Son olarak rengi sıfırla ve bildirim gönder
		sleep 0.5 # Küçük bir bekleme ekle
		hyprsunset -i
		notify-send -t 2000 "Hypr Sunset" "Durduruldu"
		return 0
	fi
	return 1
}

# Toggle fonksiyonu
toggle_sunset() {
	if [ -f "$STATE_FILE" ]; then
		# Eğer state file varsa ama PID file yoksa, servisi yeniden başlat
		if [ ! -f "$PID_FILE" ]; then
			start_daemon
			notify-send -t 2000 "Hypr Sunset" "Servis yeniden başlatıldı"
			return
		fi

		# PID file varsa, servisi durdur
		stop_sunset
	else
		# State file yoksa, servisi başlat
		start_sunset
	fi
}

# Sıcaklığı ayarla
adjust_temperature() {
	local hour=$(get_current_hour)

	if [ "$hour" -ge "$TIME_DAY_START" ] && [ "$hour" -lt "$TIME_EVENING_START" ]; then
		set_temperature $TEMP_DAY
	elif [ "$hour" -ge "$TIME_EVENING_START" ] && [ "$hour" -lt "$TIME_NIGHT_START" ]; then
		set_temperature $TEMP_EVENING
	elif [ "$hour" -ge "$TIME_NIGHT_START" ] && [ "$hour" -lt "$TIME_LATE_NIGHT_START" ]; then
		set_temperature $TEMP_NIGHT
	else
		set_temperature $TEMP_LATE_NIGHT
	fi
}

# Daemon'u başlat
start_daemon() {
	# Arka planda çalıştır
	(
		while [ -f "$STATE_FILE" ]; do
			adjust_temperature
			sleep $CHECK_INTERVAL
		done
	) &

	# PID'yi kaydet
	echo $! >"$PID_FILE"
}

# Detaylı durum bilgisi göster
show_status() {
	if [ -f "$STATE_FILE" ]; then
		local pid=""
		[ -f "$PID_FILE" ] && pid=$(cat "$PID_FILE")

		echo "Hypr Sunset: AKTİF"
		echo "PID: $pid"
		echo "Son başlatma: $(stat -c %y "$STATE_FILE")"
		echo "Ayarlar:"
		echo "  Gündüz sıcaklığı: ${TEMP_DAY}K (${TIME_DAY_START}:00'dan itibaren)"
		echo "  Akşam sıcaklığı: ${TEMP_EVENING}K (${TIME_EVENING_START}:00'dan itibaren)"
		echo "  Gece sıcaklığı: ${TEMP_NIGHT}K (${TIME_NIGHT_START}:00'dan itibaren)"
		echo "  Geç gece sıcaklığı: ${TEMP_LATE_NIGHT}K (${TIME_LATE_NIGHT_START}:00'dan itibaren)"
		echo "  Kontrol aralığı: ${CHECK_INTERVAL} saniye"

		# PID dosyası yoksa uyarı göster
		if [ ! -f "$PID_FILE" ]; then
			echo "UYARI: Servis durumu tutarsız (PID dosyası bulunamadı)"
		fi
	else
		echo "Hypr Sunset: KAPALI"
	fi
}

# Ana işlem
main() {
	check_dependencies

	# Parametreleri işle
	while [[ $# -gt 0 ]]; do
		case $1 in
		--temp-day)
			TEMP_DAY="$2"
			shift 2
			;;
		--temp-evening)
			TEMP_EVENING="$2"
			shift 2
			;;
		--temp-night)
			TEMP_NIGHT="$2"
			shift 2
			;;
		--temp-late)
			TEMP_LATE_NIGHT="$2"
			shift 2
			;;
		--day-start)
			TIME_DAY_START="$2"
			shift 2
			;;
		--evening-start)
			TIME_EVENING_START="$2"
			shift 2
			;;
		--night-start)
			TIME_NIGHT_START="$2"
			shift 2
			;;
		--interval)
			CHECK_INTERVAL="$2"
			shift 2
			;;
		--auto-start)
			AUTO_START=true
			shift
			;;
		start)
			start_sunset
			exit $?
			;;
		stop)
			stop_sunset
			exit $?
			;;
		toggle)
			toggle_sunset
			exit $?
			;;
		status)
			show_status
			exit $?
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			echo "Geçersiz parametre: $1"
			usage
			exit 1
			;;
		esac
	done

	# Eğer hiç parametre verilmemişse kullanım bilgisini göster
	if [ "$AUTO_START" = true ]; then
		if [ ! -f "$STATE_FILE" ]; then
			touch "$STATE_FILE"
			start_daemon
		fi
	else
		usage
		exit 1
	fi
}

# CTRL+C ile düzgün çıkış
# Son renk değerini sakla ve çıkışta uygulama
declare -r LAST_TEMP_FILE="$HOME/.cache/hyprsunset.last"
trap 'echo "Program sonlandırılıyor..."; [ -f "$LAST_TEMP_FILE" ] && hyprsunset -t $(cat "$LAST_TEMP_FILE"); [ -f "$STATE_FILE" ] && rm "$STATE_FILE"; [ -f "$PID_FILE" ] && rm "$PID_FILE"; exit 0' SIGINT SIGTERM

# Programı başlat
main "$@"
