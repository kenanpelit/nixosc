#!/usr/bin/env bash

#######################################
# COSMIC MONITOR & WORKSPACE CONTROL
#######################################
#
# Version: 1.0.3
# Date: 2025-05-14
# Author: Kenan Pelit
# Description: CosmicFlow - Enhanced COSMIC Desktop Control Tool
#
# License: MIT
#
#######################################

# Enable strict mode
set -euo pipefail

# Constants
readonly CACHE_DIR="$HOME/.cache/cosmic/toggle"
readonly STATE_FILE="$CACHE_DIR/focus_state"
readonly CURRENT_WS_FILE="$CACHE_DIR/current_workspace"
readonly PREVIOUS_WS_FILE="$CACHE_DIR/previous_workspace"
readonly DEBUG_FILE="$CACHE_DIR/debug.log"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Create state file with default value if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
	echo "up" >"$STATE_FILE"
fi

# Create workspace tracking files if they don't exist
if [ ! -f "$CURRENT_WS_FILE" ]; then
	echo "1" >"$CURRENT_WS_FILE"
fi

if [ ! -f "$PREVIOUS_WS_FILE" ]; then
	echo "1" >"$PREVIOUS_WS_FILE"
fi

# Default values
direction="+1"
debug=false

#######################################
# Logging Functions
#######################################

log_info() {
	echo "[INFO] $1" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >>"$DEBUG_FILE"
}

log_error() {
	echo "[ERROR] $1" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >>"$DEBUG_FILE"
}

log_debug() {
	if $debug; then
		echo "[DEBUG] $1" >&2
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $1" >>"$DEBUG_FILE"
	fi
}

#######################################
# Workspace Management Functions
#######################################

get_current_workspace() {
	# Try to get current workspace from COSMIC
	if command -v cosmic-workspace-info >/dev/null 2>&1; then
		ws=$(cosmic-workspace-info current 2>/dev/null) || ws="1"
		echo "$ws"
	else
		# Fallback to stored value
		if [ -s "$CURRENT_WS_FILE" ]; then
			cat "$CURRENT_WS_FILE"
		else
			echo "1" # Default
		fi
	fi
}

get_previous_workspace() {
	if [ -s "$PREVIOUS_WS_FILE" ]; then
		cat "$PREVIOUS_WS_FILE"
	else
		echo "1" # Default to workspace 1 if no history
	fi
}

update_workspace_history() {
	local new_ws
	new_ws=$(get_current_workspace)
	log_debug "Updating workspace history. New workspace: $new_ws"

	# Read current workspace
	local old_ws
	if [ -s "$CURRENT_WS_FILE" ]; then
		old_ws=$(cat "$CURRENT_WS_FILE")

		# If workspace changed, update previous
		if [ "$new_ws" != "$old_ws" ]; then
			echo "$old_ws" >"$PREVIOUS_WS_FILE"
			log_debug "Updated previous workspace to: $old_ws"
		fi
	fi

	# Always update current workspace
	echo "$new_ws" >"$CURRENT_WS_FILE"
	log_debug "Updated current workspace to: $new_ws"
}

# Function to start ydotoold daemon if not running
start_ydotoold() {
	if ! command -v ydotool >/dev/null 2>&1; then
		log_error "ydotool bulunamadı. Lütfen ydotool paketini yükleyin."
		return 1
	fi

	if ! pidof ydotoold >/dev/null 2>&1; then
		log_debug "ydotoold servisi başlatılıyor..."
		ydotoold >/dev/null 2>&1 &
		sleep 1

		if ! pidof ydotoold >/dev/null 2>&1; then
			log_error "ydotoold servisi başlatılamadı!"
			return 1
		fi

		log_debug "ydotoold servisi başlatıldı."
	else
		log_debug "ydotoold servisi zaten çalışıyor."
	fi

	return 0
}

# Execute ydotool key sequence safely
ydotool_exec() {
	# Start ydotoold if not running
	start_ydotoold || return 1

	log_debug "ydotool komutu çalıştırılıyor: ydotool key $*"

	# Execute command with explicit timeout to prevent hanging
	timeout 2 ydotool key "$@" || {
		local ret=$?
		if [ $ret -eq 124 ]; then
			log_error "ydotool komutu zaman aşımına uğradı"
		else
			log_error "ydotool komutu başarısız oldu (kod: $ret)"
		fi
		return 1
	}

	return 0
}

# Switch to specified workspace
switch_to_workspace() {
	local target_ws=$1
	local current_ws
	current_ws=$(get_current_workspace)

	log_debug "Çalışma alanı değiştiriliyor: $current_ws -> $target_ws"

	# Store current workspace as previous
	echo "$current_ws" >"$PREVIOUS_WS_FILE"

	# Map workspace number to appropriate key code
	local key_num
	case "$target_ws" in
	10) key_num="19" ;; # key_0
	1) key_num="10" ;;
	2) key_num="11" ;;
	3) key_num="12" ;;
	4) key_num="13" ;;
	5) key_num="14" ;;
	6) key_num="15" ;;
	7) key_num="16" ;;
	8) key_num="17" ;;
	9) key_num="18" ;;
	*)
		log_error "Geçersiz çalışma alanı numarası: $target_ws (1-10 arası olmalı)"
		return 1
		;;
	esac

	# Try to switch workspace using ydotool - Super+Number
	# Super key down, number key down, number key up, Super key up
	if ! ydotool_exec "125:1" "$key_num:1" "$key_num:0" "125:0"; then
		log_error "Çalışma alanına geçiş başarısız oldu: $target_ws"
		return 1
	fi

	sleep 0.5
	update_workspace_history
}

# Switch workspace in a direction
switch_workspace_direction() {
	local direction=$1
	local current_ws
	current_ws=$(get_current_workspace)

	log_debug "Çalışma alanı yönü değiştiriliyor: $direction (şu anki: $current_ws)"

	# Store current workspace as previous
	echo "$current_ws" >"$PREVIOUS_WS_FILE"

	case "$direction" in
	"Left")
		log_debug "Sol çalışma alanına geçiliyor"
		# Super+Shift+Left: 125=Super, 50=Shift, 105=Left
		ydotool_exec "125:1" "50:1" "105:1" "105:0" "50:0" "125:0"
		;;
	"Right")
		log_debug "Sağ çalışma alanına geçiliyor"
		# Super+Shift+Right: 125=Super, 50=Shift, 106=Right
		ydotool_exec "125:1" "50:1" "106:1" "106:0" "50:0" "125:0"
		;;
	esac

	sleep 0.5
	update_workspace_history
}

# Move current window to specified workspace
move_window_to_workspace() {
	local target_ws=$1

	log_debug "Pencere çalışma alanına taşınıyor: $target_ws"

	# Map workspace number to appropriate key code
	local key_num
	case "$target_ws" in
	10) key_num="19" ;; # key_0
	1) key_num="10" ;;
	2) key_num="11" ;;
	3) key_num="12" ;;
	4) key_num="13" ;;
	5) key_num="14" ;;
	6) key_num="15" ;;
	7) key_num="16" ;;
	8) key_num="17" ;;
	9) key_num="18" ;;
	*)
		log_error "Geçersiz çalışma alanı numarası: $target_ws (1-10 arası olmalı)"
		return 1
		;;
	esac

	# Try to move window using ydotool: Super+Shift+Number
	# Super down, Shift down, Number down, Number up, Shift up, Super up
	if ! ydotool_exec "125:1" "50:1" "$key_num:1" "$key_num:0" "50:0" "125:0"; then
		log_error "Pencereyi çalışma alanına taşıma başarısız oldu: $target_ws"
		return 1
	fi

	sleep 0.5
	update_workspace_history
}

#######################################
# Monitor Management Functions
#######################################

toggle_monitor_focus() {
	# Read current state
	local current_state
	current_state=$(cat "$STATE_FILE")

	log_debug "Monitör odağı değiştiriliyor, mevcut durum: $current_state"

	if [ "$current_state" = "up" ]; then
		# Focus down monitor: Super+Down
		ydotool_exec "125:1" "108:1" "108:0" "125:0"
		echo "down" >"$STATE_FILE"
	else
		# Focus up monitor: Super+Up
		ydotool_exec "125:1" "103:1" "103:0" "125:0"
		echo "up" >"$STATE_FILE"
	fi

	log_debug "Monitör odağı değiştirildi, yeni durum: $(cat "$STATE_FILE")"
}

#######################################
# Window Management Functions
#######################################

# Move window focus in a direction
move_window_focus() {
	local direction=$1

	log_debug "Pencere odağı taşınıyor: $direction"

	case "$direction" in
	"left")
		# Super+h: 125=Super, 43=h
		ydotool_exec "125:1" "43:1" "43:0" "125:0"
		;;
	"right")
		# Super+l: 125=Super, 46=l
		ydotool_exec "125:1" "46:1" "46:0" "125:0"
		;;
	"up")
		# Super+k: 125=Super, 45=k
		ydotool_exec "125:1" "45:1" "45:0" "125:0"
		;;
	"down")
		# Super+j: 125=Super, 44=j
		ydotool_exec "125:1" "44:1" "44:0" "125:0"
		;;
	*)
		log_error "Geçersiz yön: $direction"
		return 1
		;;
	esac
}

#######################################
# COSMIC Specific Functions
#######################################

toggle_tiling() {
	log_debug "Karo modu değiştiriliyor"

	# Toggle tiling with Super+Y: 125=Super, 21=y
	if ! ydotool_exec "125:1" "21:1" "21:0" "125:0"; then
		log_error "Karo modu değiştirilemedi"
		return 1
	fi

	log_debug "Karo modu değiştirildi"
	return 0
}

open_launcher() {
	log_debug "Başlatıcı açılıyor"

	# Open launcher with Super key: 125=Super
	if ! ydotool_exec "125:1" "125:0"; then
		log_error "Başlatıcı açılamadı"
		return 1
	fi

	log_debug "Başlatıcı açıldı"
	return 0
}

#######################################
# Help and Maintenance Functions
#######################################

show_help() {
	cat <<EOF
╔══════════════════════════════════╗
║   CosmicFlow - COSMIC Control    ║
╚══════════════════════════════════╝

Usage: $0 [-h] [OPTION]

Monitor Operations:
  -mt         Toggle monitor focus (up/down)
  -ml         Switch to left monitor
  -mr         Switch to right monitor

Workspace Operations:
  -wt         Switch to previous workspace
  -wr         Switch to workspace on the right
  -wl         Switch to workspace on the left
  -wn NUM     Jump to workspace NUM
  -mw NUM     Move focused window to workspace NUM

Window Operations:
  -vl         Move focus left
  -vr         Move focus right
  -vu         Move focus up
  -vd         Move focus down

COSMIC Specific:
  -tt         Toggle tiling mode
  -ol         Open launcher

Other:
  -h          Show this help message
  -d          Debug mode (detailed output)
  -c          Clear workspace history files

Examples:
  $0 -wn 5    # Jump to workspace 5
  $0 -mw 3    # Move current window to workspace 3
  $0 -wt      # Go to previous workspace
  $0 -tt      # Toggle auto-tiling

Version: 1.0.3
EOF
	exit 0
}

clear_workspace_history() {
	log_info "Çalışma alanı geçmiş dosyaları temizleniyor"
	rm -f "$CURRENT_WS_FILE" "$PREVIOUS_WS_FILE"

	# Create them anew
	echo "1" >"$CURRENT_WS_FILE"
	echo "1" >"$PREVIOUS_WS_FILE"

	log_info "Çalışma alanı geçmiş dosyaları sıfırlandı"
}

#######################################
# Main Command Processor
#######################################

# Show help if no arguments provided
if [ $# -eq 0 ]; then
	show_help
fi

# Process command line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-h)
		show_help
		;;
	-d)
		debug=true
		log_info "Hata ayıklama modu etkinleştirildi"
		shift
		;;
	-c)
		clear_workspace_history
		shift
		;;
	-mt)
		log_debug "Monitör odağı değiştiriliyor"
		toggle_monitor_focus
		shift
		;;
	-ml)
		log_debug "Sol monitöre odaklanılıyor"
		# Super+Left: 125=Super, 105=Left
		ydotool_exec "125:1" "105:1" "105:0" "125:0"
		shift
		;;
	-mr)
		log_debug "Sağ monitöre odaklanılıyor"
		# Super+Right: 125=Super, 106=Right
		ydotool_exec "125:1" "106:1" "106:0" "125:0"
		shift
		;;
	-wt)
		log_debug "Önceki çalışma alanına geçiliyor"
		prev_ws=$(get_previous_workspace)
		log_debug "Önceki çalışma alanı: $prev_ws"
		switch_to_workspace "$prev_ws"
		shift
		;;
	-wr)
		log_debug "Sağdaki çalışma alanına geçiliyor"
		switch_workspace_direction "Right"
		shift
		;;
	-wl)
		log_debug "Soldaki çalışma alanına geçiliyor"
		switch_workspace_direction "Left"
		shift
		;;
	-wn)
		if [[ -z "${2:-}" ]]; then
			log_error "-wn için çalışma alanı numarası gereklidir"
			exit 1
		fi
		log_debug "$2 numaralı çalışma alanına geçiliyor"
		switch_to_workspace "$2"
		shift 2
		;;
	-mw)
		if [[ -z "${2:-}" ]]; then
			log_error "-mw için çalışma alanı numarası gereklidir"
			exit 1
		fi
		log_debug "Pencere $2 numaralı çalışma alanına taşınıyor"
		move_window_to_workspace "$2"
		shift 2
		;;
	-vl)
		log_debug "Odak sola taşınıyor"
		move_window_focus "left"
		shift
		;;
	-vr)
		log_debug "Odak sağa taşınıyor"
		move_window_focus "right"
		shift
		;;
	-vu)
		log_debug "Odak yukarı taşınıyor"
		move_window_focus "up"
		shift
		;;
	-vd)
		log_debug "Odak aşağı taşınıyor"
		move_window_focus "down"
		shift
		;;
	-tt)
		log_debug "Karo modu değiştiriliyor"
		toggle_tiling
		shift
		;;
	-ol)
		log_debug "Başlatıcı açılıyor"
		open_launcher
		shift
		;;
	*)
		log_error "Geçersiz seçenek: $1"
		show_help
		;;
	esac
done
