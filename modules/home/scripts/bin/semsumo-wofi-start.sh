#!/usr/bin/env bash
#===============================================================================
#   Script: Advanced Session Manager Runner
#   Version: 1.0.0
#   Description: Enhanced session starter with debugging
#===============================================================================

VERSION="1.0.0"
SCRIPTS_DIR="/home/kenan/.bin/start-scripts" # Tam yol
HISTORY_FILE="$HOME/.cache/session-runner-history"
MAX_HISTORY=100

# Debug modu
DEBUG=true

# Renkler ve simgeler
SUCCESS_ICON="✓"
ERROR_ICON="✗"
VPN_ICON="🔒"
NO_VPN_ICON="🔓"

debug_log() {
	[[ "$DEBUG" == true ]] && echo "[DEBUG] $*" >>/tmp/semsumo-wofi.log
}

# VPN durumunu kontrol et
check_vpn() {
	if mullvad status 2>/dev/null | grep -q "Connected"; then
		echo "$VPN_ICON VPN Aktif"
		return 0
	fi
	echo "$NO_VPN_ICON VPN Pasif"
	return 1
}

# Mevcut scriptleri topla
get_sessions() {
	debug_log "Scriptler aranıyor: $SCRIPTS_DIR"
	(
		# Önce geçmiş
		if [[ -f "$HISTORY_FILE" ]]; then
			debug_log "History okunuyor: $HISTORY_FILE"
			cat "$HISTORY_FILE"
		fi

		# Sonra tüm scriptler
		find "$SCRIPTS_DIR" -type f -name "start-*" -exec basename {} \; |
			sed 's/\.sh$//' |
			sort -u
	) | awk '!seen[$0]++'
}

# Session bilgilerini göster
format_sessions() {
	while read -r session; do
		if [[ $session == *"-always" ]]; then
			echo "$session [$VPN_ICON]"
		elif [[ $session == *"-never" ]]; then
			echo "$session [$NO_VPN_ICON]"
		else
			echo "$session"
		fi
	done
}

# Ana menü
main() {
	local vpn_status
	vpn_status=$(check_vpn)

	debug_log "Wofi menüsü açılıyor..."
	selected=$(get_sessions | format_sessions | wofi \
		--show dmenu \
		--replace \
		--prompt "Session Runner ($vpn_status)" \
		--conf ~/.config/wofi/config \
		--style ~/.config/wofi/styles/style.css \
		--width 600 --height 400 \
		--cache-file /dev/null \
		--insensitive)

	[[ -n "$selected" ]] && {
		# Simgeleri temizle
		selected=$(echo "$selected" | sed 's/ \[.*\]$//')
		debug_log "Seçilen session: $selected"

		# History'ye ekle
		echo "$selected" >>"$HISTORY_FILE"

		# Scripti çalıştır
		script_path="$SCRIPTS_DIR/${selected}.sh"
		debug_log "Script yolu: $script_path"

		if [[ -x "$script_path" ]]; then
			debug_log "Script çalıştırılıyor: $script_path"
			notify-send "Session Manager" "$SUCCESS_ICON Başlatılıyor: $selected"
			# Tam yol ile çalıştır
			/bin/bash "$script_path" >/tmp/semsumo-wofi-exec.log 2>&1 &
		else
			debug_log "HATA: Script bulunamadı veya çalıştırılamıyor: $script_path"
			notify-send -u critical "Session Manager" "$ERROR_ICON Hata: Script bulunamadı: $selected"
		fi
	}
}

# History temizliği
cleanup_history() {
	if [[ -f "$HISTORY_FILE" ]]; then
		tail -n "$MAX_HISTORY" "$HISTORY_FILE" >"${HISTORY_FILE}.tmp"
		mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
	fi
}

trap cleanup_history EXIT

# Başlangıç kontrolleri
debug_log "Script başlatılıyor..."
debug_log "Scripts dizini: $SCRIPTS_DIR"
debug_log "History dosyası: $HISTORY_FILE"

# Dizin kontrolü
if [[ ! -d "$SCRIPTS_DIR" ]]; then
	debug_log "HATA: Scripts dizini bulunamadı!"
	notify-send -u critical "Session Manager" "$ERROR_ICON Hata: Scripts dizini bulunamadı!"
	exit 1
fi

# Ana programı çalıştır
main
