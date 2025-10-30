#!/usr/bin/env bash
#######################################
#
# tm.sh - Birleşik Tmux Yönetim Aracı
#
# Version: 2.0.0
# Date: 2025-10-30
# Author: Kenan Pelit
# Description: Comprehensive Tmux management, session, layouts, buffers, plugins, and more
#
# Bu script birçok tmux yardımcı programını tek bir komut satırı aracında birleştirir:
#
# - Oturum Yönetimi:
#   - Oturum oluştur, bağlan, sonlandır, listele
#   - Akıllı oturum adlandırma (git/dizin tabanlı)
#   - Layout şablonları (1-5 panel düzeni)
#
# - Pano ve Buffer Yönetimi:
#   - Tmux buffer yönetimi
#   - Sistem panosu entegrasyonu
#   - Sık kullanılan komutlar için hızlandırma
#
# - Eklenti Yönetimi:
#   - Eklenti kurulumu ve güncelleme
#   - TPM entegrasyonu
#
# - Yapılandırma:
#   - Yapılandırma yedekleme ve geri yükleme
#   - Terminal entegrasyonu (kitty/wezterm/alacritty)
#
# License: MIT
#
#######################################

# Katı hata yönetimi
set -euo pipefail

# Global yapılandırma
readonly VERSION="2.0.0"
readonly CONFIG_DIR="${HOME}/.config/tmux"
readonly PLUGIN_DIR="${CONFIG_DIR}/plugins"
readonly CACHE_DIR="${HOME}/.cache/tmux-manager"
readonly FZF_DIR="${CONFIG_DIR}/fzf"
readonly DEFAULT_SESSION="KENP"
readonly BACKUP_FILE="tmux_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
readonly HISTORY_LIMIT=100
readonly SOCKET_DIR="/tmp/tmux-$(id -u)"

# Gerekli dizinleri oluştur
mkdir -p "${CONFIG_DIR}" "${PLUGIN_DIR}" "${CACHE_DIR}" "${FZF_DIR}"

# Renk tanımlamaları
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # Renk yok

# Mesaj fonksiyonları - timestamp eklendi
info() {
	echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} ${GREEN}[INFO]${NC} $*"
}

warn() {
	echo -e "${YELLOW}[$(date +%H:%M:%S)]${NC} ${YELLOW}[WARN]${NC} $*"
}

error() {
	echo -e "${RED}[$(date +%H:%M:%S)]${NC} ${RED}[ERROR]${NC} $*" >&2
}

status() {
	echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} ${BLUE}[STATUS]${NC} $*"
}

success() {
	echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} ${GREEN}[SUCCESS]${NC} $*"
}

debug() {
	if [[ "${DEBUG:-0}" == "1" ]]; then
		echo -e "${MAGENTA}[$(date +%H:%M:%S)]${NC} ${MAGENTA}[DEBUG]${NC} $*" >&2
	fi
}

# FZF tema kurulumu - Catppuccin Mocha - Tüm modlarda tutarlı
setup_fzf_theme() {
	local prompt_text="${1:-Tmux}"
	local header_text="${2:-CTRL-R: Yenile | ESC: Çık}"

	export FZF_DEFAULT_OPTS="\
        -e -i \
        --info=inline \
        --layout=reverse \
        --border=rounded \
        --margin=1 \
        --padding=1 \
        --ansi \
        --prompt='$prompt_text ❯ ' \
        --pointer='▶' \
        --marker='✓' \
        --header='$header_text' \
        --color='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8' \
        --color='fg:#cdd6f4,header:#89b4fa,info:#cba6f7,pointer:#f5e0dc' \
        --color='marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8' \
        --bind 'ctrl-j:preview-down,ctrl-k:preview-up' \
        --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
        --bind 'ctrl-/:toggle-preview' \
        --bind 'ctrl-a:select-all,ctrl-n:deselect-all' \
        --tiebreak=index"
}

#--------------------------------------
# HELPER FUNCTIONS
#--------------------------------------

# Tmux kurulu mu kontrol et
check_tmux() {
	if ! command -v tmux >/dev/null 2>&1; then
		error "Tmux kurulu değil. Lütfen önce tmux'u kurun."
		exit 1
	fi
}

# Tmux oturumu içinde miyiz
is_in_tmux() {
	[[ -n "${TMUX:-}" ]]
}

# Oturum var mı kontrolü (tam eşleşme)
has_session_exact() {
	check_tmux
	tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -qx "$1"
}

# Oturum adı doğrulaması - daha geniş karakter desteği
validate_session_name() {
	local name="$1"

	if [[ -z "$name" ]]; then
		error "Oturum adı boş olamaz."
		return 1
	fi

	if [[ "$name" =~ [^a-zA-Z0-9_.-] ]]; then
		error "Geçersiz oturum adı: '$name'. Sadece harf, rakam, tire, alt çizgi ve nokta kullanabilirsiniz."
		return 1
	fi

	if [[ "${#name}" -gt 50 ]]; then
		error "Oturum adı çok uzun (maksimum 50 karakter)."
		return 1
	fi

	return 0
}

# Mevcut dizin veya git reposuna göre oturum adı al
get_session_name() {
	local dir_name
	local git_name

	dir_name="$(basename "$(pwd)")"
	git_name="$(git rev-parse --git-dir 2>/dev/null || true)"

	if [[ -n "$git_name" ]]; then
		basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "$dir_name")"
	else
		echo "$dir_name"
	fi
}

# Oturuma bağlan veya zaten bağlıysa değiştir
attach_or_switch() {
	local session_name="$1"

	if ! has_session_exact "$session_name"; then
		error "Oturum '$session_name' bulunamadı."
		return 1
	fi

	if is_in_tmux; then
		if ! tmux switch-client -t "$session_name" 2>/dev/null; then
			error "'$session_name' oturumuna geçilemedi."
			return 1
		fi
	else
		if ! tmux attach-session -t "$session_name" 2>/dev/null; then
			error "'$session_name' oturumuna bağlanılamadı."
			return 1
		fi
	fi

	success "Oturum '$session_name' aktif."
}

# Belirli bir mod için gerekli bağımlılıkları kontrol et
check_requirements() {
	local mode="$1"
	local req_failed=0

	case "$mode" in
	"session")
		check_tmux
		;;
	"buffer")
		check_tmux
		if ! is_in_tmux; then
			error "Tmux oturumunda değilsiniz. Lütfen tmux içinde çalıştırın."
			req_failed=1
		fi
		;;
	"clipboard")
		if ! command -v cliphist &>/dev/null; then
			error "cliphist kurulu değil!"
			info "Kurulum: yay -S cliphist (Arch) veya https://github.com/sentriz/cliphist"
			req_failed=1
		fi
		if ! command -v wl-copy &>/dev/null; then
			error "wl-clipboard kurulu değil!"
			info "Kurulum: sudo pacman -S wl-clipboard"
			req_failed=1
		fi
		;;
	"plugin")
		check_tmux
		if ! command -v git &>/dev/null; then
			error "git kurulu değil!"
			req_failed=1
		fi
		;;
	"speed")
		if [[ ! -d "$FZF_DIR" ]]; then
			warn "Komut dizini bulunamadı: $FZF_DIR"
			info "Dizin oluşturuluyor..."
			mkdir -p "$FZF_DIR"
		fi
		;;
	"all")
		check_tmux
		for cmd in fzf git; do
			if ! command -v "$cmd" &>/dev/null; then
				error "$cmd kurulu değil!"
				req_failed=1
			fi
		done
		;;
	esac

	return "$req_failed"
}

# Terminal tespiti - genişletilmiş destek
detect_terminal() {
	if [[ -n "${KITTY_WINDOW_ID:-}" ]] || command -v kitty >/dev/null 2>&1; then
		echo "kitty"
	elif [[ -n "${WEZTERM_EXECUTABLE:-}" ]] || command -v wezterm >/dev/null 2>&1; then
		echo "wezterm"
	elif command -v alacritty >/dev/null 2>&1; then
		echo "alacritty"
	elif command -v foot >/dev/null 2>&1; then
		echo "foot"
	else
		echo "x-terminal-emulator"
	fi
}

# Tmux soket dosyalarını temizle
clean_sockets() {
	warn "Soket dosyaları temizleniyor..."

	if [[ -d "$SOCKET_DIR" ]]; then
		for socket in "$SOCKET_DIR"/*; do
			if [[ -S "$socket" ]]; then
				rm -f "$socket" 2>/dev/null || true
				debug "Soket silindi: $socket"
			fi
		done
	fi

	tmux kill-server >/dev/null 2>&1 || true
	sleep 1
	success "Soketler temizlendi"
}

# Tmux sürüm kontrolü
check_tmux_version() {
	local required_version="3.0"
	local current_version

	if ! current_version=$(tmux -V 2>/dev/null | grep -oP '\d+\.\d+' | head -1); then
		return 0
	fi

	# Basit sürüm karşılaştırması (bc gerektirmeyen)
	local req_major req_minor cur_major cur_minor
	req_major="${required_version%%.*}"
	req_minor="${required_version##*.}"
	cur_major="${current_version%%.*}"
	cur_minor="${current_version##*.}"

	if [[ "$cur_major" -lt "$req_major" ]] ||
		[[ "$cur_major" -eq "$req_major" && "$cur_minor" -lt "$req_minor" ]]; then
		warn "Tmux sürümü eski: $current_version (Önerilen: $required_version+)"
	fi
}

#--------------------------------------
# SESSION MANAGEMENT
#--------------------------------------

# Tüm tmux oturumlarını listele - gelişmiş format
list_sessions() {
	if ! tmux list-sessions 2>/dev/null; then
		warn "Aktif oturum yok"
		return 0
	fi

	info "Mevcut oturumlar:"
	tmux list-sessions -F "#{session_name}: #{session_windows} pencere, #{session_attached} bağlı#{?session_grouped, (gruplu),}" 2>/dev/null |
		while IFS= read -r line; do
			echo "  • $line"
		done
}

# Tmux oturumunu sonlandır
kill_session() {
	local session_name="$1"

	if ! has_session_exact "$session_name"; then
		error "Oturum '$session_name' bulunamadı"
		return 1
	fi

	# Eğer şu an bu oturumun içindeysek uyar
	if is_in_tmux && [[ "$(tmux display-message -p '#S')" == "$session_name" ]]; then
		warn "Şu anda bu oturumun içindesiniz!"
		read -p "Yine de sonlandırmak istiyor musunuz? (e/H): " -n 1 -r
		echo
		if [[ ! $REPLY =~ ^[Ee]$ ]]; then
			info "İptal edildi"
			return 0
		fi
	fi

	if tmux kill-session -t "$session_name" 2>/dev/null; then
		success "Oturum '$session_name' sonlandırıldı"
	else
		error "Oturum '$session_name' sonlandırılamadı"
		return 1
	fi
}

# Yeni oturum oluştur veya mevcut oturuma bağlan
create_session() {
	local session_name="$1"
	local layout="${2:-}"

	if ! validate_session_name "$session_name"; then
		return 1
	fi

	if has_session_exact "$session_name"; then
		info "Oturum '$session_name' zaten var, bağlanıyor..."

		# Oturum zaten başka yerde bağlıysa ve biz tmux içinde değilsek yeni pencere oluştur
		if ! is_in_tmux && tmux list-sessions 2>/dev/null | grep -q "^${session_name}: .* (attached)$"; then
			warn "Oturum başka yerde bağlı, yeni pencere oluşturuluyor..."
			local window_count
			window_count=$(tmux list-windows -t "$session_name" 2>/dev/null | wc -l)
			debug "Mevcut pencere sayısı: $window_count"
			tmux new-window -t "$session_name" 2>/dev/null || warn "Yeni pencere oluşturulamadı"
		fi

		attach_or_switch "$session_name"
	else
		info "Yeni oturum oluşturuluyor: '$session_name'..."

		if ! tmux new-session -d -s "$session_name" 2>/dev/null; then
			warn "Oturum oluşturulamadı, soket temizliği deneniyor..."
			clean_sockets

			if ! tmux new-session -d -s "$session_name" 2>/dev/null; then
				error "Temizlikten sonra bile oturum oluşturulamadı!"
				return 1
			fi
		fi

		# Layout belirtilmişse uygula
		if [[ -n "$layout" ]]; then
			create_layout "$session_name" "$layout"
		fi

		success "Oturum oluşturuldu, bağlanıyor..."
		attach_or_switch "$session_name"
	fi
}

# Yeni terminal penceresinde oturum aç
open_session_in_terminal() {
	local terminal_type="$1"
	local session_name="$2"
	local layout="${3:-1}"
	local class_name="tmux-$session_name"
	local title="Tmux: $session_name"
	local script_path

	script_path="$(readlink -f "$0")"

	case "$terminal_type" in
	kitty)
		if ! command -v kitty &>/dev/null; then
			error "Kitty terminal kurulu değil!"
			return 1
		fi
		kitty --class="$class_name" \
			--title="$title" \
			--directory="$PWD" \
			-e bash -c "$script_path session create \"$session_name\" $layout" &
		;;
	wezterm)
		if ! command -v wezterm &>/dev/null; then
			error "WezTerm terminal kurulu değil!"
			return 1
		fi
		# WezTerm için sadece class kullan, title'ı tmux içinde ayarla
		wezterm start \
			--class "$class_name" \
			-- bash -c "cd '$PWD' && $script_path session create \"$session_name\" $layout" &
		;;
	alacritty)
		if ! command -v alacritty &>/dev/null; then
			error "Alacritty terminal kurulu değil!"
			return 1
		fi
		alacritty --class "$class_name" \
			--title "$title" \
			--working-directory "$PWD" \
			-e bash -c "$script_path session create \"$session_name\" $layout" &
		;;
	*)
		error "Desteklenmeyen terminal türü: $terminal_type"
		info "Desteklenen terminaller: kitty, wezterm, alacritty"
		return 1
		;;
	esac

	success "Terminal başlatıldı: '$session_name'"
}

#--------------------------------------
# LAYOUT FUNCTIONS
#--------------------------------------

# Çeşitli tmux düzenleri oluştur
create_layout() {
	local session_name="$1"
	local layout_num="$2"

	if ! has_session_exact "$session_name"; then
		error "Oturum '$session_name' bulunamadı."
		return 1
	fi

	info "Oturum '$session_name' için düzen $layout_num oluşturuluyor..."

	case "$layout_num" in
	1)
		# Tek panel düzeni
		tmux new-window -t "$session_name" -n 'main' 2>/dev/null || true
		tmux select-pane -t 1 2>/dev/null || true
		;;
	2)
		# İki panel düzeni (dikey bölme)
		tmux new-window -t "$session_name" -n 'main' 2>/dev/null || true
		tmux split-window -v -p 30 2>/dev/null || true
		tmux select-pane -t 1 2>/dev/null || true
		;;
	3)
		# Üç panel düzeni (2 üstte, 1 altta)
		tmux new-window -t "$session_name" -n 'main' 2>/dev/null || true
		tmux split-window -h -p 50 2>/dev/null || true
		tmux split-window -v -p 30 2>/dev/null || true
		tmux select-pane -t 1 2>/dev/null || true
		;;
	4)
		# Dört panel düzeni (2x2 grid)
		tmux new-window -t "$session_name" -n 'main' 2>/dev/null || true
		tmux split-window -h -p 50 2>/dev/null || true
		tmux split-window -v -p 50 2>/dev/null || true
		tmux select-pane -t 1 2>/dev/null || true
		tmux split-window -v -p 50 2>/dev/null || true
		tmux select-pane -t 1 2>/dev/null || true
		;;
	5)
		# Beş panel düzeni (1 ana, 4 yan)
		tmux new-window -t "$session_name" -n 'main' 2>/dev/null || true
		tmux split-window -h -p 75 2>/dev/null || true
		tmux split-window -v -p 66 2>/dev/null || true
		tmux split-window -v -p 50 2>/dev/null || true
		tmux split-window -v -p 33 2>/dev/null || true
		tmux select-pane -t 1 2>/dev/null || true
		;;
	*)
		error "Geçersiz düzen numarası: $layout_num (1-5 arası olmalı)"
		return 1
		;;
	esac

	success "Düzen $layout_num oluşturuldu"
}

#--------------------------------------
# BUFFER MANAGEMENT
#--------------------------------------

# Buffer modunu işle - geliştirilmiş
handle_buffer_mode() {
	if ! check_requirements "buffer"; then
		return 1
	fi

	setup_fzf_theme "Buffer" "ENTER: Kopyala | CTRL-D: Sil | ESC: Çık"

	local buffer_count
	buffer_count=$(tmux list-buffers 2>/dev/null | wc -l)

	if [[ "$buffer_count" -eq 0 ]]; then
		warn "Hiç buffer yok"
		return 0
	fi

	info "Buffer sayısı: $buffer_count"

	local selected
	selected=$(tmux list-buffers -F "#{buffer_name}: #{buffer_sample}" 2>/dev/null |
		fzf --preview 'echo {}| cut -d: -f1 | xargs -I {} tmux show-buffer -b {}' \
			--preview-window=up:70%:wrap \
			--bind 'ctrl-d:execute(tmux delete-buffer -b {1})+reload(tmux list-buffers -F "#{buffer_name}: #{buffer_sample}")' \
			--header-lines=0)

	if [[ -n "$selected" ]]; then
		local buffer_name
		buffer_name=$(echo "$selected" | cut -d: -f1)

		if tmux show-buffer -b "$buffer_name" | wl-copy 2>/dev/null; then
			success "Buffer kopyalandı: $buffer_name"
		else
			error "Buffer kopyalanamadı"
			return 1
		fi
	fi
}

#--------------------------------------
# CLIPBOARD MANAGEMENT
#--------------------------------------

# Pano modunu işle
handle_clipboard_mode() {
	if ! check_requirements "clipboard"; then
		return 1
	fi

	setup_fzf_theme "Clipboard" "ENTER: Yapıştır | CTRL-D: Sil | ESC: Çık"

	local selected
	selected=$(cliphist list |
		fzf --preview 'echo {} | cliphist decode' \
			--preview-window=up:70%:wrap \
			--bind 'ctrl-d:execute(echo {} | cliphist delete)+reload(cliphist list)')

	if [[ -n "$selected" ]]; then
		if echo "$selected" | cliphist decode | wl-copy 2>/dev/null; then
			success "Panoya kopyalandı"
		else
			error "Panoya kopyalanamadı"
			return 1
		fi
	fi
}

#--------------------------------------
# PLUGIN MANAGEMENT
#--------------------------------------

# Eklenti kur
install_plugin() {
	local plugin_name="$1"
	local repo_url="$2"
	local plugin_path="${PLUGIN_DIR}/${plugin_name}"

	if [[ -d "$plugin_path" ]]; then
		warn "Eklenti zaten kurulu: $plugin_name"
		read -p "Güncelleme yapmak ister misiniz? (e/H): " -n 1 -r
		echo
		if [[ $REPLY =~ ^[Ee]$ ]]; then
			info "Eklenti güncelleniyor: $plugin_name"
			if git -C "$plugin_path" pull 2>/dev/null; then
				success "Eklenti güncellendi: $plugin_name"
			else
				error "Eklenti güncellenemedi: $plugin_name"
				return 1
			fi
		fi
		return 0
	fi

	info "Eklenti kuruluyor: $plugin_name"
	if git clone "$repo_url" "$plugin_path" 2>/dev/null; then
		success "Eklenti kuruldu: $plugin_name"
	else
		error "Eklenti kurulamadı: $plugin_name"
		return 1
	fi
}

# Kurulu eklentileri listele
list_plugins() {
	if [[ ! -d "$PLUGIN_DIR" ]] || [[ -z "$(ls -A "$PLUGIN_DIR" 2>/dev/null)" ]]; then
		warn "Kurulu eklenti yok"
		return 0
	fi

	info "Kurulu eklentiler:"
	for plugin in "$PLUGIN_DIR"/*; do
		if [[ -d "$plugin" ]]; then
			local plugin_name
			plugin_name=$(basename "$plugin")
			local last_update=""

			if [[ -d "$plugin/.git" ]]; then
				last_update=$(git -C "$plugin" log -1 --format="%ar" 2>/dev/null || echo "bilinmiyor")
				echo "  • $plugin_name (son güncelleme: $last_update)"
			else
				echo "  • $plugin_name"
			fi
		fi
	done
}

# Tüm önerilen eklentileri kur
install_all_plugins() {
	info "Önerilen eklentiler kuruluyor..."

	local plugins=(
		"tpm:https://github.com/tmux-plugins/tpm"
		"tmux-sensible:https://github.com/tmux-plugins/tmux-sensible"
		"tmux-resurrect:https://github.com/tmux-plugins/tmux-resurrect"
		"tmux-continuum:https://github.com/tmux-plugins/tmux-continuum"
		"tmux-yank:https://github.com/tmux-plugins/tmux-yank"
		"tmux-copycat:https://github.com/tmux-plugins/tmux-copycat"
	)

	local failed=0
	for plugin_info in "${plugins[@]}"; do
		local name="${plugin_info%%:*}"
		local url="${plugin_info##*:}"

		if ! install_plugin "$name" "$url"; then
			((failed++))
		fi
	done

	if [[ "$failed" -eq 0 ]]; then
		success "Tüm eklentiler başarıyla kuruldu"
	else
		warn "$failed eklenti kurulamadı"
	fi
}

#--------------------------------------
# SPEED MODE (Command Shortcuts)
#--------------------------------------

# Hız modunu işle
handle_speed_mode() {
	if ! check_requirements "speed"; then
		return 1
	fi

	setup_fzf_theme "Komut" "ENTER: Çalıştır | CTRL-E: Düzenle | ESC: Çık"

	# Örnek komut dosyası oluştur
	local sample_file="${FZF_DIR}/commands.txt"
	if [[ ! -f "$sample_file" ]]; then
		cat >"$sample_file" <<'EOF'
# Tmux Hızlı Komutlar
# Format: açıklama | komut

Oturum Listele | tmux ls
Yeni Oturum | tmux new -s
Oturumu Öldür | tmux kill-session -t
Pencere Listele | tmux list-windows
Panel Listele | tmux list-panes
Yapılandırmayı Yükle | tmux source ~/.config/tmux/tmux.conf
EOF
		info "Örnek komut dosyası oluşturuldu: $sample_file"
	fi

	local selected
	selected=$(grep -v '^#' "$sample_file" | grep -v '^$' |
		fzf --delimiter=' | ' \
			--with-nth=1 \
			--preview 'echo {2}' \
			--preview-window=up:3:wrap \
			--bind 'ctrl-e:execute(${EDITOR:-vim} '"$sample_file"')+abort')

	if [[ -n "$selected" ]]; then
		local command
		command=$(echo "$selected" | cut -d'|' -f2- | xargs)

		info "Komut çalıştırılıyor: $command"
		eval "$command"
	fi
}

#--------------------------------------
# CONFIGURATION BACKUP/RESTORE
#--------------------------------------

# Yapılandırmayı yedekle
backup_config() {
	local backup_path="${HOME}/${BACKUP_FILE}"

	info "Tmux yapılandırması yedekleniyor..."

	if tar czf "$backup_path" -C "$HOME" \
		".config/tmux" \
		".cache/tmux-manager" 2>/dev/null; then
		success "Yedek oluşturuldu: $backup_path"

		local size
		size=$(du -h "$backup_path" | cut -f1)
		info "Yedek boyutu: $size"
	else
		error "Yedek oluşturulamadı"
		return 1
	fi
}

# Yapılandırmayı geri yükle
restore_config() {
	local backup_path="${HOME}/${BACKUP_FILE}"

	if [[ ! -f "$backup_path" ]]; then
		error "Yedek dosyası bulunamadı: $backup_path"
		return 1
	fi

	warn "Mevcut yapılandırma üzerine yazılacak!"
	read -p "Devam etmek istiyor musunuz? (e/H): " -n 1 -r
	echo

	if [[ ! $REPLY =~ ^[Ee]$ ]]; then
		info "İptal edildi"
		return 0
	fi

	info "Yapılandırma geri yükleniyor..."

	if tar xzf "$backup_path" -C "$HOME" 2>/dev/null; then
		success "Yapılandırma geri yüklendi"
	else
		error "Yapılandırma geri yüklenemedi"
		return 1
	fi
}

#--------------------------------------
# KENP SESSION MODE
#--------------------------------------

# KENP geliştirme oturumu
kenp_session_mode() {
	local session_name="${1:-$DEFAULT_SESSION}"

	if ! validate_session_name "$session_name"; then
		return 1
	fi

	info "KENP oturumu başlatılıyor: $session_name"

	# Oturum varsa bağlan
	if has_session_exact "$session_name"; then
		attach_or_switch "$session_name"
		return $?
	fi

	# Yeni oturum oluştur
	if ! tmux new-session -d -s "$session_name" -n 'editor' 2>/dev/null; then
		error "KENP oturumu oluşturulamadı"
		return 1
	fi

	# İkinci pencere: terminal
	tmux new-window -t "$session_name" -n 'terminal'

	# Üçüncü pencere: monitoring (htop/btop)
	tmux new-window -t "$session_name" -n 'monitor'
	if command -v btop &>/dev/null; then
		tmux send-keys -t "$session_name:monitor" 'btop' C-m
	elif command -v htop &>/dev/null; then
		tmux send-keys -t "$session_name:monitor" 'htop' C-m
	fi

	# İlk pencereyi seç
	tmux select-window -t "$session_name:editor"

	success "KENP oturumu hazır"
	attach_or_switch "$session_name"
}

#--------------------------------------
# HELP FUNCTIONS
#--------------------------------------

# Oturum yardımı
show_session_help() {
	cat <<EOF
$(echo -e "${GREEN}")Oturum Yönetimi$(echo -e "${NC}")

Kullanım: $(basename "$0") session <komut> [parametreler]

Komutlar:
    create <ad> [düzen]  Yeni oturum oluştur veya mevcut oturuma bağlan
    list                 Tüm oturumları listele
    kill <ad>            Oturumu sonlandır
    attach <ad>          Oturuma bağlan
    layout <ad> <no>     Belirtilen düzeni uygula (1-5)
    term <tip> <ad> [düzen]  Yeni terminalde oturum aç (kitty/wezterm/alacritty)

Düzenler:
    1: Tek panel
    2: İki panel (dikey bölme)
    3: Üç panel (2 üst, 1 alt)
    4: Dört panel (2x2 grid)
    5: Beş panel (1 ana, 4 yan)

Örnekler:
    $(basename "$0") session create myproject 3
    $(basename "$0") session list
    $(basename "$0") session kill myproject
    $(basename "$0") session term kitty dev 2
    $(basename "$0") session term wezterm myproject 3

Notlar:
    • Parametre verilmezse, mevcut dizin adıyla oturum oluşturulur
    • Git repo'dayken, repo adı oturum adı olarak kullanılır
    • Oturum adları sadece harf, rakam, tire, nokta ve alt çizgi içerebilir
EOF
}

# Buffer yardımı
show_buffer_help() {
	cat <<EOF
$(echo -e "${GREEN}")Buffer Yönetimi$(echo -e "${NC}")

Kullanım: $(basename "$0") buffer [komut]

Komutlar:
    show    İnteraktif buffer tarayıcısı (varsayılan)
    list    Buffer'ları listele

Kısayollar (buffer modunda):
    ENTER:   Buffer'ı panoya kopyala
    CTRL-D:  Buffer'ı sil
    CTRL-J/K: Preview yukarı/aşağı
    ESC:     Çık

Not: Buffer modu sadece tmux oturumu içinde çalışır
EOF
}

# Pano yardımı
show_clipboard_help() {
	cat <<EOF
$(echo -e "${GREEN}")Pano Yönetimi$(echo -e "${NC}")

Kullanım: $(basename "$0") clip

İnteraktif pano geçmişi tarayıcısı.

Kısayollar:
    ENTER:   Öğeyi panoya kopyala
    CTRL-D:  Öğeyi sil
    CTRL-J/K: Preview yukarı/aşağı
    ESC:     Çık

Gereksinimler:
    • cliphist
    • wl-clipboard

Kurulum (Arch):
    yay -S cliphist wl-clipboard
EOF
}

# Eklenti yardımı
show_plugin_help() {
	cat <<EOF
$(echo -e "${GREEN}")Eklenti Yönetimi$(echo -e "${NC}")

Kullanım: $(basename "$0") plugin <komut> [parametreler]

Komutlar:
    install <ad> <url>  Eklenti kur
    list                Kurulu eklentileri listele
    all                 Tüm önerilen eklentileri kur

Önerilen Eklentiler:
    • tpm              - Tmux Plugin Manager
    • tmux-sensible    - Temel ayarlar
    • tmux-resurrect   - Oturum kaydetme
    • tmux-continuum   - Otomatik kaydetme
    • tmux-yank        - Gelişmiş kopyalama
    • tmux-copycat     - Regex arama

Örnekler:
    $(basename "$0") plugin all
    $(basename "$0") plugin list
    $(basename "$0") plugin install custom https://github.com/user/plugin

Not: TPM kullanıyorsanız, eklentileri tmux.conf'da da tanımlamalısınız
EOF
}

# Hız modu yardımı
show_speed_help() {
	cat <<EOF
$(echo -e "${GREEN}")Komut Hızlandırma$(echo -e "${NC}")

Kullanım: $(basename "$0") speed

İnteraktif komut seçici ve çalıştırıcı.

Özellikler:
    • Sık kullanılan komutları favorilere ekle
    • Hızlı erişim ve çalıştırma
    • Özelleştirilebilir komut listesi

Kısayollar:
    ENTER:   Komutu çalıştır
    CTRL-E:  Komut dosyasını düzenle
    ESC:     Çık

Komut Dosyası:
    ~/.config/tmux/fzf/commands.txt

Format:
    açıklama | komut

Örnek:
    Oturum Listele | tmux ls
    Yeni Pencere | tmux new-window
EOF
}

# Yapılandırma yardımı
show_backup_help() {
	cat <<EOF
$(echo -e "${GREEN}")Yapılandırma Yönetimi$(echo -e "${NC}")

Kullanım: $(basename "$0") config <komut>

Komutlar:
    backup   Tmux yapılandırmasını yedekle
    restore  Yapılandırmayı geri yükle

Yedeklenen Dizinler:
    • ~/.config/tmux
    • ~/.cache/tmux-manager

Yedek Dosyası:
    ~/tmux_backup_YYYYMMDD_HHMMSS.tar.gz

Örnekler:
    $(basename "$0") config backup
    $(basename "$0") config restore

Not: Geri yükleme işlemi mevcut yapılandırmanın üzerine yazar
EOF
}

# KENP yardımı
show_kenp_help() {
	cat <<EOF
$(echo -e "${GREEN}")KENP Geliştirme Oturumu$(echo -e "${NC}")

Kullanım: $(basename "$0") kenp [oturum_adı]

Özelleştirilmiş geliştirme ortamı oturumu oluşturur.

Pencereler:
    1. editor   - Ana düzenleme penceresi
    2. terminal - Terminal penceresi
    3. monitor  - Sistem izleme (htop/btop)

Örnekler:
    $(basename "$0") kenp          # 'KENP' adıyla oturum
    $(basename "$0") kenp dev      # 'dev' adıyla oturum
    $(basename "$0")               # KENP oturumu (varsayılan)

Not: Parametre verilmezse 'KENP' adıyla oturum oluşturulur
EOF
}

# TMX yardımı (legacy uyumluluk)
show_tmx_help() {
	cat <<EOF
$(echo -e "${GREEN}")TMX Modu (Legacy Uyumluluk)$(echo -e "${NC}")

Kullanım: $(basename "$0") tmx [seçenek] [parametreler]

Seçenekler:
    -h, --help              Bu yardımı göster
    -l, --list              Oturumları listele
    -k, --kill <ad>         Oturumu sonlandır
    -n, --new <ad>          Yeni oturum oluştur
    -a, --attach <ad>       Oturuma bağlan
    -d, --detach            Oturumdan ayrıl
    -t, --terminal <tip> <ad> [düzen]  Terminalde oturum aç
    --layout <no>           Düzen uygula (1-5)

Örnekler:
    $(basename "$0") tmx -l
    $(basename "$0") tmx -n myproject
    $(basename "$0") tmx -t kitty dev 3
    $(basename "$0") tmx --layout 2

Not: Yeni projeler için 'session' modunu kullanın
EOF
}

# Ana yardım
show_help() {
	cat <<EOF
$(echo -e "${CYAN}")╔════════════════════════════════════════════════════════════════╗
║         tm.sh v${VERSION} - Tmux Yönetim Aracı               ║
╚════════════════════════════════════════════════════════════════╝$(echo -e "${NC}")

$(echo -e "${GREEN}")Kullanım:$(echo -e "${NC}") $(basename "$0") <modül> [komut] [parametreler]

$(echo -e "${GREEN}")Modüller:$(echo -e "${NC}")
    $(echo -e "${YELLOW}")session$(echo -e "${NC}")    Oturum ve düzen yönetimi
    $(echo -e "${YELLOW}")buffer$(echo -e "${NC}")     Buffer yönetimi ve navigasyon
    $(echo -e "${YELLOW}")clip$(echo -e "${NC}")       Pano geçmişi ve yönetimi
    $(echo -e "${YELLOW}")plugin$(echo -e "${NC}")     Eklenti kurulumu ve yönetimi
    $(echo -e "${YELLOW}")speed$(echo -e "${NC}")      Komut hızlandırma ve favoriler
    $(echo -e "${YELLOW}")config$(echo -e "${NC}")     Yapılandırma yedekleme ve geri yükleme
    $(echo -e "${YELLOW}")kenp$(echo -e "${NC}")       KENP geliştirme oturumu başlat
    $(echo -e "${YELLOW}")tmx$(echo -e "${NC}")        Legacy tmux komutları (eski uyumluluk)
    $(echo -e "${YELLOW}")help$(echo -e "${NC}")       Yardım mesajlarını göster

$(echo -e "${GREEN}")Hızlı Başlangıç:$(echo -e "${NC}")
    $(basename "$0")                           # KENP oturumu (varsayılan)
    $(basename "$0") session create proje 3    # 3 nolu düzenle oturum
    $(basename "$0") buffer                    # Buffer tarayıcı
    $(basename "$0") clip                      # Pano geçmişi
    $(basename "$0") plugin all                # Tüm eklentileri kur

$(echo -e "${GREEN}")Örnekler:$(echo -e "${NC}")
    # Oturum yönetimi
    $(basename "$0") s create myproject        # Oturum oluştur
    $(basename "$0") s list                    # Oturumları listele
    $(basename "$0") s kill myproject          # Oturumu sonlandır
    
    # Düzen kullanımı
    $(basename "$0") s create dev 3            # 3 nolu düzenle oturum
    $(basename "$0") s layout dev 4            # Mevcut oturuma düzen 4 uygula
    
    # Terminal entegrasyonu
    $(basename "$0") s term kitty dev 2        # Kitty'de 2 nolu düzenle oturum

$(echo -e "${GREEN}")Detaylı Yardım:$(echo -e "${NC}")
    $(basename "$0") help <modül>              # Modül-spesifik yardım

$(echo -e "${GREEN}")Ortam Değişkenleri:$(echo -e "${NC}")
    DEBUG=1                                    # Debug modunu etkinleştir
    EDITOR=vim                                 # Varsayılan editör

$(echo -e "${GREEN}")Gereksinimler:$(echo -e "${NC}")
    $(echo -e "${CYAN}")Temel:$(echo -e "${NC}") tmux, bash, fzf
    $(echo -e "${CYAN}")İsteğe Bağlı:$(echo -e "${NC}") git, cliphist, wl-clipboard, kitty/wezterm/alacritty

$(echo -e "${GREEN}")Yapılandırma:$(echo -e "${NC}")
    $(echo -e "${CYAN}")Ana Dizin:$(echo -e "${NC}")       ~/.config/tmux
    $(echo -e "${CYAN}")Eklentiler:$(echo -e "${NC}")      ~/.config/tmux/plugins
    $(echo -e "${CYAN}")Önbellek:$(echo -e "${NC}")        ~/.cache/tmux-manager
    $(echo -e "${CYAN}")Komutlar:$(echo -e "${NC}")        ~/.config/tmux/fzf/commands.txt

$(echo -e "${GREEN}")Yazar:$(echo -e "${NC}") Kenan Pelit
$(echo -e "${GREEN}")Lisans:$(echo -e "${NC}") MIT
$(echo -e "${GREEN}")Sürüm:$(echo -e "${NC}") ${VERSION}

Daha fazla bilgi: $(basename "$0") help <modül>
EOF
}

# Yardım komutlarını işle
process_help_commands() {
	local module="${1:-}"

	case "$module" in
	"session" | "s")
		show_session_help
		;;
	"buffer" | "b")
		show_buffer_help
		;;
	"clip" | "c")
		show_clipboard_help
		;;
	"plugin" | "p")
		show_plugin_help
		;;
	"speed" | "cmd")
		show_speed_help
		;;
	"config" | "cfg")
		show_backup_help
		;;
	"kenp" | "k")
		show_kenp_help
		;;
	"tmx")
		show_tmx_help
		;;
	*)
		show_help
		;;
	esac
}

#--------------------------------------
# COMMAND PROCESSORS
#--------------------------------------

# Oturum komutlarını işle
process_session_commands() {
	local command="${1:-}"
	shift 2>/dev/null || true

	case "$command" in
	"create" | "c")
		local session_name="${1:-$(get_session_name)}"
		local layout="${2:-}"
		create_session "$session_name" "$layout"
		;;
	"list" | "l" | "ls")
		list_sessions
		;;
	"kill" | "k")
		if [[ -z "${1:-}" ]]; then
			error "Oturum adı belirtilmedi"
			return 1
		fi
		kill_session "$1"
		;;
	"attach" | "a")
		if [[ -z "${1:-}" ]]; then
			error "Oturum adı belirtilmedi"
			return 1
		fi
		if has_session_exact "$1"; then
			attach_or_switch "$1"
		else
			error "Oturum '$1' bulunamadı"
			return 1
		fi
		;;
	"layout" | "lo")
		if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
			error "Oturum adı ve düzen numarası gerekli"
			return 1
		fi
		create_layout "$1" "$2"
		;;
	"term" | "t")
		if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
			error "Terminal türü ve oturum adı gerekli"
			info "Desteklenen terminaller: kitty, wezterm, alacritty"
			return 1
		fi
		local layout="${3:-1}"
		open_session_in_terminal "$1" "$2" "$layout"
		;;
	*)
		error "Bilinmeyen oturum komutu: $command"
		show_session_help
		return 1
		;;
	esac
}

# Buffer komutlarını işle
process_buffer_commands() {
	local command="${1:-show}"
	shift 2>/dev/null || true

	case "$command" in
	"list" | "l" | "ls")
		if ! check_requirements "buffer"; then
			return 1
		fi
		tmux list-buffers
		;;
	"show" | "s" | "")
		handle_buffer_mode
		;;
	*)
		error "Bilinmeyen buffer komutu: $command"
		show_buffer_help
		return 1
		;;
	esac
}

# Pano komutlarını işle
process_clipboard_commands() {
	local command="${1:-show}"
	shift 2>/dev/null || true

	case "$command" in
	"show" | "s" | "")
		handle_clipboard_mode
		;;
	*)
		error "Bilinmeyen pano komutu: $command"
		show_clipboard_help
		return 1
		;;
	esac
}

# Eklenti komutlarını işle
process_plugin_commands() {
	local command="${1:-}"
	shift 2>/dev/null || true

	case "$command" in
	"install" | "i")
		if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
			error "Eklenti adı ve repository gerekli"
			show_plugin_help
			return 1
		fi
		install_plugin "$1" "$2"
		;;
	"list" | "l" | "ls")
		list_plugins
		;;
	"all" | "a")
		install_all_plugins
		;;
	*)
		error "Bilinmeyen eklenti komutu: $command"
		show_plugin_help
		return 1
		;;
	esac
}

# Hız komutlarını işle
process_speed_commands() {
	local command="${1:-show}"
	shift 2>/dev/null || true

	case "$command" in
	"show" | "s" | "")
		handle_speed_mode
		;;
	*)
		error "Bilinmeyen hız komutu: $command"
		show_speed_help
		return 1
		;;
	esac
}

# Yapılandırma komutlarını işle
process_config_commands() {
	local command="${1:-}"
	shift 2>/dev/null || true

	case "$command" in
	"backup" | "b")
		backup_config
		;;
	"restore" | "r")
		restore_config
		;;
	*)
		error "Bilinmeyen config komutu: $command"
		show_backup_help
		return 1
		;;
	esac
}

# TMX komutlarını işle (legacy uyumluluk)
process_tmx_commands() {
	local command="${1:-}"
	shift 2>/dev/null || true

	case "$command" in
	"-h" | "--help" | "help")
		show_tmx_help
		;;
	"-l" | "--list" | "list")
		list_sessions
		;;
	"-k" | "--kill" | "kill")
		if [[ -z "${1:-}" ]]; then
			error "Oturum adı belirtilmedi"
			return 1
		fi
		kill_session "$1"
		;;
	"-n" | "--new" | "new")
		if [[ -z "${1:-}" ]]; then
			error "Oturum adı belirtilmedi"
			return 1
		fi
		create_session "$1"
		;;
	"-t" | "--terminal" | "term")
		if [[ -z "${1:-}" ]] || [[ -z "${2:-}" ]]; then
			error "Terminal türü ve oturum adı belirtilmelidir"
			return 1
		fi
		local layout="${3:-1}"
		open_session_in_terminal "$1" "$2" "$layout"
		;;
	"-d" | "--detach" | "detach")
		tmux detach-client
		;;
	"-a" | "--attach" | "attach")
		if [[ -z "${1:-}" ]]; then
			error "Oturum adı belirtilmedi"
			return 1
		fi
		if has_session_exact "$1"; then
			attach_or_switch "$1"
		else
			error "Oturum '$1' bulunamadı"
			return 1
		fi
		;;
	"--layout" | "layout")
		if [[ -z "${1:-}" ]]; then
			error "Düzen numarası belirtilmelidir"
			return 1
		fi

		if ! is_in_tmux; then
			error "Tmux oturumunda değilsiniz"
			return 1
		fi

		create_layout "$(tmux display-message -p '#S')" "$1"
		;;
	"")
		local session_name="$(get_session_name)"
		create_session "$session_name"
		;;
	*)
		# Oturum adı olarak yorumla
		create_session "$command"
		;;
	esac
}

#--------------------------------------
# MAIN FUNCTION
#--------------------------------------

main() {
	local module="${1:-}"
	shift 2>/dev/null || true

	# Tmux sürüm kontrolü (sadece bir kere)
	check_tmux_version

	# Hiçbir parametre verilmezse KENP oturumu başlat
	if [[ -z "$module" ]]; then
		kenp_session_mode
		return $?
	fi

	case "$module" in
	"session" | "s")
		process_session_commands "$@"
		;;
	"buffer" | "b")
		process_buffer_commands "$@"
		;;
	"clip" | "c")
		process_clipboard_commands "$@"
		;;
	"plugin" | "p")
		process_plugin_commands "$@"
		;;
	"speed" | "cmd")
		process_speed_commands "$@"
		;;
	"config" | "cfg")
		process_config_commands "$@"
		;;
	"help" | "h" | "-h" | "--help")
		process_help_commands "$@"
		;;
	"kenp" | "k")
		kenp_session_mode "$@"
		;;
	"tmx")
		process_tmx_commands "$@"
		;;
	"version" | "-v" | "--version")
		echo "tm.sh v${VERSION}"
		;;
	*)
		# Varsayılan davranış - oturum adı olarak yorumla
		if validate_session_name "$module"; then
			create_session "$module"
		else
			error "Bilinmeyen komut veya geçersiz oturum adı: $module"
			info "Yardım için: $(basename "$0") help"
			return 1
		fi
		;;
	esac
}

# Ana fonksiyonu tüm parametrelerle çalıştır
main "$@"
