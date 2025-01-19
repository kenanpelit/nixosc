#!/usr/bin/env bash
#######################################
# Version: 1.1.0
# Description: TmuxManager - Tmux Oturum Yöneticisi
# License: MIT
#######################################
# Hata yönetimi
set -euo pipefail

# Renk tanımlamaları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Mesaj fonksiyonları
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
print_status() { echo -e "${BLUE}[STATUS]${NC} $1"; }

# Yardımcı fonksiyonlar
has_session_exact() {
	tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -qx "$1"
}

validate_session_name() {
	local name="$1"
	if [[ "$name" =~ [^a-zA-Z0-9_-] ]]; then
		print_error "Geçersiz session ismi. Sadece harfler, rakamlar, tire ve alt çizgi kullanılabilir."
		return 1
	fi
	return 0
}

# Terminal işlemleri
check_terminal() {
	if command -v foot >/dev/null 2>&1; then
		echo "foot"
	elif command -v kitty >/dev/null 2>&1; then
		echo "kitty"
	elif command -v alacritty >/dev/null 2>&1; then
		echo "alacritty"
	else
		echo "x-terminal-emulator"
	fi
}

open_terminal() {
	local terminal_type="$1"
	local session_name="$2"
	local class_name="tmux-$session_name"
	local title="Tmux: $session_name"

	case "$terminal_type" in
	foot)
		if ! command -v foot >/dev/null 2>&1; then
			print_error "Foot terminal yüklü değil!"
			return 1
		fi
		foot --app-id="$class_name" \
			--title="$title" \
			--working-directory="$PWD" \
			bash -c "tmux new-session -A -s \"$session_name\"" &
		;;
	kitty)
		if ! command -v kitty >/dev/null 2>&1; then
			print_error "Kitty terminal yüklü değil!"
			return 1
		fi
		kitty --class="$class_name" \
			--title="$title" \
			--directory="$PWD" \
			-e bash -c "tmux new-session -A -s \"$session_name\"" &
		;;
	alacritty)
		if ! command -v alacritty >/dev/null 2>&1; then
			print_error "Alacritty terminal yüklü değil!"
			return 1
		fi
		alacritty --class "$class_name" \
			--title "$title" \
			--working-directory "$PWD" \
			-e bash -c "tmux new-session -A -s \"$session_name\"" &
		;;
	*)
		print_error "Desteklenmeyen terminal tipi: $terminal_type"
		return 1
		;;
	esac
}

# Tmux işlemleri
attach_or_switch() {
	local session_name="$1"
	if [[ -n "${TMUX:-}" ]]; then
		tmux switch-client -t "$session_name" || print_error "Session '$session_name'e geçilemedi."
	else
		tmux attach-session -t "$session_name" || print_error "Session '$session_name'e bağlanılamadı."
	fi
}

create_session() {
	local session_name="$1"
	local terminal_type="${2:-}"

	if ! validate_session_name "$session_name"; then
		return 1
	fi

	# Eğer terminal tipi belirtilmemişse ve tmux oturumunda değilsek, varsayılan terminali tespit et
	if [[ -z "$terminal_type" ]] && [[ -z "${TMUX:-}" ]]; then
		terminal_type=$(check_terminal)
	fi

	if has_session_exact "$session_name"; then
		if [[ -n "$terminal_type" ]]; then
			open_terminal "$terminal_type" "$session_name"
		else
			if tmux list-sessions | grep -q "^${session_name}: .* (attached)$"; then
				print_warning "Oturum '${session_name}' zaten bağlı, yeni pencere açılıyor..."
				tmux new-window -t "$session_name"
			fi
			attach_or_switch "$session_name"
		fi
	else
		if [[ -n "$terminal_type" ]]; then
			open_terminal "$terminal_type" "$session_name"
		else
			print_info "Yeni tmux oturumu '${session_name}' başlatılıyor..."
			tmux new-session -d -s "$session_name" && attach_or_switch "$session_name"
		fi
	fi
}

# Kullanım bilgisi
show_help() {
	cat <<EOF
Tmux Oturum Yöneticisi

Kullanım: $(basename "$0") <session_ismi> [terminal_tipi]

Parametreler:
    session_ismi     Oluşturulacak/bağlanılacak oturum ismi
    terminal_tipi    İsteğe bağlı: foot, kitty, alacritty

Örnekler:
    $(basename "$0") proje1
    $(basename "$0") proje1 foot
    $(basename "$0") proje1 kitty
    $(basename "$0") proje1 alacritty

Notlar:
    - Session isimleri sadece harf, rakam, tire ve alt çizgi içerebilir
    - Terminal tipi belirtilmezse mevcut terminal kullanılır
    - Launcher'lardan (wofi, ulauncher vb.) çağrılabilir
EOF
}

# Ana işlev
main() {
	# Eğer parametre yoksa yardım göster
	if [ $# -eq 0 ]; then
		show_help
		exit 1
	fi

	case "${1:-}" in
	-h | --help)
		show_help
		;;
	*)
		local session_name="$1"
		local terminal_type="${2:-}"
		create_session "$session_name" "$terminal_type"
		;;
	esac
}

# Scripti çalıştır
main "$@"
