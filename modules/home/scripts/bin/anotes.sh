#!/usr/bin/env bash
# ===========================================================================
# anotes.sh - Anote.sh için geliştirilmiş başlatıcı
# ===========================================================================
#
# Bu betik, anote.sh terminal not yönetim sistemini çeşitli terminal emülatörlerinde
# çalıştırmak için bir başlatıcı görevi görür, kullanıcıya daha iyi bir deneyim sunar.
#
# Geliştiren: Kenan Pelit
# Repository: github.com/kenanpelit
# Versiyon: 1.1
# Lisans: GPLv3

# Hataları yakalamak için
set -euo pipefail

# =================================================================
# KONFİGÜRASYON
# =================================================================

# Temel ayarlar
ANOTE_CMD="${ANOTE_CMD:-anote}"
ANOTE_WINDOW_TITLE="${ANOTE_WINDOW_TITLE:-Anote}"
ANOTE_WINDOW_CLASS="${ANOTE_WINDOW_CLASS:-anote}"
ANOTE_DIR="${ANOTE_DIR:-$HOME/.anote}"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/anotes/config"

# EDITOR değişkeni ayarlanmamışsa nvim'i varsayılan olarak ayarla
if [ -z "${EDITOR:-}" ] && [ -z "${VISUAL:-}" ]; then
	export EDITOR=nvim
fi

# Konfigürasyon dosyası varsa yükle
if [[ -f "$CONFIG_FILE" ]]; then
	# shellcheck source=/dev/null
	source "$CONFIG_FILE"
fi

# =================================================================
# FONKSİYONLAR
# =================================================================

# Show help message
show_help() {
	cat <<EOF
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃                          ANOTES - Anote Başlatıcı                            ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

KULLANIM: anotes [SEÇENEK]

AÇIKLAMA:
    anote.sh terminal not yönetim sistemi için geliştirilmiş başlatıcı.

SEÇENEKLER:
    -t, --single       Tek satır snippet modunu başlat
    -M, --multi        Çok satırlı snippet modunu başlat
    -s, --search       Arama modunu başlat
    -A, --audit        Denetim modunu başlat (karalama defteri)
    -c, --create       Dosya oluşturma modunu başlat
    -C, --config       Anotes yapılandırma dosyasını aç
    -r, --restart      Varsa mevcut anote penceresini yeniden başlat
    -d, --daemon       Arka planda çalıştır
    -a, --auto METİN   Hızlı not ekle ve çık
    -S, --scratch      Doğrudan karalama defterini aç
    -k, --kill         Çalışan tüm anote örneklerini sonlandır
    -h, --help         Bu yardım mesajını göster

ÖRNEKLER:
    anotes                      # Anote'u varsayılan ayarlarla çalıştır
    anotes -a "Yapılacak: John'u ara" # Hızlı not ekle ve çık

YAPILANDIRMA DOSYASI: ~/.config/anotes/config
EOF
}

# Terminal emülatörünü tespit et ve uygun komutu ayarla
detect_terminal() {
	# Desteklenen terminalleri kontrol et
	if command -v kitty &>/dev/null; then
		TERMINAL_CMD="kitty --class $ANOTE_WINDOW_CLASS -T $ANOTE_WINDOW_TITLE --single-instance"
		return 0
	fi

	if command -v wezterm &>/dev/null; then
		TERMINAL_CMD="wezterm start --class $ANOTE_WINDOW_CLASS --window-title $ANOTE_WINDOW_TITLE"
		return 0
	fi

	# Eğer terminal bulunamazsa hatayla çık
	echo "Hata: Desteklenen terminal bulunamadı (kitty veya wezterm)" >&2
	exit 1
}

# anote.sh'nin var olup olmadığını kontrol et
check_anote() {
	if ! command -v "$ANOTE_CMD" &>/dev/null; then
		echo "Hata: $ANOTE_CMD PATH üzerinde bulunamadı" >&2
		exit 1
	fi
}

# Çalışan anote örneklerini sonlandır
kill_anote() {
	if command -v pkill &>/dev/null; then
		pkill -f "$ANOTE_WINDOW_CLASS" || true
		echo "Anote örnekleri sonlandırıldı"
	else
		echo "Uyarı: pkill bulunamadı, anote örnekleri sonlandırılamıyor" >&2
	fi
}

# Yapılandırma dosyasını oluştur (yoksa)
ensure_config() {
	if [[ ! -f "$CONFIG_FILE" ]]; then
		mkdir -p "$(dirname "$CONFIG_FILE")"
		cat >"$CONFIG_FILE" <<EOF
# anotes.sh yapılandırma dosyası

# Temel ayarlar
ANOTE_CMD="$ANOTE_CMD"
ANOTE_WINDOW_TITLE="$ANOTE_WINDOW_TITLE"
ANOTE_WINDOW_CLASS="$ANOTE_WINDOW_CLASS"

# Ek özellikler
ANOTE_USE_TMUX=false  # tmux varsa tmux içinde çalıştırmak için true olarak ayarlayın
ANOTE_AUTOSTART=false # Giriş sırasında anote'u başlatmak için true olarak ayarlayın
EOF
		echo "Varsayılan yapılandırma oluşturuldu: $CONFIG_FILE"
	fi
}

# Daemon modunda çalıştır
run_daemon() {
	nohup "$@" >/dev/null 2>&1 &
	echo "Anote arka planda başlatıldı"
	exit 0
}

# =================================================================
# ANA PROGRAM
# =================================================================

# Çalışma dizini yoksa oluştur
mkdir -p "$ANOTE_DIR" 2>/dev/null

# Komut satırı parametrelerini işle
ANOTE_ARGS=()
DAEMON=false
RESTART=false

while [[ $# -gt 0 ]]; do
	case "$1" in
	-t | --single)
		ANOTE_ARGS+=("-t")
		shift
		;;
	-M | --multi)
		ANOTE_ARGS+=("-M")
		shift
		;;
	-s | --search)
		ANOTE_ARGS+=("-s")
		shift
		;;
	-A | --audit)
		ANOTE_ARGS+=("-A")
		shift
		;;
	-S | --scratch)
		ANOTE_ARGS+=("--scratch")
		shift
		;;
	-c | --create)
		ANOTE_ARGS+=("--create")
		shift
		;;
	-C | --config)
		ensure_config
		${EDITOR:-vim} "$CONFIG_FILE"
		exit 0
		;;
	-r | --restart)
		RESTART=true
		shift
		;;
	-d | --daemon)
		DAEMON=true
		shift
		;;
	-a | --auto)
		if [[ -n "${2:-}" ]]; then
			# Anote'u doğrudan auto seçeneğiyle çalıştır
			$ANOTE_CMD -a "$2"
			exit 0
		else
			echo "Hata: -a/--auto metin argümanı gerektirir" >&2
			exit 1
		fi
		;;
	-k | --kill)
		kill_anote
		exit 0
		;;
	-h | --help)
		show_help
		exit 0
		;;
	*)
		# Diğer argümanları anote'a ilet
		ANOTE_ARGS+=("$1")
		shift
		;;
	esac
done

# anote.sh'yi kontrol et
check_anote

# Eğer yeniden başlatma istenmişse mevcut örnekleri sonlandır
if [[ "$RESTART" == "true" ]]; then
	kill_anote
fi

# Terminal tespit et ve komutu ayarla
detect_terminal

# Son komutu oluştur
if [[ ${#ANOTE_ARGS[@]} -eq 0 ]]; then
	# Hiçbir argüman belirtilmemişse, varsayılan ayarlarla çalıştır
	CMD="$TERMINAL_CMD -e bash -c \"$ANOTE_CMD\""
else
	# Belirtilen argümanlarla çalıştır
	CMD="$TERMINAL_CMD -e bash -c \"$ANOTE_CMD ${ANOTE_ARGS[*]}\""
fi

# İstenirse daemon modunda çalıştır
if [[ "$DAEMON" == "true" ]]; then
	run_daemon bash -c "$CMD"
else
	# Komutu çalıştır
	eval "$CMD"
fi

# Başarılı durumla çık
exit 0
