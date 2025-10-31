#!/usr/bin/env bash
#===============================================================================
#  Script: safe-reboot
#  Amaç : Brave/Chromium tabanlı tarayıcılar crash uyarısı vermeden reboot
#  Author: Kenan Pelit
#===============================================================================
set -euo pipefail

#--- Ayarlar -------------------------------------------------------------------
GRACE_APPS=("brave" "chromium")
SOFT_TIMEOUT=5 # SIGTERM sonrası bekleme (saniye)
HARD_DELAY=0.5 # KILL öncesi küçük bekleme

#--- Brave/Chromium fix fonksiyonu ---------------------------------------------
fix_browser_flags() {
	local base="$HOME/.config/BraveSoftware/Brave-Browser"
	local profiles=("$base"/Default "$base"/Profile*)

	for p in "${profiles[@]}"; do
		[[ -d "$p" ]] || continue
		# Preferences dosyası
		if [[ -f "$p/Preferences" ]]; then
			sed -i \
				-e 's/"exited_cleanly":[^,]*/"exited_cleanly":true/' \
				-e 's/"exit_type":"[^"]*"/"exit_type":"Normal"/' \
				"$p/Preferences" || true
		fi
	done

	# Local State dosyası
	if [[ -f "$base/Local State" ]]; then
		sed -i \
			-e 's/"exited_cleanly":[^,]*/"exited_cleanly":true/' \
			-e 's/"exit_type":"[^"]*"/"exit_type":"Normal"/' \
			"$base/Local State" || true
	fi
}

#--- Uygulamaları graceful şekilde kapat ---------------------------------------
graceful_shutdown() {
	echo "[INFO] SIGTERM gönderiliyor: ${GRACE_APPS[*]}"

	for a in "${GRACE_APPS[@]}"; do
		# -f kullan (komut satırında ara), -x kaldır
		if pgrep -f "$a" >/dev/null 2>&1; then
			echo "[INFO] $a bulundu, kapatılıyor..."
			pkill -TERM -f "$a" 2>/dev/null || true
		fi
	done

	echo "[INFO] ${SOFT_TIMEOUT}s bekleniyor..."
	sleep "$SOFT_TIMEOUT"

	# Hala açık olanları KILL
	for a in "${GRACE_APPS[@]}"; do
		if pgrep -f "$a" >/dev/null 2>&1; then
			echo "[WARN] $a hala açık, SIGKILL gönderiliyor..."
			pkill -KILL -f "$a" 2>/dev/null || true
			sleep "$HARD_DELAY"
		fi
	done

	echo "[INFO] Tüm hedef uygulamalar kapatıldı."
}

#--- Ana akış ------------------------------------------------------------------
echo "[STEP] Uygulamalar kapatılıyor..."
graceful_shutdown

echo "[STEP] Brave/Chromium flag fix..."
fix_browser_flags

echo "[STEP] Reboot başlatılıyor..."
exec systemctl reboot -i
