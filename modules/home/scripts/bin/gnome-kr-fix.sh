#!/usr/bin/env bash
# gkr-fix.sh — GNOME keyring lag fixer (NixOS/TTY GNOME)
set -euo pipefail
log() { printf '[%(%F %T)T] %s\n' -1 "$*"; }
die() {
	log "ERROR: $*"
	"$NOTIFY_SEND" -u critical -a "Keyring Fix" "❌ Keyring Fix Hatası" "$*" 2>/dev/null || true
	exit 1
}

# --- notification helper ----------------------------------------------------
NOTIFY_SEND="$(command -v notify-send || echo /run/current-system/sw/bin/notify-send)"

notify() {
	local title="$1"
	local body="$2"
	local urgency="${3:-normal}"

	# Full path ile çağır, arka plana at
	if [[ -x "$NOTIFY_SEND" ]]; then
		"$NOTIFY_SEND" -u "$urgency" -a "Keyring Fix" "$title" "$body" &
		disown
	fi
}

# --- binaries ---------------------------------------------------------------
GKD_BIN="$(command -v gnome-keyring-daemon || true)"
[[ -n "$GKD_BIN" ]] || GKD_BIN="/run/current-system/sw/bin/gnome-keyring-daemon"
[[ -x "$GKD_BIN" ]] || die "gnome-keyring-daemon bulunamadı"
SYSTEMD_RUN="$(command -v systemd-run || true)"
[[ -n "$SYSTEMD_RUN" ]] || SYSTEMD_RUN="/run/current-system/sw/bin/systemd-run"
[[ -x "$SYSTEMD_RUN" ]] || die "systemd-run yok"

SYSTEMCTL="$(command -v systemctl || true)"
[[ -n "$SYSTEMCTL" ]] || SYSTEMCTL="/run/current-system/sw/bin/systemctl"
[[ -x "$SYSTEMCTL" ]] || die "systemctl yok"

BUSCTL_BIN="$(command -v busctl || true)"
[[ -n "$BUSCTL_BIN" ]] || BUSCTL_BIN="/run/current-system/sw/bin/busctl"
[[ -x "$BUSCTL_BIN" ]] || die "busctl yok"

# grep kullan (ripgrep farklı syntax kullanıyor)
GREP_BIN="$(command -v grep || true)"
[[ -n "$GREP_BIN" ]] || GREP_BIN="/run/current-system/sw/bin/grep"
[[ -x "$GREP_BIN" ]] || die "grep yok"

# --- force user bus ---------------------------------------------------------
: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
if [[ -S "${XDG_RUNTIME_DIR}/bus" ]]; then
	export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
else
	die "User bus yok: ${XDG_RUNTIME_DIR}/bus"
fi

# bus hazır mı?
for _ in {1..50}; do
	if "$BUSCTL_BIN" --user list >/dev/null 2>&1; then break; fi
	sleep 0.1
done

log "DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS}"
log "Keyring binary            : ${GKD_BIN}"

# İlk notification'ı hemen gönder, dbus çalışıyor mu test et
"$NOTIFY_SEND" -u low -a "Keyring Fix" "🔧 Keyring Fix" "GNOME Keyring yeniden başlatılıyor..." 2>/dev/null || log "notify başarısız (devam ediyoruz)"

# --- start/replace keyring in background via systemd-run --------------------
UNIT="gnome-keyring-fix-$(date +%s 2>/dev/null || echo $)"
log "systemd-run --user başlatılıyor (unit: ${UNIT})"

"$SYSTEMD_RUN" --user --unit="$UNIT" --collect --quiet \
	"$GKD_BIN" --replace --foreground --components=secrets,ssh,pkcs11 ||
	die "systemd-run keyring başlatamadı"

# --- wait until org.freedesktop.secrets is really owned ---------------------
own_ok() {
	"$BUSCTL_BIN" --user list 2>/dev/null |
		"$GREP_BIN" -E '^org\.freedesktop\.secrets[[:space:]]' |
		"$GREP_BIN" -v '(activatable)' |
		"$GREP_BIN" -qE '^[^[:space:]]+[[:space:]]+[0-9]+[[:space:]]'
}

log "org.freedesktop.secrets ownership bekleniyor…"
for _ in {1..100}; do
	if own_ok; then
		log "✅ org.freedesktop.secrets *owned* — lag fix tamam."

		# Başarı notification'ı direkt gönder
		"$NOTIFY_SEND" -u normal -a "Keyring Fix" "✅ Keyring Fix Başarılı" "GNOME Keyring aktif, lag düzeltildi!" 2>/dev/null || true

		# gsd-media-keys'i nazikçe dürt (opsiyonel; hata verirse sessiz)
		systemctl --user try-restart org.gnome.SettingsDaemon.MediaKeys.service 2>/dev/null || true
		systemctl --user try-restart org.gnome.SettingsDaemon.media-keys.service 2>/dev/null || true
		exit 0
	fi
	sleep 0.1
done

log "❌ sahiplenemedi. Teşhis:"
"$BUSCTL_BIN" --user list | "$GREP_BIN" -E 'org\.freedesktop\.secrets|org\.gnome\.keyring' || true

# Hata notification'ı direkt gönder
"$NOTIFY_SEND" -u critical -a "Keyring Fix" "❌ Keyring Fix Başarısız" "DBus servisini alamadı. Detay için log'a bak." 2>/dev/null || true

die "Keyring DBus adını alamadı; yine de bazı durumlarda pratikte çalışıyor olabilir."
