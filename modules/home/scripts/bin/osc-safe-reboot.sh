#!/usr/bin/env bash
#===============================================================================
#  Script: safe-reboot
#  Amaç : Brave/Chromium tabanlı tarayıcılar crash uyarısı vermeden reboot
#  Author: Kenan Pelit
#===============================================================================
set -euo pipefail

#--- Ayarlar -------------------------------------------------------------------
GRACE_APPS=("brave" "chromium")
SOFT_TIMEOUT=5   # SIGTERM sonrası bekleme (saniye)
HARD_DELAY=0.5   # KILL öncesi küçük bekleme
NOTIFY_TIME=3000 # Bildirim gösterim süresi (ms)

#--- Notify fonksiyonu ---------------------------------------------------------
send_notify() {
	local title="$1"
	local msg="$2"
	local urgency="${3:-normal}"

	if command -v notify-send &>/dev/null; then
		notify-send -u "$urgency" -t "$NOTIFY_TIME" "$title" "$msg"
	fi
}

#--- Brave/Chromium fix fonksiyonu ---------------------------------------------
fix_profile_files_in_dir() {
	local base="$1"

	# Local State dosyası
	if [[ -f "$base/Local State" ]]; then
		sed -i \
			-e 's/"exited_cleanly":[^,]*/"exited_cleanly":true/' \
			-e 's/"exit_type":"[^"]*"/"exit_type":"Normal"/' \
			"$base/Local State" || true
	fi

	# Profile*/Default Preferences
	local profiles=("$base"/Default "$base"/Profile*)
	for p in "${profiles[@]}"; do
		[[ -d "$p" ]] || continue
		if [[ -f "$p/Preferences" ]]; then
			sed -i \
				-e 's/"exited_cleanly":[^,]*/"exited_cleanly":true/' \
				-e 's/"exit_type":"[^"]*"/"exit_type":"Normal"/' \
				"$p/Preferences" || true
		fi
	done
}

fix_browser_flags() {
	# Brave - ana dizin
	fix_profile_files_in_dir "$HOME/.config/BraveSoftware/Brave-Browser"

	# Brave isolated (profile_brave --separate ile)
	# ~/.brave/isolated/<Class>/Local State + Profile*/Default
	if [[ -d "$HOME/.brave/isolated" ]]; then
		local d
		for d in "$HOME/.brave/isolated"/*; do
			[[ -d "$d" ]] || continue
			fix_profile_files_in_dir "$d"
		done
	fi

	# Chromium (opsiyonel)
	if [[ -d "$HOME/.config/chromium" ]]; then
		fix_profile_files_in_dir "$HOME/.config/chromium"
	fi
}

#--- Uygulamaları graceful şekilde kapat ---------------------------------------
graceful_shutdown() {
	echo "[INFO] SIGTERM gönderiliyor: ${GRACE_APPS[*]}"
	send_notify "🔄 Güvenli Reboot" "Tarayıcılar kapatılıyor..."

	for a in "${GRACE_APPS[@]}"; do
		# -f kullan (komut satırında ara)
		if pgrep -f "$a" >/dev/null 2>&1; then
			echo "[INFO] $a bulundu, kapatılıyor..."
			pkill -TERM -f "$a" 2>/dev/null || true
		fi
	done

	echo "[INFO] ${SOFT_TIMEOUT}s bekleniyor..."
	sleep "$SOFT_TIMEOUT"

	# Hala açık olanları KILL
	local killed=0
	for a in "${GRACE_APPS[@]}"; do
		if pgrep -f "$a" >/dev/null 2>&1; then
			echo "[WARN] $a hala açık, SIGKILL gönderiliyor..."
			pkill -KILL -f "$a" 2>/dev/null || true
			sleep "$HARD_DELAY"
			killed=1
		fi
	done

	if [[ $killed -eq 1 ]]; then
		send_notify "⚠️ Güvenli Reboot" "Bazı uygulamalar zorla kapatıldı" "critical"
	fi

	echo "[INFO] Tüm hedef uygulamalar kapatıldı."
}

#--- Ana akış ------------------------------------------------------------------
echo "[STEP] Uygulamalar kapatılıyor..."
graceful_shutdown

echo "[STEP] Brave/Chromium flag fix..."
fix_browser_flags
send_notify "✅ Güvenli Reboot" "Browser flag'leri düzeltildi"

echo "[STEP] Reboot başlatılıyor..."
send_notify "🔌 Sistem Yeniden Başlatılıyor" "3 saniye sonra reboot..." "critical"
sleep 1

exec systemctl reboot -i
