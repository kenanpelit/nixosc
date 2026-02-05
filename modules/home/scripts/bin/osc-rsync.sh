#!/usr/bin/env bash
# osc-rsync.sh - single rsync entrypoint (presets + backup + retry)
#
# This replaces legacy helpers:
# - rsync_backup / osc-rsync_backup
# - rsync-retry
# - rsync-tool
#
# Logs: ~/.logs/osc-rsync/

set -Eeuo pipefail

LOG_ROOT="${HOME}/.logs/osc-rsync"
mkdir -p "$LOG_ROOT"

timestamp() { date "+%Y-%m-%d %H:%M:%S"; }
log() { printf "%s %s\n" "$(timestamp)" "$*" | tee -a "${LOG_FILE:-/dev/null}" >&2; }
die() { log "ERROR: $*"; exit 1; }

show_help() {
	cat <<'EOF'
osc-rsync - rsync presets + backup + retry

Usage:
  osc-rsync <preset> <src> <dest> [--delete] [--dry-run] [-- <extra rsync args...>]
  osc-rsync backup <dest> [--delete] [--dry-run]
  osc-rsync retry <src> <dest> [--tries N] [--delay S] [--dry-run] [-- <extra rsync args...>]

Presets:
  std   Standard
  net   Network (preserve more metadata)
  loc   Local/LAN (no compression)
  web   Internet/large files

Examples:
  osc-rsync std ./src/ user@host:/backup/src/
  osc-rsync web ./big/ user@host:/backup/big/ --delete
  osc-rsync backup /mnt/backup/home --dry-run
  osc-rsync retry ./src/ user@host:/backup/src/ --tries 5 --delay 2

Legacy compatibility (still supported):
  osc-rsync -t <std|net|loc|web> -s <src> -d <dest> [-r]
EOF
}

ensure_rsync() { command -v rsync >/dev/null 2>&1 || die "rsync not found"; }

rsync_preset_args() {
	local preset="$1"
	case "$preset" in
	std) echo "-avzPh --info=progress2 --stats" ;;
	net) echo "-axAXvzE --compress-level=9 --numeric-ids --info=progress2 --stats" ;;
	loc) echo "-avxHAXW --no-compress --numeric-ids --info=progress2 --stats" ;;
	web) echo "-avzP --compress-level=9 --partial-dir=.rsync-partial --append-verify --timeout=120 --info=progress2 --stats" ;;
	*) die "unknown preset: $preset" ;;
	esac
}

do_transfer() {
	local preset="$1"
	local src="$2"
	local dest="$3"
	local delete_flag="$4"
	local dry_run="$5"
	shift 5

	ensure_rsync

	LOG_FILE="${LOG_ROOT}/transfer-$(date +%Y%m%d-%H%M%S)-$$.log"
	log "Starting: preset=$preset src=$src dest=$dest delete=$delete_flag dry_run=$dry_run"

	local args
	args="$(rsync_preset_args "$preset")"

	# shellcheck disable=SC2086
	rsync $args ${delete_flag:+--delete} ${dry_run:+--dry-run} "$src" "$dest" "$@" 2>&1 | tee -a "$LOG_FILE"
	log "Done."
}

do_backup() {
	local dest="$1"
	local delete_flag="$2"
	local dry_run="$3"

	ensure_rsync

	local src="$HOME"
	local exclude_file="$HOME/.rsync-homedir-excludes"

	[[ -d "$dest" ]] || die "backup destination not found: $dest"

	LOG_FILE="${LOG_ROOT}/backup-$(date +%Y%m%d-%H%M%S)-$$.log"
	log "Backup: $src -> $dest delete=$delete_flag dry_run=$dry_run"
	[[ -f "$exclude_file" ]] && log "Using excludes: $exclude_file"

	local rsync_args=(
		-avzhPr
		--stats
		--partial
		--append
		--append-verify
		--info=progress2
	)

	[[ -f "$exclude_file" ]] && rsync_args+=(--exclude-from="$exclude_file")
	[[ -n "$delete_flag" ]] && rsync_args+=(--delete)
	[[ -n "$dry_run" ]] && rsync_args+=(--dry-run)

	rsync "${rsync_args[@]}" "$src" "$dest" 2>&1 | tee -a "$LOG_FILE"
	log "Backup done."
}

do_retry() {
	local src="$1"
	local dest="$2"
	local tries="$3"
	local delay="$4"
	local dry_run="$5"
	shift 5

	ensure_rsync

	LOG_FILE="${LOG_ROOT}/retry-$(date +%Y%m%d-%H%M%S)-$$.log"
	log "Retry: src=$src dest=$dest tries=$tries delay=${delay}s dry_run=$dry_run"

	local i=0
	while :; do
		i=$((i + 1))
		log "Attempt $i/$tries"
		# shellcheck disable=SC2086
		if rsync -avzhPr --stats --partial --append --append-verify ${dry_run:+--dry-run} "$src" "$dest" "$@" 2>&1 | tee -a "$LOG_FILE"; then
			log "Success."
			return 0
		fi

		if [[ "$i" -ge "$tries" ]]; then
			die "failed after $tries attempts"
		fi
		log "Retrying in ${delay}s..."
		sleep "$delay"
	done
}

legacy_mode() {
	local transfer_type=""
	local source=""
	local dest=""
	local delete_flag=""

	while getopts ":t:s:d:rh" opt; do
		case $opt in
		t) transfer_type=$OPTARG ;;
		s) source=$OPTARG ;;
		d) dest=$OPTARG ;;
		r) delete_flag="1" ;;
		h) show_help; exit 0 ;;
		\?) die "Invalid option: -$OPTARG" ;;
		:) die "Option -$OPTARG requires an argument." ;;
		esac
	done

	[[ -n "$transfer_type" && -n "$source" && -n "$dest" ]] || die "Missing required parameters (legacy mode). Use --help."
	do_transfer "$transfer_type" "$source" "$dest" "$delete_flag" "" || exit $?
}

main() {
	if [[ $# -eq 0 ]]; then
		show_help
		exit 0
	fi

	case "$1" in
	-h | --help | help)
		show_help
		exit 0
		;;
	-t)
		legacy_mode "$@"
		;;
	backup)
		shift
		[[ $# -ge 1 ]] || die "Usage: osc-rsync backup <dest> [--delete] [--dry-run]"
		local dest="$1"
		shift
		local delete_flag="" dry_run=""
		while [[ $# -gt 0 ]]; do
			case "$1" in
			--delete) delete_flag="1" ;;
			--dry-run) dry_run="1" ;;
			-h | --help) show_help; exit 0 ;;
			*) die "Unknown option: $1" ;;
			esac
			shift
		done
		do_backup "$dest" "$delete_flag" "$dry_run"
		;;
	retry)
		shift
		[[ $# -ge 2 ]] || die "Usage: osc-rsync retry <src> <dest> [--tries N] [--delay S] [--dry-run] [-- ...]"
		local src="$1"
		local dest="$2"
		shift 2
		local tries=10 delay=2 dry_run=""
		while [[ $# -gt 0 ]]; do
			case "$1" in
			--tries) tries="${2:-}"; shift ;;
			--delay) delay="${2:-}"; shift ;;
			--dry-run) dry_run="1" ;;
			--) shift; break ;;
			-h | --help) show_help; exit 0 ;;
			*) break ;;
			esac
			shift
		done
		[[ "$tries" =~ ^[0-9]+$ ]] || die "--tries must be a number"
		[[ "$delay" =~ ^[0-9]+$ ]] || die "--delay must be a number"
		do_retry "$src" "$dest" "$tries" "$delay" "$dry_run" "$@"
		;;
	std | net | loc | web)
		local preset="$1"
		shift
		[[ $# -ge 2 ]] || die "Usage: osc-rsync $preset <src> <dest> [--delete] [--dry-run] [-- ...]"
		local src="$1"
		local dest="$2"
		shift 2
		local delete_flag="" dry_run=""
		while [[ $# -gt 0 ]]; do
			case "$1" in
			--delete) delete_flag="1" ;;
			--dry-run) dry_run="1" ;;
			--) shift; break ;;
			-h | --help) show_help; exit 0 ;;
			*) break ;;
			esac
			shift
		done
		do_transfer "$preset" "$src" "$dest" "$delete_flag" "$dry_run" "$@"
		;;
	*)
		die "Unknown command: $1 (use --help)"
		;;
	esac
}

main "$@"
