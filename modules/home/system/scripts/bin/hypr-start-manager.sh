#!/usr/bin/env bash

#===============================================================================
#
#   Version: 1.2.0
#   Date: 2025-03-28
#   Author: Kenan Pelit
#   Description: HyprFlow Start Manager - Streamlined Version
#
#   License: MIT
#
#===============================================================================

VERSION="1.2.0"
SCRIPT_NAME=$(basename "$0")
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprflow"
CONFIG_FILE="$CONFIG_DIR/config"
LOG_FILE="$CONFIG_DIR/hyprflow.log"

# Create config directory if not exists
mkdir -p "$CONFIG_DIR"

# Default language (en/tr)
LANGUAGE="tr"

# Load config if exists
if [ -f "$CONFIG_FILE" ]; then
	source "$CONFIG_FILE"
fi

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Messages in multiple languages
declare -A MESSAGES=(
	[success_en]="Success"
	[success_tr]="Başarılı"
	[error_en]="Error"
	[error_tr]="Hata"
	[not_found_en]="application not found."
	[not_found_tr]="uygulaması bulunamadı."
	[starting_en]="Starting..."
	[starting_tr]="Başlatılıyor..."
	[already_running_en]="is already running."
	[already_running_tr]="zaten çalışıyor."
	[focusing_en]="Focusing on existing window."
	[focusing_tr]="Mevcut pencereye odaklanıldı."
)

# Terminal emulator configurations
declare -A TERMINAL_CONFIGS=(
	[kitty]="--class {class} --title {title}"
	[wezterm]="start --class {class}"
)

# App specific configurations
declare -A APP_CONFIGS=(
	[default_terminal]="kitty"
	[yazi_terminal]="kitty"
	[anote_terminal]="kitty"
	[default_timeout]=5
)

# Logging function
log_message() {
	local level="$1"
	local message="$2"
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >>"$LOG_FILE"
}

# Get localized message
get_message() {
	local key="$1_$LANGUAGE"
	echo "${MESSAGES[$key]}"
}

# Error exit function
exit_with_error() {
	local error_msg="$1"
	local error_title=$(get_message "error")

	notify-send -u critical -t 5000 "$error_title" "$error_msg"
	echo -e "${RED}$error_title: $error_msg${NC}"
	log_message "ERROR" "$error_msg"
	exit 1
}

# Success message function
show_success() {
	local success_msg="$1"
	local success_title=$(get_message "success")

	echo -e "${GREEN}$success_msg${NC}"
	notify-send -t 2000 "$success_title" "$success_msg"
	log_message "INFO" "$success_msg"
}

# Application check function
check_application() {
	local app="$1"
	if ! command -v "$app" &>/dev/null; then
		local not_found=$(get_message "not_found")
		exit_with_error "$app $not_found"
	fi
}

# Hyprland window check function
check_window() {
	local target_class="$1"
	local window_info

	window_info=$(hyprctl -j clients | jq -r ".[] | select(.class == \"$target_class\")")

	if [[ -n "$window_info" ]]; then
		hyprctl dispatch focuswindow "class:$target_class"
		local app_name="${2:-$target_class}"
		local focusing=$(get_message "focusing")
		notify-send "$app_name" "$focusing"
		log_message "INFO" "Focused on existing $app_name window"
		return 0
	fi
	return 1
}

# Process check function
check_process() {
	if pgrep -x "$1" >/dev/null; then
		return 0
	fi
	return 1
}

# Generic start application function with timeout
start_application() {
	local app_name="$1"
	local app_command="$2"
	local app_class="${3:-$app_name}"
	local timeout="${4:-${APP_CONFIGS[default_timeout]}}"

	if check_window "$app_class" "$app_name"; then
		return 0
	fi

	check_application "${app_command%% *}"

	local starting=$(get_message "starting")
	notify-send -t 1000 "$app_name" "$starting"
	log_message "INFO" "Starting $app_name"

	# Run the command in background with timeout
	(
		eval "$app_command" >>/dev/null 2>&1 &
		app_pid=$!
		disown

		# Monitor process for timeout seconds
		sleep "$timeout"
		if kill -0 $app_pid 2>/dev/null; then
			log_message "INFO" "$app_name started successfully (PID: $app_pid)"
		else
			log_message "WARNING" "$app_name might have failed to start"
		fi
	) &
}

# Terminal applications start functions
start_kitty() {
	start_application "Kitty Terminal" "kitty" "kitty"
}

start_wezterm() {
	start_application "Wezterm" "wezterm start" "org.wezfurlong.wezterm"
}

# Start terminal-based application with specific terminal
start_terminal_app() {
	local app="$1"
	local terminal="${2:-${APP_CONFIGS[default_terminal]}}"
	local app_class="${3:-$app}"
	local app_title="${4:-$app}"
	local app_args="${5:-}"

	if ! command -v "$terminal" &>/dev/null; then
		exit_with_error "$terminal terminal not found."
	fi

	if ! command -v "$app" &>/dev/null; then
		exit_with_error "$app application not found."
	fi

	local terminal_config="${TERMINAL_CONFIGS[$terminal]}"
	terminal_config="${terminal_config//\{class\}/$app_class}"
	terminal_config="${terminal_config//\{title\}/$app_title}"

	local command="$terminal $terminal_config -e $app $app_args"
	start_application "$app" "$command" "$app_class"
}

start_yazi() {
	local terminal="${1:-${APP_CONFIGS[yazi_terminal]}}"
	local TMP_FILE
	TMP_FILE="$(mktemp -t yazi-cwd.XXXXX)"

	check_application "yazi"

	if ! command -v "$terminal" &>/dev/null; then
		exit_with_error "$terminal terminal not found."
	fi

	if ! command -v zoxide &>/dev/null; then
		exit_with_error "Zoxide not found. Please install it."
	fi

	local starting=$(get_message "starting")
	notify-send -t 1000 "Yazi" "$starting with $terminal"
	log_message "INFO" "Starting Yazi with $terminal"

	# Cleanup function for temporary file
	cleanup() {
		rm -f "$TMP_FILE"
	}
	trap cleanup EXIT

	# Get zoxide initialization
	ZOXIDE_INIT="$(zoxide init zsh)"

	case "$terminal" in
	kitty)
		kitty --class yazi --title "yazi" -e zsh -c "
          export EDITOR=\"nvim\";
          $ZOXIDE_INIT;
          yazi --cwd-file=\"$TMP_FILE\";
          cwd=\$(cat \"$TMP_FILE\");
          if [ -n \"\$cwd\" ] && [ \"\$cwd\" != \"\$PWD\" ]; then
            z \"\$cwd\";
          fi;
          zsh" >>/dev/null 2>&1 &
		;;
	wezterm)
		wezterm start --class yazi -e zsh -c "
          export EDITOR=\"nvim\";
          $ZOXIDE_INIT;
          yazi --cwd-file=\"$TMP_FILE\";
          cwd=\$(cat \"$TMP_FILE\");
          if [ -n \"\$cwd\" ] && [ \"\$cwd\" != \"\$PWD\" ]; then
            z \"\$cwd\";
          fi;
          zsh" >>/dev/null 2>&1 &
		;;
	*)
		exit_with_error "Unsupported terminal: $terminal"
		;;
	esac
	disown
	log_message "INFO" "Started Yazi with $terminal"
}

# Enhanced anote function with proper window management
start_anote() {
	if hyprctl clients -j | jq -e '.[] | select(.class == "anote")' >/dev/null; then
		window_address=$(hyprctl clients -j | jq -r '
            [.[] | select(.class == "anote")] | 
            sort_by(.focusHistoryID) | 
            last | 
            .address
        ')
		current_workspace=$(hyprctl activewindow -j | jq -r '.workspace.id')
		hyprctl dispatch movetoworkspace "$current_workspace,address:$window_address"
		hyprctl dispatch focuswindow "address:$window_address"
		focusing=$(get_message "focusing")
		notify-send -t 1000 "Anote" "$focusing"
		log_message "INFO" "Focused on existing Anote window"
	else
		# Get configured terminal or use default
		terminal="${APP_CONFIGS[anote_terminal]:-${APP_CONFIGS[default_terminal]}}"
		check_application "anote"

		starting=$(get_message "starting")
		notify-send -t 1000 "Anote" "$starting with $terminal"

		case "$terminal" in
		wezterm)
			wezterm start --class anote -e anote $APP_ARGS >>/dev/null 2>&1 &
			;;
		kitty | *)
			kitty --class anote --title anote -e anote $APP_ARGS >>/dev/null 2>&1 &
			;;
		esac
		disown
		log_message "INFO" "Started Anote with $terminal and args: $APP_ARGS"
	fi
}

# Generic GUI application starter function
start_gui_app() {
	local app_name="$1"
	local command="$2"
	local app_class="${3:-$app_name}"

	if check_window "$app_class" "$app_name"; then
		return 0
	fi

	check_application "${command%% *}"

	local starting=$(get_message "starting")
	notify-send -t 1000 "$app_name" "$starting"
	log_message "INFO" "Starting $app_name"

	GDK_BACKEND=wayland $command >>/dev/null 2>&1 &
	disown
}

start_clock() {
	notify-send -t 1000 "Clock..." "Başlatılıyor..."
	GDK_BACKEND=wayland kitty --class clock --title clock tty-clock -c -C7 >>/dev/null 2>&1 &
	disown
}

start_discord() {
	start_gui_app "Discord" "discord -m" "discord"
}

start_gsconnect() {
	if gapplication launch org.gnome.Shell.Extensions.GSConnect >>/dev/null 2>&1; then
		notify-send -t 1000 "GSConnect Başlatıldı" "GSConnect uygulaması başarıyla başlatıldı."
	else
		exit_with_error "GSConnect başlatılamadı."
	fi
}

start_keepassxc() {
	start_gui_app "KeePassXC" "keepassxc" "org.keepassxc.KeePassXC"
}

start_enteauth() {
	if check_process "enteauth"; then
		notify-send -u normal -t 1000 "EnteAuth Zaten Çalışıyor" "EnteAuth uygulaması zaten çalışıyor."
		return
	fi
	notify-send -t 1000 "EnteAuth Başlatılıyor..." "EnteAuth uygulaması başlatılıyor."
	GDK_BACKEND=wayland enteauth $APP_ARGS >>/dev/null 2>&1 &
	disown
}

start_mpv() {
	if check_process "mpv"; then
		echo -e "${CYAN}MPV zaten çalışıyor.${NC} Pencere aktif hale getiriliyor."
		notify-send -i mpv -t 1000 "MPV Zaten Çalışıyor" "MPV aktif durumda, pencere öne getiriliyor."
		hyprctl dispatch focuswindow "class:mpv"
	else
		mpv --player-operation-mode=pseudo-gui --input-ipc-server=/tmp/mpvsocket -- >>/dev/null 2>&1 &
		disown
		notify-send -i mpv -t 1000 "MPV Başlatılıyor" "MPV oynatıcı başlatıldı ve hazır."
	fi
}

start_rmpc() {
	# MPD durumunu kontrol et
	if ! pgrep -x mpd >/dev/null; then
		systemctl --user start mpd
		sleep 1
	fi

	# Hyprctl ile mevcut pencereyi kontrol et
	if ! hyprctl clients | grep -q "class: rmpc"; then
		notify-send -t 1000 "RMPC" "RMPC başlatılıyor..."
		kitty \
			--class="rmpc" \
			--title="rmpc" \
			--override "initial_window_width=1000" \
			--override "initial_window_height=600" \
			--override "background_opacity=0.95" \
			--override "window_padding_width=15" \
			--override "hide_window_decorations=yes" \
			--override "font_size=13" \
			--override "confirm_os_window_close=0" \
			--config "$HOME/.config/kitty/kitty.conf" \
			-e rmpc $APP_ARGS >>/dev/null 2>&1 &
		disown
	else
		hyprctl dispatch focuswindow "^(rmpc)$"
		notify-send -t 1000 "RMPC" "Mevcut pencereye odaklanıldı."
	fi
}

start_nemo() {
	# start_nemo da çağırılırken parametreleri geçirelim
	check_application "nemo"
	starting=$(get_message "starting")
	notify-send -t 1000 "Nemo" "$starting"
	log_message "INFO" "Starting Nemo with args: $APP_ARGS"
	GDK_BACKEND=wayland nemo $APP_ARGS >>/dev/null 2>&1 &
	disown
}

start_pavucontrol() {
	start_gui_app "Pavucontrol" "pavucontrol" "pavucontrol"
}

start_spotify() {
	start_gui_app "Spotify" "spotify" "spotify"
}

start_tcopyb() {
	notify-send -t 1000 "Copy Manager" "Copy Manager (b) başlatılıyor..."
	kitty --class clipb --title clipb tmux-copy -b >>/dev/null 2>&1 &
	disown
}

start_tcopyc() {
	notify-send -t 1000 "Copy Manager" "Copy Manager (c) başlatılıyor..."
	kitty --class clipb --title clipb tmux-copy -c >>/dev/null 2>&1 &
	disown
}

start_todo() {
	check_application "vim"
	GDK_BACKEND=wayland kitty --title todo --hold -e vim ~/.todo >>/dev/null 2>&1 &
	disown
	notify-send -t 1000 "Todo" "Todo uygulaması başlatılıyor..."
}

start_ulauncher() {
	start_gui_app "Ulauncher" "ulauncher-toggle" "ulauncher"
}

start_webcord() {
	start_gui_app "WebCord" "webcord -m" "webcord"
}

start_whatsapp() {
	start_gui_app "WhatsApp" "zapzap" "zapzap"
}

start_netflix() {
	start_gui_app "Netflix" "netflix" "netflix"
}

# Function to create default config file
create_default_config() {
	cat >"$CONFIG_FILE" <<EOF
# HyprFlow configuration file

# Language setting (en/tr)
LANGUAGE="$LANGUAGE"

# Default terminal for applications
APP_CONFIGS[default_terminal]="kitty"
APP_CONFIGS[yazi_terminal]="kitty"
APP_CONFIGS[anote_terminal]="kitty"

# Default timeout for application startup (seconds)
APP_CONFIGS[default_timeout]=5

# Enable/disable logging (true/false)
ENABLE_LOGGING=true
EOF

	log_message "INFO" "Created default configuration file at $CONFIG_FILE"
	echo -e "${GREEN}Created default configuration file at $CONFIG_FILE${NC}"
}

# Help message function
show_help() {
	echo -e "${CYAN}HyprFlow Start Manager v$VERSION${NC}"
	echo "Usage: $SCRIPT_NAME [OPTION]"
	echo ""
	echo -e "${YELLOW}Terminal Emulators:${NC}"
	echo "  kitty       - Start Kitty terminal"
	echo "  wezterm     - Start Wezterm terminal"
	echo ""
	echo -e "${YELLOW}File Managers:${NC}"
	echo "  yazi        - Start Yazi file manager (with default terminal)"
	echo "  yazi-kitty  - Start Yazi with Kitty"
	echo "  yazi-wez    - Start Yazi with Wezterm"
	echo ""
	echo -e "${YELLOW}Temel Uygulamalar:${NC}"
	echo "  anote       - Start Anote"
	echo "  clock       - Start Terminal clock"
	echo "  tcopyb      - Start Copy Manager (-b)"
	echo "  tcopyc      - Start Copy Manager (-c)"
	echo "  todo        - Start Todo application"
	echo ""
	echo -e "${YELLOW}Internet Uygulamaları:${NC}"
	echo "  discord     - Start Discord"
	echo "  webcord     - Start WebCord"
	echo "  whatsapp    - Start WhatsApp (ZapZap)"
	echo "  netflix     - Start Netflix"
	echo ""
	echo -e "${YELLOW}Sistem Uygulamaları:${NC}"
	echo "  gsconnect   - Start GSConnect"
	echo "  keepassxc   - Start KeePassXC"
	echo "  enteauth    - Start EnteAuth"
	echo "  pavucontrol - Start Sound control panel"
	echo "  nemo        - Start Nemo file manager"
	echo "  ulauncher   - Start Ulauncher"
	echo ""
	echo -e "${YELLOW}Medya Uygulamaları:${NC}"
	echo "  mpv         - Start MPV media player"
	echo "  rmpc        - Start RMPC music player"
	echo "  spotify     - Start Spotify"
	echo ""
	echo -e "${YELLOW}Genel Seçenekler:${NC}"
	echo "  all         - Start all applications"
	echo "  --help, -h  - Show this help message"
	echo "  --menu, -m  - Run in menu mode"
	echo "  --config    - Create/edit configuration file"
	echo "  --log       - View log file"
	echo ""
}

# Main menu
show_menu() {
	echo -e "${CYAN}HyprFlow Start Manager v$VERSION${NC}"
	echo "================================"
	echo -e "${YELLOW}Terminal Emülatörler:${NC}"
	echo "1) Kitty"
	echo "2) Wezterm"
	echo ""
	echo -e "${YELLOW}Dosya Yöneticileri:${NC}"
	echo "3) Yazi (Kitty)"
	echo "4) Yazi (Wezterm)"
	echo ""
	echo -e "${YELLOW}Temel Uygulamalar:${NC}"
	echo "5) Anote"
	echo "6) Clock"
	echo "7) Copy Manager (-b)"
	echo "8) Copy Manager (-c)"
	echo "9) Todo"
	echo ""
	echo -e "${YELLOW}Internet Uygulamaları:${NC}"
	echo "10) Discord"
	echo "11) WebCord"
	echo "12) WhatsApp"
	echo "13) Netflix"
	echo ""
	echo -e "${YELLOW}Sistem Uygulamaları:${NC}"
	echo "14) GSConnect"
	echo "15) KeePassXC"
	echo "16) EnteAuth"
	echo "17) Pavucontrol"
	echo "18) Nemo"
	echo "19) Ulauncher"
	echo ""
	echo -e "${YELLOW}Medya Uygulamaları:${NC}"
	echo "20) MPV"
	echo "21) RMPC"
	echo "22) Spotify"
	echo ""
	echo -e "${YELLOW}Genel Seçenekler:${NC}"
	echo "23) Tüm uygulamaları başlat"
	echo "0) Çıkış"
	echo "================================"
	echo -n "Seçiminiz (0-23): "
}

# Menu mode
menu_mode() {
	while true; do
		clear
		show_menu
		read -r choice

		case $choice in
		0)
			echo "Çıkış yapılıyor..."
			break
			;;
		# Terminal emulators
		1) start_kitty ;;
		2) start_wezterm ;;
		# File managers
		3) start_yazi "kitty" ;;
		4) start_yazi "wezterm" ;;
		# Basic applications
		5) start_anote ;;
		6) start_clock ;;
		7) start_tcopyb ;;
		8) start_tcopyc ;;
		9) start_todo ;;
		# Internet applications
		10) start_discord ;;
		11) start_webcord ;;
		12) start_whatsapp ;;
		13) start_netflix ;;
		# System applications
		14) start_gsconnect ;;
		15) start_keepassxc ;;
		16) start_enteauth ;;
		17) start_pavucontrol ;;
		18) start_nemo ;;
		19) start_ulauncher ;;
		# Media applications
		20) start_mpv ;;
		21) start_rmpc ;;
		22) start_spotify ;;
		# General options
		23) start_all ;;
		*)
			echo "Geçersiz seçim! Lütfen 0-23 arası bir sayı girin."
			sleep 2
			;;
		esac
	done
}

# Start all applications
start_all() {
	echo -e "${CYAN}Tüm uygulamalar başlatılıyor...${NC}"

	# Terminal emulators
	start_kitty
	start_wezterm

	# File managers
	start_yazi "kitty"

	# Basic applications
	start_anote
	start_clock
	start_tcopyb
	start_tcopyc
	start_todo

	# Internet applications
	start_discord
	start_webcord
	start_whatsapp
	start_netflix

	# System applications
	start_gsconnect
	start_keepassxc
	start_enteauth
	start_pavucontrol
	start_nemo
	start_ulauncher

	# Media applications
	start_mpv
	start_rmpc
	start_spotify

	show_success "Tüm uygulamalar başlatıldı!"
}

# Main program
if [ $# -eq 0 ]; then
	show_help
	exit 1
fi

# Get the command/application name
COMMAND="$1"
shift

# Pass remaining arguments to the application
APP_ARGS="$@"

case "$COMMAND" in
# Terminal emulators
"kitty") start_kitty ;;
"wezterm") start_wezterm ;;

# File managers
"yazi") start_yazi ;;
"yazi-kitty") start_yazi "kitty" ;;
"yazi-wez") start_yazi "wezterm" ;;

# Basic applications
"anote") start_anote ;;
"clock") start_clock ;;
"tcopyb") start_tcopyb ;;
"tcopyc") start_tcopyc ;;
"todo") start_todo ;;

# Internet applications
"discord") start_discord ;;
"webcord") start_webcord ;;
"whatsapp") start_whatsapp ;;
"netflix") start_netflix ;;

# System applications
"gsconnect") start_gsconnect ;;
"keepassxc") start_keepassxc ;;
"enteauth") start_enteauth ;;
"pavucontrol") start_pavucontrol ;;
"nemo") start_nemo ;;
"ulauncher") start_ulauncher ;;

# Media applications
"mpv") start_mpv ;;
"rmpc") start_rmpc ;;
"spotify") start_spotify ;;

# General options
"all") start_all ;;
"--help" | "-h") show_help ;;
"--menu" | "-m") menu_mode ;;
"--config")
	if [ ! -f "$CONFIG_FILE" ]; then
		create_default_config
	fi
	${EDITOR:-vim} "$CONFIG_FILE"
	;;
"--log")
	if [ -f "$LOG_FILE" ]; then
		${PAGER:-less} "$LOG_FILE"
	else
		echo -e "${YELLOW}Log file not found.${NC}"
	fi
	;;
*)
	echo "Invalid parameter: $COMMAND"
	show_help
	exit 1
	;;
esac

exit 0
