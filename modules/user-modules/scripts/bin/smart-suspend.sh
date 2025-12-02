#!/usr/bin/env bash
#######################################
# Smart Suspend Script for Hyprland
# Features:
#   - Pre-suspend state saving
#   - Post-wake restoration
#   - Process safety checks
#   - PipeWire (wpctl) integration
#######################################

LOG_DIR="$HOME/.log"
LOG_FILE="$LOG_DIR/smart-suspend.log"
CACHE_DIR="$HOME/.cache/smart-suspend"

mkdir -p "$LOG_DIR" "$CACHE_DIR"
touch "$LOG_FILE"

# Log rotation
if [ -f "$LOG_FILE" ]; then
	for i in {4..1}; do
		[ -f "$LOG_FILE.$i" ] && mv "$LOG_FILE.$i" "$LOG_FILE.$((i + 1))"
	done
	mv "$LOG_FILE" "$LOG_FILE.1"
fi

exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

echo "$(date): Hyprland suspend kontrolü başlatıldı"

# ============================================================================
# Hyprland State Management
# ============================================================================

save_hyprland_state() {
	if command -v hyprctl >/dev/null 2>&1; then
		# Workspace bilgilerini kaydet
		hyprctl workspaces >"$CACHE_DIR/hypr_workspace_state"
		# Aktif pencere bilgilerini kaydet
		hyprctl clients >"$CACHE_DIR/hypr_clients_state"
		# Aktif workspace ID'sini kaydet
		hyprctl activeworkspace -j | jq -r '.id' >"$CACHE_DIR/active_workspace" 2>/dev/null
		return 0
	else
		echo "Hyprctl bulunamadı"
		return 1
	fi
}

check_hyprland_active() {
	if [[ "$DESKTOP_SESSION" == *"hyprland"* ]] || [[ "$XDG_CURRENT_DESKTOP" == *"Hyprland"* ]]; then
		echo "Hyprland masaüstü ortamı tespit edildi"
		return 0
	else
		echo "Hyprland masaüstü ortamı bulunamadı!"
		return 1
	fi
}

# ============================================================================
# System Checks
# ============================================================================

check_battery() {
	if [ -d "/sys/class/power_supply/BAT0" ]; then
		battery_level=$(cat /sys/class/power_supply/BAT0/capacity)
		charging_status=$(cat /sys/class/power_supply/BAT0/status)
		echo "Pil seviyesi: $battery_level%"
		echo "Şarj durumu: $charging_status"

		# Low battery warning
		if [ "$battery_level" -lt 15 ] && [ "$charging_status" != "Charging" ]; then
			notify-send -u critical "⚠️ Düşük Pil" "Pil seviyesi: ${battery_level}%"
		fi
	fi
	return 0
}

check_processes() {
	important_processes=("rsync" "mv" "cp" "git" "npm" "yarn" "cargo" "make" "cmake" "build")

	for proc in "${important_processes[@]}"; do
		if pgrep -f "$proc" >/dev/null; then
			echo "Önemli işlem çalışıyor: $proc"
			notify-send -u critical "⚠️ Uyarı" "$proc işlemi çalışıyor. İşlem bitene kadar bekleyin."
			return 1
		fi
	done
	return 0
}

check_active_windows() {
	if command -v hyprctl >/dev/null 2>&1; then
		active_windows=$(hyprctl clients -j | jq 'length' 2>/dev/null)
		if [ "$active_windows" -gt 0 ]; then
			echo "Aktif pencere sayısı: $active_windows"
			hyprctl clients -j | jq -r '.[] | "\(.class) - \(.title)"' 2>/dev/null | while read -r window; do
				echo "  • $window"
			done
		fi
	fi
}

# ============================================================================
# Audio Management (wpctl)
# ============================================================================

save_audio_state() {
	if ! command -v wpctl >/dev/null 2>&1; then
		echo "wpctl bulunamadı, ses durumu kaydedilemiyor"
		return 1
	fi

	# Sink (output) volume ve mute durumunu kaydet
	local sink_volume sink_mute
	sink_volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print $2}')
	sink_mute=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED" && echo "yes" || echo "no")

	# Source (input) volume ve mute durumunu kaydet
	local source_volume source_mute
	source_volume=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | awk '{print $2}')
	source_mute=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q "MUTED" && echo "yes" || echo "no")

	# Durumları dosyaya yaz
	cat >"$CACHE_DIR/audio_state" <<-EOF
		SINK_VOLUME=$sink_volume
		SINK_MUTE=$sink_mute
		SOURCE_VOLUME=$source_volume
		SOURCE_MUTE=$source_mute
	EOF

	echo "Ses durumu kaydedildi: Sink ${sink_volume} (Mute: ${sink_mute}), Source ${source_volume} (Mute: ${source_mute})"
	return 0
}

restore_audio_state() {
	if ! command -v wpctl >/dev/null 2>&1; then
		echo "wpctl bulunamadı, ses durumu geri yüklenemiyor"
		return 1
	fi

	if [ ! -f "$CACHE_DIR/audio_state" ]; then
		echo "Kaydedilmiş ses durumu bulunamadı"
		return 1
	fi

	# Durumları oku
	source "$CACHE_DIR/audio_state"

	# Sink (output) durumunu geri yükle
	if [ -n "$SINK_VOLUME" ]; then
		wpctl set-volume @DEFAULT_AUDIO_SINK@ "$SINK_VOLUME" 2>/dev/null
		echo "Sink volume geri yüklendi: $SINK_VOLUME"
	fi

	if [ "$SINK_MUTE" = "yes" ]; then
		wpctl set-mute @DEFAULT_AUDIO_SINK@ 1 2>/dev/null
		echo "Sink mute edildi"
	else
		wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null
	fi

	# Source (input) durumunu geri yükle
	if [ -n "$SOURCE_VOLUME" ]; then
		wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$SOURCE_VOLUME" 2>/dev/null
		echo "Source volume geri yüklendi: $SOURCE_VOLUME"
	fi

	if [ "$SOURCE_MUTE" = "yes" ]; then
		wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1 2>/dev/null
		echo "Source mute edildi"
	else
		wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 2>/dev/null
	fi

	return 0
}

# ============================================================================
# Bluetooth Management
# ============================================================================

save_bluetooth_state() {
	if ! command -v bluetoothctl >/dev/null 2>&1; then
		echo "bluetoothctl bulunamadı"
		return 1
	fi

	bluetoothctl show 2>/dev/null | grep "Powered" >"$CACHE_DIR/bluetooth_state"

	# Connected devices
	bluetoothctl devices Connected 2>/dev/null >"$CACHE_DIR/bluetooth_devices"

	if [ -s "$CACHE_DIR/bluetooth_devices" ]; then
		echo "Bağlı Bluetooth cihazları kaydedildi:"
		cat "$CACHE_DIR/bluetooth_devices"
	fi

	return 0
}

restore_bluetooth_state() {
	if ! command -v bluetoothctl >/dev/null 2>&1; then
		echo "bluetoothctl bulunamadı"
		return 1
	fi

	if [ -f "$CACHE_DIR/bluetooth_state" ]; then
		if grep -q "Powered: yes" "$CACHE_DIR/bluetooth_state"; then
			bluetoothctl power on 2>/dev/null
			echo "Bluetooth açıldı"
		fi
	fi

	return 0
}

# ============================================================================
# Suspend Preparation & Restoration
# ============================================================================

prepare_suspend() {
	echo "$(date): Suspend hazırlıkları başlatılıyor..."

	# Hyprland özel hazırlıkları
	if command -v hyprctl >/dev/null 2>&1; then
		# Ekranı kitle
		hyprctl dispatch dpms off 2>/dev/null
		sleep 0.5
	fi

	# Durumları kaydet
	save_audio_state
	save_bluetooth_state
	save_hyprland_state

	echo "Tüm durumlar kaydedildi"
}

restore_after_wake() {
	echo "$(date): Sistem uyandırıldı, restore işlemi başlatılıyor..."

	# Hyprland özel restorasyon
	if command -v hyprctl >/dev/null 2>&1; then
		# Ekranı aç
		hyprctl dispatch dpms on 2>/dev/null
		sleep 0.5

		# Aktif workspace'e dön
		if [ -f "$CACHE_DIR/active_workspace" ]; then
			workspace=$(cat "$CACHE_DIR/active_workspace")
			hyprctl dispatch workspace "$workspace" 2>/dev/null
		fi
	fi

	# Durumları geri yükle
	restore_audio_state
	restore_bluetooth_state

	echo "$(date): Sistem restore edildi"
	notify-send "✅ Sistem Uyandırıldı" "Tüm ayarlar geri yüklendi"
}

# ============================================================================
# Main
# ============================================================================

main() {
	# Hyprland kontrolü
	check_hyprland_active || exit 1

	# Temel kontroller
	check_battery
	check_processes || exit 1

	# Aktif pencereleri göster
	check_active_windows

	# Suspend öncesi hazırlıklar
	prepare_suspend

	echo "$(date): Sistem askıya alınıyor..."
	notify-send "💤 Suspend" "Sistem askıya alınıyor..."
	sleep 1

	# Suspend işlemi
	systemctl suspend

	# Uyanma sonrası işlemler (suspend'den döndüğünde burası çalışır)
	sleep 2 # Sisteme biraz nefes alma süresi
	restore_after_wake
}

# Cleanup on interrupt
trap restore_after_wake SIGINT SIGTERM

main
exit 0
