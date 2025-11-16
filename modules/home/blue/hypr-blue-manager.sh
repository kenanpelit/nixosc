#!/usr/bin/env bash

#######################################
#
# Version: 3.0.0
# Date: 2025-11-04
# Author: Kenan Pelit (Modified)
# Repository: github.com/kenanpelit/dotfiles
# Description: Unified Gammastep + HyprSunset + wl-gammarelay Manager
#
# License: MIT
#
#######################################

#########################################################################
# Unified Night Light Manager
#
# Bu script, Gammastep, HyprSunset ve wl-gammarelay'i birlikte yönetir.
# Her üç araç da aynı anda çalışarak istediğiniz renk tonunu elde eder.
#
# Özellikler:
#   - Gammastep, HyprSunset ve wl-gammarelay'i eşzamanlı başlatma/durdurma
#   - Zaman tabanlı otomatik renk sıcaklığı ayarlama
#   - Waybar entegrasyonu
#   - Sistem bildirimleri
#   - Daemon ve fork modları
#   - Her araç ayrı ayrı çalışabilir
#
# Gereksinimler:
#   - gammastep (opsiyonel)
#   - hyprsunset (opsiyonel)
#   - wl-gammarelay-rs (opsiyonel)
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

# Araç aktiflik kontrolleri
ENABLE_GAMMASTEP=true
ENABLE_HYPRSUNSET=true
ENABLE_WLGAMMARELAY=true

# Gammastep ayarları
MODE="wayland"
LOCATION="41.0108:29.0219"
GAMMA="1,0.2,0.1"
BRIGHTNESS_DAY=1.0
BRIGHTNESS_NIGHT=0.8

# Sıcaklık profilleri - Her araç için 3 farklı seviye
# 4000K - Hafif sarı/turuncu
# 3500K - Orta sarı/turuncu
# 3000K - Koyu turuncu/kırmızımsı

# HyprSunset sıcaklık ayarları
TEMP_DAY=4000   # Gündüz sıcaklığı
TEMP_NIGHT=3500 # Gece sıcaklığı

# Gammastep sıcaklık ayarları
GAMMASTEP_TEMP_DAY=4000
GAMMASTEP_TEMP_NIGHT=3500

# wl-gammarelay sıcaklık ayarları
WLGAMMA_TEMP_DAY=4000
WLGAMMA_TEMP_NIGHT=3500
WLGAMMA_BRIGHTNESS=1.0
WLGAMMA_GAMMA=1.0

# Diğer ayarlar
CHECK_INTERVAL=3600
CLEANUP_ON_EXIT=false

export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/run/wrappers/bin:${PATH:-}"

# Loglama fonksiyonu
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

# Kullanım bilgisi
usage() {
	cat <<EOF
Hypr Blue Manager - Unified Gammastep + HyprSunset + wl-gammarelay Manager

KULLANIM:
    $(basename "$0") [KOMUT] [PARAMETRELER]

KOMUTLAR:
    start         Night light'ı başlat (fork modu)
    daemon        Daemon modunda başlat (systemd için)
    stop          Night light'ı durdur
    toggle        Night light'ı aç/kapat
    status        Durum göster
    -h, --help    Bu yardım mesajını göster

ARAÇ KONTROLÜ:
    --enable-gammastep BOOL     Gammastep'i aktif et (true/false, varsayılan: $ENABLE_GAMMASTEP)
    --enable-hyprsunset BOOL    HyprSunset'i aktif et (true/false, varsayılan: $ENABLE_HYPRSUNSET)
    --enable-wlgamma BOOL       wl-gammarelay'i aktif et (true/false, varsayılan: $ENABLE_WLGAMMARELAY)

HYPRSUNSET PARAMETRELERI:
    --temp-day VALUE            Gündüz sıcaklığı (Kelvin, varsayılan: $TEMP_DAY)
    --temp-night VALUE          Gece sıcaklığı (Kelvin, varsayılan: $TEMP_NIGHT)

GAMMASTEP PARAMETRELERI:
    --gs-temp-day VALUE         Gammastep gündüz sıcaklığı (Kelvin, varsayılan: $GAMMASTEP_TEMP_DAY)
    --gs-temp-night VALUE       Gammastep gece sıcaklığı (Kelvin, varsayılan: $GAMMASTEP_TEMP_NIGHT)
    --bright-day VALUE          Gündüz parlaklığı (0.1-1.0, varsayılan: $BRIGHTNESS_DAY)
    --bright-night VALUE        Gece parlaklığı (0.1-1.0, varsayılan: $BRIGHTNESS_NIGHT)
    --location VALUE            Konum (format: enlem:boylam, varsayılan: $LOCATION)
    --gamma VALUE               Gamma değeri (format: r,g,b, varsayılan: $GAMMA)

WL-GAMMARELAY PARAMETRELERI:
    --wl-temp-day VALUE         wl-gammarelay gündüz sıcaklığı (Kelvin, varsayılan: $WLGAMMA_TEMP_DAY)
    --wl-temp-night VALUE       wl-gammarelay gece sıcaklığı (Kelvin, varsayılan: $WLGAMMA_TEMP_NIGHT)
    --wl-brightness VALUE       wl-gammarelay parlaklık (0.1-1.0, varsayılan: $WLGAMMA_BRIGHTNESS)
    --wl-gamma VALUE            wl-gammarelay gamma (0.1-2.0, varsayılan: $WLGAMMA_GAMMA)

DİĞER PARAMETRELER:
    --interval VALUE            Kontrol aralığı (saniye, varsayılan: $CHECK_INTERVAL)

ÖRNEKLER:
    # Varsayılan ayarlarla başlatma (tüm araçlar aktif)
    $(basename "$0") start

    # Sadece Gammastep ile çalıştırma
    $(basename "$0") start --enable-hyprsunset false --enable-wlgamma false

    # Sadece wl-gammarelay ile çalıştırma
    $(basename "$0") start --enable-gammastep false --enable-hyprsunset false

    # Özel sıcaklıklarla başlatma (tüm araçlar)
    $(basename "$0") start --temp-day 4000 --temp-night 3000 \\
                           --gs-temp-day 4000 --gs-temp-night 3000 \\
                           --wl-temp-day 4000 --wl-temp-night 3000

    # Hafif sarı ton (4000K) - tüm araçlar
    $(basename "$0") start --temp-day 4000 --temp-night 4000 \\
                           --gs-temp-day 4000 --gs-temp-night 4000 \\
                           --wl-temp-day 4000 --wl-temp-night 4000

    # Orta ton (3500K) - tüm araçlar
    $(basename "$0") start --temp-day 3500 --temp-night 3500 \\
                           --gs-temp-day 3500 --gs-temp-night 3500 \\
                           --wl-temp-day 3500 --wl-temp-night 3500

    # Koyu turuncu (3000K) - tüm araçlar
    $(basename "$0") start --temp-day 3000 --temp-night 3000 \\
                           --gs-temp-day 3000 --gs-temp-night 3000 \\
                           --wl-temp-day 3000 --wl-temp-night 3000

    # Systemd servisi için
    $(basename "$0") daemon

    # Durum kontrolü
    $(basename "$0") status

SICAKLIK REHBERİ:
    4000K - Hafif sarı/turuncu (en az etki)
    3500K - Orta sarı/turuncu (dengeli)
    3000K - Koyu turuncu/kırmızımsı (maksimum etki)

NOT:
    - Her araç bağımsız olarak aktif/pasif edilebilir
    - En az bir araç aktif olmalıdır
    - Tüm araçlar aynı anda çalışabilir (maksimum etki)
    - Düşük sıcaklık değerleri daha sıcak/kırmızımsı renk verir
    - Her araç kendi katmanını ekler, birlikte daha güçlü etki sağlar
EOF
}

# Bağımlılıkları kontrol et
check_dependencies() {
	local missing_deps=()
	local available_tools=0

	if [[ "$ENABLE_GAMMASTEP" == "true" ]]; then
		if command -v gammastep >/dev/null 2>&1; then
			((available_tools++))
		else
			log "UYARI: Gammastep aktif ama bulunamadı"
			ENABLE_GAMMASTEP=false
		fi
	fi

	if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then
		if command -v hyprsunset >/dev/null 2>&1; then
			((available_tools++))
		else
			log "UYARI: HyprSunset aktif ama bulunamadı"
			ENABLE_HYPRSUNSET=false
		fi
	fi

	if [[ "$ENABLE_WLGAMMARELAY" == "true" ]]; then
		if command -v busctl >/dev/null 2>&1; then
			((available_tools++))
		else
			log "UYARI: wl-gammarelay aktif ama busctl bulunamadı"
			ENABLE_WLGAMMARELAY=false
		fi
	fi

	if [[ $available_tools -eq 0 ]]; then
		echo "Hata: Hiçbir araç kullanılabilir değil veya aktif değil"
		log "HATA: Hiçbir araç kullanılabilir değil"
		exit 1
	fi

	log "Aktif araçlar: Gammastep=$ENABLE_GAMMASTEP, HyprSunset=$ENABLE_HYPRSUNSET, wl-gammarelay=$ENABLE_WLGAMMARELAY"
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
	local hour
	hour="$(date +%H 2>/dev/null || echo 00)"
	echo $((10#$hour))
}

# HyprSunset için sıcaklık belirle
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

# wl-gammarelay için sıcaklık belirle
get_wlgamma_temp() {
	local hour=$(get_current_hour)

	if [[ "$hour" -ge 6 && "$hour" -lt 18 ]]; then
		echo "$WLGAMMA_TEMP_DAY"
	else
		echo "$WLGAMMA_TEMP_NIGHT"
	fi
}

# Gammastep'i başlat
start_gammastep() {
	if [[ "$ENABLE_GAMMASTEP" != "true" ]]; then
		log "Gammastep devre dışı, atlanıyor"
		return 0
	fi

	log "Gammastep başlatılıyor..."

	# Eski gammastep process'lerini temizle
	pkill -9 gammastep 2>/dev/null
	sleep 1

	$(command -v gammastep) -m "$MODE" \
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
	if [[ "$ENABLE_GAMMASTEP" != "true" ]]; then
		return 0
	fi

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

# HyprSunset daemon'ını başlat veya sıcaklığı güncelle
start_or_update_hyprsunset() {
	if [[ "$ENABLE_HYPRSUNSET" != "true" ]]; then
		return 0
	fi

	local temp=$1

	# Sıcaklık değerini kontrol et
	if [[ ! "$temp" =~ ^[0-9]+$ ]] || [[ "$temp" -lt 1000 ]] || [[ "$temp" -gt 10000 ]]; then
		log "HATA: Geçersiz sıcaklık değeri: ${temp}K (1000-10000 arası olmalı)"
		return 1
	fi

	log "HyprSunset sıcaklığı ayarlanıyor: ${temp}K"

	# Eski hyprsunset process'lerini durdur
	pkill -9 hyprsunset 2>/dev/null
	sleep 0.5

	# Daemon modunda başlat (arka planda sürekli çalışır)
	hyprsunset -t "$temp" >/dev/null 2>&1 &
	local hs_pid=$!
	disown

	# Başlamasını bekle
	sleep 1

	if kill -0 "$hs_pid" 2>/dev/null; then
		echo "$temp" >"$LAST_TEMP_FILE"
		log "HyprSunset başlatıldı ve sıcaklık ayarlandı: ${temp}K (PID: $hs_pid)"
		return 0
	else
		log "HATA: HyprSunset başlatılamadı"
		return 1
	fi
}

# wl-gammarelay daemon'ını başlat veya kontrol et
start_wlgammarelay() {
	if [[ "$ENABLE_WLGAMMARELAY" != "true" ]]; then
		log "wl-gammarelay devre dışı, atlanıyor"
		return 0
	fi

	log "wl-gammarelay kontrol ediliyor..."

	# Servis zaten çalışıyor mu kontrol et
	if busctl --user status rs.wl-gammarelay >/dev/null 2>&1; then
		log "wl-gammarelay zaten çalışıyor (servis veya manuel)"
		# Mevcut sıcaklığı al
		local current_temp=$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Temperature 2>/dev/null | awk '{print $2}')
		log "wl-gammarelay mevcut sıcaklık: ${current_temp}K"

		# Eğer varsayılan 6500K'de ise, istediğimiz sıcaklığa ayarla
		if [[ "$current_temp" == "6500" ]]; then
			local target_temp=$(get_wlgamma_temp)
			log "wl-gammarelay 6500K'de, ${target_temp}K'ye ayarlanıyor"
			set_wlgamma_temperature "$target_temp"
		fi
		return 0
	fi

	# wl-gammarelay yoksa başlat
	if command -v wl-gammarelay-rs >/dev/null 2>&1; then
		log "wl-gammarelay başlatılıyor..."
		wl-gammarelay-rs >/dev/null 2>&1 &
		local wl_pid=$!
		disown

		# Başlamasını bekle
		for i in {1..10}; do
			if busctl --user status rs.wl-gammarelay >/dev/null 2>&1; then
				log "wl-gammarelay başlatıldı (PID: $wl_pid)"
				sleep 1
				# Başlangıç sıcaklığını ayarla
				local target_temp=$(get_wlgamma_temp)
				set_wlgamma_temperature "$target_temp"
				return 0
			fi
			sleep 0.5
		done

		log "UYARI: wl-gammarelay başlatılamadı veya yanıt vermiyor"
		return 1
	else
		log "UYARI: wl-gammarelay-rs komutu bulunamadı"
		return 1
	fi
}

# wl-gammarelay daemon'ını durdur (sadece biz başlattıysak)
stop_wlgammarelay() {
	if [[ "$ENABLE_WLGAMMARELAY" != "true" ]]; then
		return 0
	fi

	log "wl-gammarelay durduruluyor..."

	# Sadece sıcaklığı sıfırla, daemon'ı kapatma
	# (başka servisler kullanıyor olabilir)
	if busctl --user status rs.wl-gammarelay >/dev/null 2>&1; then
		busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q 6500 >/dev/null 2>&1
		log "wl-gammarelay sıcaklığı sıfırlandı (6500K)"
	fi
}

# wl-gammarelay sıcaklığını ayarla
set_wlgamma_temperature() {
	if [[ "$ENABLE_WLGAMMARELAY" != "true" ]]; then
		return 0
	fi

	local temp=$1
	log "wl-gammarelay sıcaklığı ayarlanıyor: ${temp}K"

	# wl-gammarelay servisinin çalıştığını kontrol et
	if ! busctl --user status rs.wl-gammarelay >/dev/null 2>&1; then
		log "UYARI: wl-gammarelay servisi bulunamadı"
		return 1
	fi

	# Sıcaklığı ayarla
	if busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q "$temp" >/dev/null 2>&1; then
		log "wl-gammarelay sıcaklığı ayarlandı: ${temp}K"

		# Parlaklık ve gamma'yı da ayarla
		busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Brightness d "$WLGAMMA_BRIGHTNESS" >/dev/null 2>&1
		busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Gamma d "$WLGAMMA_GAMMA" >/dev/null 2>&1

		return 0
	else
		log "HATA: wl-gammarelay sıcaklığı ayarlanamadı"
		return 1
	fi
}

# Tüm sıcaklıkları ayarla
adjust_temperature() {
	local hour=$(get_current_hour)
	local period="gece"
	[[ "$hour" -ge 6 && "$hour" -lt 18 ]] && period="gündüz"

	log "Sıcaklık ayarlama başlıyor (saat: $hour, dönem: $period)"

	# HyprSunset
	if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then
		local hs_temp=$(get_hyprsunset_temp)
		start_or_update_hyprsunset "$hs_temp"
	fi

	# wl-gammarelay
	if [[ "$ENABLE_WLGAMMARELAY" == "true" ]]; then
		local wl_temp=$(get_wlgamma_temp)
		set_wlgamma_temperature "$wl_temp"
	fi

	log "Sıcaklık ayarlama tamamlandı"
}

# Cleanup fonksiyonu
cleanup() {
	local exit_code=$?
	log "Cleanup çağrıldı (exit code: $exit_code)"

	if [[ "$CLEANUP_ON_EXIT" == "true" ]]; then
		log "Cleanup yapılıyor..."

		# Gammastep'i durdur
		stop_gammastep

		# wl-gammarelay'i sıfırla
		stop_wlgammarelay

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
		if [[ "$ENABLE_HYPRSUNSET" == "true" ]] && command -v hyprsunset >/dev/null 2>&1; then
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
	stop_wlgammarelay
	rm -f "$STATE_FILE" "$PID_FILE"

	if [[ "$ENABLE_HYPRSUNSET" == "true" ]] && command -v hyprsunset >/dev/null 2>&1; then
		hyprsunset -i >/dev/null 2>&1
		log "HyprSunset sıcaklığı sıfırlandı"
	fi

	log "Daemon cleanup tamamlandı"
}

# Trap ayarla
trap cleanup EXIT INT TERM

# Daemon loop (fork modu için)
daemon_loop() {
	# Log dosyasını temizle (eski loglar karışmasın)
	>"$LOG_FILE"

	log "Fork daemon döngüsü başlatıldı (PID: $$)"
	log "Parametreler: Gammastep=$ENABLE_GAMMASTEP, HyprSunset=$ENABLE_HYPRSUNSET, wl-gammarelay=$ENABLE_WLGAMMARELAY"

	# İlk ayarlamaları yap
	start_gammastep
	start_wlgammarelay

	# Eğer wl-gammarelay devre dışı ama dışarıdan çalışıyorsa, onu da ayarla
	if [[ "$ENABLE_WLGAMMARELAY" != "true" ]] && busctl --user status rs.wl-gammarelay >/dev/null 2>&1; then
		log "Harici wl-gammarelay bulundu, sıcaklık ayarlanıyor"
		local temp=$(get_wlgamma_temp)
		busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q "$temp" >/dev/null 2>&1
		log "Harici wl-gammarelay ${temp}K'ye ayarlandı"
	fi

	adjust_temperature

	while [[ -f "$STATE_FILE" ]]; do
		sleep "$CHECK_INTERVAL"

		if [[ ! -f "$STATE_FILE" ]]; then
			log "State file silinmiş, daemon sonlanıyor"
			break
		fi

		# Gammastep'in çalıştığını kontrol et
		if [[ "$ENABLE_GAMMASTEP" == "true" ]]; then
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
		fi

		adjust_temperature
		log "Bir sonraki kontrol: ${CHECK_INTERVAL} saniye sonra"
	done

	log "Fork daemon döngüsü sona erdi"
}

# Daemon modu (systemd için)
daemon_mode() {
	# Log dosyasını temizle (eski loglar karışmasın)
	>"$LOG_FILE"

	log "Systemd daemon modu başlatıldı (PID: $$)"
	log "Parametreler: Gammastep=$ENABLE_GAMMASTEP, HyprSunset=$ENABLE_HYPRSUNSET, wl-gammarelay=$ENABLE_WLGAMMARELAY"

	touch "$STATE_FILE"
	echo "$$" >"$PID_FILE"

	trap 'cleanup_daemon; exit 0' EXIT INT TERM

	# İlk ayarlamaları yap
	start_gammastep
	start_wlgammarelay

	# Eğer wl-gammarelay devre dışı ama dışarıdan çalışıyorsa, onu da ayarla
	if [[ "$ENABLE_WLGAMMARELAY" != "true" ]] && busctl --user status rs.wl-gammarelay >/dev/null 2>&1; then
		log "Harici wl-gammarelay bulundu, sıcaklık ayarlanıyor"
		local temp=$(get_wlgamma_temp)
		busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q "$temp" >/dev/null 2>&1
		log "Harici wl-gammarelay ${temp}K'ye ayarlandı"
	fi

	adjust_temperature

	while true; do
		sleep "$CHECK_INTERVAL"

		if [[ ! -f "$STATE_FILE" ]]; then
			log "State file silinmiş, daemon sonlanıyor"
			break
		fi

		# Gammastep kontrolü
		if [[ "$ENABLE_GAMMASTEP" == "true" ]]; then
			if [[ -f "$GAMMASTEP_PID_FILE" ]]; then
				local gs_pid=$(cat "$GAMMASTEP_PID_FILE")
				if ! kill -0 "$gs_pid" 2>/dev/null; then
					log "Gammastep durmuş, yeniden başlatılıyor"
					start_gammastep
				fi
			else
				start_gammastep
			fi
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
	log "Aktif araçlar: Gammastep=$ENABLE_GAMMASTEP, HyprSunset=$ENABLE_HYPRSUNSET, wl-gammarelay=$ENABLE_WLGAMMARELAY"

	touch "$STATE_FILE"

	daemon_loop &
	local daemon_pid=$!

	echo "$daemon_pid" >"$PID_FILE"
	log "Fork daemon başlatıldı (PID: $daemon_pid)"

	sleep 1
	if kill -0 "$daemon_pid" 2>/dev/null; then
		local tools=""
		[[ "$ENABLE_GAMMASTEP" == "true" ]] && tools+="Gammastep "
		[[ "$ENABLE_HYPRSUNSET" == "true" ]] && tools+="HyprSunset "
		[[ "$ENABLE_WLGAMMARELAY" == "true" ]] && tools+="wl-gammarelay"

		send_notification "Hypr Blue Manager" "Başarıyla başlatıldı ($tools)"
		echo "Hypr Blue Manager başlatıldı (PID: $daemon_pid)"
		echo "Aktif araçlar: $tools"
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

	# wl-gammarelay'i sıfırla
	stop_wlgammarelay

	# HyprSunset'i sıfırla
	if [[ "$ENABLE_HYPRSUNSET" == "true" ]] && hyprsunset -i >/dev/null 2>&1; then
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
	echo "--- Araç Durumları ---"
	echo "Gammastep: $([ "$ENABLE_GAMMASTEP" == "true" ] && echo "AKTİF" || echo "KAPALI")"
	echo "HyprSunset: $([ "$ENABLE_HYPRSUNSET" == "true" ] && echo "AKTİF" || echo "KAPALI")"
	echo "wl-gammarelay: $([ "$ENABLE_WLGAMMARELAY" == "true" ] && echo "AKTİF" || echo "KAPALI")"

	if [[ "$ENABLE_GAMMASTEP" == "true" ]]; then
		echo ""
		echo "--- Gammastep Detayları ---"
		if [[ -f "$GAMMASTEP_PID_FILE" ]]; then
			local gs_pid=$(cat "$GAMMASTEP_PID_FILE")
			if kill -0 "$gs_pid" 2>/dev/null; then
				echo "Durum: ÇALIŞIYOR (PID: $gs_pid)"
			else
				echo "Durum: HATA (PID geçersiz)"
			fi
		else
			if pgrep gammastep &>/dev/null; then
				echo "Durum: ÇALIŞIYOR (PID dosyası yok)"
			else
				echo "Durum: DURDU"
			fi
		fi
		echo "Gündüz sıcaklığı: ${GAMMASTEP_TEMP_DAY}K"
		echo "Gece sıcaklığı: ${GAMMASTEP_TEMP_NIGHT}K"
		echo "Gündüz parlaklık: $BRIGHTNESS_DAY"
		echo "Gece parlaklık: $BRIGHTNESS_NIGHT"
	fi

	if [[ "$ENABLE_HYPRSUNSET" == "true" ]]; then
		echo ""
		echo "--- HyprSunset Detayları ---"
		echo "Gündüz sıcaklığı: ${TEMP_DAY}K (06:00-18:00)"
		echo "Gece sıcaklığı: ${TEMP_NIGHT}K (18:00-06:00)"
		echo "Kontrol aralığı: ${CHECK_INTERVAL} saniye"
		if [[ -f "$LAST_TEMP_FILE" ]]; then
			echo "Son sıcaklık: $(cat "$LAST_TEMP_FILE")K"
		fi
	fi

	if [[ "$ENABLE_WLGAMMARELAY" == "true" ]]; then
		echo ""
		echo "--- wl-gammarelay Detayları ---"
		if busctl --user status rs.wl-gammarelay >/dev/null 2>&1; then
			echo "Durum: ÇALIŞIYOR"
			local current_temp=$(busctl --user get-property rs.wl-gammarelay / rs.wl.gammarelay Temperature 2>/dev/null | awk '{print $2}')
			[[ -n "$current_temp" ]] && echo "Mevcut sıcaklık: ${current_temp}K"
		else
			echo "Durum: DURDU veya BULUNAMADI"
		fi
		echo "Gündüz sıcaklığı: ${WLGAMMA_TEMP_DAY}K (06:00-18:00)"
		echo "Gece sıcaklığı: ${WLGAMMA_TEMP_NIGHT}K (18:00-06:00)"
		echo "Parlaklık: $WLGAMMA_BRIGHTNESS"
		echo "Gamma: $WLGAMMA_GAMMA"
	fi

	echo ""
	echo "--- Konum ve Gamma ---"
	echo "Konum: $LOCATION"
	echo "Gamma: $GAMMA"

	if [[ -f "$LOG_FILE" ]]; then
		echo ""
		echo "--- Son Log Kayıtları ---"
		echo "Log dosyası: $LOG_FILE"
		if [[ -f "$PID_FILE" ]]; then
			local current_pid=$(cat "$PID_FILE")
			echo "Daemon PID: $current_pid"
		fi
		tail -n 5 "$LOG_FILE" 2>/dev/null || echo "Log okunamadı"
	fi
}

# Ana işlem
main() {
	mkdir -p "$(dirname "$LOG_FILE")"
	mkdir -p "$HOME/.cache"
	touch "$LOG_FILE"
	log "=== Hypr Blue Manager başlatıldı (v3.0.0) ==="

	if [[ $# -eq 0 ]]; then
		usage
		exit 1
	fi

	# Parametreleri parse et
	while [[ $# -gt 0 ]]; do
		case $1 in
		# Araç kontrolü
		--enable-gammastep)
			ENABLE_GAMMASTEP="$2"
			shift 2
			;;
		--enable-hyprsunset)
			ENABLE_HYPRSUNSET="$2"
			shift 2
			;;
		--enable-wlgamma)
			ENABLE_WLGAMMARELAY="$2"
			shift 2
			;;
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
		# wl-gammarelay parametreleri
		--wl-temp-day)
			WLGAMMA_TEMP_DAY="$2"
			shift 2
			;;
		--wl-temp-night)
			WLGAMMA_TEMP_NIGHT="$2"
			shift 2
			;;
		--wl-brightness)
			WLGAMMA_BRIGHTNESS="$2"
			shift 2
			;;
		--wl-gamma)
			WLGAMMA_GAMMA="$2"
			shift 2
			;;
		# Komutlar
		start)
			check_dependencies
			start_service
			exit $?
			;;
		daemon)
			check_dependencies
			daemon_mode
			exit $?
			;;
		stop)
			stop_service
			exit $?
			;;
		toggle)
			check_dependencies
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
