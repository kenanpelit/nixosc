#!/usr/bin/env bash
# ~/.config/waybar/scripts/mako-status.sh
# Waybar Mako Notification Status Script

# CRITICAL: Exit cleanly on any error
trap 'exit 0' ERR

# Icons (Nerd Font)
ICON_NONE="󰂚 "
ICON_NOTIFICATIONS="󰂜 "
ICON_UNREAD="󰅸 "

# Simple, safe functions
get_unread_count() {
	makoctl list 2>/dev/null | grep -c "^Notification" 2>/dev/null || echo "0"
}

get_total_count() {
	makoctl history 2>/dev/null | grep -c "^Notification" 2>/dev/null || echo "0"
}

is_mako_running() {
	pgrep -f mako >/dev/null 2>&1
}

# Main function - absolutely bulletproof JSON
main() {
	# Safe defaults
	local icon="$ICON_NONE"
	local text=""
	local class="none"
	local tooltip="No notifications"

	# Only proceed if mako is running
	if is_mako_running; then
		local unread=$(get_unread_count)
		local total=$(get_total_count)

		# Clean the numbers
		unread=$(echo "$unread" | tr -d '\n\r\t ' || echo "0")
		total=$(echo "$total" | tr -d '\n\r\t ' || echo "0")

		# Validate numbers
		[[ "$unread" =~ ^[0-9]+$ ]] || unread=0
		[[ "$total" =~ ^[0-9]+$ ]] || total=0

		# Set display priority: unread > total > none
		if [ "$unread" -gt 0 ]; then
			# Aktif bildirimler var - kırmızı
			icon="$ICON_UNREAD"
			text="$unread"
			class="unread"
			tooltip="$unread active notifications"
		elif [ "$total" -gt 0 ]; then
			# Sadece history'de bildirimler var - yeşil
			icon="$ICON_NOTIFICATIONS"
			text="$total"
			class="read"
			tooltip="$total notifications in history"
		else
			# Hiç bildirim yok - gri
			icon="$ICON_NONE"
			text=""
			class="none"
			tooltip="No notifications"
		fi
	else
		icon="❌"
		class="error"
		tooltip="Mako not running"
	fi

	# Output SAFE JSON - no special characters in strings
	cat <<EOF
{"text": "$icon$text", "tooltip": "$tooltip", "class": "$class"}
EOF
}

# Handle clicks - all safe
case "${1:-}" in
"click")
	makoctl dismiss --all 2>/dev/null || makoctl restore 2>/dev/null || true
	;;
"right-click")
	if makoctl mode 2>/dev/null | grep -q "do-not-disturb" 2>/dev/null; then
		makoctl mode -r do-not-disturb 2>/dev/null || true
	else
		makoctl mode -a do-not-disturb 2>/dev/null || true
	fi
	;;
"middle-click")
	makoctl dismiss --all 2>/dev/null || true
	;;
"restore")
	makoctl restore 2>/dev/null || true
	;;
"clear-history")
	# Clear history by restarting mako
	pkill mako 2>/dev/null || true
	sleep 1
	mako &
	2>/dev/null || true
	;;
"help" | "-h" | "--help")
	echo "Mako Waybar Notification Script"
	echo ""
	echo "Usage: $0 [COMMAND]"
	echo ""
	echo "Commands:"
	echo "  (no args)     Show notification status as JSON for waybar"
	echo "  click         Left click: Dismiss all notifications or restore"
	echo "  right-click   Right click: Toggle do-not-disturb mode"
	echo "  middle-click  Middle click: Dismiss all notifications"
	echo "  restore       Restore notifications from history"
	echo "  clear-history Clear notification history (restart mako)"
	echo "  help|-h       Show this help message"
	echo ""
	echo "Examples:"
	echo "  $0            # Show JSON status"
	echo "  $0 click      # Dismiss notifications"
	echo "  $0 right-click # Toggle DND mode"
	echo ""
	echo "Waybar Config:"
	echo '  "custom/mako-notifications" = {'
	echo '    format = "{}";'
	echo '    exec = "mako-status";'
	echo '    return-type = "json";'
	echo '    interval = 3;'
	echo '    on-click = "mako-status click";'
	echo '    on-click-right = "mako-status right-click";'
	echo '    on-click-middle = "mako-status middle-click";'
	echo '  };'
	;;
*)
	main
	;;
esac

# Always exit cleanly
exit 0
