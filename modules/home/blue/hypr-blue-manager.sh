#!/usr/bin/env bash

#######################################
#
# Version: 2.0.0
# Date: 2025-11-03
# Author: Kenan Pelit (Modified)
# Repository: github.com/kenanpelit/dotfiles
# Description: Unified Gammastep + HyprSunset Manager
#
# License: MIT
#
#######################################

#########################################################################
# Unified Night Light Manager
#
# Bu script, Gammastep ve HyprSunset'i birlikte yönetir.
# Her iki araç da aynı anda çalışarak istediğiniz renk tonunu elde eder.
#
# Özellikler:
#   - Gammastep ve HyprSunset'i eşzamanlı başlatma/durdurma
#   - Zaman tabanlı otomatik renk sıcaklığı ayarlama
#   - Waybar entegrasyonu
#   - Sistem bildirimleri
#   - Daemon ve fork modları
#
# Gereksinimler:
#   - gammastep
#   - hyprsunset
#   - libnotify (notify-send için)
#   - waybar (opsiyonel)
#
#########################################################################

# Dosya yolları
declare -r STATE_FILE="$HOME/.cache/hypr-blue.state"
declare -r PID_FILE="$HOME/.cache/hypr-blue.pid"
declare -r GAMMASTEP_PID_FILE="$HOME/.cache/hypr-blue-gammastep.pid"
declare -r LOG_FILE="/tmp/hypr-blue.log"
declare -r LAST_TEMP_FILE="$HOME/.cache/hypr-blue.last"

# Gammastep ayarları
MODE="wayland"
LOCATION="41.0108:29.0219"
GAMMA="1,0.2,0.1"
BRIGHTNESS_DAY=1.0
BRIGHTNESS_NIGHT=0.8

# Sıcaklık ayarları - Sarı/Turuncu ton (Basitleştirilmiş)
TEMP_DAY=3400   # Gündüz sıcaklığı - Hafif sarı
TEMP_NIGHT=3100 # Gece sıcaklığı - Koyu turuncu

# Gammastep sıcaklık ayarları - HyprSunset ile uyumlu
GAMMASTEP_TEMP_DAY=3400   # Gündüz - Hafif sarı (HyprSunset ile aynı)
GAMMASTEP_TEMP_NIGHT=3100 # Gece - Koyu turuncu (HyprSunset ile aynı)

# Diğer ayarlar
CHECK_INTERVAL=3600
CLEANUP_ON_EXIT=false

# Loglama fonksiyonu
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

# Kullanım bilgisi
usage() {
	cat <<EOF
Hypr Blue Manager - Unified Gammastep + HyprSunset Manager

KULLANIM:
    $(basename "$0") [KOMUT] [PARAMETRELER]

KOMUTLAR:
    start         Night light'ı başlat (fork modu)
    daemon        Daemon modunda başlat (systemd için)
    stop          Night light'ı durdur
    toggle        Night light'ı aç/kapat
    status        Durum göster
    -h, --help    Bu yardım mesajını göster

HYPRSUNSET PARAMETRELERI:
    --temp-day VALUE        Gündüz sıcaklığı (Kelvin, varsayılan: $TEMP_DAY)
    --temp-night VALUE      Gece sıcaklığı (Kelvin, varsayılan: $TEMP_NIGHT)

GAMMASTEP PARAMETRELERI:
    --gs-temp-day VALUE     Gammastep gündüz sıcaklığı (Kelvin, varsayılan: $GAMMASTEP_TEMP_DAY)
    --gs-temp-night VALUE   Gammastep gece sıcaklığı (Kelvin, varsayılan: $GAMMASTEP_TEMP_NIGHT)
    --bright-day VALUE      Gündüz parlaklığı (0.1-1.0, varsayılan: $BRIGHTNESS_DAY)
    --bright-night VALUE    Gece parlaklığı (0.1-1.0, varsayılan: $BRIGHTNESS_NIGHT)
    --location VALUE        Konum (format: enlem:boylam, varsayılan: $LOCATION)
    --gamma VALUE           Gamma değeri (format: r,g,b, varsayılan: $GAMMA)
    --interval VALUE        Kontrol aralığı (saniye, varsayılan: $CHECK_INTERVAL)

ÖRNEKLER:
    # Varsayılan ayarlarla başlatma
    $(basename "$0") start

    # Özel sıcaklıklarla başlatma
    $(basename "$0") start --temp-day 3800 --temp-night 3200

    # Gammastep ayarları ile
    $(basename "$0") start --gs-temp-day 3700 --gs-temp-night 3100

    # Systemd servisi için
    $(basename "$0") daemon

    # Durum kontrolü
    $(basename "$0") status

NOT:
    - Bu script hem gammastep hem de hyprsunset'i birlikte çalıştırır
    - Her iki araç da aynı sıcaklıklarda çalışır (uyumlu katmanlar)
    - Gammastep otomatik yumuşak geçiş yapar
    - HyprSunset ek renk katmanı olarak çalışır
    - Düşük sıcaklık değerleri daha sıcak/kırmızımsı renk verir
EOF
}

# Bağımlılıkları kontrol et
check_dependencies() {
	local missing_deps=()

	if ! command -v gammastep >/dev/null 2>&1; then
		missing_deps+=("gammastep")
	fi

	if ! command -v hyprsunset >/dev/null 2>&1; then
		missing_deps+=("hyprsunset")
	fi

	if [ ${#missing_deps[@]} -gt 0 ]; then
		echo "Hata: Eksik bağımlılıklar: ${missing_deps[*]}"
		log "HATA: Eksik bağımlılıklar: ${missing_deps[*]}"
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

# Waybar'ı güncelle
update_waybar() {
	if command -v waybar &>/dev/null; then
		pkill -RTMIN+8 waybar
	fi
}

# Mevcut saati al
get_current_hour() {
	date +%H
}

# HyprSunset için sıcaklık belirle (Gammastep gibi basit)
get_hyprsunset_temp() {
	local hour=$(get_current_hour)

	# Gündüz: 6:00-18:00 arası
	# Gece: 18:00-6:00 arası
	if [[ "$hour" -ge 6 && "$hour" -lt 18 ]]; then
		echo "$TEMP_DAY"
	else
		echo "$TEMP_NIGHT"
	fi
}

# Gammastep'i başlat
start_gammastep() {
	log "Gammastep başlatılıyor..."

	# Eski gammastep process'lerini temizle
	pkill -9 gammastep 2>/dev/null
	sleep 1

	/usr/bin/gammastep -m "$MODE" \
		-l manual \
		-t "$GAMMASTEP_TEMP_DAY:$GAMMASTEP_TEMP_NIGHT" \
		-b "$BRIGHTNESS_DAY:$BRIGHTNESS_NIGHT" \
		-l "$LOCATION" \
		-g "$GAMMA" \
		>>/dev/null 2>&1 &

	local gammastep_pid=$!
	echo "$gammastep_pid" >"$GAMMASTEP_PID_FILE"
	disown

	log "Gammastep başlatıldı (PID: $gammastep_pid, Gündüz: ${GAMMASTEP_TEMP_DAY}K, Gece: ${GAMMASTEP_TEMP_NIGHT}K)"
}

# Gammastep'i durdur
stop_gammastep() {
	log "Gammastep durduruluyor..."

	if [[ -f "$GAMMASTEP_PID_FILE" ]]; then
		local pid=$(cat "$GAMMASTEP_PID_FILE")
		if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
			kill -TERM "$pid" 2>/dev/null
			sleep 1
			kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null
		fi
		rm -f "$GAMMASTEP_PID_FILE"
	fi

	# Tüm gammastep process'lerini temizle
	pkill -9 gammastep 2>/dev/null
	log "Gammastep durduruldu"
}

# HyprSunset sıcaklığını ayarla
set_hyprsunset_temperature() {
	local temp=$1
	log "HyprSunset sıcaklığı ayarlanıyor: ${temp}K"

	if hyprsunset -t "$temp" >/dev/null 2>&1; then
		echo "$temp" >"$LAST_TEMP_FILE"
		log "HyprSunset sıcaklığı ayarlandı: ${temp}K"
	else
		log "HATA: HyprSunset sıcaklığı ayarlanamadı: ${temp}K"
	fi
}

# Sıcaklıkları ayarla
adjust_temperature() {
	local temp=$(get_hyprsunset_temp)
	set_hyprsunset_temperature "$temp"
}

# Cleanup fonksiyonu
cleanup() {
	local exit_code=$?
	log "Cleanup çağrıldı (exit code: $exit_code)"

	if [[ "$CLEANUP_ON_EXIT" == "true" ]]; then
		log "Cleanup yapılıyor..."

		# Gammastep'i durdur
		stop_gammastep

		# HyprSunset daemon'ı durdur
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

		# HyprSunset sıcaklığını sıfırla
		if command -v hyprsunset >/dev/null 2>&1; then
			hyprsunset -i >/dev/null 2>&1
		fi

		log "Cleanup tamamlandı"
	else
		log "Normal çıkış - cleanup atlandı"
	fi
}

# Daemon cleanup
cleanup_daemon() {
	log "Daemon cleanup başlıyor (PID: $$)"

	stop_gammastep
	rm -f "$STATE_FILE" "$PID_FILE"

	if command -v hyprsunset >/dev/null 2>&1; then
		hyprsunset -i >/dev/null 2>&1
		log "HyprSunset sıcaklığı sıfırlandı"
	fi

	log "Daemon cleanup tamamlandı"
}

# Trap ayarla
trap cleanup EXIT INT TERM

# Daemon loop (fork modu için)
daemon_loop() {
	log "Fork daemon döngüsü başlatıldı (PID: $$)"

	# İlk ayarlamaları yap
	start_gammastep
	adjust_temperature

	while [[ -f "$STATE_FILE" ]]; do
		sleep "$CHECK_INTERVAL"

		if [[ ! -f "$STATE_FILE" ]]; then
			log "State file silinmiş, daemon sonlanıyor"
			break
		fi

		# Gammastep'in çalıştığını kontrol et
		if [[ -f "$GAMMASTEP_PID_FILE" ]]; then
			local gs_pid=$(cat "$GAMMASTEP_PID_FILE")
			if ! kill -0 "$gs_pid" 2>/dev/null; then
				log "Gammastep durmuş, yeniden başlatılıyor"
				start_gammastep
			fi
		else
			log "Gammastep PID file yok, yeniden başlatılıyor"
			start_gammastep
		fi

		adjust_temperature
		log "Bir sonraki kontrol: ${CHECK_INTERVAL} saniye sonra"
	done

	log "Fork daemon döngüsü sona erdi"
}

# Daemon modu (systemd için)
daemon_mode() {
	log "Systemd daemon modu başlatıldı (PID: $$)"

	touch "$STATE_FILE"
	echo "$$" >"$PID_FILE"

	trap 'cleanup_daemon; exit 0' EXIT INT TERM

	# İlk ayarlamaları yap
	start_gammastep
	adjust_temperature

	while true; do
		sleep "$CHECK_INTERVAL"

		if [[ ! -f "$STATE_FILE" ]]; then
			log "State file silinmiş, daemon sonlanıyor"
			break
		fi

		# Gammastep kontrolü
		if [[ -f "$GAMMASTEP_PID_FILE" ]]; then
			local gs_pid=$(cat "$GAMMASTEP_PID_FILE")
			if ! kill -0 "$gs_pid" 2>/dev/null; then
				log "Gammastep durmuş, yeniden başlatılıyor"
				start_gammastep
			fi
		else
			start_gammastep
		fi

		adjust_temperature
		log "Bir sonraki kontrol: ${CHECK_INTERVAL} saniye sonra"
	done

	log "Daemon modu sona erdi"
}

# Servisi başlat (fork modu)
start_service() {
	if [[ -f "$STATE_FILE" ]]; then
		log "Servis zaten çalışıyor"
		echo "Hypr Blue Manager zaten çalışıyor"
		return 1
	fi

	log "Hypr Blue Manager başlatılıyor (fork modu)"
	touch "$STATE_FILE"

	daemon_loop &
	local daemon_pid=$!

	echo "$daemon_pid" >"$PID_FILE"
	log "Fork daemon başlatıldı (PID: $daemon_pid)"

	sleep 1
	if kill -0 "$daemon_pid" 2>/dev/null; then
		send_notification "Hypr Blue Manager" "Başarıyla başlatıldı (Gammastep + HyprSunset)"
		echo "Hypr Blue Manager başlatıldı (PID: $daemon_pid)"
		update_waybar
		return 0
	else
		log "HATA: Fork daemon başlatılamadı"
		rm -f "$STATE_FILE" "$PID_FILE"
		echo "HATA: Servis başlatılamadı"
		return 1
	fi
}

# Servisi durdur
stop_service() {
	if [[ ! -f "$STATE_FILE" ]]; then
		log "Servis zaten durdurulmuş"
		echo "Hypr Blue Manager zaten durdurulmuş"
		return 1
	fi

	log "Hypr Blue Manager durduruluyor"
	CLEANUP_ON_EXIT=true

	rm -f "$STATE_FILE"

	if [[ -f "$PID_FILE" ]]; then
		local pid=$(cat "$PID_FILE")
		if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
			log "Daemon sonlandırılıyor (PID: $pid)"
			kill -TERM "$pid" 2>/dev/null

			for i in {1..5}; do
				if ! kill -0 "$pid" 2>/dev/null; then
					break
				fi
				sleep 1
			done

			if kill -0 "$pid" 2>/dev/null; then
				log "Daemon zorla sonlandırılıyor"
				kill -KILL "$pid" 2>/dev/null
			fi
		fi
		rm -f "$PID_FILE"
	fi

	# Gammastep'i durdur
	stop_gammastep

	# HyprSunset'i sıfırla
	if hyprsunset -i >/dev/null 2>&1; then
		log "HyprSunset sıcaklığı sıfırlandı"
	fi

	send_notification "Hypr Blue Manager" "Durduruldu"
	echo "Hypr Blue Manager durduruldu"
	update_waybar

	CLEANUP_ON_EXIT=false
	return 0
}

# Toggle fonksiyonu
toggle_service() {
	if [[ -f "$STATE_FILE" ]]; then
		stop_service
	else
		start_service
	fi
}

# Durum göster
show_status() {
	echo "=== Hypr Blue Manager Durumu ==="
	echo ""

	if [[ -f "$STATE_FILE" ]]; then
		local pid=""
		local status="AKTİF"
		local mode="Bilinmiyor"

		if [[ -f "$PID_FILE" ]]; then
			pid=$(cat "$PID_FILE")
			if kill -0 "$pid" 2>/dev/null; then
				if ps -p "$pid" -o cmd= | grep -q "daemon"; then
					mode="Systemd Daemon"
				else
					mode="Fork Daemon"
				fi
			else
				status="HATA (PID geçersiz)"
			fi
		else
			status="HATA (PID dosyası yok)"
		fi

		echo "Ana Servis: $status"
		[[ -n "$pid" ]] && echo "PID: $pid"
		echo "Mod: $mode"
		echo "Son başlatma: $(stat -c %y "$STATE_FILE" 2>/dev/null || echo 'Bilinmiyor')"
	else
		echo "Ana Servis: KAPALI"
	fi

	echo ""
	echo "--- Gammastep Durumu ---"
	if [[ -f "$GAMMASTEP_PID_FILE" ]]; then
		local gs_pid=$(cat "$GAMMASTEP_PID_FILE")
		if kill -0 "$gs_pid" 2>/dev/null; then
			echo "Durum: AKTİF (PID: $gs_pid)"
		else
			echo "Durum: HATA (PID geçersiz)"
		fi
	else
		if pgrep gammastep &>/dev/null; then
			echo "Durum: AKTİF (PID dosyası yok)"
		else
			echo "Durum: KAPALI"
		fi
	fi
	echo "Gündüz sıcaklığı: ${GAMMASTEP_TEMP_DAY}K"
	echo "Gece sıcaklığı: ${GAMMASTEP_TEMP_NIGHT}K"
	echo "Gündüz parlaklık: $BRIGHTNESS_DAY"
	echo "Gece parlaklık: $BRIGHTNESS_NIGHT"

	echo ""
	echo "--- HyprSunset Durumu ---"
	echo "Gündüz sıcaklığı: ${TEMP_DAY}K (06:00-18:00)"
	echo "Gece sıcaklığı: ${TEMP_NIGHT}K (18:00-06:00)"
	echo "Kontrol aralığı: ${CHECK_INTERVAL} saniye"

	if [[ -f "$LAST_TEMP_FILE" ]]; then
		echo "Son sıcaklık: $(cat "$LAST_TEMP_FILE")K"
	fi

	echo ""
	echo "--- Konum ve Gamma ---"
	echo "Konum: $LOCATION"
	echo "Gamma: $GAMMA"

	if [[ -f "$LOG_FILE" ]]; then
		echo ""
		echo "--- Son Log Kayıtları ---"
		tail -n 5 "$LOG_FILE" 2>/dev/null || echo "Log okunamadı"
	fi
}

# Ana işlem
main() {
	mkdir -p "$(dirname "$LOG_FILE")"
	mkdir -p "$HOME/.cache"
	touch "$LOG_FILE"
	log "=== Hypr Blue Manager başlatıldı (v2.0.0) ==="

	check_dependencies

	if [[ $# -eq 0 ]]; then
		usage
		exit 1
	fi

	while [[ $# -gt 0 ]]; do
		case $1 in
		# HyprSunset parametreleri
		--temp-day)
			TEMP_DAY="$2"
			shift 2
			;;
		--temp-night)
			TEMP_NIGHT="$2"
			shift 2
			;;
		--interval)
			CHECK_INTERVAL="$2"
			shift 2
			;;
		# Gammastep parametreleri
		--gs-temp-day)
			GAMMASTEP_TEMP_DAY="$2"
			shift 2
			;;
		--gs-temp-night)
			GAMMASTEP_TEMP_NIGHT="$2"
			shift 2
			;;
		--bright-day)
			BRIGHTNESS_DAY="$2"
			shift 2
			;;
		--bright-night)
			BRIGHTNESS_NIGHT="$2"
			shift 2
			;;
		--location)
			LOCATION="$2"
			shift 2
			;;
		--gamma)
			GAMMA="$2"
			shift 2
			;;
		# Komutlar
		start)
			start_service
			exit $?
			;;
		daemon)
			daemon_mode
			exit $?
			;;
		stop)
			stop_service
			exit $?
			;;
		toggle)
			toggle_service
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
