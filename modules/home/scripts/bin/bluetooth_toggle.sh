#!/usr/bin/env bash
#######################################
#
# Version: 1.7.0
# Date: 2025-09-03
# Original Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Script: HyprFlow - Enhanced Bluetooth Connection Manager (PipeWire/PulseAudio)
#
# License: MIT
#
#######################################

# ──────────────────────────────────────────────────────────────────────────────
# Kullanıcı ayarları
# ──────────────────────────────────────────────────────────────────────────────
DEFAULT_DEVICE_ADDRESS="F4:9D:8A:3D:CB:30"
DEFAULT_DEVICE_NAME="SL4P"
ALTERNATIVE_DEVICE_ADDRESS="E8:EE:CC:4D:29:00"
ALTERNATIVE_DEVICE_NAME="SL4"

# Ses seviyeleri (yüzde)
BT_VOLUME_LEVEL=40
BT_MIC_LEVEL=5
DEFAULT_VOLUME_LEVEL=15
DEFAULT_MIC_LEVEL=0

# Bekleme/deneme
BLUETOOTH_TIMEOUT=10
AUDIO_WAIT_TIME=4
MAX_RETRY_COUNT=8

# ──────────────────────────────────────────────────────────────────────────────
# Renkler & logging
# ──────────────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
log() {
	local msg="$1" level="${2:-INFO}" color=""
	case "$level" in ERROR) color=$RED ;; SUCCESS) color=$GREEN ;; WARNING) color=$YELLOW ;; INFO) color=$BLUE ;; esac
	echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $msg${NC}"
}
send_notification() { command -v notify-send >/dev/null 2>&1 && notify-send -t 5000 "$1" "$2"; }

# ──────────────────────────────────────────────────────────────────────────────
# Yardımcılar (genel)
# ──────────────────────────────────────────────────────────────────────────────
check_command() { command -v "$1" >/dev/null 2>&1 || {
	log "Hata: $1 komutu bulunamadı." "ERROR"
	exit 1
}; }
check_bluetooth_service() { if ! systemctl is-active --quiet bluetooth; then
	log "Bluetooth servisi aktif değil. Başlatılıyor..." "WARNING"
	sudo systemctl start bluetooth || true
	sleep 2
fi; }
check_device_availability() {
	local addr="$1"
	bluetoothctl info "$addr" >/dev/null 2>&1 || {
		log "Cihaz $addr bulunamadı veya eşleştirilmemiş." "ERROR"
		return 1
	}
}
check_bluetooth_power() { if ! bluetoothctl show | grep -q "Powered: yes"; then
	log "Bluetooth etkin değil. Etkinleştiriliyor..." "WARNING"
	if bluetoothctl power on >/dev/null 2>&1; then
		sleep 2
		log "Bluetooth başarıyla etkinleştirildi." "SUCCESS"
	else
		log "Bluetooth etkinleştirilemedi." "ERROR"
		return 1
	fi
fi; }

# Pil yüzdesi (BluetoothCTL üzerinden; bazı cihazlar desteklemez)
get_battery_percentage() {
	local addr="$1"
	bluetoothctl info "$addr" 2>/dev/null | awk -F': ' '/Battery Percentage/ {gsub(/[[:space:]]*/,"",$2); print $2}'
}

# ──────────────────────────────────────────────────────────────────────────────
# Backend seçimi
# ──────────────────────────────────────────────────────────────────────────────
AUDIO_BACKEND=""
BACKEND_FORCED=""
detect_backend() {
	if [ -n "$BACKEND_FORCED" ]; then
		case "$BACKEND_FORCED" in wpctl | pactl) AUDIO_BACKEND="$BACKEND_FORCED" ;; *)
			log "Geçersiz backend: $BACKEND_FORCED (wpctl|pactl)" "ERROR"
			exit 1
			;;
		esac
	else
		if command -v wpctl >/dev/null 2>&1; then
			AUDIO_BACKEND="wpctl"
		elif command -v pactl >/dev/null 2>&1; then
			AUDIO_BACKEND="pactl"
		else
			log "No audio control backend found. Install PipeWire (wpctl) or PulseAudio (pactl)." "ERROR"
			exit 1
		fi
	fi
	log "Audio backend: ${AUDIO_BACKEND}" "INFO"
}

# ──────────────────────────────────────────────────────────────────────────────
# wpctl yardımcıları
# ──────────────────────────────────────────────────────────────────────────────
_strip_box_chars() { sed 's/[│├─└]//g'; }
_mac_upper() { echo "$1" | tr '[:lower:]' '[:upper:]'; }
_mac_underscore() { _mac_upper "$1" | tr ':' '_'; }

# Satır başında opsiyonel * destekli ID çek
_extract_id_from_line() {
	# girdi: satırın tamamı; çıktı: sadece sayısal id
	local line="$1"
	line="${line#"${line%%[![:space:]]*}"}"
	line="${line#\* }"
	line="${line#\*}"
	echo "$line" | awk -F. '{gsub(/^[[:space:]]*/,"",$1); print $1}'
}

# Sinks/Sources bloklarını al
_wpctl_block() {
	local start="$1" end="$2"
	wpctl status | sed -n "/^ *$start:/,/^ *$end:/p" | _strip_box_chars
}

# Sinks/Sources içinde isimle ID bul
_find_id_in_block_by_name() {
	local block="$1" needle_regex="$2" line
	while IFS= read -r line; do
		echo "$line" | grep -qiE "$needle_regex" || continue
		if [[ "$line" =~ ^[[:space:]]*\*?[[:space:]]*[0-9]+\.[[:space:]] ]]; then
			_extract_id_from_line "$line"
			return 0
		fi
	done <<<"$block"
	return 1
}

# Section içinde inspect ile MAC ara
_find_id_by_mac_in_section() {
	local section="$1" end="$2" mac_upper="$3" mac_und="$4" block line id
	block="$(_wpctl_block "$section" "$end")"
	while IFS= read -r line; do
		[[ "$line" =~ ^[[:space:]]*\*?[[:space:]]*[0-9]+\.[[:space:]] ]] || continue
		id="$(_extract_id_from_line "$line")"
		wpctl inspect "$id" 2>/dev/null | grep -qE "($mac_upper|$mac_und)" && {
			echo "$id"
			return 0
		}
	done <<<"$block"
	return 1
}

# Settings → Default Configured Devices içinden seri adını çek (bluez_output/bluez_input)
_find_default_serial_from_settings() {
	local kind="$1" # sink|source
	local macU="$2" macUnd="$3"
	local what
	[ "$kind" = "sink" ] && what="Audio/Sink" || what="Audio/Source"
	wpctl status | sed -n "/^ *Settings:/,\$p" | awk -v w="$what" -v m="$macU" -v mu="$macUnd" '
    BEGIN{IGNORECASE=1}
    /Default Configured Devices:/,0 {
      if ($0 ~ w) {
        line=$0
        # örn: "0. Audio/Sink    bluez_output.F4_9D_... .1"
        if (index(line,m)>0 || index(line,mu)>0) {
          # satırın sonundaki seri adını çek
          gsub(/^.*Audio\/(Sink|Source)[[:space:]]+/,"",line)
          gsub(/[[:space:]]+$/,"",line)
          print line; exit
        }
      }
    }'
}

# ID → node.name çöz (olmuyorsa boş döner)
_resolve_node_name_from_id() {
	local id="$1"
	wpctl inspect "$id" 2>/dev/null | awk -F'"' '/node.name/ {print $2; exit}'
}

# BlueZ card’ı bul ve profili A2DP’ye geçir
_switch_bt_profile_a2dp() {
	local macU="$(_mac_upper "$DEVICE_ADDRESS")" macUnd="$(_mac_underscore "$DEVICE_ADDRESS")"
	# card id’yi settings/devices tarafında bul
	local card_id
	card_id="$(wpctl status | _strip_box_chars | awk -v m="$macU" -v mu="$macUnd" '
    BEGIN{IGNORECASE=1}
    /^[[:space:]]*\*?[[:space:]]*[0-9]+\./ && /bluez_card/ {
      if (index($0,m)>0 || index($0,mu)>0) {
        line=$0; sub(/^[[:space:]]*\*?[[:space:]]*/,"",line); sub(/\..*/,"",line); print line; exit
      }
    }')" || true
	[ -n "$card_id" ] && wpctl set-profile "$card_id" a2dp-sink >/dev/null 2>&1 || true
}

# BT output/input görünene kadar bekle (Filters’taki input da yeter)
_wait_for_bt_nodes() {
	local macU="$(_mac_upper "$DEVICE_ADDRESS")" macUnd="$(_mac_underscore "$DEVICE_ADDRESS")"
	local tries=0 max=$((MAX_RETRY_COUNT + 5))
	while [ $tries -lt $max ]; do
		# Sinks’te cihaz adı ya da S4/bluez_output görünmese bile Settings’te seri adı oluşur
		local s_serial="$(_find_default_serial_from_settings sink "$macU" "$macUnd")"
		local i_serial="$(_find_default_serial_from_settings source "$macU" "$macUnd")"
		if [ -n "$s_serial" ] || [ -n "$i_serial" ]; then return 0; fi
		tries=$((tries + 1))
		sleep 1
	done
	return 1
}

# ──────────────────────────────────────────────────────────────────────────────
# BACKEND SOYUT KATMANI
# ──────────────────────────────────────────────────────────────────────────────
# wpctl set-default her zaman node SERİ ADI ile çağrılacak (ID bulunursa önce adı çöz)
_set_default_wpctl() {
	local kind="$1" target="$2" # kind: sink|source ; target: id veya seri adı
	local serial=""
	if [[ "$target" =~ ^[0-9]+$ ]]; then
		serial="$(_resolve_node_name_from_id "$target")"
	else
		serial="$target"
	fi
	# serial hâlâ boşsa Settings’ten çek
	if [ -z "$serial" ]; then
		local macU="$(_mac_upper "$DEVICE_ADDRESS")" macUnd="$(_mac_underscore "$DEVICE_ADDRESS")"
		serial="$(_find_default_serial_from_settings "$kind" "$macU" "$macUnd")"
	fi
	if [ -n "$serial" ]; then
		wpctl set-default "$serial" >/dev/null 2>&1 && return 0
	fi
	return 1
}

audio_find_bt_sink() {
	case "$AUDIO_BACKEND" in
	pactl) pactl list short sinks | awk '/bluez/i {print $2; exit}' ;;
	wpctl)
		local macU="$(_mac_upper "$DEVICE_ADDRESS")" macUnd="$(_mac_underscore "$DEVICE_ADDRESS")" block id
		# 1) Sinks bloğunda ad ile (S4/cihaz adı/bluez/A2DP)
		block="$(_wpctl_block "Sinks" "Sources")"
		_find_id_in_block_by_name "$block" "bluez|Bluetooth|A2DP|Headset|Headphones|Earbuds|${DEFAULT_DEVICE_NAME}|${ALTERNATIVE_DEVICE_NAME}|S4" && return 0
		# 2) MAC ile inspect
		_find_id_by_mac_in_section "Sinks" "Sources" "$macU" "$macUnd" && return 0
		# 3) Settings’ten seri adı (bluez_output.*) — ID yerine seri adı döndürelim
		_find_default_serial_from_settings sink "$macU" "$macUnd" && return 0
		return 1
		;;
	esac
}

audio_find_bt_source() {
	case "$AUDIO_BACKEND" in
	pactl) pactl list short sources | awk '/bluez.*input/i {print $2; exit}' ;;
	wpctl)
		local macU="$(_mac_upper "$DEVICE_ADDRESS")" macUnd="$(_mac_underscore "$DEVICE_ADDRESS")" block
		block="$(_wpctl_block "Sources" "Clients")"
		_find_id_in_block_by_name "$block" "bluez|Bluetooth|HSP|HFP|Headset|Mic|${DEFAULT_DEVICE_NAME}|${ALTERNATIVE_DEVICE_NAME}|S4" && return 0
		_find_id_by_mac_in_section "Sources" "Clients" "$macU" "$macUnd" && return 0
		_find_default_serial_from_settings source "$macU" "$macUnd" && return 0
		# Filters fallback (bluez_input.*)
		wpctl status | _strip_box_chars | awk -v m="$(_mac_upper "$DEVICE_ADDRESS")" -v mu="$(_mac_underscore "$DEVICE_ADDRESS")" '
        BEGIN{IGNORECASE=1}
        /^[[:space:]]*\*?[[:space:]]*[0-9]+\./ && /\[Audio\/Source\]/ && /bluez_input/ {
          if (index($0,m)>0 || index($0,mu)>0) {
            line=$0; sub(/^[[:space:]]*\*?[[:space:]]*/,"",line); sub(/\..*/,"",line); print line; exit
          }
        }' && return 0
		return 1
		;;
	esac
}

audio_set_default_sink() {
	local target="$1"
	case "$AUDIO_BACKEND" in
	pactl) pactl set-default-sink "$target" ;;
	wpctl) _set_default_wpctl sink "$target" ;;
	esac
}
audio_set_default_source() {
	local target="$1"
	case "$AUDIO_BACKEND" in
	pactl) pactl set-default-source "$target" ;;
	wpctl) _set_default_wpctl source "$target" ;;
	esac
}
audio_set_sink_volume_pct() {
	local pct="$1"
	case "$AUDIO_BACKEND" in pactl) pactl set-sink-volume @DEFAULT_SINK@ "${pct}%" ;; wpctl) wpctl set-volume @DEFAULT_AUDIO_SINK@ "${pct}%" ;; esac
}
audio_set_source_volume_pct() {
	local pct="$1"
	case "$AUDIO_BACKEND" in pactl) pactl set-source-volume @DEFAULT_SOURCE@ "${pct}%" ;; wpctl) wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "${pct}%" ;; esac
}

# ──────────────────────────────────────────────────────────────────────────────
# Ses yapılandırması
# ──────────────────────────────────────────────────────────────────────────────
configure_audio() {
	local mode="$1" retry_count=0

	if [ "$mode" = "bluetooth" ]; then
		log "Bluetooth ses cihazı bekleniyor..." "INFO"
		sleep "$AUDIO_WAIT_TIME"
		[ "$AUDIO_BACKEND" = "wpctl" ] && {
			_switch_bt_profile_a2dp
			_wait_for_bt_nodes || log "Uyarı: wpctl BT node’ları gecikti, yine de deniyorum." "WARNING"
		}

		# SINK
		retry_count=0
		while [ $retry_count -lt $MAX_RETRY_COUNT ]; do
			local bt_sink
			bt_sink="$(audio_find_bt_sink)" || true
			if [ -n "$bt_sink" ] && audio_set_default_sink "$bt_sink"; then
				audio_set_sink_volume_pct "$BT_VOLUME_LEVEL" 2>/dev/null || true
				log "Ses çıkışı Bluetooth cihazına ayarlandı: $bt_sink (%${BT_VOLUME_LEVEL})" "SUCCESS"
				break
			fi
			retry_count=$((retry_count + 1))
			log "Bluetooth sink bulunamadı, tekrar deneniyor... ($retry_count/$MAX_RETRY_COUNT)" "WARNING"
			sleep 1
		done

		# SOURCE
		retry_count=0
		while [ $retry_count -lt $MAX_RETRY_COUNT ]; do
			local bt_src
			bt_src="$(audio_find_bt_source)" || true
			if [ -n "$bt_src" ] && audio_set_default_source "$bt_src"; then
				audio_set_source_volume_pct "$BT_MIC_LEVEL" 2>/dev/null || true
				log "Ses girişi Bluetooth cihazına ayarlandı: $bt_src (%${BT_MIC_LEVEL})" "SUCCESS"
				break
			fi
			retry_count=$((retry_count + 1))
			log "Bluetooth source bulunamadı, tekrar deneniyor... ($retry_count/$MAX_RETRY_COUNT)" "WARNING"
			sleep 1
		done

		[ $retry_count -eq $MAX_RETRY_COUNT ] && log "Bluetooth mikrofon ayarlanamadı, sadece hoparlör kullanılabilir." "WARNING"
	else
		if audio_set_sink_volume_pct "$DEFAULT_VOLUME_LEVEL" 2>/dev/null && audio_set_source_volume_pct "$DEFAULT_MIC_LEVEL" 2>/dev/null; then
			log "Varsayılan ses çıkışı %${DEFAULT_VOLUME_LEVEL}, ses girişi %${DEFAULT_MIC_LEVEL} seviyesine ayarlandı." "SUCCESS"
		else
			log "Varsayılan ses ayarları yapılandırılırken hata oluştu." "WARNING"
		fi
	fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Bluetooth bağlantı yönetimi
# ──────────────────────────────────────────────────────────────────────────────
manage_bluetooth_connection() {
	local device_address="$1" device_name="$2"
	check_device_availability "$device_address" || return 1

	local connection_status
	if ! connection_status=$(bluetoothctl info "$device_address" 2>/dev/null | awk -F': ' '/Connected:/ {print $2}'); then
		log "Bluetooth cihaz bilgisi alınamadı." "ERROR"
		return 1
	fi

	if [ "$connection_status" = "yes" ]; then
		log "Cihaz $device_name ($device_address) şu anda bağlı" "INFO"
		log "Bağlantı kesiliyor..." "INFO"
		if timeout "$BLUETOOTH_TIMEOUT" bluetoothctl disconnect "$device_address" >/dev/null 2>&1; then
			log "Bağlantı başarıyla kesildi." "SUCCESS"
			send_notification "$device_name Bağlantısı Kesildi" "$device_name ($device_address) bağlantısı kesildi."
			configure_audio "default"
			log "Cihaz $device_name ($device_address) şimdi bağlantı kesildi" "INFO"
		else
			log "Bağlantı kesilirken timeout veya bir sorun oluştu." "ERROR"
			return 1
		fi
	else
		log "Cihaz $device_name ($device_address) şu anda bağlı değil" "INFO"
		log "Bağlanılıyor..." "INFO"
		if timeout "$BLUETOOTH_TIMEOUT" bluetoothctl connect "$device_address" >/dev/null 2>&1; then
			log "Bağlantı başarıyla kuruldu." "SUCCESS"
			local battery
			battery="$(get_battery_percentage "$device_address")"
			if [ -n "$battery" ]; then
				send_notification "$device_name Bağlandı" "$device_name ($device_address) bağlantısı kuruldu. Pil: $battery"
				log "Pil durumu: $battery" "INFO"
			else
				send_notification "$device_name Bağlandı" "$device_name ($device_address) bağlantısı kuruldu."
			fi
			configure_audio "bluetooth"
			log "Cihaz $device_name ($device_address) şimdi bağlandı" "INFO"
		else
			log "Bağlanırken timeout veya bir sorun oluştu." "ERROR"
			return 1
		fi
	fi
	return 0
}

# ──────────────────────────────────────────────────────────────────────────────
# Yardım & Argümanlar
# ──────────────────────────────────────────────────────────────────────────────
show_help() {
	cat <<EOF
Kullanım: $0 [SEÇENEKLER] [MAC_ADRESI] [CİHAZ_ADI]

Seçenekler:
  -h, --help           Bu yardım mesajını göster
  -v, --verbose        Detaylı çıktı ver (set -x)
  -q, --quiet          Sadece hata mesajlarını göster
  --backend=wpctl      Backend'i wpctl olarak zorla
  --backend=pactl      Backend'i pactl olarak zorla

Örnekler:
  $0
  $0 F4:9D:8A:3D:CB:30 "SL4P"
  $0 --backend=wpctl -v

Varsayılan cihaz: $DEFAULT_DEVICE_NAME ($DEFAULT_DEVICE_ADDRESS)
EOF
}

parse_arguments() {
	while [[ $# -gt 0 ]]; do
		case "$1" in
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
		--backend=*)
			BACKEND_FORCED="${1#*=}"
			shift
			;;
		-*)
			log "Bilinmeyen seçenek: $1" "ERROR"
			show_help
			exit 1
			;;
		*)
			if [ -z "${DEVICE_ADDRESS:-}" ]; then
				DEVICE_ADDRESS="$1"
			elif [ -z "${DEVICE_NAME:-}" ]; then
				DEVICE_NAME="$1"
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

cleanup() {
	log "Script sonlandırılıyor..." "INFO"
	exit 0
}
trap cleanup SIGINT SIGTERM

main() {
	parse_arguments "$@"
	detect_backend
	DEVICE_ADDRESS="${DEVICE_ADDRESS:-$DEFAULT_DEVICE_ADDRESS}"
	DEVICE_NAME="${DEVICE_NAME:-$DEFAULT_DEVICE_NAME}"

	check_command bluetoothctl
	check_command timeout
	[ "$AUDIO_BACKEND" = "pactl" ] && check_command pactl
	[ "$AUDIO_BACKEND" = "wpctl" ] && check_command wpctl

	check_bluetooth_service
	check_bluetooth_power || exit 1
	log "Bluetooth cihazı: $DEVICE_NAME ($DEVICE_ADDRESS)" "INFO"

	if manage_bluetooth_connection "$DEVICE_ADDRESS" "$DEVICE_NAME"; then
		log "İşlem başarıyla tamamlandı." "SUCCESS"
		exit 0
	else
		log "İşlem sırasında hata oluştu." "ERROR"
		exit 1
	fi
}

main "$@"
