#!/usr/bin/env bash

#######################################
#
# Version: 2.1.0
# Date: 2025-04-08
# Author: Kenan Pelit
# Repository: github.com/kenanpelit/dotfiles
# Description: Session Manager (sem) - Terminal ve Uygulama Oturumları Yönetici
#
# Bu script Unix/Linux sistemlerde uygulama oturumlarını yönetmek için
# tasarlanmıştır. Temel özellikleri:
# - Basitleştirilmiş VPN (Mullvad) entegrasyonu (secure/bypass)
# - JSON tabanlı yapılandırma sistemi
# - Oturum başlatma/durdurma/yeniden başlatma
# - CPU ve bellek kullanımı izleme
# - JSON formatında metrik toplama
# - Güvenli dosya izinleri ve hata yönetimi
#
# Config: ~/.config/sem/config.json
# Logs: ~/.config/sem/logs/sem.log
# PID: /tmp/sem/
#
# License: MIT
#
#######################################

# shellcheck disable=SC2034
# shellcheck disable=SC2154

# Strict mode configuration
set -Eeuo pipefail
IFS=$'\n\t'

# Version
readonly VERSION="2.1.0"

# Core configuration
readonly SCRIPT_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/sem"
readonly CONFIG_FILE="$SCRIPT_PATH/config.json"
readonly LOG_FILE="$SCRIPT_PATH/logs/sem.log"
readonly CONFIG_SCHEMA="$SCRIPT_PATH/schema.json"
readonly BACKUP_DIR="$SCRIPT_PATH/backups"
readonly PID_DIR="/tmp/sem"
readonly METRICS_FILE="/tmp/sem_metrics.json"

# Default values
readonly DEFAULT_COMMAND_TIMEOUT=30
readonly DEFAULT_MAX_RETRIES=3
readonly DEFAULT_RETRY_DELAY=1
readonly DEFAULT_MONITOR_INTERVAL=5

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Global variables
declare -a TEMP_FILES=()
declare -A ACTIVE_MONITORS=()

# Initialize environment
initialize() {
	mkdir -p "$SCRIPT_PATH"/{logs,backups} "$PID_DIR"
	touch "$LOG_FILE" "$METRICS_FILE"
	chmod 700 "$SCRIPT_PATH"
	chmod 600 "$CONFIG_FILE" "$LOG_FILE" 2>/dev/null || true

	if [[ ! -s "$METRICS_FILE" ]]; then
		echo '{"sessions":{}}' >"$METRICS_FILE"
	fi
}

# Cleanup handler
cleanup() {
	local exit_code=$?
	for pid in "${ACTIVE_MONITORS[@]}"; do
		kill "$pid" 2>/dev/null || true
	done
	rm -f "${TEMP_FILES[@]}" 2>/dev/null || true
	exit "$exit_code"
}

# Error handler
error_handler() {
	local exit_code=$1
	local line_no=$2
	local bash_lineno=$3
	local last_command=$4
	local func_trace=$5

	log_error "Error on line $line_no: Command '$last_command' exited with status $exit_code"
	log_error "Function trace: $func_trace"
}

# Set up traps
trap cleanup EXIT
trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

# Logging functions
log_info() {
	echo -e "${GREEN}[INFO]${NC} $1" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >>"$LOG_FILE"
}

log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $1" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >>"$LOG_FILE"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1" >&2
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >>"$LOG_FILE"
}

# Config validation
validate_config() {
	if ! command -v ajv &>/dev/null; then
		log_error "ajv komutu bulunamadı. npm install -g ajv-cli ile yükleyin"
		return 1
	fi

	if ! ajv validate -s "$CONFIG_SCHEMA" -d "$CONFIG_FILE"; then
		log_error "Config dosyası şema validasyonunu geçemedi"
		return 1
	fi
}

# VPN functions
check_vpn() {
	local status_output
	if ! command -v mullvad &>/dev/null; then
		log_warn "Mullvad VPN client bulunamadı - VPN bağlantısı yok varsayılıyor"
		echo "false"
		return 0
	fi

	status_output=$(mullvad status 2>/dev/null || echo "Not connected")

	if echo "$status_output" | grep -q "Connected"; then
		local vpn_details
		vpn_details=$(echo "$status_output" | grep "Relay:" | awk -F': ' '{print $2}')
		log_info "VPN aktif: $vpn_details"
		echo "true"
		return 0
	fi

	log_info "VPN bağlantısı yok"
	echo "false"
	return 0
}

get_vpn_mode() {
	local session_name=$1
	local cli_mode=${2:-}

	case "$cli_mode" in
	bypass | secure)
		echo "$cli_mode"
		;;
	"")
		if [[ -f "$CONFIG_FILE" ]]; then
			jq -r ".sessions.\"$session_name\".vpn // \"secure\"" "$CONFIG_FILE"
		else
			echo "secure"
		fi
		;;
	*)
		log_error "Geçersiz VPN modu: $cli_mode. 'secure' veya 'bypass' kullanın"
		return 1
		;;
	esac
}

# Session management
execute_application() {
	local cmd=$1
	shift
	local -a args=("$@")

	nohup "$cmd" "${args[@]}" >/dev/null 2>&1 &
	echo $!
}

start_session() {
	local session_name=$1
	local vpn_param=${2:-}
	local start_time
	start_time=$(date +%s)

	if [[ ! -f "$CONFIG_FILE" ]]; then
		log_error "Config dosyası bulunamadı: $CONFIG_FILE"
		return 1
	fi

	local command
	command=$(jq -r ".sessions.\"${session_name}\".command" "$CONFIG_FILE")
	if [[ "$command" == "null" ]]; then
		log_error "Oturum bulunamadı: $session_name"
		return 1
	fi

	readarray -t args < <(jq -r ".sessions.\"${session_name}\".args[]" "$CONFIG_FILE")

	local vpn_mode
	vpn_mode=$(get_vpn_mode "$session_name" "$vpn_param")
	local vpn_status
	vpn_status=$(check_vpn)
	local pid

	case "$vpn_mode" in
	secure)
		if [[ "$vpn_status" != "true" ]]; then
			log_warn "VPN bağlantısı bulunamadı. Uygulamayı normal şekilde başlatıyorum: $session_name"
			if command -v notify-send &>/dev/null; then
				notify-send "Session Manager" "VPN bağlantısı bulunamadı. $session_name oturumu VPN olmadan başlatılıyor."
			fi
			pid=$(execute_application "$command" "${args[@]}")
		else
			pid=$(execute_application "$command" "${args[@]}")
		fi
		;;
	bypass)
		if [[ "$vpn_status" == "true" ]]; then
			if command -v mullvad-exclude &>/dev/null; then
				pid=$(mullvad-exclude "$command" "${args[@]}")
			else
				log_warn "mullvad-exclude bulunamadı - normal şekilde çalıştırılıyor"
				pid=$(execute_application "$command" "${args[@]}")
			fi
		else
			pid=$(execute_application "$command" "${args[@]}")
		fi
		;;
	esac

	local pid_file="$PID_DIR/${session_name}.pid"
	echo "$pid" >"$pid_file"

	monitor_resources "$session_name" "$pid" &
	ACTIVE_MONITORS["$session_name"]=$!

	update_metrics "$session_name" "$start_time" "$(date +%s)" "started"
	log_info "Oturum başlatıldı: $session_name (PID: $pid)"
}

stop_session() {
	local session_name=$1
	local pid_file="$PID_DIR/${session_name}.pid"

	if [[ -f "$pid_file" ]]; then
		local pid
		pid=$(<"$pid_file")
		if kill "$pid" 2>/dev/null; then
			rm -f "$pid_file"
			if [[ -n "${ACTIVE_MONITORS[$session_name]:-}" ]]; then
				kill "${ACTIVE_MONITORS[$session_name]}" 2>/dev/null || true
				unset "ACTIVE_MONITORS[$session_name]"
			fi
			log_info "Oturum durduruldu: $session_name"
			update_metrics "$session_name" "$(date +%s)" "$(date +%s)" "stopped"
			return 0
		fi
	fi
	log_error "Çalışan oturum bulunamadı: $session_name"
	return 1
}

# Session management functions
add_session() {
	if [[ ! -f "$CONFIG_FILE" ]]; then
		# İlk kez config oluşturuluyorsa
		echo '{"sessions":{}}' >"$CONFIG_FILE"
	fi

	if ! echo "$1" | jq . >/dev/null 2>&1; then
		log_error "Geçersiz JSON verisi"
		return 1
	fi

	local temp_file
	temp_file=$(mktemp)
	TEMP_FILES+=("$temp_file")

	if jq --argjson new "$1" '.sessions += $new' "$CONFIG_FILE" >"$temp_file" &&
		mv "$temp_file" "$CONFIG_FILE"; then
		log_info "Oturum başarıyla eklendi"
	else
		log_error "Oturum eklenirken hata oluştu"
		return 1
	fi
}

remove_session() {
	if [[ ! -f "$CONFIG_FILE" ]]; then
		log_error "Config dosyası bulunamadı"
		return 1
	fi

	local temp_file
	temp_file=$(mktemp)
	TEMP_FILES+=("$temp_file")

	if jq --arg name "$1" 'del(.sessions[$name])' "$CONFIG_FILE" >"$temp_file" &&
		mv "$temp_file" "$CONFIG_FILE"; then
		log_info "Oturum başarıyla kaldırıldı: $1"
	else
		log_error "Oturum kaldırılırken hata oluştu"
		return 1
	fi
}

list_sessions() {
	if [[ ! -f "$CONFIG_FILE" ]]; then
		log_error "Config dosyası bulunamadı"
		return 1
	fi

	printf "${BLUE}%s${NC}\n" "Mevcut Oturumlar:"

	jq -r '.sessions | to_entries[] | {
        key: .key,
        command: .value.command,
        vpn: (.value.vpn // "secure"),
        args: (.value.args|join(" "))
    } | "\(.key):\n  Komut: \(.command)\n  VPN Modu: \(.vpn)\n  Argümanlar: \(.args)"' "$CONFIG_FILE" |
		while IFS= read -r line; do
			if [[ $line =~ :$ ]]; then
				session=${line%:}
				status=$(check_status "$session")
				echo -e "${GREEN}${line}${NC}"
			elif [[ $line =~ ^[[:space:]]*VPN[[:space:]]Modu:[[:space:]]*(.*) ]]; then
				mode=${BASH_REMATCH[1]}
				case "$mode" in
				secure) printf "  VPN Modu: ${RED}%s${NC}\n" "$mode" ;;
				bypass) printf "  VPN Modu: ${GREEN}%s${NC}\n" "$mode" ;;
				*) printf "  VPN Modu: ${YELLOW}%s${NC}\n" "$mode" ;;
				esac
			else
				echo "$line"
			fi
		done
}

# Resource monitoring
monitor_resources() {
	local session_name=$1
	local pid=$2
	local interval=${3:-$DEFAULT_MONITOR_INTERVAL}

	while kill -0 "$pid" 2>/dev/null; do
		local cpu mem
		cpu=$(ps -p "$pid" -o %cpu= 2>/dev/null || echo "0")
		mem=$(ps -p "$pid" -o %mem= 2>/dev/null || echo "0")

		update_metrics "$session_name" "$(date +%s)" "$(date +%s)" "running" "{\"cpu\":$cpu,\"mem\":$mem}"
		sleep "$interval"
	done
}

# Metrics management
update_metrics() {
	local session_name=$1
	local start_time=$2
	local end_time=$3
	local status=$4
	local resources=${5:-"{}"}

	local duration=$((end_time - start_time))
	local temp_file
	temp_file=$(mktemp)
	TEMP_FILES+=("$temp_file")

	jq --arg session "$session_name" \
		--arg timestamp "$(date -Iseconds)" \
		--arg duration "$duration" \
		--arg status "$status" \
		--argjson resources "$resources" \
		'.sessions[$session].runs += [{
            timestamp: $timestamp,
            duration: $duration | tonumber,
            status: $status,
            resources: $resources
        }]' "$METRICS_FILE" >"$temp_file" && mv "$temp_file" "$METRICS_FILE"
}

# Utility functions
check_status() {
	local session_name=$1
	local pid_file="$PID_DIR/${session_name}.pid"

	if [[ -f "$pid_file" ]] && kill -0 "$(<"$pid_file")" 2>/dev/null; then
		echo "running"
	else
		echo "stopped"
	fi
}

backup_config() {
	local timestamp
	timestamp=$(date +%Y%m%d_%H%M%S)
	local backup_file="$BACKUP_DIR/sem_config_$timestamp.json"

	if cp "$CONFIG_FILE" "$backup_file"; then
		log_info "Config yedeklendi: $backup_file"
		return 0
	else
		log_error "Config yedeklenirken hata oluştu"
		return 1
	fi
}

show_version() {
	echo "sem version $VERSION"
}

show_help() {
	cat <<EOF
Session Manager $VERSION - Terminal ve Uygulama Oturumları Yönetimi

Kullanım: 
  sem <komut> [parametreler]

Komutlar:
  start   <oturum> [vpn_modu]  Oturum başlat
  stop    <oturum>            Oturum durdur
  restart <oturum> [vpn_modu]  Oturum yeniden başlat
  status  <oturum>            Oturum durumunu göster
  list                        Mevcut oturumları listele
  add     <json_veri>         Yeni oturum yapılandırması ekle
  remove  <oturum>            Oturum yapılandırmasını kaldır
  backup                      Config yedekle
  validate                    Config doğrula  
  version                     Versiyon bilgisi
  help                        Bu yardım mesajını göster

VPN Modları:
  bypass  : VPN dışında çalıştır (VPN'i bypass et)
  secure  : VPN üzerinden güvenli şekilde çalıştır

Örnek Kullanımlar:
  # Oturum başlatma örnekleri
  sem start secure-browser         # Yapılandırma VPN modunu kullan
  sem start local-browser bypass   # VPN dışında çalıştır
  sem restart zen-browser secure   # VPN içinde yeniden başlat

  # Oturum yönetimi
  sem list                        # Tüm oturumları listele
  sem status local-browser        # Oturum durumunu kontrol et
  sem stop secure-browser         # Oturumu durdur

  # Yapılandırma örnekleri
  sem add '{
    "secure-browser": {
      "command": "/usr/bin/firefox",
      "args": ["-P", "Secure", "--class", "Firefox-Secure"],
      "vpn": "secure"
    }
  }'

  sem add '{
    "local-terminal": {
      "command": "/usr/bin/alacritty",
      "args": ["--class", "Terminal", "-T", "Local"],
      "vpn": "bypass"
    }
  }'

  sem remove old-profile          # Profili kaldır
  sem backup                      # Yapılandırmayı yedekle

Not: VPN modu yapılandırma dosyasında tanımlıysa ve komut satırında 
belirtilmemişse, yapılandırmadaki mod kullanılır. Hiçbiri belirtilmemişse 
"secure" mod varsayılan olarak kullanılır.
EOF
}

# Main program
main() {
	initialize

	case "${1:-}" in
	start)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		start_session "$2" "${3:-}"
		;;
	stop)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		stop_session "$2"
		;;
	restart)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		stop_session "$2" && start_session "$2" "${3:-}"
		;;
	status)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		check_status "$2"
		;;
	list)
		list_sessions
		;;
	add)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		add_session "$2"
		;;
	remove)
		if [[ -z "${2:-}" ]]; then
			show_help
			exit 1
		fi
		remove_session "$2"
		;;
	backup)
		backup_config
		;;
	validate)
		validate_config
		;;
	version)
		show_version
		;;
	help | --help | -h)
		show_help
		;;
	*)
		show_help
		exit 1
		;;
	esac
}

main "$@"
