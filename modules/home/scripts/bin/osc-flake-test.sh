#!/usr/bin/env bash
# ==============================================================================
# OSC-FLAKE-TEST: Quick build/check helper for nixosc (Snowfall Edition)
# ==============================================================================
# Purpose:
#   Lightweight helper for common dev/test loops:
#     - List available hosts / home profiles
#     - Build NixOS host or Home Manager profile (no switch)
#     - Run flake checks
#     - Locate / syntax-check a module's default.nix
#
# Notes:
#   - This script is intentionally conservative: it uses `nix build` by default
#     (no activation). For switching, use `install.sh` or `nixos-rebuild`.
#   - Uses `--no-write-lock-file` to avoid dirtying `flake.lock` during tests.
#
# Env:
#   NIXOSC_DIR   Repo path (default: $HOME/.nixosc)
#   NIX_FLAGS    Extra args passed to `nix` (string; split on spaces)
#
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

VERSION="3.0.0"
SCRIPT_NAME="$(basename "$0")"

if [[ -t 1 ]]; then
	BOLD=$'\e[1m'
	RED=$'\e[31m'
	GRN=$'\e[32m'
	YLW=$'\e[33m'
	BLU=$'\e[34m'
	CYN=$'\e[36m'
	RST=$'\e[0m'
else
	BOLD="" RED="" GRN="" YLW="" BLU="" CYN="" RST=""
fi

die() { printf "%s%sERROR:%s %s\n" "${RED}" "${BOLD}" "${RST}" "$*" >&2; exit 1; }
info() { printf "%s%sℹ%s  %s\n" "${BLU}" "${BOLD}" "${RST}" "$*"; }
ok() { printf "%s%s✓%s  %s\n" "${GRN}" "${BOLD}" "${RST}" "$*"; }
warn() { printf "%s%s⚠%s  %s\n" "${YLW}" "${BOLD}" "${RST}" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

repo_dir() {
	local dir="${NIXOSC_DIR:-"$HOME/.nixosc"}"
	[[ -f "$dir/flake.nix" ]] || die "flake.nix not found under: $dir (set NIXOSC_DIR to override)"
	printf "%s" "$dir"
}

detect_arch() {
	local machine
	machine="$(uname -m 2>/dev/null || true)"
	case "$machine" in
	x86_64) printf "x86_64-linux" ;;
	aarch64 | arm64) printf "aarch64-linux" ;;
	*) printf "x86_64-linux" ;;
	esac
}

usage() {
	cat <<EOF
${BOLD}${CYN}${SCRIPT_NAME}${RST} v${VERSION} - nixosc quick build/check helper

${BOLD}Usage:${RST}
  ${SCRIPT_NAME} list hosts
  ${SCRIPT_NAME} list homes
  ${SCRIPT_NAME} list modules <home|nixos>
  ${SCRIPT_NAME} build host <host>
  ${SCRIPT_NAME} build home <user@host>
  ${SCRIPT_NAME} check
  ${SCRIPT_NAME} module path <home|nixos> <name>
  ${SCRIPT_NAME} module syntax <home|nixos> <name>

${BOLD}Examples:${RST}
  ${SCRIPT_NAME} list hosts
  ${SCRIPT_NAME} build host hay
  ${SCRIPT_NAME} build home kenan@hay
  ${SCRIPT_NAME} list modules nixos
  ${SCRIPT_NAME} module path nixos kernel
  ${SCRIPT_NAME} module syntax home niri

${BOLD}Environment:${RST}
  NIXOSC_DIR   Repo path (default: \$HOME/.nixosc)
  NIX_FLAGS    Extra args passed to \`nix\` (string)

EOF
}

list_hosts() {
	local root arch path
	root="$(repo_dir)"
	arch="$(detect_arch)"
	path="$root/systems/$arch"

	[[ -d "$path" ]] || die "systems dir not found: $path"
	find "$path" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

list_homes() {
	local root arch path
	root="$(repo_dir)"
	arch="$(detect_arch)"
	path="$root/homes/$arch"

	[[ -d "$path" ]] || die "homes dir not found: $path"
	find "$path" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

list_modules() {
	local scope="${1:-}"
	local root path
	root="$(repo_dir)"
	[[ "$scope" == "home" || "$scope" == "nixos" ]] || die "scope must be: home|nixos"
	path="$root/modules/$scope"
	[[ -d "$path" ]] || die "modules dir not found: $path"

	find "$path" -mindepth 1 -maxdepth 1 -type d -print0 |
		while IFS= read -r -d '' dir; do
			[[ -f "$dir/default.nix" ]] && basename "$dir"
		done | sort
}

module_default_nix() {
	local scope="${1:-}"
	local name="${2:-}"
	local root path
	root="$(repo_dir)"
	[[ "$scope" == "home" || "$scope" == "nixos" ]] || die "scope must be: home|nixos"
	[[ -n "$name" ]] || die "module name required"
	path="$root/modules/$scope/$name/default.nix"
	[[ -f "$path" ]] || die "module not found: $path"
	printf "%s" "$path"
}

nix_cmd_base=(
	nix
	--extra-experimental-features "nix-command flakes"
	--option accept-flake-config true
	--option warn-dirty false
	--no-write-lock-file
)

run_nix() {
	local -a argv=("${nix_cmd_base[@]}")
	if [[ -n "${NIX_FLAGS:-}" ]]; then
		# shellcheck disable=SC2206
		local -a extra=(${NIX_FLAGS})
		argv+=("${extra[@]}")
	fi
	argv+=("$@")

	info "Running: ${argv[*]}"
	"${argv[@]}"
}

cmd_build_host() {
	local host="${1:-}"
	[[ -n "$host" ]] || die "host required (try: ${SCRIPT_NAME} list hosts)"
	local root
	root="$(repo_dir)"
	run_nix build --print-out-paths --no-link "$root#nixosConfigurations.${host}.config.system.build.toplevel"
	ok "Build finished for host: $host"
}

cmd_build_home() {
	local profile="${1:-}"
	[[ -n "$profile" ]] || die "home profile required (try: ${SCRIPT_NAME} list homes)"
	local root
	root="$(repo_dir)"
	run_nix build --print-out-paths --no-link "$root#homeConfigurations.\"${profile}\".activationPackage"
	ok "Build finished for home: $profile"
}

cmd_check() {
	local root
	root="$(repo_dir)"
	run_nix flake check "$root"
	ok "flake check finished"
}

cmd_module_path() {
	local scope="${1:-}"
	local name="${2:-}"
	module_default_nix "$scope" "$name"
	echo
}

cmd_module_syntax() {
	local scope="${1:-}"
	local name="${2:-}"
	local path
	path="$(module_default_nix "$scope" "$name")"
	have nix-instantiate || die "nix-instantiate not found"
	info "Parsing: $path"
	nix-instantiate --parse "$path" >/dev/null
	ok "Syntax OK: $scope/$name"
}

main() {
	local cmd="${1:-}"
	shift || true

	case "$cmd" in
	"" | -h | --help | help)
		usage
		;;
	list)
		local sub="${1:-}"
		shift || true
		case "$sub" in
		hosts) list_hosts ;;
		homes) list_homes ;;
		modules) list_modules "${1:-}" ;;
		*) die "unknown list subcommand: $sub" ;;
		esac
		;;
	build)
		local sub="${1:-}"
		shift || true
		case "$sub" in
		host) cmd_build_host "${1:-}" ;;
		home) cmd_build_home "${1:-}" ;;
		*) die "unknown build subcommand: $sub" ;;
		esac
		;;
	check) cmd_check ;;
	module)
		local sub="${1:-}"
		shift || true
		case "$sub" in
		path) cmd_module_path "${1:-}" "${2:-}" ;;
		syntax) cmd_module_syntax "${1:-}" "${2:-}" ;;
		*) die "unknown module subcommand: $sub" ;;
		esac
		;;
	*)
		die "unknown command: $cmd (try: ${SCRIPT_NAME} --help)"
		;;
	esac
}

main "$@"
