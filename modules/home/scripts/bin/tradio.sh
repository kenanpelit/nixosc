#!/usr/bin/env bash

# tradio - Terminal Based Radio Player
# Version: 1.2.0

set -o pipefail

SCRIPT_NAME="tradio"
SCRIPT_VERSION="1.2.0"

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# Radio stations
# Keep "Virgin Radio" first, then sort the rest alphabetically.
declare -A RADIOS=(
    ["Virgin Radio"]="http://playerservices.streamtheworld.com/api/livestream-redirect/VIRGIN_RADIO_SC"
    ["Joy FM"]="http://playerservices.streamtheworld.com/api/livestream-redirect/JOY_FM_SC"
    ["Joy Jazz"]="http://playerservices.streamtheworld.com/api/livestream-redirect/JOY_JAZZ_SC"
    ["Kral 45lik"]="https://ssldyg.radyotvonline.com/kralweb/smil:kral45lik.smil/chunklist_w1544647566_b64000.m3u8"
    ["Metro FM"]="http://playerservices.streamtheworld.com/api/livestream-redirect/METRO_FM_SC"
    ["NTV Radyo"]="http://ntvrdsc.radyotvonline.com/"
    ["Pal Akustik"]="http://shoutcast.radyogrup.com:2030/"
    ["Pal Dance"]="http://shoutcast.radyogrup.com:2040/"
    ["Pal Nostalji"]="http://shoutcast.radyogrup.com:1010/"
    ["Pal Orient"]="http://shoutcast.radyogrup.com:1050/"
    ["Pal Slow"]="http://shoutcast.radyogrup.com:2020/"
    ["Pal Station"]="http://shoutcast.radyogrup.com:1020/"
    ["Radyo 45lik"]="http://104.236.16.158:3060/"
    ["Radyo Dejavu"]="http://radyodejavu.canliyayinda.com:8054/"
    ["Radyo Voyage"]="http://voyagewmp.radyotvonline.com:80/"
    ["Retro Türk"]="http://playerservices.streamtheworld.com/api/livestream-redirect/RETROTURK_SC"
    ["World Hits"]="http://37.247.98.8/stream/34/.mp3"
)

# Runtime/config paths
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tradio"
CONFIG_FILE="$CONFIG_DIR/config"
HISTORY_FILE="$CONFIG_DIR/history"
FAVORITES_FILE="$CONFIG_DIR/favorites"

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/tradio-$UID"
PID_FILE="$RUNTIME_DIR/player.pid"
NOW_PLAYING_FILE="$RUNTIME_DIR/current_station"

# Defaults
VOLUME=100
PLAYER="cvlc"

# Dynamic station list
SORTED_STATIONS=()

print_info() {
    printf "%b\n" "${BLUE}$*${NC}"
}

print_success() {
    printf "%b\n" "${GREEN}$*${NC}"
}

print_warn() {
    printf "%b\n" "${YELLOW}$*${NC}"
}

print_error() {
    printf "%b\n" "${RED}$*${NC}" >&2
}

trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf '%s' "$value"
}

pause_for_key() {
    printf "%b" "${GREEN}Press any key to continue...${NC}"
    read -r -n 1 -s _
    printf "\n"
}

is_valid_volume() {
    local value="${1:-}"
    [[ "$value" =~ ^[0-9]+$ ]] && ((value >= 0 && value <= 100))
}

is_valid_station_number() {
    local value="${1:-}"
    [[ "$value" =~ ^[0-9]+$ ]] && ((value >= 1 && value <= ${#SORTED_STATIONS[@]}))
}

preferred_player() {
    if command -v cvlc >/dev/null 2>&1; then
        printf '%s\n' "cvlc"
    elif command -v mpv >/dev/null 2>&1; then
        printf '%s\n' "mpv"
    else
        printf '%s\n' ""
    fi
}

write_config() {
    local tmp_file
    tmp_file=$(mktemp "$CONFIG_FILE.tmp.XXXXXX")

    {
        printf 'volume=%s\n' "$VOLUME"
        printf 'player=%s\n' "$PLAYER"
    } >"$tmp_file"

    mv "$tmp_file" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
}

init_config() {
    mkdir -p "$CONFIG_DIR" "$RUNTIME_DIR"
    touch "$HISTORY_FILE" "$FAVORITES_FILE"
    chmod 600 "$HISTORY_FILE" "$FAVORITES_FILE"

    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            case "$key" in
            volume)
                if is_valid_volume "$value"; then
                    VOLUME="$value"
                fi
                ;;
            player)
                if [[ "$value" == "cvlc" || "$value" == "mpv" ]]; then
                    PLAYER="$value"
                fi
                ;;
            esac
        done <"$CONFIG_FILE"
    fi

    write_config
}

check_dependencies() {
    local has_cvlc=0
    local has_mpv=0

    command -v cvlc >/dev/null 2>&1 && has_cvlc=1
    command -v mpv >/dev/null 2>&1 && has_mpv=1

    if ((has_cvlc == 0 && has_mpv == 0)); then
        print_error "Missing dependency: install at least one player (cvlc or mpv)."
        exit 1
    fi

    if ! command -v "$PLAYER" >/dev/null 2>&1; then
        PLAYER="$(preferred_player)"
        print_warn "Configured player is not installed. Falling back to: $PLAYER"
        write_config
    fi
}

create_station_list() {
    local station
    local rest=()

    SORTED_STATIONS=("Virgin Radio")

    for station in "${!RADIOS[@]}"; do
        if [[ "$station" != "Virgin Radio" ]]; then
            rest+=("$station")
        fi
    done

    if ((${#rest[@]} > 0)); then
        mapfile -t rest < <(printf '%s\n' "${rest[@]}" | sort -f)
        SORTED_STATIONS+=("${rest[@]}")
    fi
}

add_to_history() {
    local name="$1"
    local ts
    local tmp_file

    ts=$(date '+%Y-%m-%d %H:%M:%S')
    printf '%s - %s\n' "$ts" "$name" >>"$HISTORY_FILE"

    # Keep history bounded so file does not grow forever.
    if [[ $(wc -l <"$HISTORY_FILE") -gt 1000 ]]; then
        tmp_file=$(mktemp "$HISTORY_FILE.tmp.XXXXXX")
        tail -n 1000 "$HISTORY_FILE" >"$tmp_file"
        mv "$tmp_file" "$HISTORY_FILE"
        chmod 600 "$HISTORY_FILE"
    fi
}

is_favorite() {
    local name="$1"
    grep -Fxq -- "$name" "$FAVORITES_FILE"
}

add_to_favorites() {
    local name="$1"

    if is_favorite "$name"; then
        print_warn "Already in favorites: $name"
        return 0
    fi

    printf '%s\n' "$name" >>"$FAVORITES_FILE"
    print_success "Added to favorites: $name"
}

remove_from_favorites() {
    local name="$1"
    local tmp_file

    if ! is_favorite "$name"; then
        print_warn "Not in favorites: $name"
        return 0
    fi

    tmp_file=$(mktemp "$FAVORITES_FILE.tmp.XXXXXX")
    grep -Fxv -- "$name" "$FAVORITES_FILE" >"$tmp_file" || true
    mv "$tmp_file" "$FAVORITES_FILE"
    chmod 600 "$FAVORITES_FILE"

    print_success "Removed from favorites: $name"
}

read_current_station() {
    if [[ -f "$NOW_PLAYING_FILE" ]]; then
        cat "$NOW_PLAYING_FILE"
    fi
}

is_radio_playing() {
    local pid

    if [[ ! -f "$PID_FILE" ]]; then
        return 1
    fi

    pid=$(<"$PID_FILE")
    if [[ "$pid" =~ ^[0-9]+$ ]] && ps -p "$pid" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

clear_runtime_state() {
    rm -f "$PID_FILE" "$NOW_PLAYING_FILE"
}

stop_radio() {
    local silent="${1:-false}"
    local pid

    if ! is_radio_playing; then
        clear_runtime_state
        if [[ "$silent" != "true" ]]; then
            print_warn "No active playback."
        fi
        return 0
    fi

    pid=$(<"$PID_FILE")
    if [[ "$silent" != "true" ]]; then
        print_warn "Stopping playback..."
    fi

    kill "$pid" >/dev/null 2>&1 || true
    sleep 0.2

    if ps -p "$pid" >/dev/null 2>&1; then
        kill -9 "$pid" >/dev/null 2>&1 || true
    fi

    clear_runtime_state

    if [[ "$silent" != "true" ]]; then
        print_success "Playback stopped."
    fi
}

set_system_volume() {
    local volume="$1"

    if command -v pactl >/dev/null 2>&1; then
        pactl set-sink-volume @DEFAULT_SINK@ "${volume}%" >/dev/null 2>&1 || true
    elif command -v amixer >/dev/null 2>&1; then
        amixer -q sset Master "${volume}%" >/dev/null 2>&1 || true
    fi
}

change_volume() {
    local new_vol="$1"

    if ! is_valid_volume "$new_vol"; then
        print_error "Invalid volume: $new_vol (expected 0-100)"
        return 1
    fi

    VOLUME="$new_vol"
    write_config
    set_system_volume "$VOLUME"
    print_success "Volume set to ${VOLUME}%"
}

send_notification() {
    local station="$1"

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -i "audio-x-generic" "Radio Player" "Now playing: $station" -t 2000 >/dev/null 2>&1 || true
    fi
}

start_player_process() {
    local url="$1"

    case "$PLAYER" in
    cvlc)
        cvlc --no-video --play-and-exit --quiet --intf dummy --volume="$VOLUME" "$url" >/dev/null 2>&1 &
        ;;
    mpv)
        mpv --no-video --quiet --volume="$VOLUME" "$url" >/dev/null 2>&1 &
        ;;
    *)
        return 1
        ;;
    esac

    printf '%s\n' "$!"
}

play_radio() {
    local url="$1"
    local name="$2"
    local toggle="${3:-false}"
    local current_station
    local pid

    if [[ -z "$url" || -z "$name" ]]; then
        print_error "Missing station name or URL."
        return 1
    fi

    if [[ "$toggle" == "true" ]]; then
        current_station="$(read_current_station)"
        if [[ -n "$current_station" && "$current_station" == "$name" ]] && is_radio_playing; then
            stop_radio
            return 0
        fi
    fi

    if is_radio_playing; then
        stop_radio "true"
    fi

    print_success "Starting: $name"
    add_to_history "$name"
    send_notification "$name"

    if ! pid="$(start_player_process "$url")"; then
        print_error "Failed to start player: $PLAYER"
        return 1
    fi

    sleep 1
    if ! ps -p "$pid" >/dev/null 2>&1; then
        clear_runtime_state
        print_error "Player exited immediately. Stream might be unavailable."
        return 1
    fi

    printf '%s\n' "$pid" >"$PID_FILE"
    printf '%s\n' "$name" >"$NOW_PLAYING_FILE"
    chmod 600 "$PID_FILE" "$NOW_PLAYING_FILE"

    return 0
}

play_station_by_number() {
    local number="$1"
    local toggle="${2:-false}"
    local station_name

    if ! is_valid_station_number "$number"; then
        print_error "Invalid station number: $number"
        print_info "Valid range: 1-${#SORTED_STATIONS[@]}"
        return 1
    fi

    station_name="${SORTED_STATIONS[$((number - 1))]}"
    play_radio "${RADIOS[$station_name]}" "$station_name" "$toggle"
}

play_random_station() {
    local random_idx
    local station_name

    random_idx=$((RANDOM % ${#SORTED_STATIONS[@]}))
    station_name="${SORTED_STATIONS[$random_idx]}"

    print_info "Random selection: $station_name"
    play_radio "${RADIOS[$station_name]}" "$station_name" "true"
}

search_radio() {
    local search_term="$1"
    local normalized
    local matches=()
    local station
    local i
    local choice

    normalized="${search_term,,}"

    for station in "${SORTED_STATIONS[@]}"; do
        if [[ "${station,,}" == *"$normalized"* ]]; then
            matches+=("$station")
        fi
    done

    if ((${#matches[@]} == 0)); then
        print_warn "No stations found for: $search_term"
        return 1
    fi

    print_success "Search results:"
    i=1
    for station in "${matches[@]}"; do
        printf "  %2d) %s\n" "$i" "$station"
        ((i++))
    done

    printf "Select station number (0 to cancel): "
    read -r choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]]; then
        print_error "Invalid input."
        return 1
    fi

    if ((choice == 0)); then
        return 0
    fi

    if ((choice < 1 || choice > ${#matches[@]})); then
        print_error "Selection out of range."
        return 1
    fi

    station="${matches[$((choice - 1))]}"
    play_radio "${RADIOS[$station]}" "$station" "false"
}

toggle_current_station_favorite() {
    local current_station

    current_station="$(read_current_station)"
    if [[ -z "$current_station" ]]; then
        print_warn "No active station to favorite."
        return 1
    fi

    if is_favorite "$current_station"; then
        remove_from_favorites "$current_station"
    else
        add_to_favorites "$current_station"
    fi
}

show_favorites_menu() {
    local favorites=()
    local favorite
    local i
    local action
    local idx

    while true; do
        clear
        printf "%b\n" "${BOLD}Favorites${NC}"
        printf '%s\n' "----------------------------------------"

        while IFS= read -r favorite; do
            [[ -n "$favorite" ]] && favorites+=("$favorite")
        done <"$FAVORITES_FILE"

        if ((${#favorites[@]} == 0)); then
            print_warn "Favorites list is empty."
            pause_for_key
            return
        fi

        i=1
        for favorite in "${favorites[@]}"; do
            printf "  %2d) %s\n" "$i" "$favorite"
            ((i++))
        done

        printf '\n'
        printf "Choose: number=play, d<number>=delete, q=back\n"
        printf "> "
        read -r action
        action="$(trim "$action")"

        case "$action" in
        q | Q | "")
            return
            ;;
        d[0-9]*)
            idx="${action#d}"
            if ((idx >= 1 && idx <= ${#favorites[@]})); then
                remove_from_favorites "${favorites[$((idx - 1))]}"
                sleep 1
            else
                print_error "Invalid favorites index: $idx"
                sleep 1
            fi
            ;;
        [0-9]*)
            if ((action >= 1 && action <= ${#favorites[@]})); then
                play_radio "${RADIOS[${favorites[$((action - 1))]}]}" "${favorites[$((action - 1))]}" "true"
                pause_for_key
            else
                print_error "Invalid favorites index: $action"
                sleep 1
            fi
            ;;
        *)
            print_error "Invalid favorites action."
            sleep 1
            ;;
        esac

        favorites=()
    done
}

show_history() {
    clear
    printf "%b\n" "${BOLD}Recently Played${NC}"
    printf '%s\n' "----------------------------------------"

    if [[ ! -s "$HISTORY_FILE" ]]; then
        print_warn "History is empty."
        pause_for_key
        return
    fi

    tail -n 15 "$HISTORY_FILE"
    printf '\n'
    pause_for_key
}

switch_player() {
    local requested="${1:-toggle}"

    case "$requested" in
    toggle)
        if [[ "$PLAYER" == "cvlc" ]]; then
            requested="mpv"
        else
            requested="cvlc"
        fi
        ;;
    cvlc | mpv)
        ;;
    *)
        print_error "Invalid player value: $requested (use: cvlc, mpv, toggle)"
        return 1
        ;;
    esac

    if ! command -v "$requested" >/dev/null 2>&1; then
        print_error "Player is not installed: $requested"
        return 1
    fi

    PLAYER="$requested"
    write_config
    print_success "Active player: $PLAYER"
}

show_menu() {
    local current_station=""
    local max_length=0
    local station
    local name_length
    local number=1
    local marker
    local padding
    local columns=2
    local col=1
    local term_width=80

    clear

    printf "%b\n" "${BOLD}Terminal Radio Player v${SCRIPT_VERSION}${NC}"
    printf '%s\n' "----------------------------------------"
    printf "%b\n" "${YELLOW}Volume:${NC} ${VOLUME}%"
    printf "%b\n" "${YELLOW}Player:${NC} $PLAYER"

    if is_radio_playing; then
        current_station="$(read_current_station)"
        printf "%b\n" "${GREEN}Now Playing:${NC} ${current_station:-Unknown}"
    else
        printf "%b\n" "${YELLOW}Now Playing:${NC} None"
    fi

    printf '%s\n' "----------------------------------------"
    printf "%b\n" "${BLUE}Stations${NC}"
    printf '%s\n' "----------------------------------------"

    for station in "${SORTED_STATIONS[@]}"; do
        name_length=${#station}
        if ((name_length > max_length)); then
            max_length=$name_length
        fi
    done

    if command -v tput >/dev/null 2>&1; then
        term_width=$(tput cols 2>/dev/null || echo 80)
    fi

    padding=$((max_length + 8))
    if ((padding <= 0)); then
        padding=30
    fi

    columns=$((term_width / padding))
    if ((columns < 1)); then
        columns=1
    elif ((columns > 3)); then
        columns=3
    fi

    for station in "${SORTED_STATIONS[@]}"; do
        marker=" "
        if is_favorite "$station"; then
            marker="*"
        fi

        printf "(%2d) %-*s [%s]" "$number" "$max_length" "$station" "$marker"

        if ((col == columns)); then
            printf "\n"
            col=1
        else
            printf "   "
            ((col++))
        fi

        ((number++))
    done

    if ((col != 1)); then
        printf "\n"
    fi

    printf '\n'
    printf "%b\n" "${BLUE}Commands${NC}"
    printf '%s\n' "  r) random   s) search   f) favorites"
    printf '%s\n' "  h) history  v) volume   p) switch player"
    printf '%s\n' "  a) toggle favorite for current station"
    printf '%s\n' "  q) quit"
    printf '> '
}

print_help() {
    cat <<HELP
Usage: $SCRIPT_NAME [OPTION] [NUMBER]

Options:
  -h, --help               Show this help
  -s, --stop               Stop currently playing station
  -l, --list               List stations
  -t, --toggle NUMBER      Toggle play/stop for station NUMBER
  -p, --player [VALUE]     Set player to cvlc/mpv (or toggle if VALUE omitted)

Arguments:
  NUMBER                   Play station number (1-${#SORTED_STATIONS[@]})
HELP
}

list_stations() {
    local i=1
    local station

    for station in "${SORTED_STATIONS[@]}"; do
        printf "%2d) %s\n" "$i" "$station"
        ((i++))
    done
}

handle_cli_arguments() {
    if (($# == 0)); then
        return 1
    fi

    case "$1" in
    -h | --help)
        print_help
        exit 0
        ;;
    -s | --stop)
        stop_radio
        exit 0
        ;;
    -l | --list)
        list_stations
        exit 0
        ;;
    -t | --toggle)
        if (($# != 2)); then
            print_error "Station number is required for --toggle"
            exit 1
        fi

        if play_station_by_number "$2" "true"; then
            exit 0
        fi
        exit 1
        ;;
    -p | --player)
        if (($# > 2)); then
            print_error "Too many arguments for --player"
            exit 1
        fi

        if (($# == 2)) && switch_player "$2"; then
            exit 0
        fi

        if (($# != 2)) && switch_player "toggle"; then
            exit 0
        fi

        exit 1
        ;;
    *)
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            if play_station_by_number "$1" "false"; then
                printf "%b\n" "${GREEN}Playback started.${NC}"
                exit 0
            fi
            exit 1
        fi

        print_error "Invalid argument: $1"
        exit 1
        ;;
    esac
}

interactive_loop() {
    local choice
    local search_term
    local new_volume

    while true; do
        show_menu
        read -r choice
        choice="$(trim "$choice")"

        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if play_station_by_number "$choice" "true"; then
                pause_for_key
            else
                sleep 1
            fi
            continue
        fi

        case "${choice,,}" in
        r)
            play_random_station
            pause_for_key
            ;;
        s)
            printf "Search term: "
            read -r search_term
            search_term="$(trim "$search_term")"
            if [[ -n "$search_term" ]]; then
                search_radio "$search_term"
            else
                print_warn "Search term cannot be empty."
            fi
            pause_for_key
            ;;
        f)
            show_favorites_menu
            ;;
        h)
            show_history
            ;;
        v)
            printf "New volume (0-100): "
            read -r new_volume
            change_volume "$new_volume"
            sleep 1
            ;;
        p)
            switch_player "toggle"
            sleep 1
            ;;
        a)
            toggle_current_station_favorite
            sleep 1
            ;;
        q)
            cleanup
            ;;
        "")
            ;;
        *)
            print_error "Invalid choice."
            sleep 1
            ;;
        esac
    done
}

cleanup() {
    stop_radio "true"
    printf "\n%b\n" "${GREEN}Exiting...${NC}"
    exit 0
}

main() {
    init_config
    check_dependencies
    create_station_list

    if ! handle_cli_arguments "$@"; then
        interactive_loop
    fi
}

trap cleanup INT TERM
main "$@"
