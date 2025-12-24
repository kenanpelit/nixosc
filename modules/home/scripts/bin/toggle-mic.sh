#!/usr/bin/env bash
#######################################
# Fancy Microphone Toggle with LED & Notifications
# Features:
#   - Hardware LED control (ThinkPad micmute)
#   - Volume-aware notifications with icons
#   - Visual volume bar
#   - Color-coded urgency levels
#######################################

# Configuration
LED_PATH="/sys/class/leds/platform::micmute/brightness"
NOTIFICATION_TIMEOUT=2500
APP_NAME="Microphone Control"

# Best-effort LED control without blocking (no sudo prompt from keybinds)
set_led() {
	local val="$1"
	if [[ -w "$LED_PATH" ]]; then
		echo "$val" >"$LED_PATH" 2>/dev/null || true
	elif command -v sudo >/dev/null 2>&1; then
		echo "$val" | sudo -n tee "$LED_PATH" >/dev/null 2>&1 || true
	fi
}

# Check if wpctl is available
if ! command -v wpctl >/dev/null 2>&1; then
	echo "Error: wpctl not found. Install pipewire-tools."
	notify-send -u critical "Microphone Toggle" "wpctl not found!" 2>/dev/null
	exit 1
fi

# Toggle mute
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

# Get current status
volume_info=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
is_muted=$(echo "$volume_info" | grep -q "MUTED" && echo "yes" || echo "no")
volume_raw=$(echo "$volume_info" | awk '{print $2}')
volume_pct=$(echo "$volume_raw * 100" | bc | cut -d. -f1)

# Generate volume bar
generate_volume_bar() {
	local vol=$1
	local bar_length=10
	local filled=$((vol * bar_length / 100))
	local empty=$((bar_length - filled))

	printf "["
	printf "█%.0s" $(seq 1 $filled)
	printf "░%.0s" $(seq 1 $empty)
	printf "]"
}

volume_bar=$(generate_volume_bar "$volume_pct")

# Control LED and send notification
if [ "$is_muted" = "yes" ]; then
	# Muted state
	set_led 1

	echo "🔇 Microphone MUTED - LED ON"

	if command -v notify-send >/dev/null 2>&1; then
		notify-send \
			-a "$APP_NAME" \
			-u normal \
			-t $NOTIFICATION_TIMEOUT \
			-i microphone-sensitivity-muted \
			"🔇 Microphone Muted" \
			"Input disabled"
	fi
else
	# Unmuted state
	set_led 0

	echo "🎤 Microphone ACTIVE - LED OFF (${volume_pct}%)"

	# Choose icon based on volume level
	if [ "$volume_pct" -ge 70 ]; then
		icon="microphone-sensitivity-high"
		urgency="normal"
	elif [ "$volume_pct" -ge 30 ]; then
		icon="microphone-sensitivity-medium"
		urgency="normal"
	else
		icon="microphone-sensitivity-low"
		urgency="low"
	fi

	if command -v notify-send >/dev/null 2>&1; then
		notify-send \
			-a "$APP_NAME" \
			-u "$urgency" \
			-t $NOTIFICATION_TIMEOUT \
			-i "$icon" \
			"🎤 Microphone Active" \
			"Volume: ${volume_pct}% ${volume_bar}"
	fi
fi

exit 0
