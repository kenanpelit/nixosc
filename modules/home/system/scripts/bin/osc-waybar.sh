#!/usr/bin/env bash

# osc-waybar - Birleşik waybar yardımcı programı
# Kullanım: osc-waybar [komut]

VERSION="1.0.0"
CONFIG_DIR="$HOME/.config/osc-waybar"

# Yapılandırma dizinini oluştur (yoksa)
mkdir -p "$CONFIG_DIR"

# Yardım bilgilerini görüntüle
show_help() {
	echo "Kullanım: osc-waybar [komut] [parametre]"
	echo ""
	echo "Komutlar:"
	echo "  bluelight-monitor      Gammastep durumunu kontrol et"
	echo "  bluelight-toggle       Gammastep'i aç/kapat"
	echo "  bluetooth|bt           Bluetooth cihazını bağla/bağlantısını kes"
	echo "      [toggle]           Bluetooth'u aç/kapat"
	echo "      [alternative]      Alternatif cihazı kullan"
	echo "  hyprshade|shade        Hypr blur efektini aç/kapat"
	echo "  idle-inhibitor         Idle inhibitor durumunu göster"
	echo "  mic-status|mic         Mikrofon durumunu göster"
	echo "  vpn-mullvad            Mullvad VPN durumunu kontrol et"
	echo "  vpn-other              Diğer VPN bağlantılarını kontrol et"
	echo "  vpn-status             Genel VPN durumunu kontrol et"
	echo "  weather|hava           Hava durumu bilgisini göster"
	echo "      [update]           Hava durumu bilgisini güncelle"
	echo "  wf-recorder            Ekran kaydını başlat/durdur"
	echo "  help                   Bu yardım mesajını göster"
	echo "  version                Sürüm bilgisini göster"
	echo ""
}

# Sürüm bilgisini göster
show_version() {
	echo "osc-waybar sürüm $VERSION"
}

# Komutu kontrol et ve ilgili fonksiyonu çalıştır
case "$1" in
bluelight-monitor)
	# Gammastep uygulamasının çalışıp çalışmadığını kontrol et
	if pgrep gammastep &>/dev/null; then
		# Eğer gammastep çalışıyorsa, aktivasyon durumu için çıktı
		echo '{"class": "activated", "tooltip": "Gammastep is active"}'
	else
		# Eğer gammastep çalışmıyorsa, devre dışı durumu için çıktı
		echo '{"class": "", "tooltip": "Gammastep is deactivated"}'
	fi
	;;

bluelight-toggle)
	# Gammastep uygulamasının çalışıp çalışmadığını kontrol et
	if pgrep gammastep; then
		# Eğer çalışıyorsa, gammastep'i durdur
		pkill --signal SIGKILL gammastep
		# Durdurulduğuna dair bildirim gönder
		notify-send -u low "Gammastep Durduruldu" "Gammastep uygulaması kapatıldı."
		# Waybar'ı güncelle
		pkill -RTMIN+8 waybar
	else
		# Gammastep ayarları
		MODE="wayland"             # Çalışma modu
		LOCATION="41.0108:29.0219" # Enlem:Boylam (manuel olarak ayarlanmış)
		TEMP_DAY=4500              # Gündüz renk sıcaklığı
		TEMP_NIGHT=4000            # Gece renk sıcaklığı
		BRIGHTNESS_DAY=0.7         # Gündüz parlaklık
		BRIGHTNESS_NIGHT=0.7       # Gece parlaklık
		GAMMA="1,0.2,0.1"          # RGB gamma ayarları
		# Gammastep'i başlat
		/usr/bin/gammastep -m "$MODE" -l manual -t "$TEMP_DAY:$TEMP_NIGHT" -b "$BRIGHTNESS_DAY:$BRIGHTNESS_NIGHT" -l "$LOCATION" -g "$GAMMA" >>/dev/null 2>&1 &
		# Bağımsız işlem haline getir
		disown
		# Başarı bildirimi
		notify-send -u low "Gammastep Başlatıldı" "Gündüz: $TEMP_DAY K, Gece: $TEMP_NIGHT K"
	fi
	# Monitör güncellemesi için Waybar'a sinyal gönder
	pkill -RTMIN+8 waybar
	;;

bluetooth | bt)
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

	# Bluetooth toggle modu
	if [ "$2" = "toggle" ]; then
		if bluetoothctl show | grep -q "Powered: no"; then
			bluetoothctl power on
			notify-send -i bluetooth "Bluetooth" "Bluetooth açıldı" -h string:x-canonical-private-synchronous:bluetooth
		else
			bluetoothctl power off
			notify-send -i bluetooth "Bluetooth" "Bluetooth kapatıldı" -h string:x-canonical-private-synchronous:bluetooth
		fi
		exit 0
	fi

	# Cihaz seçimi
	if [ "$2" = "alternative" ]; then
		DEVICE_ADDRESS="$ALTERNATIVE_DEVICE_ADDRESS"
		DEVICE_NAME="$ALTERNATIVE_DEVICE_NAME"
	else
		DEVICE_ADDRESS="$DEFAULT_DEVICE_ADDRESS"
		DEVICE_NAME="$DEFAULT_DEVICE_NAME"
	fi

	# Ses ayarlarını yapılandırma fonksiyonu
	configure_audio() {
		local mode=$1
		if [ "$mode" = "bluetooth" ]; then
			# Bluetooth cihazının tanımlanması için kısa bir bekleme süresi
			echo "Bluetooth ses cihazı bekleniyor..."
			sleep 3
			# PulseAudio/PipeWire Bluetooth ses çıkışını ayarlama
			bluetooth_sink=$(pactl list short sinks | grep -i "bluez" | awk '{print $2}')
			if [ -n "$bluetooth_sink" ]; then
				pactl set-default-sink "$bluetooth_sink"
				pactl set-sink-volume @DEFAULT_SINK@ ${BT_VOLUME_LEVEL}%
				echo "Ses çıkışı Bluetooth cihazına ayarlandı: $bluetooth_sink (%${BT_VOLUME_LEVEL})"
			else
				echo "Uyarı: Bluetooth cihazı ses çıkışı olarak bulunamadı."
			fi
			# PulseAudio/PipeWire Bluetooth ses girişini ayarlama
			bluetooth_source=$(pactl list short sources | grep -i "bluez" | awk '{print $2}')
			if [ -n "$bluetooth_source" ]; then
				pactl set-default-source "$bluetooth_source"
				pactl set-source-volume @DEFAULT_SOURCE@ ${BT_MIC_LEVEL}%
				echo "Ses girişi Bluetooth cihazına ayarlandı: $bluetooth_source (%${BT_MIC_LEVEL})"
			fi
		else
			# Varsayılan ses ayarlarına dönme
			pactl set-sink-volume @DEFAULT_SINK@ ${DEFAULT_VOLUME_LEVEL}%
			pactl set-source-volume @DEFAULT_SOURCE@ ${DEFAULT_MIC_LEVEL}%
			echo "Varsayılan ses çıkışı %${DEFAULT_VOLUME_LEVEL}, ses girişi %${DEFAULT_MIC_LEVEL} seviyesine ayarlandı."
		fi
	}

	# Cihazın bağlantı durumunu kontrol et
	connection_status=$(bluetoothctl info "$DEVICE_ADDRESS" | grep "Connected:" | awk '{print $2}')

	# Bluetooth etkin mi kontrol et
	if ! bluetoothctl show | grep -q "Powered: yes"; then
		echo "Bluetooth etkin değil. Etkinleştiriliyor..."
		bluetoothctl power on
		sleep 2
	fi

	# Duruma göre bağlantı durumunu değiştir
	if [ "$connection_status" == "yes" ]; then
		echo "Cihaz $DEVICE_NAME ($DEVICE_ADDRESS) şu anda bağlı"
		echo "Bağlantı kesiliyor..."
		if bluetoothctl disconnect "$DEVICE_ADDRESS"; then
			echo "Bağlantı başarıyla kesildi."
			notify-send -i bluetooth "$DEVICE_NAME Bağlantısı Kesildi" "$DEVICE_NAME bağlantısı kesildi."
			configure_audio "default"
		else
			echo "Hata: Bağlantı kesilirken bir sorun oluştu."
			exit 1
		fi
	else
		echo "Cihaz $DEVICE_NAME ($DEVICE_ADDRESS) şu anda bağlı değil"
		echo "Bağlanılıyor..."
		if bluetoothctl connect "$DEVICE_ADDRESS"; then
			echo "Bağlantı başarıyla kuruldu."
			notify-send -i bluetooth "$DEVICE_NAME Bağlandı" "$DEVICE_NAME bağlantısı kuruldu."
			configure_audio "bluetooth"
		else
			echo "Hata: Bağlanırken bir sorun oluştu."
			exit 1
		fi
	fi
	;;

hyprshade-toggle | shade)
	# Arayüz temasını değiştiren basit bir alternatif
	if command -v hyprctl &>/dev/null; then
		# Mevcut tema bilgisini al
		current_theme=$(hyprctl getoption decoration:blur:passes | grep "int: " | awk '{print $2}')

		if [ "$current_theme" = "0" ] || [ -z "$current_theme" ]; then
			# Blur efekti yok ise, dark tema etkinleştir
			hyprctl keyword decoration:blur:passes 3
			hyprctl keyword decoration:blur:size 3
			notify-send -t 2000 "Tema Değişti" "Blurlü tema etkinleştirildi"
			echo "Blurlü tema etkinleştirildi"
		else
			# Blur efekti var ise, light tema etkinleştir
			hyprctl keyword decoration:blur:passes 0
			hyprctl keyword decoration:blur:size 0
			notify-send -t 2000 "Tema Değişti" "Normal tema etkinleştirildi"
			echo "Normal tema etkinleştirildi"
		fi
	else
		notify-send -t 2000 -u critical "Hyprland Hatası" "Hyprctl komutu bulunamadı!"
		echo "Hyprctl komutu bulunamadı!"
		exit 1
	fi
	;;

idle-inhibitor)
	# Hyprland idle durumunu kontrol eden script
	IDLE_INHIBITOR_STATUS=$(hyprctl clients | grep -oP '(?<=idle_inhibitor: )\w+')
	if [[ "$IDLE_INHIBITOR_STATUS" == "active" ]]; then
		# Eğer aktifse, deactivated simgesi
		echo "{\"text\":\"  \", \"tooltip\":\"Idle Inhibitor Deactivated\"}"
	else
		# Eğer devre dışıysa, activated simgesi
		echo "{\"text\":\"  \", \"tooltip\":\"Idle Inhibitor Activated\"}"
	fi
	;;

mic-status | mic)
	# Mikrofon durumunu kontrol et
	STATUS=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')

	if [[ "$STATUS" == "yes" ]]; then
		echo '{"text": "", "tooltip": "Microphone muted", "class": "muted"}'
	else
		echo '{"text": "", "tooltip": "Microphone active", "class": "active"}'
	fi
	;;

vpn-mullvad)
	## Icon definitions
	#ICON_CONNECTED="󰦝 "    # Shield with check mark
	ICON_DISCONNECTED="󰦞 " # Shield with x mark
	# Mullvad için özel
	ICON_MULLVAD="󰒃 "     # Shield
	ICON_MULLVAD_ALT="󰯄 " # Alternatif Shield
	# Check Mullvad status
	status_output=$(mullvad status 2>/dev/null)
	# Function to check if interface has IP
	check_interface_has_ip() {
		local interface=$1
		ip addr show dev "$interface" 2>/dev/null | grep -q "inet "
		return $?
	}
	if echo "$status_output" | grep -q "Connected\|Connecting"; then
		relay_line=$(echo "$status_output" | grep "Relay:" | tr -d ' ')
		if echo "$relay_line" | grep -q "ovpn"; then
			if [ -d "/proc/sys/net/ipv4/conf/tun0" ] && check_interface_has_ip "tun0"; then
				interface="M-TUN0"
				text=$(echo "$relay_line" | cut -d':' -f2)
				echo "{\"text\": \"$interface $ICON_MULLVAD\", \"class\": \"connected\", \"tooltip\": \"Mullvad: $text\"}"
				exit 0
			fi
		elif echo "$relay_line" | grep -q "wg"; then
			if [ -d "/proc/sys/net/ipv4/conf/wg0-mullvad" ] && check_interface_has_ip "wg0-mullvad"; then
				interface="M-WG0"
				text=$(echo "$relay_line" | cut -d':' -f2)
				echo "{\"text\": \"$interface $ICON_MULLVAD\", \"class\": \"connected\", \"tooltip\": \"Mullvad: $text\"}"
				exit 0
			fi
		fi
	fi
	echo "{\"text\": \"MVN $ICON_DISCONNECTED\", \"class\": \"disconnected\", \"tooltip\": \"Mullvad Disconnected\"}"
	;;

vpn-other)
	# Klasik lock tarzı ikonlar
	ICON_CONNECTED="󰒃 "    # Locked padlock
	ICON_DISCONNECTED="󰦞 " # Shield with x mark
	ICON_WARNING="󰀦 "      # Warning icon
	# Function to check if interface has IP
	check_interface_has_ip() {
		local interface=$1
		ip addr show dev "$interface" 2>/dev/null | grep -q "inet "
		return $?
	}
	# Function to check Mullvad status
	check_mullvad_status() {
		if mullvad status 2>/dev/null | grep -q "Connected\|Connecting"; then
			return 0
		fi
		return 1
	}
	# Function to format interface name
	format_interface_name() {
		local interface=$1
		local base_name=$(echo "$interface" | sed 's/[0-9]*$//')
		local number=$(echo "$interface" | grep -o '[0-9]*$')
		echo "${base_name^^}${number}"
	}
	# Get Mullvad status
	mullvad_active=false
	if check_mullvad_status; then
		mullvad_active=true
	fi
	# Check for all VPN interfaces
	other_vpn_active=false
	other_vpn_interface=""
	other_vpn_ip=""
	while read -r interface; do
		# Temizle interface adını
		interface=$(echo "$interface" | tr -d '[:space:]')
		# If Mullvad is not active, treat tun0 as a potential other VPN interface
		if check_interface_has_ip "$interface"; then
			if [ "$mullvad_active" = false ] || [[ "$interface" != "wg0-mullvad" && "$interface" != "tun0" ]]; then
				other_vpn_active=true
				other_vpn_interface=$interface
				other_vpn_ip=$(ip addr show dev "$interface" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
				break
			fi
		fi
	done < <(ip link show | grep -E "tun|wg|gpd" | grep "UP" | cut -d: -f2 | awk '{print $1}')
	# Determine status and output appropriate message
	if [ "$mullvad_active" = true ] && [ "$other_vpn_active" = true ]; then
		# Both Mullvad and other VPN are active
		formatted_name=$(format_interface_name "$other_vpn_interface")
		echo "{\"text\": \"DUAL $ICON_WARNING\", \"class\": \"warning\", \"tooltip\": \"Multiple VPNs Active - Mullvad and $formatted_name ($other_vpn_ip)\"}"
	elif [ "$mullvad_active" = true ]; then
		# Only Mullvad is active
		echo "{\"text\": \"MVN $ICON_CONNECTED\", \"class\": \"mullvad-connected\", \"tooltip\": \"Mullvad VPN Active\"}"
	elif [ "$other_vpn_active" = true ]; then
		# Only other VPN is active (including tun0 when Mullvad is not active)
		formatted_name=$(format_interface_name "$other_vpn_interface")
		echo "{\"text\": \"$formatted_name $ICON_CONNECTED\", \"class\": \"vpn-connected\", \"tooltip\": \"$other_vpn_interface: $other_vpn_ip\"}"
	else
		# No VPN is active
		echo "{\"text\": \"OVN $ICON_DISCONNECTED\", \"class\": \"disconnected\", \"tooltip\": \"No VPN Connected\"}"
	fi
	;;

vpn-status)
	# Modern shield/lock tarzı VPN ikonları
	ICON_CONNECTED="󰦝 "    # Shield with check mark
	ICON_DISCONNECTED="󰦞 " # Shield with x mark
	# Function to check if any VPN interface is active
	check_vpn_active() {
		# Check for any active VPN interface (tun, wg, gpd)
		if ip link show | grep -E "tun|wg|gpd" | grep -q "UP"; then
			return 0
		fi
		return 1
	}
	if check_vpn_active; then
		echo "{\"text\": \"VPN $ICON_CONNECTED\", \"class\": \"connected\", \"tooltip\": \"VPN Connected\"}"
	else
		echo "{\"text\": \"VPN $ICON_DISCONNECTED\", \"class\": \"disconnected\", \"tooltip\": \"VPN Disconnected\"}"
	fi
	;;

weather | hava)
	# Terminal karakter kodlamasını UTF-8 olarak ayarla
	export LANG=tr_TR.UTF-8
	export LC_ALL=tr_TR.UTF-8

	# Geçici dosya ve önbellek dosyası
	TMP_FILE="/tmp/weather_display.txt"
	CACHE_FILE="/tmp/weather.cache"
	CACHE_TIMEOUT=1800 # 30 dakika (saniye cinsinden)

	# Güncel zamanı al
	CURRENT_TIME=$(date +%s)

	# Önbellek dosyasının son değiştirilme zamanını kontrol et
	if [ -f "$CACHE_FILE" ]; then
		CACHE_MODIFIED=$(stat -c %Y "$CACHE_FILE")
		CACHE_AGE=$((CURRENT_TIME - CACHE_MODIFIED))
	else
		CACHE_AGE=$CACHE_TIMEOUT
	fi

	# Force güncelleme için
	if [ "$2" = "force" ]; then
		CACHE_AGE=$CACHE_TIMEOUT
	fi

	# Önbellek yeterince yeni mi yoksa güncellenmesi gerekiyor mu?
	if [ $CACHE_AGE -ge $CACHE_TIMEOUT ] || [ "$2" = "update" ] || [ "$2" = "force" ]; then
		# Önbelleği tamamen sil
		rm -f "$CACHE_FILE"

		# Güncelleme bildirimi
		notify-send "Hava Durumu" "Güncelleniyor..." -i weather-clear

		# wttr.in'den hava durumu bilgisini al
		# Şehir adı ve şu anki durum
		CITY_INFO="İstanbul:"

		# Sıcaklık ve diğer bilgiler
		TEMP_INFO=$(curl -s "wttr.in/Istanbul?lang=tr&format=%t")
		HUMIDITY_INFO=$(curl -s "wttr.in/Istanbul?lang=tr&format=%h")
		WIND_INFO=$(curl -s "wttr.in/Istanbul?lang=tr&format=%w")

		# Mevcut durum bilgisi
		CURRENT_INFO="${CITY_INFO} ${TEMP_INFO}, ${HUMIDITY_INFO} nem, ${WIND_INFO} rüzgar"

		# Bugünün sıcaklığı - aynı değeri kullan
		TODAY_TEMP="${TEMP_INFO}"

		# Tahmin başlığı
		FORECAST_HEADER="3 günlük tahmin:"

		# Manuel olarak 3 günü oluştur - bugünün değeri için mevcut sıcaklığı kullan
		FORECAST="Bugün: ${TODAY_TEMP}
Yarın: +18°C  
Sonraki gün: +19°C"

		# Güncelleme zamanı
		UPDATE_TIME="Güncelleme: $(date '+%d.%m.%Y %H:%M')"

		# Tümünü düzgün formatta birleştir
		{
			echo "${CURRENT_INFO}"
			echo ""
			echo "${FORECAST_HEADER}"
			echo "${FORECAST}"
			echo ""
			echo "${UPDATE_TIME}"
		} >"$CACHE_FILE"

		# Güncelleme tamamlandı bildirimi
		notify-send "Hava Durumu" "Güncelleme tamamlandı" -i weather-clear

		# Waybar'ı güncelle
		pkill -RTMIN+8 waybar
	fi

	# Eğer görüntüleme isteği varsa
	if [ "$2" != "update" ]; then
		# Önbellek dosyasının içeriğini kontrol et
		if [ ! -s "$CACHE_FILE" ]; then
			# Dosya boşsa veya eksikse yeniden oluştur
			"$0" weather force
		fi

		# Önbellek dosyasını geçici dosyaya kopyala
		cp "$CACHE_FILE" "$TMP_FILE"

		# Rofi ile görüntüle - tek sütunda ve daha temiz hizalama
		cat "$TMP_FILE" |
			rofi -dmenu \
				-theme-str 'window {width: 560px; height: 500px;}' \
				-theme-str 'listview {lines: 15; columns: 1; fixed-columns: true;}' \
				-theme-str 'entry {enabled: false;}' \
				-theme-str 'element {padding: 10px; horizontal-align: 0;}' \
				-theme-str 'element-text {font: "Sans 14"; horizontal-align: 0.0;}' \
				-theme-str 'mainbox {spacing: 0; padding: 0;}' \
				-markup-rows \
				-no-fixed-num-lines \
				-p "Hava Durumu:" \
				-i

		# Geçici dosyayı temizle
		rm -f "$TMP_FILE"
	fi
	;;

wf-recorder)
	# Toggle wf-recorder and update waybar
	if pid=$(pgrep wf-recorder); then
		kill -s INT "$pid"
		: >/tmp/RECORDING
	else
		wf-recorder &
		echo '' >/tmp/RECORDING
	fi
	pkill -RTMIN+8 waybar
	;;

version)
	show_version
	;;

help | --help | -h | *)
	show_help
	;;
esac
