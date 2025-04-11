#!/usr/bin/env bash

#######################################
#
# Version: 1.0.2
# Date: 2025-04-11
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
TEMP_DAY=4300        # Gündüz sıcaklığı (6000K)
TEMP_EVENING=4200    # Akşam sıcaklığı (5000K)
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
    yüksek değerler (örn. 6500K) daha soğuk/manvimsi renk verir.

EOF
}

# Bağımlılıkları kontrol et
check_dependencies() {
	log "Bağımlılıkları kontrol ediliyor"
	if ! command -v hyprsunset &>/dev/null; then
		echo "Error: hyprsunset bulunamadı. Lütfen yükleyin."
		log "HATA: hyprsunset komutu bulunamadı"
		exit 1
	fi

	# notify-send de kontrol edilsin
	if ! command -v notify-send &>/dev/null; then
		log "UYARI: notify-send bulunamadı, bildirimler gösterilmeyecek"
		# notify-send olmadan da çalışabilir, sadece uyarı verelim
		send_notification() {
			log "Bildirim (notify-send olmadan): $2"
		}
	else
		send_notification() {
			notify-send -t 2000 "$1" "$2"
			log "Bildirim gönderildi: $1 - $2"
		}
	fi
}

# Sıcaklığı ayarla
set_temperature() {
	local temp=$1
	log "Sıcaklık ayarlanıyor: ${temp}K"
	hyprsunset -t $temp
	# Son ayarlanan sıcaklığı kaydet
	echo "$temp" >"$LAST_TEMP_FILE"
}

# Mevcut saati al
get_current_hour() {
	date +%H
}

# Servisi başlat
start_sunset() {
	if [ ! -f "$STATE_FILE" ]; then
		log "Hypr Sunset başlatılıyor"
		touch "$STATE_FILE"
		start_daemon
		send_notification "Hypr Sunset" "Başlatıldı"

		# Daha güvenli başlangıç kontrolü
		sleep 1
		if [ -f "$PID_FILE" ]; then
			pid=$(cat "$PID_FILE")
			if kill -0 $pid 2>/dev/null; then
				log "Daemon başarıyla başlatıldı (PID: $pid)"
				return 0
			else
				log "UYARI: Daemon başlatıldı ama PID geçersiz!"
				rm -f "$PID_FILE"
				return 2
			fi
		else
			log "UYARI: Daemon başlatılamadı!"
			return 2
		fi
	else
		log "Servis zaten çalışıyor"
		send_notification "Hypr Sunset" "Servis zaten çalışıyor"
		return 1
	fi
}

# Servisi durdur
stop_sunset() {
	if [ -f "$STATE_FILE" ]; then
		log "Hypr Sunset durduruluyor"
		# Önce state dosyasını kaldır
		rm -f "$STATE_FILE"

		# Tüm hyprsunset process'lerini bul ve öldür
		pkill -f hyprsunset || true
		log "hyprsunset süreçleri sonlandırıldı"

		# PID dosyasını kontrol et ve process'i öldür
		if [ -f "$PID_FILE" ]; then
			pid=$(cat "$PID_FILE")
			kill -9 "$pid" 2>/dev/null || true
			log "Daemon süreci sonlandırıldı (PID: $pid)"
			rm -f "$PID_FILE"
		fi

		# Son olarak rengi sıfırla ve bildirim gönder
		sleep 0.5 # Küçük bir bekleme ekle
		hyprsunset -i
		log "Renk sıcaklığı sıfırlandı"
		send_notification "Hypr Sunset" "Durduruldu"
		return 0
	else
		log "Servis zaten durdurulmuş durumda"
		send_notification "Hypr Sunset" "Servis zaten durdurulmuş"
		return 1
	fi
}

# Toggle fonksiyonu
toggle_sunset() {
	log "Toggle çağrıldı"
	if [ -f "$STATE_FILE" ]; then
		# Eğer state file varsa ama PID file yoksa, servisi yeniden başlat
		if [ ! -f "$PID_FILE" ]; then
			log "State dosyası var ama PID dosyası yok, servis yeniden başlatılıyor"
			start_daemon
			send_notification "Hypr Sunset" "Servis yeniden başlatıldı"
			return
		fi

		# PID file varsa, servisi durdur
		log "Servis kapatılıyor (toggle)"
		stop_sunset
	else
		# State file yoksa, servisi başlat
		log "Servis başlatılıyor (toggle)"
		start_sunset
	fi
}

# Sıcaklığı ayarla
adjust_temperature() {
	local hour=$(get_current_hour)
	log "Saat $hour için sıcaklık ayarlanıyor"

	if [ "$hour" -ge "$TIME_DAY_START" ] && [ "$hour" -lt "$TIME_EVENING_START" ]; then
		log "Gündüz modu: ${TEMP_DAY}K"
		set_temperature $TEMP_DAY
	elif [ "$hour" -ge "$TIME_EVENING_START" ] && [ "$hour" -lt "$TIME_NIGHT_START" ]; then
		log "Akşam modu: ${TEMP_EVENING}K"
		set_temperature $TEMP_EVENING
	elif [ "$hour" -ge "$TIME_NIGHT_START" ] && [ "$hour" -lt "$TIME_LATE_NIGHT_START" ]; then
		log "Gece modu: ${TEMP_NIGHT}K"
		set_temperature $TEMP_NIGHT
	else
		log "Geç gece modu: ${TEMP_LATE_NIGHT}K"
		set_temperature $TEMP_LATE_NIGHT
	fi
}

# Daemon'u başlat
start_daemon() {
	log "Daemon başlatılıyor"
	# Arka planda çalıştır
	(
		while [ -f "$STATE_FILE" ]; do
			adjust_temperature
			log "Bir sonraki kontrol için bekleniyor (${CHECK_INTERVAL} saniye)"
			sleep $CHECK_INTERVAL
		done
	) &

	# PID'yi kaydet
	echo $! >"$PID_FILE"
	log "Daemon PID: $(cat "$PID_FILE")"
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
		echo "  Log dosyası: ${LOG_FILE}"

		# PID dosyası yoksa uyarı göster
		if [ ! -f "$PID_FILE" ]; then
			echo "UYARI: Servis durumu tutarsız (PID dosyası bulunamadı)"
		elif ! kill -0 $pid 2>/dev/null; then
			echo "UYARI: Servis durumu tutarsız (PID geçersiz)"
		fi
	else
		echo "Hypr Sunset: KAPALI"
	fi

	# Log bilgisini göster
	if [ -f "$LOG_FILE" ]; then
		echo ""
		echo "Son log kayıtları:"
		tail -n 5 "$LOG_FILE"
	fi
}

# Ana işlem
main() {
	# Log dosyasını başlat/kontrol et
	touch "$LOG_FILE"
	log "Hypr Blue Hyprsunset Manager başlatıldı"

	check_dependencies

	# Parametreleri işle
	while [[ $# -gt 0 ]]; do
		case $1 in
		--temp-day)
			TEMP_DAY="$2"
			log "Gündüz sıcaklığı ayarlandı: $TEMP_DAY"
			shift 2
			;;
		--temp-evening)
			TEMP_EVENING="$2"
			log "Akşam sıcaklığı ayarlandı: $TEMP_EVENING"
			shift 2
			;;
		--temp-night)
			TEMP_NIGHT="$2"
			log "Gece sıcaklığı ayarlandı: $TEMP_NIGHT"
			shift 2
			;;
		--temp-late)
			TEMP_LATE_NIGHT="$2"
			log "Geç gece sıcaklığı ayarlandı: $TEMP_LATE_NIGHT"
			shift 2
			;;
		--day-start)
			TIME_DAY_START="$2"
			log "Gündüz başlangıcı ayarlandı: $TIME_DAY_START"
			shift 2
			;;
		--evening-start)
			TIME_EVENING_START="$2"
			log "Akşam başlangıcı ayarlandı: $TIME_EVENING_START"
			shift 2
			;;
		--night-start)
			TIME_NIGHT_START="$2"
			log "Gece başlangıcı ayarlandı: $TIME_NIGHT_START"
			shift 2
			;;
		--interval)
			CHECK_INTERVAL="$2"
			log "Kontrol aralığı ayarlandı: $CHECK_INTERVAL saniye"
			shift 2
			;;
		--auto-start)
			AUTO_START=true
			log "Otomatik başlatma etkinleştirildi"
			shift
			;;
		start)
			log "'start' komutu alındı"
			start_sunset
			exit $?
			;;
		stop)
			log "'stop' komutu alındı"
			stop_sunset
			exit $?
			;;
		toggle)
			log "'toggle' komutu alındı"
			toggle_sunset
			exit $?
			;;
		status)
			log "'status' komutu alındı"
			show_status
			exit $?
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			echo "Geçersiz parametre: $1"
			log "HATA: Geçersiz parametre: $1"
			usage
			exit 1
			;;
		esac
	done

	# Eğer hiç parametre verilmemişse kullanım bilgisini göster
	if [ "$AUTO_START" = true ]; then
		log "Otomatik başlatma modu"
		if [ ! -f "$STATE_FILE" ]; then
			log "State dosyası bulunamadı, otomatik başlatılıyor"
			touch "$STATE_FILE"
			start_daemon
		else
			log "State dosyası zaten var, servis çalışıyor olabilir"
		fi
	else
		log "Parametre verilmedi, kullanım bilgisi gösteriliyor"
		usage
		exit 1
	fi
}

# CTRL+C ile düzgün çıkış
trap 'echo "Program sonlandırılıyor..."; log "Program sonlandırılıyor (SIGINT/SIGTERM)"; [ -f "$LAST_TEMP_FILE" ] && hyprsunset -t $(cat "$LAST_TEMP_FILE"); [ -f "$STATE_FILE" ] && rm "$STATE_FILE"; [ -f "$PID_FILE" ] && rm "$PID_FILE"; exit 0' SIGINT SIGTERM

# Programı başlat
main "$@"
