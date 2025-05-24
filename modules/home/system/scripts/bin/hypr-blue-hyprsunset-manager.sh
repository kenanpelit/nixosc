#!/usr/bin/env bash

#######################################
#
# Version: 1.0.3
# Date: 2025-05-24
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
declare -r LAST_TEMP_FILE="$HOME/.cache/hyprsunset.last"

# Loglama fonksiyonu
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

# Varsayılan sıcaklık ayarları
TEMP_DAY=4300
TEMP_EVENING=4200
TEMP_NIGHT=4100
TEMP_LATE_NIGHT=4000

# Varsayılan zaman ayarları
TIME_DAY_START=6
TIME_EVENING_START=17
TIME_NIGHT_START=20
TIME_LATE_NIGHT_START=22

# Diğer ayarlar
CHECK_INTERVAL=3600
AUTO_START=false

# Cleanup function - FIXED
cleanup() {
	local exit_code=$?
	log "Cleanup çağrıldı (exit code: $exit_code)"

	# Sadece stop komutu veya hata durumunda cleanup yap
	if [[ "$CLEANUP_ON_EXIT" == "true" ]]; then
		log "Cleanup yapılıyor..."
		if [[ -f "$PID_FILE" ]]; then
			local pid=$(cat "$PID_FILE" 2>/dev/null)
			if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
				kill -TERM "$pid" 2>/dev/null
				sleep 2
				kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null
			fi
			rm -f "$PID_FILE"
		fi
		rm -f "$STATE_FILE"

		# Reset temperature
		if command -v hyprsunset >/dev/null 2>&1; then
			hyprsunset -i >/dev/null 2>&1
		fi
		log "Cleanup tamamlandı"
	else
		log "Normal çıkış - cleanup atlandı"
	fi
}

# Set trap for cleanup
CLEANUP_ON_EXIT=false
trap cleanup EXIT INT TERM

# Kullanım bilgisi
usage() {
	cat <<EOF
Hypr Sunset - Renk Sıcaklığı Yönetim Aracı (Fixed Version)

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
    --temp-evening VALUE    Akşam sıcaklığı (Kelvin)
    --temp-night VALUE      Gece sıcaklığı (Kelvin)
    --temp-late VALUE       Geç gece sıcaklığı (Kelvin)
    --day-start VALUE       Gündüz başlangıç saati (0-23)
    --evening-start VALUE   Akşam başlangıç saati (0-23)
    --night-start VALUE     Gece başlangıç saati (0-23)
    --interval VALUE        Kontrol aralığı (saniye)

ÖRNEKLER:
    $(basename "$0") start
    $(basename "$0") toggle
    $(basename "$0") status
EOF
}

# Bağımlılıkları kontrol et
check_dependencies() {
	if ! command -v hyprsunset >/dev/null 2>&1; then
		echo "Error: hyprsunset bulunamadı. Lütfen yükleyin."
		log "HATA: hyprsunset komutu bulunamadı"
		exit 1
	fi
}

# Bildirim gönder
send_notification() {
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -t 2000 "$1" "$2" 2>/dev/null
	fi
	log "Bildirim: $1 - $2"
}

# Sıcaklığı ayarla
set_temperature() {
	local temp=$1
	log "Sıcaklık ayarlanıyor: ${temp}K"

	# Sessiz modda çalıştır
	if hyprsunset -t "$temp" >/dev/null 2>&1; then
		echo "$temp" >"$LAST_TEMP_FILE"
		log "Sıcaklık başarıyla ayarlandı: ${temp}K"
	else
		log "HATA: Sıcaklık ayarlanamadı: ${temp}K"
	fi
}

# Mevcut saati al
get_current_hour() {
	date +%H
}

# Sıcaklığı ayarla
adjust_temperature() {
	local hour=$(get_current_hour)
	log "Saat $hour için sıcaklık ayarlanıyor"

	if [[ "$hour" -ge "$TIME_DAY_START" && "$hour" -lt "$TIME_EVENING_START" ]]; then
		set_temperature "$TEMP_DAY"
	elif [[ "$hour" -ge "$TIME_EVENING_START" && "$hour" -lt "$TIME_NIGHT_START" ]]; then
		set_temperature "$TEMP_EVENING"
	elif [[ "$hour" -ge "$TIME_NIGHT_START" && "$hour" -lt "$TIME_LATE_NIGHT_START" ]]; then
		set_temperature "$TEMP_NIGHT"
	else
		set_temperature "$TEMP_LATE_NIGHT"
	fi
}

# Daemon fonksiyonu - FIXED
daemon_loop() {
	log "Daemon döngüsü başlatıldı (PID: $$)"

	# İlk sıcaklık ayarını yap
	adjust_temperature

	while [[ -f "$STATE_FILE" ]]; do
		sleep "$CHECK_INTERVAL"

		# State file kontrol et
		if [[ ! -f "$STATE_FILE" ]]; then
			log "State file silinmiş, daemon sonlanıyor"
			break
		fi

		adjust_temperature
		log "Bir sonraki kontrol: ${CHECK_INTERVAL} saniye sonra"
	done

	log "Daemon döngüsü sona erdi"
}

# Servisi başlat - FIXED
start_sunset() {
	if [[ -f "$STATE_FILE" ]]; then
		log "Servis zaten çalışıyor"
		echo "Hypr Sunset zaten çalışıyor"
		return 1
	fi

	log "Hypr Sunset başlatılıyor"
	touch "$STATE_FILE"

	# Daemon'u arka planda başlat
	daemon_loop &
	local daemon_pid=$!

	# PID'yi kaydet
	echo "$daemon_pid" >"$PID_FILE"
	log "Daemon başlatıldı (PID: $daemon_pid)"

	# Başlatmanın başarılı olduğunu kontrol et
	sleep 1
	if kill -0 "$daemon_pid" 2>/dev/null; then
		send_notification "Hypr Sunset" "Başarıyla başlatıldı"
		echo "Hypr Sunset başlatıldı (PID: $daemon_pid)"
		return 0
	else
		log "HATA: Daemon başlatılamadı"
		rm -f "$STATE_FILE" "$PID_FILE"
		echo "HATA: Servis başlatılamadı"
		return 1
	fi
}

# Servisi durdur - FIXED
stop_sunset() {
	if [[ ! -f "$STATE_FILE" ]]; then
		log "Servis zaten durdurulmuş"
		echo "Hypr Sunset zaten durdurulmuş"
		return 1
	fi

	log "Hypr Sunset durduruluyor"

	# Cleanup flag'i set et
	CLEANUP_ON_EXIT=true

	# State file'ı sil (daemon döngüsünü durdurmak için)
	rm -f "$STATE_FILE"

	# PID file varsa daemon'u öldür
	if [[ -f "$PID_FILE" ]]; then
		local pid=$(cat "$PID_FILE")
		if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
			log "Daemon sonlandırılıyor (PID: $pid)"
			kill -TERM "$pid" 2>/dev/null

			# 5 saniye bekle
			for i in {1..5}; do
				if ! kill -0 "$pid" 2>/dev/null; then
					break
				fi
				sleep 1
			done

			# Hala çalışıyorsa zorla öldür
			if kill -0 "$pid" 2>/dev/null; then
				log "Daemon zorla sonlandırılıyor"
				kill -KILL "$pid" 2>/dev/null
			fi
		fi
		rm -f "$PID_FILE"
	fi

	# Rengi sıfırla
	if hyprsunset -i >/dev/null 2>&1; then
		log "Renk sıcaklığı sıfırlandı"
	fi

	send_notification "Hypr Sunset" "Durduruldu"
	echo "Hypr Sunset durduruldu"

	# Cleanup flag'i sıfırla
	CLEANUP_ON_EXIT=false
	return 0
}

# Toggle fonksiyonu - FIXED
toggle_sunset() {
	if [[ -f "$STATE_FILE" ]]; then
		stop_sunset
	else
		start_sunset
	fi
}

# Durum göster - FIXED
show_status() {
	if [[ -f "$STATE_FILE" ]]; then
		local pid=""
		local status="AKTİF"

		if [[ -f "$PID_FILE" ]]; then
			pid=$(cat "$PID_FILE")
			if ! kill -0 "$pid" 2>/dev/null; then
				status="HATA (PID geçersiz)"
			fi
		else
			status="HATA (PID dosyası yok)"
		fi

		echo "Hypr Sunset: $status"
		[[ -n "$pid" ]] && echo "PID: $pid"
		echo "Son başlatma: $(stat -c %y "$STATE_FILE" 2>/dev/null || echo 'Bilinmiyor')"
		echo "Ayarlar:"
		echo "  Gündüz: ${TEMP_DAY}K (${TIME_DAY_START}:00)"
		echo "  Akşam: ${TEMP_EVENING}K (${TIME_EVENING_START}:00)"
		echo "  Gece: ${TEMP_NIGHT}K (${TIME_NIGHT_START}:00)"
		echo "  Geç gece: ${TEMP_LATE_NIGHT}K (${TIME_LATE_NIGHT_START}:00)"
		echo "  Kontrol aralığı: ${CHECK_INTERVAL} saniye"

		# Son sıcaklık
		if [[ -f "$LAST_TEMP_FILE" ]]; then
			echo "  Son sıcaklık: $(cat "$LAST_TEMP_FILE")K"
		fi
	else
		echo "Hypr Sunset: KAPALI"
	fi

	# Son log kayıtları
	if [[ -f "$LOG_FILE" ]]; then
		echo ""
		echo "Son log kayıtları:"
		tail -n 3 "$LOG_FILE" 2>/dev/null || echo "Log okunamadı"
	fi
}

# Ana işlem - FIXED
main() {
	# Log dosyasını başlat
	mkdir -p "$(dirname "$LOG_FILE")"
	touch "$LOG_FILE"
	log "=== Hypr Sunset Manager başlatıldı ==="

	check_dependencies

	# Eğer parametre yoksa usage göster
	if [[ $# -eq 0 ]]; then
		usage
		exit 1
	fi

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
}

# Programı başlat
main "$@"
