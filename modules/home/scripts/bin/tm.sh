#!/usr/bin/env bash
#######################################
#
# tm.sh - Birleşik Tmux Yönetim Aracı
#
# Version: 1.0.0
# Date: 2025-04-17
# Author: Kenan Pelit
# Description: Comprehensive Tmux management, session, layouts, buffers, plugins, and more
#
# This script combines multiple tmux utilities into a single command-line tool:
#
# - Session Management:
#   - Create, attach, kill, list sessions
#   - Smart session naming (git/directory based)
#   - Layout templates (1-5 panel layouts)
#
# - Clipboard & Buffer Management:
#   - Tmux buffer management
#   - System clipboard integration
#   - Command speedup for frequent commands
#
# - Plugin Management:
#   - Install and update plugins
#   - TPM integration
#
# - Configuration:
#   - Backup and restore configuration
#   - Terminal integration (kitty/wezterm)
#
# License: MIT
#
#######################################

# Strict error handling
set -euo pipefail

# Global configuration
VERSION="1.0.0"
CONFIG_DIR="${HOME}/.config/tmux"
PLUGIN_DIR="${CONFIG_DIR}/plugins"
CACHE_DIR="${HOME}/.cache/tmux-manager"
FZF_DIR="${CONFIG_DIR}/fzf"
DEFAULT_SESSION="KENP"
BACKUP_FILE="tmux_backup.tar.gz"
HISTORY_LIMIT=100

# Create necessary directories
mkdir -p "${CONFIG_DIR}" "${PLUGIN_DIR}" "${CACHE_DIR}" "${FZF_DIR}"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Message functions
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
status() { echo -e "${BLUE}[STATUS]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

# FZF theme setup - Catppuccin Mocha - Consistent across all modes
setup_fzf_theme() {
	local prompt_text="${1:-Tmux}"
	local header_text="${2:-CTRL-R: Yenile | ESC: Çık}"
	export FZF_DEFAULT_OPTS="\
        -e -i \
        --info=default \
        --layout=reverse \
        --margin=1 \
        --padding=1 \
        --ansi \
        --prompt='$prompt_text: ' \
        --pointer='❯' \
        --header='$header_text' \
        --color='bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4' \
        --color='header:#89b4fa,info:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1,prompt:#cba6f7' \
        --bind 'ctrl-j:preview-down,ctrl-k:preview-up' \
        --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up' \
        --bind 'ctrl-/:change-preview-window(hidden|)' \
        --color='pointer:#cba6f7' \
        --tiebreak=index"
}

#--------------------------------------
# HELPER FUNCTIONS
#--------------------------------------

# Check if tmux is installed
check_tmux() {
	if ! command -v tmux >/dev/null 2>&1; then
		error "Tmux is not installed. Please install tmux first."
		exit 1
	fi
}

# Check if we're inside a tmux session
is_in_tmux() {
	[ -n "${TMUX:-}" ]
}

# Check if a session exists (exact match)
has_session_exact() {
	check_tmux
	tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -qx "$1"
}

# Validate session name
validate_session_name() {
	local name="$1"
	if [[ "$name" =~ [^a-zA-Z0-9_-] ]]; then
		error "Invalid session name: '$name'. Only letters, numbers, hyphens, and underscores are allowed."
		return 1
	fi
	return 0
}

# Get session name based on current directory or git repo
get_session_name() {
	local dir_name="$(basename "$(pwd)")"
	local git_name="$(git rev-parse --git-dir 2>/dev/null)"

	if [[ -n "$git_name" ]]; then
		echo "$(basename "$(git rev-parse --show-toplevel)")"
	else
		echo "$dir_name"
	fi
}

# Attach to session or switch if already attached
attach_or_switch() {
	local session_name="$1"
	if is_in_tmux; then
		tmux switch-client -t "$session_name" || error "Could not switch to session '$session_name'."
	else
		tmux attach-session -t "$session_name" || error "Could not attach to session '$session_name'."
	fi
}

# Check for required dependencies for a specific mode
check_requirements() {
	local mode="$1"
	local req_failed=0

	case "$mode" in
	"session")
		check_tmux
		;;
	"buffer")
		check_tmux
		if is_in_tmux; then
			# We're good
			:
		else
			error "Not in a tmux session. Please run inside tmux."
			req_failed=1
		fi
		;;
	"clipboard")
		if ! command -v cliphist &>/dev/null; then
			error "cliphist is not installed!"
			req_failed=1
		fi
		if ! command -v wl-copy &>/dev/null; then
			error "wl-clipboard is not installed!"
			req_failed=1
		fi
		;;
	"plugin")
		check_tmux
		if ! command -v git &>/dev/null; then
			error "git is not installed!"
			req_failed=1
		fi
		;;
	"speed")
		if [ ! -d "$FZF_DIR" ]; then
			error "Command directory not found: $FZF_DIR"
			error "Please create the directory or check the configuration"
			req_failed=1
		fi
		;;
	"all")
		check_tmux
		for cmd in fzf git; do
			if ! command -v "$cmd" &>/dev/null; then
				error "$cmd is not installed!"
				req_failed=1
			fi
		done
		;;
	esac

	if [ "$req_failed" -eq 1 ]; then
		return 1
	fi
	return 0
}

# Terminal detection
check_terminal() {
	if command -v kitty >/dev/null 2>&1; then
		echo "kitty"
	elif command -v wezterm >/dev/null 2>&1; then
		echo "wezterm"
	else
		echo "x-terminal-emulator"
	fi
}

# Clean tmux socket files (in case of issues)
clean_sockets() {
	warn "Cleaning socket files..."
	for socket in /tmp/tmux-$(id -u)/*; do
		if [ -S "$socket" ]; then
			rm -f "$socket" 2>/dev/null || true
		fi
	done
	tmux kill-server >/dev/null 2>&1 || true
	sleep 1
	success "Sockets cleaned"
}

#--------------------------------------
# SESSION MANAGEMENT
#--------------------------------------

# List all tmux sessions
list_sessions() {
	info "Available sessions:"
	tmux list-sessions 2>/dev/null || warn "No active sessions"
}

# Kill a tmux session
kill_session() {
	local session_name="$1"
	if has_session_exact "$session_name"; then
		if tmux kill-session -t "$session_name"; then
			success "Session '$session_name' terminated"
		else
			error "Failed to terminate session '$session_name'"
			return 1
		fi
	else
		error "Session '$session_name' not found"
		return 1
	fi
}

# Create a new session or attach to existing
create_session() {
	local session_name="$1"
	local layout="${2:-}"

	if ! validate_session_name "$session_name"; then
		return 1
	fi

	if has_session_exact "$session_name"; then
		info "Session '$session_name' already exists, attaching..."

		# If session is already attached and we're not in tmux, open a new window
		if ! is_in_tmux && tmux list-sessions | grep -q "^${session_name}: .* (attached)$"; then
			warn "Session is already attached elsewhere, creating a new window..."
			local window_count
			window_count=$(tmux list-windows -t "$session_name" | wc -l)
			status "Current window count: $window_count"
			tmux new-window -t "$session_name"
		fi

		attach_or_switch "$session_name"
	else
		info "Creating new session '$session_name'..."
		if ! tmux new-session -d -s "$session_name"; then
			error "Failed to create session, trying socket cleanup..."
			clean_sockets
			if ! tmux new-session -d -s "$session_name"; then
				error "Failed to create session even after cleanup!"
				return 1
			fi
		fi

		# Apply layout if specified
		if [[ -n "$layout" ]]; then
			create_layout "$session_name" "$layout"
		fi

		success "Session created, attaching..."
		attach_or_switch "$session_name"
	fi
}

# Create session in a new terminal window
open_session_in_terminal() {
	local terminal_type="$1"
	local session_name="$2"
	local layout="${3:-1}"
	local class_name="tmux-$session_name"
	local title="Tmux: $session_name"

	case "$terminal_type" in
	kitty)
		if ! command -v kitty &>/dev/null; then
			error "Kitty terminal is not installed!"
			return 1
		fi
		kitty --class="$class_name" \
			--title="$title" \
			--directory="$PWD" \
			-e bash -c "$(readlink -f "$0") session create \"$session_name\" $layout" &
		;;
	wezterm)
		if ! command -v wezterm &>/dev/null; then
			error "WezTerm terminal is not installed!"
			return 1
		fi
		wezterm start \
			--class "$class_name" \
			--window-title "$title" \
			-- bash -c "cd $PWD && $(readlink -f "$0") session create \"$session_name\" $layout" &
		;;
	*)
		error "Unsupported terminal type: $terminal_type"
		return 1
		;;
	esac

	success "Terminal launched for session '$session_name'"
}

#--------------------------------------
# LAYOUT FUNCTIONS
#--------------------------------------

# Create various tmux layouts
create_layout() {
	local session_name="$1"
	local layout_num="$2"

	if ! has_session_exact "$session_name"; then
		error "Session '$session_name' not found."
		return 1
	fi

	info "Creating layout $layout_num in session '$session_name'..."

	case "$layout_num" in
	1)
		# Single panel layout
		tmux new-window -t "$session_name" -n 'kenp'
		tmux select-pane -t 1
		;;
	2)
		# Two panel layout
		tmux new-window -t "$session_name" -n 'kenp'
		tmux split-window -v -p 80
		tmux select-pane -t 2
		;;
	3)
		# Three panel L-shaped layout
		tmux new-window -t "$session_name" -n 'kenp'
		tmux split-window -h -p 80
		tmux select-pane -t 2
		tmux split-window -v -p 85
		tmux select-pane -t 3
		;;
	4)
		# Four panel grid layout
		tmux new-window -t "$session_name" -n 'kenp'
		tmux split-window -h -p 80
		tmux split-window -v -p 80
		tmux select-pane -t 1
		tmux split-window -v -p 80
		tmux select-pane -t 4
		;;
	5)
		# Five panel layout
		tmux new-window -t "$session_name" -n 'kenp'
		tmux split-window -h -p 70
		tmux split-window -h -p 50
		tmux select-pane -t 1
		tmux split-window -v -p 50
		tmux select-pane -t 2
		tmux split-window -v -p 50
		tmux select-pane -t 5
		;;
	*)
		error "Invalid layout number $layout_num. Choose between 1-5."
		return 1
		;;
	esac

	success "Layout $layout_num created in session '$session_name'"
}

# KENPSession için create_layout fonksiyonunu ekle
kenp_create_layout() {
	local session_name="$1"
	info "KENPSession için 3-panelli düzen oluşturuluyor..."

	# Doğrudan 3-panelli düzeni oluşturalım
	tmux new-window -t "$session_name" -n 'kenp'
	tmux split-window -h -p 80
	tmux select-pane -t 2
	tmux split-window -v -p 85
	tmux select-pane -t 3

	success "3-panelli düzen oluşturuldu"
	return 0
}

# KENP session mode - pre-configured development environment
kenp_session_mode() {
	local session_name="${1:-KENP}"

	# Check if tmux is installed
	check_tmux

	# Set environment variables
	export TERM=xterm-256color
	USER_SHELL="$(getent passwd "$(id -u)")"
	USER_SHELL="${USER_SHELL##*:}"

	# Check if already in tmux
	if is_in_tmux; then
		warn "Zaten bir tmux oturumu içindesiniz."
		return 0
	fi

	# Check if session exists
	session=$(tmux ls 2>/dev/null | grep "^${session_name}:" || echo "")

	if [[ $session == *"${session_name}: attached"* ]]; then
		# Session exists and is attached
		info "Oturum '${session_name}' zaten bağlı, yeni bir shell başlatılıyor..."
		exec "$USER_SHELL"
	elif [[ $session == *"${session_name}:"* ]]; then
		# Session exists but is not attached
		info "Oturum '${session_name}' mevcut, oturuma bağlanılıyor..."
		if ! tmux attach-session -t "$session_name"; then
			warn "Mevcut oturuma bağlanılamadı, yeni bir oturum oluşturuluyor..."
			tmux kill-session -t "$session_name" 2>/dev/null || true
			tmux new-session -A -s "$session_name"
		fi
	else
		# Session doesn't exist, create it
		info "Oturum '${session_name}' mevcut değil, yeni bir tmux oturumu başlatılıyor..."

		# Try to start tmux server if it fails
		if ! tmux start-server 2>/dev/null; then
			warn "Tmux sunucusu başlatılamadı, soketler temizleniyor..."
			clean_sockets
		fi

		# Create session
		if ! tmux new-session -d -s "$session_name"; then
			error "Oturum oluşturulamadı, son bir deneme daha yapılıyor..."
			clean_sockets
			if ! tmux new-session -d -s "$session_name"; then
				error "Oturum oluşturulamadı!"
				return 1
			fi
		fi

		# Create layout directly with built-in function
		#kenp_create_layout "$session_name"

		# Attach to the session
		info "Yeni oluşturulan '$session_name' oturumuna bağlanılıyor..."
		if ! tmux attach-session -t "$session_name"; then
			error "Oturuma bağlanılamadı!"
			return 1
		fi
	fi
}

#--------------------------------------
# BUFFER MANAGEMENT
#--------------------------------------

# Show empty buffer art
show_empty_buffer_art() {
	cat <<-'EMPTYART'
		        
		   ┌────────────────────────────────────────────────────┐
		   │                                                    │
		   │   ¯\_(ツ)_/¯                                       │
		   │                                                    │
		   │   Tmux buffer'ım boş!                              │
		   │                                                    │
		   │   Önce bir şeyler kopyalasanız iyi olur yoksa      │
		   │   burada birlikte bekleyeceğiz...                  │
		   │                                                    │
		   │   İpucu: Tmux'ta [prefix]+[ ile copy mode'a girin  │
		   │   ve birşeyler kopyalayın                          │
		   │                                                    │
		   └────────────────────────────────────────────────────┘
		        
	EMPTYART
}

# Handle buffer mode - for tmux buffer management
handle_buffer_mode() {
	# Requirements check
	if ! check_requirements "buffer"; then
		return 1
	fi

	# Buffer list empty check
	if ! tmux list-buffers &>/dev/null || [[ -z "$(tmux list-buffers 2>/dev/null)" ]]; then
		show_empty_buffer_art
		return 1
	fi

	# FZF theme setup
	setup_fzf_theme "Buffer" "Buffer Seçimi | CTRL-R: Yenile | CTRL-Y: Kopyala | ESC: Çık"

	info "Starting buffer mode..."

	# FZF buffer selection
	selected_buffer=$(tmux list-buffers -F '#{buffer_name}:#{buffer_sample}' |
		fzf --preview 'buffer_name=$(echo {} | cut -d ":" -f1); tmux show-buffer -b "$buffer_name"' \
			--preview-window 'right:60%:wrap' \
			--bind "ctrl-r:reload(tmux list-buffers -F '#{buffer_name}:#{buffer_sample}')" \
			--bind "ctrl-y:execute-silent(buffer_name=\$(echo {} | cut -d ':' -f1); tmux show-buffer -b \"\$buffer_name\" | wl-copy 2>/dev/null || tmux load-buffer -b \"\$buffer_name\" && echo 'Copied: \$buffer_name' >&2)" \
			--delimiter ':')

	# Process selection
	if [[ -n "$selected_buffer" ]]; then
		buffer_name=$(echo "$selected_buffer" | cut -d ':' -f1)
		if [[ -n "$buffer_name" ]]; then
			tmux paste-buffer -b "$buffer_name"
			success "Selected buffer pasted: $buffer_name"
		else
			error "Invalid buffer name, could not paste"
			return 1
		fi
	fi
}

#--------------------------------------
# CLIPBOARD MANAGEMENT
#--------------------------------------

# Handle clipboard mode - for system clipboard management
handle_clipboard_mode() {
	# Requirements check
	if ! check_requirements "clipboard"; then
		return 1
	fi

	# FZF theme setup
	setup_fzf_theme "Clipboard" "Clipboard Geçmişi | CTRL-R: Yenile | CTRL-D: Sil | CTRL-Y: Kopyala | Enter: Seç"

	info "Starting clipboard mode..."

	# Create preview script
	PREVIEW_SCRIPT=$(mktemp)
	chmod +x "$PREVIEW_SCRIPT"

	# Generate preview script content
	cat >"$PREVIEW_SCRIPT" <<'EOL'
#!/usr/bin/env bash
set -euo pipefail

preview_limit=5000

# Clear terminal screen
clear

# Parameter check
if [ -z "${1:-}" ]; then
    echo "No content provided for preview"
    exit 0
fi

# Create temp file
temp_file=$(mktemp)

# Get content and save to temp file
if ! cliphist decode <<< "$1" > "$temp_file" 2>/dev/null; then
    echo "Could not get content"
    rm -f "$temp_file"
    exit 0
fi

# Check if file is empty
if [ ! -s "$temp_file" ]; then
    echo "Content is empty"
    rm -f "$temp_file"
    exit 0
fi

# Get file output
file_output=$(file -b "$temp_file")
echo -e "\033[1;34mFile type:\033[0m $file_output"
echo -e "\033[1;34mSize:\033[0m $(du -h "$temp_file" | cut -f1)"
echo -e "\033[1;34mContent:\033[0m"
echo

# Check for PNG/JPEG
if [[ "$file_output" == *"PNG"* ]] || [[ "$file_output" == *"JPEG"* ]] || [[ "$file_output" == *"image data"* ]]; then
    if command -v chafa &>/dev/null; then
        chafa --size=80x25 --symbols=block+space --colors=256 "$temp_file" 2>/dev/null || echo "Image preview failed"
    else
        echo "[chafa required for image preview]"
    fi
else
    head -c "$preview_limit" "$temp_file"
    if [ "$(wc -c < "$temp_file")" -gt "$preview_limit" ]; then
        echo -e "\n\033[0;33m... (more content)\033[0m"
    fi
fi

# Cleanup
rm -f "$temp_file"
EOL

	# FZF selection
	selected=$(cliphist list |
		fzf --preview "$PREVIEW_SCRIPT {}" \
			--preview-window "right:60%:wrap" \
			--bind "ctrl-r:reload(cliphist list)" \
			--bind "ctrl-d:execute(echo {} | cliphist delete)+reload(cliphist list)" \
			--bind "ctrl-y:execute-silent(echo {} | cliphist decode | wl-copy && echo 'Content copied' >&2)")

	# Clean up temp files
	rm -f "$PREVIEW_SCRIPT"

	# Process selection
	if [[ -n "$selected" ]]; then
		content=$(cliphist decode <<<"$selected")
		echo "$content" | wl-copy
		if [ -n "${TMUX:-}" ]; then
			echo "$content" | tmux load-buffer -
			success "Content copied to clipboard and tmux buffer"
		else
			success "Content copied to clipboard"
		fi
	fi
}

#--------------------------------------
# SPEED COMMAND MODE
#--------------------------------------

# Handle speed mode - for quick command execution
handle_speed_mode() {
	# Requirements check
	if ! check_requirements "speed"; then
		return 1
	fi

	info "Starting command speedup mode..."

	# Create cache file directory if needed
	CACHE_FILE="${CACHE_DIR}/speed_cache"
	mkdir -p "$(dirname "$CACHE_FILE")"
	touch "$CACHE_FILE"

	# Statistics
	total=$(find "$FZF_DIR" -type f -name '_*' 2>/dev/null | wc -l)
	ssh_count=$(find "$FZF_DIR" -type f -name '_ssh*' 2>/dev/null | wc -l)
	tmux_count=$(find "$FZF_DIR" -type f -name '_tmux*' 2>/dev/null | wc -l)

	# FZF theme setup
	setup_fzf_theme "Speed" "Toplam: $total | SSH: $ssh_count | TMUX: $tmux_count | ESC ile çık, ENTER ile çalıştır"

	# Additional settings for speed mode
	export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
        --delimiter=_ \
        --with-nth=2.."

	# Get frequently used commands
	get_frequent() {
		if [ -f "$CACHE_FILE" ] && [ -s "$CACHE_FILE" ]; then
			cat "$CACHE_FILE" |
				sort |
				uniq -c |
				sort -nr |
				head -n 10 |
				awk '{print $2}' |
				sed 's/^/⭐ /'
		fi
	}

	# Main selection
	SELECTED="$(
		(
			# Frequently used commands
			get_frequent
			# All commands
			find "$FZF_DIR" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null |
				sort |
				grep '^_' |
				sed 's@\.@ @g'
		) |
			column -s ',' -t |
			fzf |
			sed 's/^⭐ //' |
			cut -d ' ' -f1
	)"

	# Check if selection was made
	[ -z "$SELECTED" ] && return 0

	# Record usage
	echo "${SELECTED}" >>"$CACHE_FILE"

	# Limit the cache file size
	if [ "$(wc -l <"$CACHE_FILE")" -gt "$HISTORY_LIMIT" ]; then
		tail -n "$HISTORY_LIMIT" "$CACHE_FILE" >"$CACHE_FILE.tmp" &&
			mv "$CACHE_FILE.tmp" "$CACHE_FILE"
	fi

	# Run the selected script
	script_path=$(find "$FZF_DIR" -name "${SELECTED},*" -o -name "${SELECTED}.*" | head -1)
	if [ -n "$script_path" ] && [ -f "$script_path" ]; then
		success "Running: $script_path"
		eval "$script_path"
	else
		error "Script not found: ${SELECTED}"
		return 1
	fi
}

#--------------------------------------
# PLUGIN MANAGEMENT
#--------------------------------------

# List of plugins with their repositories
declare -A DEFAULT_PLUGINS=(
	["tmux-window-name"]="ofirgall/tmux-window-name"
	["tmux-sensible"]="tmux-plugins/tmux-sensible"
	["tmux-open"]="tmux-plugins/tmux-open"
	["tmux-fzf-url"]="wfxr/tmux-fzf-url"
	["tmux-prefix-highlight"]="tmux-plugins/tmux-prefix-highlight"
	["tmux-online-status"]="tmux-plugins/tmux-online-status"
	["tmux-fzf"]="sainnhe/tmux-fzf"
	["tmux-ssh-status"]="kenanpelit/tmux-ssh-status"
	["tmux-net-speed"]="kenanpelit/tmux-net-speed"
	["tmux-update-display"]="lljbash/tmux-update-display"
	["tmux-fuzzback"]="roosta/tmux-fuzzback"
	["tmux-nerd-font-window-name"]="joshmedeski/tmux-nerd-font-window-name"
	["tmux-kripto"]="vascomfnunes/tmux-kripto"
	["tmux-nav-master"]="TheSast/tmux-nav-master"
	["tmux-spotify-info"]="feqzz/tmux-spotify-info"
	["tmux-sessionx"]="omerxx/tmux-sessionx"
	["tmux-plugin-playerctl"]="richin13/tmux-plugin-playerctl"
	["tmux-resurrect"]="tmux-plugins/tmux-resurrect"
	["tmux-continuum"]="tmux-plugins/tmux-continuum"
	["tmux-sessionist"]="tmux-plugins/tmux-sessionist"
)

# Install a single plugin
install_plugin() {
	local plugin_name="$1"
	local plugin_repo="$2"
	local plugin_path="${PLUGIN_DIR}/${plugin_name}"

	if [ -d "$plugin_path" ]; then
		warn "Plugin $plugin_name already exists. Updating..."
		cd "$plugin_path" || return 1
		if git pull; then
			info "$plugin_name updated"
		else
			error "$plugin_name could not be updated"
			return 1
		fi
	else
		info "Installing plugin $plugin_name..."
		if git clone "https://github.com/$plugin_repo.git" "$plugin_path"; then
			success "$plugin_name installed successfully"
		else
			error "$plugin_name installation failed"
			return 1
		fi
	fi

	return 0
}

# List installed plugins
list_plugins() {
	if [ ! -d "$PLUGIN_DIR" ] || [ -z "$(ls -A "$PLUGIN_DIR" 2>/dev/null)" ]; then
		warn "No plugins installed"
		return 0
	fi

	info "Installed plugins:"
	for plugin in "$PLUGIN_DIR"/*; do
		if [ -d "$plugin" ]; then
			echo "  - $(basename "$plugin")"
		fi
	done
}

# Install all default plugins
install_all_plugins() {
	mkdir -p "$PLUGIN_DIR"

	# Install TPM first
	local tpm_path="${PLUGIN_DIR}/tpm"
	if [ ! -d "$tpm_path" ]; then
		info "Installing TPM..."
		if git clone https://github.com/tmux-plugins/tpm "$tpm_path"; then
			success "TPM installed successfully"
		else
			error "TPM installation failed"
			return 1
		fi
	else
		warn "TPM already installed"
	fi

	# Install or update all plugins
	local failed=0
	for plugin_name in "${!DEFAULT_PLUGINS[@]}"; do
		if ! install_plugin "$plugin_name" "${DEFAULT_PLUGINS[$plugin_name]}"; then
			error "Failed to install/update plugin: $plugin_name"
			failed=1
		fi
	done

	# Reload tmux config if running
	if is_in_tmux; then
		info "Reloading tmux configuration..."
		tmux source-file "$CONFIG_DIR/tmux.conf" 2>/dev/null &&
			success "Configuration reloaded" ||
			warn "Could not reload tmux config"
	fi

	if [ "$failed" -eq 0 ]; then
		success "All plugins installed/updated successfully"
		info "Start tmux and press prefix + I to initialize plugins"
	else
		warn "Some plugins could not be installed/updated"
	fi
}

#--------------------------------------
# BACKUP AND RESTORE
#--------------------------------------

# Backup tmux configuration
backup_config() {
	info "Starting backup process..."

	# Check if directories exist
	local oh_my_tmux_dir="$HOME/.config/oh-my-tmux"

	# Check for directories
	if [ ! -d "$CONFIG_DIR" ] || [ ! -d "$oh_my_tmux_dir" ]; then
		error "One or both directories to backup don't exist!"
		echo "Checked directories:"
		echo "- $CONFIG_DIR"
		echo "- $oh_my_tmux_dir"
		return 1
	fi

	# Create backup
	info "Creating backup archive..."
	if tar -czf "$BACKUP_FILE" -C "$HOME/.config" oh-my-tmux tmux; then
		success "Backup successful!"
		success "Backup file: $BACKUP_FILE"
	else
		error "Backup failed!"
		return 1
	fi
}

# Restore tmux configuration from backup
restore_config() {
	info "Starting restore process..."

	# Check for backup file
	if [ ! -f "$BACKUP_FILE" ]; then
		error "Backup file $BACKUP_FILE not found!"
		return 1
	fi

	local oh_my_tmux_dir="$HOME/.config/oh-my-tmux"

	# Backup existing configs
	if [ -d "$CONFIG_DIR" ]; then
		mv "$CONFIG_DIR" "${CONFIG_DIR}.old"
		info "Existing tmux config backed up: ${CONFIG_DIR}.old"
	fi

	if [ -d "$oh_my_tmux_dir" ]; then
		mv "$oh_my_tmux_dir" "${oh_my_tmux_dir}.old"
		info "Existing oh-my-tmux config backed up: ${oh_my_tmux_dir}.old"
	fi

	# Restore from backup
	info "Extracting backup..."
	if tar -xzf "$BACKUP_FILE" -C "$HOME/.config"; then
		success "Restore successful!"

		# Offer to clean up old backups
		read -p "Delete old backup directories? (y/n): " answer
		if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
			rm -rf "${CONFIG_DIR}.old" "${oh_my_tmux_dir}.old"
			success "Old backups cleaned up"
		fi
	else
		error "Restore failed!"

		# Recover old configs on error
		if [ -d "${CONFIG_DIR}.old" ]; then
			mv "${CONFIG_DIR}.old" "$CONFIG_DIR"
		fi

		if [ -d "${oh_my_tmux_dir}.old" ]; then
			mv "${oh_my_tmux_dir}.old" "$oh_my_tmux_dir"
		fi

		return 1
	fi
}

#--------------------------------------
# COMMAND-LINE INTERFACE
#--------------------------------------

# Show help for session management
show_session_help() {
	cat <<EOF
Tmux Session Management

Usage: $(basename "$0") session <command> [options]

Commands:
    create <n> [layout]   Create a new session or attach to existing
    list                     List all available sessions
    kill <n>              Terminate the specified session
    attach <n>            Attach to an existing session
    layout <n> <layout>   Apply a layout to the specified session
    term <type> <n>       Open session in a new terminal window
    kenp [name]              Start a KENP development session

Layout Options:
    1  Single panel
    2  Two panels (vertical split)
    3  Three panels (L-shaped)
    4  Four panels (2x2 grid)
    5  Five panels (3 top, 2 bottom)

Examples:
    $(basename "$0") session create myproject 3  # Create session with layout 3
    $(basename "$0") session list                # List all sessions
    $(basename "$0") session term kitty dev      # Open dev session in kitty
EOF
}

# Show help for buffer management
show_buffer_help() {
	cat <<EOF
Tmux Buffer Management

Usage: $(basename "$0") buffer [command]

Commands:
    list       List all tmux buffers
    show       Interactive buffer browser (default)

Note: This command needs to be run inside a tmux session.

Examples:
    $(basename "$0") buffer         # Open interactive buffer browser
    $(basename "$0") buffer list    # List all buffers
EOF
}

# Show help for clipboard management
show_clipboard_help() {
	cat <<EOF
Clipboard Management

Usage: $(basename "$0") clip [command]

Commands:
    show       Interactive clipboard browser (default)

Requirements:
    - cliphist (for clipboard history)
    - wl-clipboard (for Wayland clipboard)
    - chafa (optional, for image preview)

Examples:
    $(basename "$0") clip         # Open interactive clipboard browser
EOF
}

# Show help for plugin management
show_plugin_help() {
	cat <<EOF
Tmux Plugin Management

Usage: $(basename "$0") plugin <command> [options]

Commands:
    install [name] [repo]  Install a specific plugin
    list                   List installed plugins
    all                    Install all default plugins

Examples:
    $(basename "$0") plugin all                     # Install all plugins
    $(basename "$0") plugin list                    # List installed plugins
    $(basename "$0") plugin install fzf sainnhe/tmux-fzf  # Install specific plugin
EOF
}

# Show help for speed mode
show_speed_help() {
	cat <<EOF
Command Speedup Mode

Usage: $(basename "$0") speed [command]

Commands:
    show       Interactive command browser (default)

Notes:
    - Commands should be placed in $FZF_DIR
    - Filenames should start with underscore (_)
    - Most frequently used commands will appear with a star

Examples:
    $(basename "$0") speed        # Open interactive command browser
EOF
}

# Show help for backup/restore
show_backup_help() {
	cat <<EOF
Tmux Configuration Backup/Restore

Usage: $(basename "$0") config <command>

Commands:
    backup     Backup tmux configuration
    restore    Restore tmux configuration from backup

Backup file: $BACKUP_FILE

Examples:
    $(basename "$0") config backup   # Backup configuration
    $(basename "$0") config restore  # Restore from backup
EOF
}

# KENP için yardım bilgisi
show_kenp_help() {
	cat <<EOF
KENP - Tmux Geliştirme Ortamı Oturumu

Kullanım: $(basename "$0") kenp [oturum_adı]

Açıklama:
    KENP geliştirme ortamı için özel yapılandırılmış bir tmux oturumu başlatır.
    Bu komut, otomatik olarak 3-panelli bir düzen oluşturur ve oturuma bağlanır.
    
    Eğer belirtilen oturum zaten varsa:
     - Bağlıysa: Yeni bir shell başlatır
     - Bağlı değilse: Oturuma bağlanır
     
    Eğer oturum yoksa:
     - Yeni bir oturum oluşturur
     - 3-panelli düzen uygular
     - Oturuma bağlanır

Seçenekler:
    [oturum_adı]   Kullanılacak oturum adı (varsayılan: KENP)

Örnekler:
    $(basename "$0") kenp             # KENP adlı oturum başlat/bağlan
    $(basename "$0") kenp projemiz    # "projemiz" adlı oturum başlat/bağlan
EOF
}

# tmx için yardım bilgisi (eski tm komutu için)
show_tmx_help() {
	cat <<EOF
TmxUtil - Genişletilmiş Tmux Komut Yöneticisi

Kullanım: $(basename "$0") tmx [seçenekler] [oturum_adı]

Oturum Yönetimi:
    -l, --list          Mevcut oturumları listele
    -k, --kill <ad>     Belirtilen oturumu sonlandır
    -n, --new <ad>      Yeni bir oturum oluştur
    -a, --attach <ad>   Mevcut bir oturuma bağlan
    -d, --detach        Oturumdan ayrıl

Terminal Seçenekleri:
    -t, --terminal <tür> <ad> [düzen]   
                        Oturumu yeni bir terminal penceresinde aç
                        Örnek: -t kitty oturumum 3

Düzen Seçenekleri:
    --layout <1-5>      Mevcut oturumda belirtilen düzeni oluştur
                          1: Tek panel
                          2: İki panel (yatay bölünmüş)
                          3: Üç panel (L-şeklinde)
                          4: Dört panel (2x2 ızgara)
                          5: Beş panel

Diğer:
    -h, --help          Bu yardım mesajını göster

Notlar:
    - Parametre verilmezse, mevcut dizin adıyla bir oturum oluşturulur
    - Git reposundayken, repo adı oturum adı olarak kullanılır
    - Kitty ve WezTerm terminal desteği
    - Oturum adları sadece harf, rakam, tire ve alt çizgi içerebilir
EOF
}

# Main help message
show_help() {
	cat <<EOF
tm.sh v${VERSION} - Birleşik Tmux Yönetim Aracı

Kullanım: $(basename "$0") <modül> [komut] [seçenekler]

Modüller:
    session    Oturum ve düzen yönetimi
    buffer     Buffer yönetimi ve navigasyon
    clip       Pano geçmişi ve yönetimi
    plugin     Eklenti kurulumu ve yönetimi
    speed      Komut hızlandırma ve favoriler
    config     Yapılandırma yedekleme ve geri yükleme
    kenp       KENP geliştirme ortamı oturumu başlat
    tmx        Genişletilmiş tmux komut yönetimi
    help       Bu yardımı veya modül-spesifik yardımı göster

Ortak Komutlar:
    $(basename "$0") session create projemiz 3   # 3 nolu düzen ile oturum oluştur
    $(basename "$0") buffer                      # Tmux buffer'larını tara
    $(basename "$0") clip                        # Pano geçmişini tara
    $(basename "$0") plugin all                  # Tüm eklentileri kur
    $(basename "$0") speed                       # Komut hızlandırmaya eriş
    $(basename "$0") config backup               # Tmux yapılandırmasını yedekle
    $(basename "$0")                             # KENP oturumunu başlat (varsayılan)

Modül-spesifik yardım için '$(basename "$0") help <modül>' kullanın.
EOF
}

# Process help commands
process_help_commands() {
	local module="${1:-}"

	case "$module" in
	"session")
		show_session_help
		;;
	"buffer")
		show_buffer_help
		;;
	"clip")
		show_clipboard_help
		;;
	"plugin")
		show_plugin_help
		;;
	"speed")
		show_speed_help
		;;
	"config")
		show_backup_help
		;;
	"kenp")
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

# Process session commands
process_session_commands() {
	local command="${1:-}"
	shift 2>/dev/null || true

	case "$command" in
	"create")
		local session_name="${1:-$(get_session_name)}"
		local layout="${2:-}"
		create_session "$session_name" "$layout"
		;;
	"list")
		list_sessions
		;;
	"kill")
		if [ -z "${1:-}" ]; then
			error "Session name not specified"
			return 1
		fi
		kill_session "$1"
		;;
	"attach")
		if [ -z "${1:-}" ]; then
			error "Session name not specified"
			return 1
		fi
		if has_session_exact "$1"; then
			attach_or_switch "$1"
		else
			error "Session '$1' not found"
			return 1
		fi
		;;
	"layout")
		if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
			error "Session name and layout number required"
			return 1
		fi
		create_layout "$1" "$2"
		;;
	"term")
		if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
			error "Terminal type and session name required"
			return 1
		fi
		local layout="${3:-1}"
		open_session_in_terminal "$1" "$2" "$layout"
		;;
	"kenp")
		local session_name="${1:-KENP}"
		kenp_session_mode "$session_name"
		;;
	*)
		error "Unknown session command: $command"
		show_session_help
		return 1
		;;
	esac
}

# Process buffer commands
process_buffer_commands() {
	local command="${1:-show}"
	shift 2>/dev/null || true

	case "$command" in
	"list")
		if ! check_requirements "buffer"; then
			return 1
		fi
		tmux list-buffers
		;;
	"show" | "")
		handle_buffer_mode
		;;
	*)
		error "Unknown buffer command: $command"
		show_buffer_help
		return 1
		;;
	esac
}

# Process clipboard commands
process_clipboard_commands() {
	local command="${1:-show}"
	shift 2>/dev/null || true

	case "$command" in
	"show" | "")
		handle_clipboard_mode
		;;
	*)
		error "Unknown clipboard command: $command"
		show_clipboard_help
		return 1
		;;
	esac
}

# Process plugin commands
process_plugin_commands() {
	local command="${1:-}"
	shift 2>/dev/null || true

	case "$command" in
	"install")
		if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
			error "Plugin name and repository required"
			show_plugin_help
			return 1
		fi
		install_plugin "$1" "$2"
		;;
	"list")
		list_plugins
		;;
	"all")
		install_all_plugins
		;;
	*)
		error "Unknown plugin command: $command"
		show_plugin_help
		return 1
		;;
	esac
}

# Process speed commands
process_speed_commands() {
	local command="${1:-show}"
	shift 2>/dev/null || true

	case "$command" in
	"show" | "")
		handle_speed_mode
		;;
	*)
		error "Unknown speed command: $command"
		show_speed_help
		return 1
		;;
	esac
}

# Process config commands
process_config_commands() {
	local command="${1:-}"
	shift 2>/dev/null || true

	case "$command" in
	"backup")
		backup_config
		;;
	"restore")
		restore_config
		;;
	*)
		error "Unknown config command: $command"
		show_backup_help
		return 1
		;;
	esac
}

# Process tmx commands (eski tm komutları)
process_tmx_commands() {
	local command="${1:-}"
	shift 2>/dev/null || true

	case "$command" in
	"-h" | "--help")
		show_tmx_help
		;;
	"-l" | "--list")
		list_sessions
		;;
	"-k" | "--kill")
		if [ -z "${1:-}" ]; then
			error "Oturum adı belirtilmedi"
			return 1
		fi
		kill_session "$1"
		;;
	"-n" | "--new")
		if [ -z "${1:-}" ]; then
			error "Oturum adı belirtilmedi"
			return 1
		fi
		create_session "$1"
		;;
	"-t" | "--terminal")
		if [ -z "${1:-}" ] || [ -z "${2:-}" ]; then
			error "Terminal türü ve oturum adı belirtilmelidir"
			return 1
		fi
		local layout="${3:-1}"
		open_session_in_terminal "$1" "$2" "$layout"
		;;
	"-d" | "--detach")
		tmux detach-client
		;;
	"-a" | "--attach")
		if [ -z "${1:-}" ]; then
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
	"--layout")
		if [ -z "${1:-}" ]; then
			error "Düzen numarası belirtilmelidir"
			return 1
		fi

		local layout_num="$1"

		# Tmux oturumu içinde miyiz kontrol et
		if ! is_in_tmux; then
			error "Tmux oturumunda değilsiniz. Lütfen tmux içinde çalıştırın."
			return 1
		fi

		create_layout "$(tmux display-message -p '#S')" "$layout_num"
		;;
	*)
		local session_name="${command:-$(get_session_name)}"
		create_session "$session_name"
		;;
	esac
}

# Ana fonksiyon - komut satırı parametrelerini işle
main() {
	local module="${1:-}"
	shift 2>/dev/null || true

	# Hiçbir parametre verilmezse doğrudan kenp_session_mode çalıştır ve çık
	if [ -z "$module" ]; then
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
		# Doğrudan KENPSession gibi çalışan komut
		kenp_session_mode "$@"
		;;
	"tmx")
		# Eski tm komutu gibi çalışan komut
		process_tmx_commands "$@"
		;;
	*)
		# Default behavior - assume it's a session name
		create_session "$module"
		;;
	esac
}

# Run the main function with all arguments
main "$@"
