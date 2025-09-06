#!/usr/bin/env bash
# ==============================================================================
# NixOS Installation Script v3.0.0
# Complete, modular, and powerful NixOS installation tool
# Location: /home/kenan/.nixosc/install.sh
# ==============================================================================

#set -euo pipefail

# ==============================================================================
# PART 1: CORE LIBRARY
# ==============================================================================

# Version and metadata
readonly VERSION="3.0.0"
readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# System Configuration (from old script)
readonly CURRENT_USERNAME='kenan'
readonly DEFAULT_USERNAME='kenan'
readonly CONFIG_DIR="$HOME/.config/nixos"
readonly WALLPAPER_DIR="$HOME/Pictures/wallpapers"
readonly BUILD_CORES=0 # Auto-detect CPU cores
readonly NIX_CONF_DIR="$HOME/.config/nix"
readonly NIX_CONF_FILE="$NIX_CONF_DIR/nix.conf"
readonly BACKUP_DIR="$HOME/.nixosb"
readonly FLAKE_LOCK="flake.lock"
readonly LOG_FILE="$HOME/.nixosb/nixos-install.log"

# Cache Configuration (from old script)
readonly CACHE_DIR="$HOME/.nixos-cache"
readonly CACHE_ENABLED=true
readonly CACHE_EXPIRY=604800  # 7 days in seconds
readonly MAX_CACHE_SIZE=10240 # 10GB in MB

# Additional paths for compatibility
readonly NIXOS_CONFIG="$CONFIG_DIR"
readonly NIXOS_CACHE="$CACHE_DIR"
readonly NIXOS_BACKUP="$BACKUP_DIR"
readonly NIXOS_LOG="$(dirname "$LOG_FILE")"

# Working directory (where script is located)
readonly WORK_DIR="/home/kenan/.nixosc"

# Terminal capabilities detection
if [[ -t 1 ]] && command -v tput &>/dev/null; then
	readonly TERM_COLORS=$(tput colors 2>/dev/null || echo 0)
	readonly TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
	# UTF-8 detection fix
	if [[ "${LANG##*.}" == "UTF-8" ]] || [[ "${LANG,,}" == *utf*8* ]]; then
		readonly HAS_UTF8=true
	else
		readonly HAS_UTF8=false
	fi
else
	readonly TERM_COLORS=0
	readonly TERM_WIDTH=80
	readonly HAS_UTF8=false
fi

# Color definitions (adaptive)
if ((TERM_COLORS >= 256)); then
	# 256 color support
	readonly C_RESET='\033[0m'
	readonly C_BOLD='\033[1m'
	readonly C_DIM='\033[2m'
	readonly C_RED='\033[38;5;196m'
	readonly C_GREEN='\033[38;5;46m'
	readonly C_YELLOW='\033[38;5;226m'
	readonly C_BLUE='\033[38;5;33m'
	readonly C_MAGENTA='\033[38;5;201m'
	readonly C_CYAN='\033[38;5;51m'
	readonly C_WHITE='\033[38;5;255m'
	readonly C_GRAY='\033[38;5;244m'
elif ((TERM_COLORS >= 8)); then
	# Basic colors
	readonly C_RESET='\033[0m'
	readonly C_BOLD='\033[1m'
	readonly C_DIM='\033[2m'
	readonly C_RED='\033[31m'
	readonly C_GREEN='\033[32m'
	readonly C_YELLOW='\033[33m'
	readonly C_BLUE='\033[34m'
	readonly C_MAGENTA='\033[35m'
	readonly C_CYAN='\033[36m'
	readonly C_WHITE='\033[37m'
	readonly C_GRAY='\033[90m'
else
	# No colors
	readonly C_RESET='' C_BOLD='' C_DIM=''
	readonly C_RED='' C_GREEN='' C_YELLOW=''
	readonly C_BLUE='' C_MAGENTA='' C_CYAN=''
	readonly C_WHITE='' C_GRAY=''
fi

# Unicode symbols (with fallback)
if [[ $HAS_UTF8 == true ]]; then
	readonly S_SUCCESS="✓"
	readonly S_ERROR="✗"
	readonly S_WARNING="⚠"
	readonly S_INFO="ℹ"
	readonly S_ARROW="→"
	readonly S_BULLET="•"
	readonly S_ELLIPSIS="…"
	readonly SPINNER=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
	readonly PROGRESS_FULL="█"
	readonly PROGRESS_EMPTY="░"
else
	readonly S_SUCCESS="[OK]"
	readonly S_ERROR="[ERROR]"
	readonly S_WARNING="[WARN]"
	readonly S_INFO="[INFO]"
	readonly S_ARROW="->"
	readonly S_BULLET="*"
	readonly S_ELLIPSIS="..."
	readonly SPINNER=(- \\ \| /)
	readonly PROGRESS_FULL="#"
	readonly PROGRESS_EMPTY="."
fi

# Logging System
log::init() {
	local log_level="${1:-INFO}"
	local log_file="${2:-$LOG_FILE}"

	mkdir -p "$(dirname "$log_file")"

	export LOG_LEVEL="$log_level"
	export LOG_FILE_PATH="$log_file" # Use different variable name
	export LOG_FD=3

	exec 3>>"$log_file"

	# Keep last 10 log files
	find "$(dirname "$log_file")" -name "nixos-install*.log" -mtime +10 -delete 2>/dev/null || true
}

declare -A LOG_LEVELS=(
	[TRACE]=0 [DEBUG]=1 [INFO]=2 [WARN]=3 [ERROR]=4 [FATAL]=5
)

log() {
	local level="${1:-INFO}"
	shift
	local message="$*"
	local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
	local caller_func="${FUNCNAME[2]:-main}"

	local current_level="${LOG_LEVELS[${LOG_LEVEL:-INFO}]}"
	local message_level="${LOG_LEVELS[$level]}"

	[[ $message_level -lt $current_level ]] && return 0

	local color symbol
	case "$level" in
	TRACE) color="$C_GRAY" symbol="$S_BULLET" ;;
	DEBUG) color="$C_BLUE" symbol="$S_INFO" ;;
	INFO) color="$C_CYAN" symbol="$S_INFO" ;;
	WARN) color="$C_YELLOW" symbol="$S_WARNING" ;;
	ERROR) color="$C_RED" symbol="$S_ERROR" ;;
	FATAL) color="$C_BOLD$C_RED" symbol="$S_ERROR" ;;
	esac

	if [[ -t 1 ]]; then
		printf "${color}%s %-5s${C_RESET} ${C_DIM}[%s]${C_RESET} %s\n" \
			"$symbol" "$level" "$caller_func" "$message" >&2
	else
		printf "%s %-5s [%s] %s\n" "$symbol" "$level" "$caller_func" "$message" >&2
	fi

	if [[ -n "${LOG_FD:-}" ]]; then
		printf "[%s] %-5s [%s] %s\n" "$timestamp" "$level" "$caller_func" "$message" >&${LOG_FD}
	fi

	[[ "$level" == "FATAL" ]] && exit 1
}

# Progress and UI Functions
declare -g PROGRESS_START_TIME
declare -g PROGRESS_CURRENT=0
declare -g PROGRESS_TOTAL=0

progress::init() {
	PROGRESS_CURRENT=0
	PROGRESS_TOTAL="${1:-0}"
	PROGRESS_START_TIME=$(date +%s)
}

progress::update() {
	local current="${1:-$((++PROGRESS_CURRENT))}"
	local total="${2:-$PROGRESS_TOTAL}"
	local message="${3:-Processing...}"

	[[ $total -eq 0 ]] && return

	local percent=$((current * 100 / total))
	local filled=$((percent * 40 / 100))
	local empty=$((40 - filled))

	local eta=""
	if [[ $current -gt 0 && $percent -lt 100 ]]; then
		local elapsed=$(($(date +%s) - PROGRESS_START_TIME))
		local estimated=$((elapsed * total / current))
		local remaining=$((estimated - elapsed))

		if [[ $remaining -gt 0 ]]; then
			if [[ $remaining -ge 3600 ]]; then
				eta=" ETA: $((remaining / 3600))h$((remaining % 3600 / 60))m"
			elif [[ $remaining -ge 60 ]]; then
				eta=" ETA: $((remaining / 60))m$((remaining % 60))s"
			else
				eta=" ETA: ${remaining}s"
			fi
		fi
	fi

	printf "\r${C_CYAN}[" >&2
	printf "%${filled}s" | tr ' ' "$PROGRESS_FULL" >&2
	printf "%${empty}s" | tr ' ' "$PROGRESS_EMPTY" >&2
	printf "] ${C_BOLD}%3d%%${C_RESET} %-30s%s" "$percent" "${message:0:30}" "$eta" >&2

	[[ $percent -eq 100 ]] && echo >&2
}

# NEW: substep helper (spinner'dan önce)
progress::substep_show() {
	local message="${1:-}"
	[[ -z "$message" ]] && return 0
	printf "\n${C_DIM}%s %s${C_RESET}\n" "$S_ARROW" "$message" >&2
}

spinner() {
	local pid="${1:-$$}"
	local message="${2:-Working...}"
	local frames=("${SPINNER[@]}")

	while kill -0 "$pid" 2>/dev/null; do
		for frame in "${frames[@]}"; do
			printf "\r${C_CYAN}%s${C_RESET} %s" "$frame" "$message" >&2
			sleep 0.1
		done
	done
	printf "\r${C_GREEN}%s${C_RESET} %s\n" "$S_SUCCESS" "$message" >&2
}

# Cache Management System (declare without -g for initial declaration)
CACHE_ENABLED_VAR=$CACHE_ENABLED
CACHE_TTL_VAR=$CACHE_EXPIRY
CACHE_MAX_SIZE_VAR=$MAX_CACHE_SIZE

cache::init() {
	[[ $CACHE_ENABLED_VAR != true ]] && return 0

	mkdir -p "$CACHE_DIR"/{packages,metadata,downloads}

	local meta_file="$CACHE_DIR/metadata.json"
	if [[ ! -f "$meta_file" ]]; then
		cat >"$meta_file" <<-EOF
			{
			  "version": "$VERSION",
			  "created": $(date +%s),
			  "last_cleaned": $(date +%s)
			}
		EOF
	fi

	cache::cleanup
}

cache::key() {
	echo "$*" | sha256sum | cut -d' ' -f1
}

cache::get() {
	local key="$1"
	local dest="${2:-}"

	[[ $CACHE_ENABLED_VAR != true ]] && return 1

	local cache_file="$CACHE_DIR/packages/${key}"
	[[ -f "$cache_file" ]] || return 1

	local age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file")))
	[[ $age -gt $CACHE_TTL_VAR ]] && return 1

	if [[ -n "$dest" ]]; then
		cp "$cache_file" "$dest"
	else
		cat "$cache_file"
	fi

	log DEBUG "Cache hit: $key"
	return 0
}

cache::set() {
	local key="$1"
	local source="${2:-/dev/stdin}"

	[[ $CACHE_ENABLED_VAR != true ]] && return 0

	local cache_file="$CACHE_DIR/packages/${key}"

	if [[ -f "$source" ]]; then
		cp "$source" "$cache_file"
	else
		cat >"$cache_file"
	fi

	log DEBUG "Cache store: $key"
	cache::cleanup
}

cache::cleanup() {
	[[ $CACHE_ENABLED_VAR != true ]] && return 0

	find "$CACHE_DIR/packages" -type f -mtime +$((CACHE_TTL_VAR / 86400)) -delete 2>/dev/null || true

	local size=$(du -sm "$CACHE_DIR" 2>/dev/null | cut -f1)
	if [[ ${size:-0} -gt $CACHE_MAX_SIZE_VAR ]]; then
		log WARN "Cache size exceeded: ${size}MB > ${CACHE_MAX_SIZE_VAR}MB"
		find "$CACHE_DIR/packages" -type f -printf '%T@ %p\n' |
			sort -n | head -n 20 | cut -d' ' -f2- | xargs rm -f
	fi

	# NEW: update metadata.last_cleaned
	local meta="$CACHE_DIR/metadata.json"
	if [[ -f "$meta" ]]; then
		# sed ile last_cleaned güncelle (jq bağımlılığı olmadan)
		sed -i -E 's/"last_cleaned": *[0-9]+/"last_cleaned": '"$(date +%s)"'/' "$meta" 2>/dev/null || true
	fi
}

# Backup System
backup::create() {
	local source="$1"
	local name="${2:-backup}"
	local timestamp=$(date +%Y%m%d_%H%M%S)
	local backup_dir="$BACKUP_DIR/${name}"
	local backup_file="${backup_dir}/${name}-${timestamp}.tar.gz"

	mkdir -p "$backup_dir"

	tar -czf "$backup_file" -C "$(dirname "$source")" "$(basename "$source")" 2>/dev/null

	cat >"${backup_file}.meta" <<-EOF
		{
		  "timestamp": $(date +%s),
		  "source": "$source",
		  "size": $(stat -c %s "$backup_file" 2>/dev/null || stat -f %z "$backup_file"),
		  "checksum": "$(sha256sum "$backup_file" | cut -d' ' -f1)"
		}
	EOF

	ls -t "${backup_dir}"/*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm -f

	log INFO "Backup created: $backup_file"
	echo "$backup_file"
}

backup::restore() {
	local name="${1:-backup}"
	local dest="${2:-}"
	local backup_dir="$BACKUP_DIR/${name}"

	# En yeni .tar.gz yedeği bul
	local latest
	latest=$(ls -t "${backup_dir}"/*.tar.gz 2>/dev/null | head -n1 || true)

	if [[ -z "$latest" ]]; then
		log ERROR "No backup found for: $name"
		return 1
	fi

	# Varsa checksum doğrula
	if [[ -f "${latest}.meta" ]]; then
		local stored_checksum actual_checksum
		stored_checksum=$(grep -o '"checksum": "[^"]*"' "${latest}.meta" | cut -d'"' -f4)
		actual_checksum=$(sha256sum "$latest" | cut -d' ' -f1)

		if [[ "$stored_checksum" != "$actual_checksum" ]]; then
			log ERROR "Backup checksum mismatch!"
			return 1
		fi
	fi

	# Çıkarma
	if [[ -n "$dest" ]]; then
		mkdir -p "$dest"
		tar -xzf "$latest" -C "$dest"
	else
		tar -xzf "$latest"
	fi

	log INFO "Restored from: $latest"
	return 0
}

# Utility Functions
has_command() {
	command -v "$1" &>/dev/null
}

require_commands() {
	local missing=()
	for cmd in "$@"; do
		has_command "$cmd" || missing+=("$cmd")
	done

	if [[ ${#missing[@]} -gt 0 ]]; then
		log FATAL "Missing required commands: ${missing[*]}"
	fi
}

run() {
	local cmd="$1"
	shift
	log DEBUG "Running: $cmd $*"

	if output=$("$cmd" "$@" 2>&1); then
		log TRACE "Output: $output"
		return 0
	else
		log ERROR "Command failed: $cmd $*"
		log DEBUG "Error output: $output"
		return 1
	fi
}

confirm() {
	local message="${1:-Continue?}"
	local default="${2:-n}"

	[[ "${CONFIG[AUTO_MODE]:-false}" == "true" ]] && return 0
	[[ "${CONFIG[SILENT_MODE]:-false}" == "true" ]] && return 0
	[[ -t 0 ]] || return 0

	local prompt
	case "${default,,}" in
	y) prompt="[Y/n]" ;;
	n) prompt="[y/N]" ;;
	*) prompt="[y/n]" ;;
	esac

	printf "${C_YELLOW}%s${C_RESET} %s " "$message" "$prompt" >&2
	read -r -n1 response
	echo >&2

	case "${response,,}" in
	y) return 0 ;;
	n) return 1 ;;
	"") [[ "${default,,}" == "y" ]] ;;
	*) return 1 ;;
	esac
}

# ==============================================================================
# PART 2: CORE INSTALLATION MODULE
# ==============================================================================

declare -A CONFIG=(
	[USERNAME]="$DEFAULT_USERNAME"
	[CURRENT_USERNAME]="$CURRENT_USERNAME"
	[HOSTNAME]=""
	[PROFILE]=""
	[FLAKE_DIR]="$WORK_DIR"
	[WALLPAPER_DIR]="$WALLPAPER_DIR"
	[BUILD_CORES]=$(nproc)
	[UPDATE_FLAKE]=false
	[UPDATE_MODULE]=""
	[PRE_INSTALL]=false
	[AUTO_MODE]=false
	[SILENT_MODE]=false
)

config::load() {
	local config_file="${1:-${CONFIG_DIR}/config.json}"

	if [[ -f "$config_file" ]]; then
		log DEBUG "Loading config from: $config_file"
		if has_command jq; then
			while IFS='=' read -r key value; do
				CONFIG[$key]="$value"
			done < <(jq -r 'to_entries[] | "\(.key)=\(.value)"' "$config_file")
		else
			while IFS=':' read -r key value; do
				key=$(echo "$key" | tr -d '"{} \t')
				value=$(echo "$value" | tr -d '", \t')
				[[ -n "$key" && -n "$value" ]] && CONFIG[$key]="$value"
			done <"$config_file"
		fi
	fi
}

config::save() {
	local config_file="${1:-${CONFIG_DIR}/config.json}"

	mkdir -p "$(dirname "$config_file")"

	{
		echo "{"
		local first=true
		for key in "${!CONFIG[@]}"; do
			[[ $first == true ]] && first=false || echo ","
			printf '  "%s": "%s"' "$key" "${CONFIG[$key]}"
		done
		echo -e "\n}"
	} >"$config_file"

	log DEBUG "Config saved to: $config_file"
}

config::get() {
	echo "${CONFIG[$1]:-}"
}

config::set() {
	CONFIG[$1]="$2"
}

system::detect() {
	local system_type="unknown"

	if systemd-detect-virt --quiet 2>/dev/null; then
		system_type="vm"
		log INFO "Virtual machine detected"
	else
		if [[ -d /sys/class/power_supply/BAT* ]] || [[ -f /sys/class/dmi/id/chassis_type ]]; then
			local chassis_type=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || echo 0)
			case $chassis_type in
			8 | 9 | 10 | 14) system_type="laptop" ;;
			3 | 4 | 5 | 6 | 7) system_type="desktop" ;;
			*) system_type="unknown" ;;
			esac
		fi
	fi

	log INFO "System type detected: $system_type"
	echo "$system_type"
}

system::validate() {
	local errors=()

	if [[ ! -f /etc/nixos/configuration.nix ]] && [[ ! -d /etc/nixos ]]; then
		errors+=("Not a NixOS system")
	fi

	local free_space=$(df -BG "$WORK_DIR" | awk 'NR==2 {print int($4)}')
	if [[ $free_space -lt 10 ]]; then
		errors+=("Insufficient disk space: ${free_space}GB < 10GB")
	fi

	local total_mem=$(free -g | awk '/^Mem:/ {print int($2)}')
	if [[ $total_mem -lt 2 ]]; then
		errors+=("Insufficient memory: ${total_mem}GB < 2GB")
	fi

	local required_cmds=(nix nixos-rebuild git)
	for cmd in "${required_cmds[@]}"; do
		has_command "$cmd" || errors+=("Missing command: $cmd")
	done

	if [[ ${#errors[@]} -gt 0 ]]; then
		for error in "${errors[@]}"; do
			log ERROR "$error"
		done
		return 1
	fi

	log INFO "System validation passed"
	return 0
}

system::health_check() {
	log INFO "Running system health check..."

	# Memory usage
	local mem_info=$(free -h | awk '/^Mem:/ {printf "Total: %s, Used: %s, Free: %s", $2, $3, $4}')
	log INFO "Memory: $mem_info"

	# CPU load
	local cpu_load=$(uptime | awk -F'load average:' '{print $2}')
	log INFO "CPU Load:$cpu_load"

	# Disk usage
	while IFS= read -r line; do
		log INFO "Disk: $line"
	done < <(df -h / /home /nix/store 2>/dev/null | awk 'NR>1 {printf "%s: %s used of %s (%s)\n", $6, $3, $2, $5}')

	# Nix store size
	if has_command nix-store; then
		local store_size=$(du -sh /nix/store 2>/dev/null | cut -f1)
		log INFO "Nix store size: ${store_size:-unknown}"
	fi

	# Network connectivity
	if ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
		log INFO "Network: Connected"
	else
		log WARN "Network: No internet connection"
	fi

	# System details
	log INFO "Hostname: $(hostname)"
	log INFO "Kernel: $(uname -r)"
	log INFO "Uptime: $(uptime -p 2>/dev/null || uptime)"

	# NixOS specific
	if [[ -f /etc/os-release ]]; then
		local nixos_version=$(grep "^VERSION=" /etc/os-release | cut -d'"' -f2)
		log INFO "NixOS Version: ${nixos_version:-unknown}"
	fi

	# Current generation
	if has_command nixos-version; then
		local current_gen=$(readlink /nix/var/nix/profiles/system | grep -oP 'system-\K[0-9]+' || echo "unknown")
		log INFO "Current generation: $current_gen"
	fi

	return 0
}

flake::init() {
	local flake_dir="${1:-$(config::get FLAKE_DIR)}"

	cd "$flake_dir" || {
		log ERROR "Cannot access flake directory: $flake_dir"
		return 1
	}

	if [[ ! -f flake.nix ]]; then
		log ERROR "No flake.nix found in: $flake_dir"
		return 1
	fi

	local nix_conf="$HOME/.config/nix/nix.conf"
	if [[ ! -f "$nix_conf" ]] || ! grep -q "experimental-features.*flakes" "$nix_conf"; then
		mkdir -p "$(dirname "$nix_conf")"
		echo "experimental-features = nix-command flakes" >>"$nix_conf"
		log INFO "Enabled flakes support"
	fi

	return 0
}

flake::update() {
	local module="${1:-}"

	if [[ -f flake.lock ]]; then
		backup::create flake.lock "flake-lock"
	fi

	if [[ -n "$module" ]]; then
		log INFO "Updating flake input: $module"
		if run nix flake lock --update-input "$module"; then
			log INFO "Successfully updated: $module"
		else
			log ERROR "Failed to update: $module"
			backup::restore "flake-lock" "."
			return 1
		fi
	else
		log INFO "Updating all flake inputs"
		if run nix flake update; then
			log INFO "Successfully updated all inputs"
		else
			log ERROR "Failed to update flake"
			backup::restore "flake-lock" "."
			return 1
		fi
	fi

	return 0
}

flake::list_inputs() {
	if has_command nix; then
		nix flake metadata --json 2>/dev/null |
			jq -r '.locks.nodes | to_entries[] | select(.key != "root") | .key' 2>/dev/null ||
			nix flake metadata 2>/dev/null | grep -A 100 "Inputs:" | grep "^├" | awk '{print $2}'
	fi
}

flake::build() {
	local hostname="${1:-$(config::get HOSTNAME)}"
	local profile="${2:-$(config::get PROFILE)}"
	local cores="${3:-$(config::get BUILD_CORES)}"

	[[ -z "$hostname" ]] && {
		log ERROR "Hostname not specified"
		return 1
	}

	local build_cmd="sudo nixos-rebuild switch"
	build_cmd+=" --flake .#${hostname}"
	build_cmd+=" --cores ${cores}"
	build_cmd+=" --accept-flake-config"
	build_cmd+=" --option warn-dirty false"

	[[ -n "$profile" ]] && build_cmd+=" --profile-name ${profile}"

	if [[ -d "$NIXOS_CACHE" ]]; then
		build_cmd+=" --option extra-substituters file://${NIXOS_CACHE}"
	fi

	log INFO "Building system: $hostname"
	log DEBUG "Build command: $build_cmd"

	if eval "$build_cmd"; then
		log INFO "System build successful"

		if [[ $CACHE_ENABLED_VAR == true ]]; then
			local cache_key=$(cache::key "build-${hostname}-$(date +%Y%m%d)")
			echo "$(date +%s)" | cache::set "$cache_key"
		fi

		return 0
	else
		log ERROR "System build failed"
		return 1
	fi
}

# NEW: güvenli kullanıcı adı değiştirme
user::setup() {
	local username="${1:-$(config::get USERNAME)}"
	local current_user="${2:-$CURRENT_USERNAME}"

	if [[ -z "$username" ]]; then
		if [[ $(config::get AUTO_MODE) == true ]]; then
			username="$current_user"
		else
			printf "${C_YELLOW}Enter username:${C_RESET} "
			read -r username
		fi
	fi

	if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
		log ERROR "Invalid username format: $username"
		return 1
	fi

	config::set USERNAME "$username"

	if [[ "$username" != "$current_user" ]]; then
		log INFO "Updating configuration files for user: $username"

		local files_updated=0
		local failed=0
		local changed_files=()

		while IFS= read -r -d '' file; do
			if grep -q "$current_user" "$file"; then
				cp -f "$file" "${file}.bak" || {
					((failed++))
					continue
				}
				if sed -i "s/${current_user}/${username}/g" "$file"; then
					((files_updated++))
					changed_files+=("$file")
				else
					# geri al
					cp -f "${file}.bak" "$file" 2>/dev/null || true
					((failed++))
				fi
			fi
		done < <(find "$WORK_DIR" -type f \( -name "*.nix" -o -name "*.conf" -o -name "*.yaml" \) -print0)

		log INFO "Updated $files_updated configuration files"
		((failed > 0)) && log WARN "Replacements failed on $failed files (restored from .bak)"
	fi

	return 0
}

host::setup() {
	local hostname="${1:-$(config::get HOSTNAME)}"

	if [[ -z "$hostname" ]]; then
		local system_type=$(system::detect)

		if [[ $(config::get AUTO_MODE) == true ]]; then
			case "$system_type" in
			laptop) hostname="hay" ;;
			vm) hostname="vhay" ;;
			*) hostname="nixos" ;;
			esac
		else
			printf "${C_YELLOW}Enter hostname (hay/vhay):${C_RESET} "
			read -r hostname
		fi
	fi

	if ! [[ "$hostname" =~ ^[a-zA-Z][a-zA-Z0-9-]*$ ]]; then
		log ERROR "Invalid hostname format: $hostname"
		return 1
	fi

	config::set HOSTNAME "$hostname"

	local hw_config="/etc/nixos/hardware-configuration.nix"
	local target="$WORK_DIR/hosts/${hostname}/hardware-configuration.nix"

	if [[ -f "$hw_config" ]] && [[ -d "$(dirname "$target")" ]]; then
		if [[ ! -f "$target" ]] || ! cmp -s "$hw_config" "$target"; then
			cp "$hw_config" "$target"
			log INFO "Hardware configuration copied for: $hostname"
		fi
	fi

	return 0
}

# ==============================================================================
# PART 3: MAIN INSTALLATION SCRIPT
# ==============================================================================

show_help() {
	echo -e "${C_CYAN}NixOS Installation Script v${VERSION}${C_RESET}

${C_BOLD}USAGE:${C_RESET}
    $(basename "$0") [COMMAND] [OPTIONS]

${C_BOLD}COMMANDS:${C_RESET}
    install             Full system installation
    update              Update flake inputs
    build               Build NixOS configuration
    switch              Switch to new configuration
    rollback            Rollback to previous configuration
    health              System health check
    cache               Cache management
    backup              Backup management
    profile             Profile management
    
${C_BOLD}OPTIONS:${C_RESET}
    -h, --help          Show this help message
    -v, --version       Show version information
    -c, --config FILE   Use custom configuration file
    -d, --debug         Enable debug logging
    -s, --silent        Silent mode (no prompts)
    -a, --auto          Automatic mode
    -H, --host NAME     Set hostname
    -u, --update        Update flake before building
    -U, --user NAME     Set username
    -p, --profile NAME  Set profile name
    --pre-install       Run pre-installation setup
    --no-cache          Disable caching
    --no-backup         Skip backups
    
${C_BOLD}EXAMPLES:${C_RESET}
    # Pre-installation (first time setup)
    $(basename "$0") -a hay --pre-install
    $(basename "$0") -a vhay --pre-install
    
    # Interactive installation
    $(basename "$0") install
    
    # Automatic installation for laptop with profile
    $(basename "$0") install --auto --host hay --profile T1
    
    # Old style command (still works)
    $(basename "$0") -u -a hay -p T1_20250826
    
    # Update specific flake input
    $(basename "$0") update home-manager
    
    # Build with custom profile
    $(basename "$0") build --host hay --profile development
    
    # System health check
    $(basename "$0") health

${C_BOLD}CONFIGURATION:${C_RESET}
    Working dir: ${WORK_DIR}
    Config file: ${CONFIG_DIR}/config.json
    Cache dir:   ${CACHE_DIR}
    Backup dir:  ${BACKUP_DIR}
    Log file:    ${LOG_FILE}

For more information, visit: https://github.com/kenanpelit/nixosc"
}

parse_args() {
	local command=""
	local args=()

	# Check for old-style command first
	if [[ "$1" == "-u" || "$1" == "-a" || "$1" == "-p" ]]; then
		# Old style command, assume install
		command="install"
		config::set AUTO_MODE true
	fi

	while [[ $# -gt 0 ]]; do
		case "$1" in
		install | update | build | switch | rollback | health | cache | backup | profile)
			[[ -z "$command" ]] && command="$1"
			shift
			;;
		-h | --help)
			show_help
			exit 0
			;;
		-v | --version)
			echo "NixOS Installation Script v${VERSION}"
			exit 0
			;;
		-c | --config)
			shift
			config::load "$1"
			shift
			;;
		-d | --debug)
			export LOG_LEVEL="DEBUG"
			shift
			;;
		-s | --silent)
			config::set SILENT_MODE true
			shift
			;;
		-a | --auto)
			config::set AUTO_MODE true
			config::set SILENT_MODE true
			# Check if next arg is hostname (old style)
			if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
				shift
				config::set HOSTNAME "$1"
			fi
			shift
			;;
		--pre-install)
			config::set PRE_INSTALL true
			command="pre-install"
			shift
			;;
		-u | --update | --update-flake)
			config::set UPDATE_FLAKE true
			shift
			;;
		-H | --host)
			shift
			config::set HOSTNAME "$1"
			shift
			;;
		-U | --user)
			shift
			config::set USERNAME "$1"
			shift
			;;
		-p | --profile)
			shift
			config::set PROFILE "$1"
			shift
			;;
		--no-cache)
			CACHE_ENABLED_VAR=false
			shift
			;;
		--no-backup)
			BACKUP_ENABLED=false
			shift
			;;
		*)
			args+=("$1")
			shift
			;;
		esac
	done

	# Default to install if old style args were used
	[[ -z "$command" && $(config::get AUTO_MODE) == true ]] && command="install"

	if [[ -n "$command" ]]; then
		"cmd_${command}" "${args[@]}"
	else
		show_menu
	fi
}

# Pre-installation command
cmd_pre-install() {
	local hostname="${1:-$(config::get HOSTNAME)}"

	[[ -z "$hostname" ]] && {
		log ERROR "Hostname required for pre-install"
		echo "Usage: $0 --pre-install --host <hostname>"
		exit 1
	}

	echo -e "${C_CYAN}Starting pre-installation for ${hostname}...${C_RESET}\n"

	# Check if running as current user (not root)
	if [[ $EUID -eq 0 ]]; then
		echo -e "${C_RED}Error: Do not run pre-install as root!${C_RESET}"
		exit 1
	fi

	# Check if user is in wheel group
	if ! id -nG | grep -qw wheel; then
		echo -e "${C_YELLOW}Warning: Current user should be in wheel group${C_RESET}"
		echo "Run: sudo usermod -aG wheel $USER"
		exit 1
	fi

	# Create initial configuration template
	local template_dir="$WORK_DIR/hosts/${hostname}/templates"
	local initial_config="$template_dir/initial-configuration.nix"

	if [[ ! -f "$initial_config" ]]; then
		echo -e "${C_YELLOW}Creating initial configuration template...${C_RESET}"
		mkdir -p "$template_dir"

		# Create a basic initial configuration (host-specific, richer template)
		# You can tweak these defaults here or pass --host to the script.
		local tz="Europe/Istanbul"
		local default_locale="en_US.UTF-8"
		local tr_locale="tr_TR.UTF-8"
		local xkb_layout="tr"
		local xkb_variant="f"
		local console_keymap="trf"

		cat >"$initial_config" <<EOF
# hosts/${hostname}/templates/initial-configuration.nix
# ==============================================================================
# !!! IMPORTANT - PLEASE READ BEFORE PROCEEDING !!!
# Before building your system, make sure to adjust the following settings
# according to your preferences and location:
#
# 1. Time Zone: Currently set to "${tz}"
# 2. System Language: Currently set to "${default_locale}"
# 3. Regional Settings: Currently configured for Turkish (${tr_locale})
# 4. Keyboard Layout: Currently set to Turkish-F layout
#
# You can find your timezone from: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
# For keyboard layouts: run 'localectl list-x11-keymap-layouts' for available options
# ==============================================================================
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # =============================================================================
  # Bootloader Configuration
  # =============================================================================
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = "nodev";          # Install GRUB without specific device (EFI)
    useOSProber = true;        # Enable OS prober for multi-boot
    efiSupport = true;         # Enable EFI support
  };
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };

  # Use latest kernel packages
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # =============================================================================
  # Networking Configuration
  # =============================================================================
  networking = {
    hostName = "${hostname}";
    networkmanager.enable = true;
  };

  # =============================================================================
  # Timezone and Localization
  # =============================================================================
  time.timeZone = "${tz}";
  i18n.defaultLocale = "${default_locale}";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "${tr_locale}";
    LC_IDENTIFICATION = "${tr_locale}";
    LC_MEASUREMENT    = "${tr_locale}";
    LC_MONETARY       = "${tr_locale}";
    LC_NAME           = "${tr_locale}";
    LC_NUMERIC        = "${tr_locale}";
    LC_PAPER          = "${tr_locale}";
    LC_TELEPHONE      = "${tr_locale}";
    LC_TIME           = "${tr_locale}";
  };

  # =============================================================================
  # Keyboard Configuration
  # =============================================================================
  services.xserver.xkb = {
    layout  = "${xkb_layout}";
    variant = "${xkb_variant}";
    options = "ctrl:nocaps";
  };
  console.keyMap = "${console_keymap}";

  # =============================================================================
  # User Account Configuration
  # =============================================================================
  users.users.kenan = {
    isNormalUser = true;
    description  = "Kenan Pelit";
    extraGroups  = [ "networkmanager" "wheel" ];
    packages     = with pkgs; [ ];
  };

  # =============================================================================
  # Package Management Configuration
  # =============================================================================
  nixpkgs.config.allowUnfree = true;

  # =============================================================================
  # System Packages
  # =============================================================================
  environment.systemPackages = with pkgs; [
    # System tools
    wget        # File downloader
    vim         # Text editor
    git         # Version control
    htop        # System monitor
    tmux        # Terminal multiplexer
    sops        # Secrets management
    age         # File encryption
    assh        # SSH config manager
    ncurses     # Terminal UI library
    pv          # Pipe viewer
    file        # File type identifier
    bc          # GNU software calculator
    # Security and encryption
    gnupg       # GNU Privacy Guard
    openssl     # SSL/TLS toolkit
  ];

  # =============================================================================
  # Program Configurations
  # =============================================================================
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # =============================================================================
  # Flakes (optional: keep enabled at system level)
  # =============================================================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # =============================================================================
  # System Version
  # =============================================================================
  # IMPORTANT: Set this to the NixOS release you initially install.
  # If you're on unstable right now, change accordingly.
  system.stateVersion = "25.11";
}
EOF

	fi

	# Backup existing configuration
	if [[ -f /etc/nixos/configuration.nix ]]; then
		local backup="/etc/nixos/configuration.nix.backup-$(date +%Y%m%d_%H%M%S)"
		echo -e "${C_YELLOW}Backing up existing configuration to: $backup${C_RESET}"
		sudo cp /etc/nixos/configuration.nix "$backup"
	fi

	# Copy initial configuration
	echo -e "${C_CYAN}Installing initial configuration...${C_RESET}"
	sudo cp "$initial_config" /etc/nixos/configuration.nix
	sudo chown root:root /etc/nixos/configuration.nix
	sudo chmod 644 /etc/nixos/configuration.nix

	# Copy hardware configuration if it doesn't exist
	if [[ ! -f /etc/nixos/hardware-configuration.nix ]]; then
		echo -e "${C_YELLOW}Generating hardware configuration...${C_RESET}"
		sudo nixos-generate-config --root /
	fi

	# Build initial system
	echo -e "${C_CYAN}Building initial system (profile: start)...${C_RESET}"
	if sudo nixos-rebuild switch --profile-name start; then
		echo -e "${C_GREEN}Pre-installation completed successfully!${C_RESET}"
		echo ""
		echo -e "${C_YELLOW}Next steps:${C_RESET}"
		echo -e "1. Reboot the system: ${C_CYAN}sudo reboot${C_RESET}"
		echo -e "2. After reboot, run: ${C_CYAN}$0 install --auto --host ${hostname}${C_RESET}"
		echo ""
		echo -e "${C_GREEN}Initial system is ready!${C_RESET}"
	else
		echo -e "${C_RED}Pre-installation failed!${C_RESET}"
		exit 1
	fi
}

# Command Implementations
cmd_install() {
	log INFO "Starting NixOS installation"

	# Debug: Show what we're doing
	echo -e "${C_CYAN}Starting installation process...${C_RESET}"
	echo -e "Host: ${C_YELLOW}$(config::get HOSTNAME)${C_RESET}"
	echo -e "Profile: ${C_YELLOW}$(config::get PROFILE)${C_RESET}"
	echo -e "Auto mode: ${C_YELLOW}$(config::get AUTO_MODE)${C_RESET}\n"

	# System validation
	echo -e "${C_CYAN}Validating system...${C_RESET}"
	if ! system::validate; then
		echo -e "${C_RED}System validation failed!${C_RESET}"
		exit 1
	fi
	echo -e "${C_GREEN}System validation passed${C_RESET}\n"

	# Initialize subsystems
	echo -e "${C_CYAN}Initializing...${C_RESET}"
	cache::init
	flake::init || {
		echo -e "${C_RED}Failed to initialize flake directory${C_RESET}"
		exit 1
	}

	local steps=(
		"Setting up user configuration"
		"Setting up host configuration"
		"Creating directory structure"
		"Copying wallpapers"
		"Building system configuration"
	)

	# Add flake update step if needed
	if [[ $(config::get UPDATE_FLAKE) == true ]]; then
		steps=("Updating flake inputs" "${steps[@]}")
	fi

	progress::init ${#steps[@]}

	for step in "${steps[@]}"; do
		echo -e "\n${C_CYAN}Step: ${step}${C_RESET}"
		progress::update "" "" "$step"

		case "$step" in
		"Setting up user configuration")
			user::setup || return 1
			;;
		"Setting up host configuration")
			host::setup || return 1
			;;
		"Creating directory structure")
			setup_directories
			;;
		"Copying wallpapers")
			setup_wallpapers
			;;
		"Updating flake inputs")
			flake::update
			;;
		"Building system configuration")
			flake::build || return 1
			;;
		esac
	done

	config::save

	echo -e "\n${C_GREEN}Installation completed successfully!${C_RESET}"
	show_summary
}

cmd_update() {
	local module="${1:-}"

	log INFO "Updating flake configuration"

	cd "$WORK_DIR" || {
		log ERROR "Cannot access work directory: $WORK_DIR"
		return 1
	}

	flake::init || return 1

	if [[ -n "$module" ]]; then
		flake::update "$module"
	else
		local inputs=($(flake::list_inputs))

		if [[ ${#inputs[@]} -eq 0 ]]; then
			log WARN "No flake inputs found"
			return 1
		fi

		if [[ $(config::get AUTO_MODE) == true ]]; then
			flake::update
		else
			echo -e "${C_CYAN}Available inputs:${C_RESET}"
			local i=1
			for input in "${inputs[@]}"; do
				echo "  $i) $input"
				((i++))
			done
			echo "  a) Update all"
			echo "  q) Cancel"

			printf "${C_YELLOW}Select input to update:${C_RESET} "
			read -r choice

			case "$choice" in
			a | A) flake::update ;;
			q | Q) return 0 ;;
			[0-9]*)
				if [[ $choice -le ${#inputs[@]} ]]; then
					flake::update "${inputs[$((choice - 1))]}"
				else
					log ERROR "Invalid selection"
					return 1
				fi
				;;
			*) log ERROR "Invalid choice" ;;
			esac
		fi
	fi
}

cmd_build() {
	log INFO "Building NixOS configuration"

	cd "$WORK_DIR" || {
		log ERROR "Cannot access work directory: $WORK_DIR"
		return 1
	}

	flake::init || return 1
	host::setup || return 1

	flake::build
}

cmd_switch() {
	cmd_build "$@"
}

cmd_rollback() {
	log INFO "Rolling back to previous configuration"

	if confirm "Rollback to previous configuration?"; then
		if sudo nixos-rebuild switch --rollback; then
			log INFO "Rollback successful"
		else
			log ERROR "Rollback failed"
			return 1
		fi
	fi
}

cmd_health() {
	# Make sure logging is properly initialized
	[[ -z "${LOG_FD:-}" ]] && log::init "INFO"

	# Run the health check and display directly to console
	echo -e "\n${C_CYAN}=== System Health Check ===${C_RESET}\n"

	# Memory
	local mem_info=$(free -h | awk '/^Mem:/ {printf "Total: %s, Used: %s, Free: %s", $2, $3, $4}')
	echo -e "${C_GREEN}Memory:${C_RESET} $mem_info"

	# CPU
	local cpu_load=$(uptime | awk -F'load average:' '{print $2}')
	echo -e "${C_GREEN}CPU Load:${C_RESET}$cpu_load"

	# Disk usage
	echo -e "${C_GREEN}Disk Usage:${C_RESET}"
	df -h / /home /nix/store 2>/dev/null | awk 'NR>1 {printf "  %s: %s used of %s (%s)\n", $6, $3, $2, $5}'

	# Nix store
	if has_command nix-store; then
		local store_size=$(du -sh /nix/store 2>/dev/null | cut -f1)
		echo -e "${C_GREEN}Nix Store:${C_RESET} ${store_size:-unknown}"
	fi

	# Network
	if ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
		echo -e "${C_GREEN}Network:${C_RESET} Connected"
	else
		echo -e "${C_YELLOW}Network:${C_RESET} No internet connection"
	fi

	# System info
	echo -e "${C_GREEN}Hostname:${C_RESET} $(hostname)"
	echo -e "${C_GREEN}Kernel:${C_RESET} $(uname -r)"
	echo -e "${C_GREEN}Uptime:${C_RESET} $(uptime -p 2>/dev/null || uptime | awk -F'up' '{print $2}' | awk -F',' '{print $1}')"

	# NixOS version
	if [[ -f /etc/os-release ]]; then
		local nixos_version=$(grep "^VERSION=" /etc/os-release | cut -d'"' -f2)
		echo -e "${C_GREEN}NixOS Version:${C_RESET} ${nixos_version:-unknown}"
	fi

	# Current generation
	if [[ -d /nix/var/nix/profiles ]]; then
		local current_gen=$(readlink /nix/var/nix/profiles/system 2>/dev/null | grep -oP 'system-\K[0-9]+' || echo "unknown")
		echo -e "${C_GREEN}Current Generation:${C_RESET} $current_gen"
	fi

	echo -e "\n${C_CYAN}=== Health Check Complete ===${C_RESET}\n"
}

cmd_cache() {
	local action="${1:-status}"

	case "$action" in
	status)
		local cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1 || echo "0")
		local cache_files=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l)

		echo -e "${C_CYAN}Cache Status:${C_RESET}"
		echo "  Location: $CACHE_DIR"
		echo "  Size: $cache_size"
		echo "  Files: $cache_files"
		echo "  TTL: $((CACHE_TTL_VAR / 86400)) days"
		echo "  Max size: $((CACHE_MAX_SIZE_VAR / 1024))GB"
		;;
	clean | clear)
		if confirm "Clear cache?"; then
			rm -rf "$CACHE_DIR"/*
			log INFO "Cache cleared"
		fi
		;;
	*)
		log ERROR "Unknown cache action: $action"
		echo "Usage: cache [status|clean]"
		return 1
		;;
	esac
}

cmd_backup() {
	local action="${1:-list}"
	local target="${2:-}"

	case "$action" in
	create)
		if [[ -z "$target" ]]; then
			# Backup flake.lock by default
			if [[ -f "$WORK_DIR/$FLAKE_LOCK" ]]; then
				backup::create "$WORK_DIR/$FLAKE_LOCK" "flake-lock"
			else
				backup::create "$WORK_DIR" "full-config"
			fi
		else
			backup::create "$target" "$(basename "$target")"
		fi
		;;
	restore)
		backup::restore "${target:-flake-lock}" "$WORK_DIR"
		;;
	list)
		echo -e "${C_CYAN}Available backups:${C_RESET}"
		find "$BACKUP_DIR" -name "*.tar.gz" -type f \
			-printf "%T+ %p\n" 2>/dev/null | sort -r |
			while read -r date file; do
				size=$(du -h "$file" | cut -f1)
				echo "  $(basename "$file") ($size) - $date"
			done
		;;
	*)
		log ERROR "Unknown backup action: $action"
		echo "Usage: backup [create|restore|list] [target]"
		return 1
		;;
	esac
}

cmd_profile() {
	local action="${1:-list}"

	case "$action" in
	list)
		echo -e "${C_CYAN}System profiles:${C_RESET}"
		sudo nix-env --list-generations -p /nix/var/nix/profiles/system
		;;
	switch)
		local generation="${2:-}"
		[[ -z "$generation" ]] && {
			log ERROR "Generation number required"
			return 1
		}
		sudo nix-env --switch-generation "$generation" -p /nix/var/nix/profiles/system
		;;
	delete)
		local generation="${2:-}"
		[[ -z "$generation" ]] && {
			log ERROR "Generation number required"
			return 1
		}
		sudo nix-env --delete-generations "$generation" -p /nix/var/nix/profiles/system
		;;
	gc)
		if confirm "Run garbage collection?"; then
			sudo nix-collect-garbage -d
		fi
		;;
	*)
		log ERROR "Unknown profile action: $action"
		echo "Usage: profile [list|switch|delete|gc] [generation]"
		return 1
		;;
	esac
}

# Helper Functions
setup_directories() {
	local dirs=(
		"$HOME/Pictures/wallpapers/others"
		"$HOME/Pictures/wallpapers/nixos"
		"$CONFIG_DIR"
		"$CACHE_DIR"
		"$BACKUP_DIR"
		"$(dirname "$LOG_FILE")"
	)

	local total=${#dirs[@]}
	local idx=0

	for dir in "${dirs[@]}"; do
		((idx++))
		progress::substep_show "Creating directory ($idx/$total): $dir"
		mkdir -p "$dir"
		log DEBUG "Created directory: $dir"
	done
}

setup_wallpapers() {
	local wallpaper_src="$WORK_DIR/wallpapers"
	local wallpaper_dst="$WALLPAPER_DIR"

	if [[ -d "$wallpaper_src" ]]; then
		local cache_key=$(cache::key "wallpapers-$(date +%Y%m%d)")

		if ! cache::get "$cache_key" >/dev/null; then
			cp -r "$wallpaper_src"/* "$wallpaper_dst/" 2>/dev/null || true
			tar -czf - -C "$wallpaper_dst" . | cache::set "$cache_key"
		else
			cache::get "$cache_key" | tar -xzf - -C "$wallpaper_dst"
		fi

		log INFO "Wallpapers configured"
	else
		log WARN "Wallpaper source not found: $wallpaper_src"
	fi
}

show_summary() {
	echo
	echo -e "${C_GREEN}╔════════════════════════════════════╗${C_RESET}"
	echo -e "${C_GREEN}║  Installation Summary              ║${C_RESET}"
	echo -e "${C_GREEN}╠════════════════════════════════════╣${C_RESET}"
	echo -e "${C_GREEN}║${C_RESET} Username: ${C_YELLOW}$(config::get USERNAME)${C_RESET}"
	echo -e "${C_GREEN}║${C_RESET} Hostname: ${C_YELLOW}$(config::get HOSTNAME)${C_RESET}"
	echo -e "${C_GREEN}║${C_RESET} Profile:  ${C_YELLOW}$(config::get PROFILE || "default")${C_RESET}"
	echo -e "${C_GREEN}║${C_RESET} Config:   ${C_YELLOW}${CONFIG_DIR}${C_RESET}"
	echo -e "${C_GREEN}║${C_RESET} Work Dir: ${C_YELLOW}${WORK_DIR}${C_RESET}"
	echo -e "${C_GREEN}║${C_RESET} Cache:    ${C_YELLOW}${CACHE_DIR}${C_RESET}"
	echo -e "${C_GREEN}║${C_RESET} Backup:   ${C_YELLOW}${BACKUP_DIR}${C_RESET}"
	echo -e "${C_GREEN}╚════════════════════════════════════╝${C_RESET}"
}

show_menu() {
	clear
	echo -e "${C_CYAN}"
	cat <<'EOF'
    ╔╗╔╦═╗ ╦╔═╗╔═╗
    ║║║║╔╩╦╝║ ║╚═╗
    ╝╚╝╩╩ ╚═╚═╝╚═╝
    Installation Tool v3.0
EOF
	echo -e "${C_RESET}"

	local options=(
		"1) Install System"
		"2) Update Flake"
		"3) Build Configuration"
		"4) Health Check"
		"5) Cache Management"
		"6) Backup Management"
		"7) Profile Management"
		"8) Advanced Options"
		"0) Exit"
	)

	echo -e "${C_CYAN}Main Menu:${C_RESET}\n"
	for opt in "${options[@]}"; do
		echo "  $opt"
	done

	printf "\n${C_YELLOW}Select option:${C_RESET} "
	read -r choice

	case "$choice" in
	1) cmd_install ;;
	2) cmd_update ;;
	3) cmd_build ;;
	4) cmd_health ;;
	5) show_cache_menu ;;
	6) show_backup_menu ;;
	7) show_profile_menu ;;
	8) show_advanced_menu ;;
	0) exit 0 ;;
	*)
		log ERROR "Invalid option"
		sleep 2
		show_menu
		;;
	esac

	printf "\n${C_YELLOW}Press Enter to continue...${C_RESET}"
	read -r
	show_menu
}

show_cache_menu() {
	clear
	echo -e "${C_CYAN}Cache Management${C_RESET}\n"
	echo "  1) Show status"
	echo "  2) Clear cache"
	echo "  3) Back"

	printf "\n${C_YELLOW}Select option:${C_RESET} "
	read -r choice

	case "$choice" in
	1) cmd_cache status ;;
	2) cmd_cache clear ;;
	3) return ;;
	*) log ERROR "Invalid option" ;;
	esac
}

show_backup_menu() {
	clear
	echo -e "${C_CYAN}Backup Management${C_RESET}\n"
	echo "  1) List backups"
	echo "  2) Create backup"
	echo "  3) Restore backup"
	echo "  4) Back"

	printf "\n${C_YELLOW}Select option:${C_RESET} "
	read -r choice

	case "$choice" in
	1) cmd_backup list ;;
	2) cmd_backup create ;;
	3)
		cmd_backup list
		printf "\n${C_YELLOW}Enter backup name:${C_RESET} "
		read -r name
		cmd_backup restore "$name"
		;;
	4) return ;;
	*) log ERROR "Invalid option" ;;
	esac
}

show_profile_menu() {
	clear
	echo -e "${C_CYAN}Profile Management${C_RESET}\n"
	echo "  1) List profiles"
	echo "  2) Switch profile"
	echo "  3) Delete profile"
	echo "  4) Garbage collection"
	echo "  5) Back"

	printf "\n${C_YELLOW}Select option:${C_RESET} "
	read -r choice

	case "$choice" in
	1) cmd_profile list ;;
	2)
		cmd_profile list
		printf "\n${C_YELLOW}Enter generation number:${C_RESET} "
		read -r gen
		cmd_profile switch "$gen"
		;;
	3)
		cmd_profile list
		printf "\n${C_YELLOW}Enter generation to delete:${C_RESET} "
		read -r gen
		cmd_profile delete "$gen"
		;;
	4) cmd_profile gc ;;
	5) return ;;
	*) log ERROR "Invalid option" ;;
	esac
}

show_advanced_menu() {
	clear
	echo -e "${C_CYAN}Advanced Options${C_RESET}\n"
	echo "  1) System validation"
	echo "  2) Rollback system"
	echo "  3) Edit configuration"
	echo "  4) View logs"
	echo "  5) Back"

	printf "\n${C_YELLOW}Select option:${C_RESET} "
	read -r choice

	case "$choice" in
	1) system::validate ;;
	2) cmd_rollback ;;
	3)
		config::save
		${EDITOR:-nano} "${CONFIG_DIR}/config.json"
		config::load
		;;
	4)
		if [[ -f "$LOG_FILE" ]]; then
			less +G "$LOG_FILE"
		else
			log WARN "No log file found at: $LOG_FILE"
		fi
		;;
	5) return ;;
	*) log ERROR "Invalid option" ;;
	esac
}

# Main Entry Point
main() {
	# Check if running as root
	if [[ $EUID -eq 0 ]]; then
		echo -e "${C_RED}Error: Do not run as root!${C_RESET}" >&2
		exit 1
	fi

	# Ensure we're in the correct directory
	cd "$WORK_DIR" 2>/dev/null || {
		echo -e "${C_RED}Error: Cannot access work directory: $WORK_DIR${C_RESET}" >&2
		echo "Please ensure you're running this script from the correct location."
		exit 1
	}

	# Initialize logging FIRST
	log::init "${LOG_LEVEL:-INFO}"

	# Load configuration
	config::load

	# Parse arguments or show menu
	if [[ $# -gt 0 ]]; then
		parse_args "$@"
	else
		show_menu
	fi
}

# Handle signals
trap 'echo -e "\n${C_YELLOW}Interrupted!${C_RESET}"; exit 130' INT TERM

# Run main
main "$@"
