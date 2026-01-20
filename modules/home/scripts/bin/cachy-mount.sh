#!/usr/bin/env bash
# cachy-mount.sh
# ------------------------------------------------------------------------------
# On-demand mounting of CachyOS BTRFS subvolumes under a base directory.
#
# Why this exists:
# - `findmnt --target /path` returns the covering mount (often "/") which can
#   mislead naive "is mounted" checks. We only accept a mount when TARGET == path.
# - BTRFS installs commonly use subvolumes (@, @home, ...) and we want a clean
#   mount layout on demand (and an easy chroot).
#
# Layout (TARGET -> subvolume):
#   <base>/root       -> @
#   <base>/home       -> @home
#   <base>/cache      -> @cache
#   <base>/log        -> @log
#   <base>/root-user  -> @root
#   <base>/srv        -> @srv
#   <base>/tmp        -> @tmp
#
# Commands:
#   mount | umount | status | chroot | help
# ------------------------------------------------------------------------------

set -euo pipefail

DEFAULT_UUID="6784b6e4-7e6e-4662-9554-7bb313b427ee"
DEFAULT_BASE="/cachy"

# Common BTRFS mount options.
# Note: "ssd" and "discard=async" are usually auto-detected; harmless if present.
OPTS_COMMON=("noatime" "compress=zstd" "space_cache=v2")

# subvolume -> target dir name (under BASE)
declare -A SUBVOLS=(
  ["@"]="root"
  ["@home"]="home"
  ["@cache"]="cache"
  ["@log"]="log"
  ["@root"]="root-user"
  ["@srv"]="srv"
  ["@tmp"]="tmp"
)

usage() {
  cat <<'EOF'
Usage:
  sudo cachy-mount.sh mount   [--uuid <UUID>] [--base <DIR>]
  sudo cachy-mount.sh umount  [--base <DIR>]
  sudo cachy-mount.sh status  [--base <DIR>]
  sudo cachy-mount.sh chroot  [--base <DIR>]
  sudo cachy-mount.sh help

Examples:
  sudo cachy-mount.sh mount
  sudo cachy-mount.sh status
  sudo cachy-mount.sh chroot
  sudo cachy-mount.sh umount
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

need_root() {
  [[ ${EUID:-0} -eq 0 ]] || die "Run as root (use sudo)."
}

dev_from_uuid() {
  local uuid="$1"
  echo "/dev/disk/by-uuid/${uuid}"
}

# Return 0 only if PATH is an actual mountpoint where TARGET == PATH.
is_mountpoint_exact() {
  local path="$1"
  local tgt
  tgt="$(findmnt -rn --target "$path" -o TARGET 2>/dev/null || true)"
  [[ "$tgt" == "$path" ]]
}

# Mount subvolume if the target isn't already a mountpoint.
mount_subvol() {
  local dev="$1" subvol="$2" target="$3"
  mkdir -p "$target"

  if is_mountpoint_exact "$target"; then
    return 0
  fi

  local opts="subvol=${subvol}"
  for o in "${OPTS_COMMON[@]}"; do
    opts="${opts},${o}"
  done

  mount -t btrfs -o "$opts" "$dev" "$target"
}

umount_target() {
  local target="$1"
  if is_mountpoint_exact "$target"; then
    umount "$target"
  fi
}

# Choose an interactive shell inside the chroot.
pick_shell() {
  local root="$1"
  if [[ -x "${root}/bin/bash" ]]; then
    echo "/bin/bash"
  elif [[ -x "${root}/usr/bin/bash" ]]; then
    echo "/usr/bin/bash"
  elif [[ -x "${root}/bin/sh" ]]; then
    echo "/bin/sh"
  else
    return 1
  fi
}

cmd_mount() {
  local uuid="$DEFAULT_UUID"
  local base="$DEFAULT_BASE"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --uuid)
      uuid="${2:-}"
      shift 2
      ;;
    --base)
      base="${2:-}"
      shift 2
      ;;
    *) die "Unknown option: $1" ;;
    esac
  done

  local dev
  dev="$(dev_from_uuid "$uuid")"
  [[ -e "$dev" ]] || die "Device not found: $dev"

  mkdir -p "$base"

  # Mount root first (useful for chroot or inspection).
  mount_subvol "$dev" "@" "${base}/${SUBVOLS[@]:0:0}" 2>/dev/null || true
  mount_subvol "$dev" "@" "${base}/${SUBVOLS[@]:0:0}" 2>/dev/null || true
  mount_subvol "$dev" "@" "${base}/${SUBVOLS[@]:0:0}" 2>/dev/null || true

  mount_subvol "$dev" "@" "${base}/${SUBVOLS["@"]}"

  # Mount the rest.
  for sv in "@home" "@cache" "@log" "@root" "@srv" "@tmp"; do
    mount_subvol "$dev" "$sv" "${base}/${SUBVOLS[$sv]}"
  done
}

cmd_umount() {
  local base="$DEFAULT_BASE"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --base)
      base="${2:-}"
      shift 2
      ;;
    *) die "Unknown option: $1" ;;
    esac
  done

  # Unmount in reverse order.
  umount_target "${base}/tmp"
  umount_target "${base}/srv"
  umount_target "${base}/root-user"
  umount_target "${base}/log"
  umount_target "${base}/cache"
  umount_target "${base}/home"
  umount_target "${base}/root"
}

cmd_status() {
  local base="$DEFAULT_BASE"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --base)
      base="${2:-}"
      shift 2
      ;;
    *) die "Unknown option: $1" ;;
    esac
  done

  echo "Base: $base"
  for d in root home cache log root-user srv tmp; do
    local p="${base}/${d}"
    if is_mountpoint_exact "$p"; then
      findmnt -rn --target "$p" -o TARGET,SOURCE,FSTYPE,OPTIONS
    else
      echo "$p : (not mounted)"
    fi
  done
}

cmd_chroot() {
  local base="$DEFAULT_BASE"

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --base)
      base="${2:-}"
      shift 2
      ;;
    *) die "Unknown option: $1" ;;
    esac
  done

  local root="${base}/root"
  is_mountpoint_exact "$root" || die "Not mounted: $root (run: sudo $0 mount)"

  local shell
  shell="$(pick_shell "$root" 2>/dev/null || true)"
  [[ -n "$shell" ]] || die "No shell found inside chroot (no /bin/bash, /usr/bin/bash, or /bin/sh)."

  # Bind-mount runtime FS for a functional chroot.
  mkdir -p "${root}/"{dev,proc,sys,run}
  mount --bind /dev "${root}/dev"
  mount --bind /proc "${root}/proc"
  mount --bind /sys "${root}/sys"
  mount --bind /run "${root}/run"

  echo "Entering chroot: $root ($shell)"
  set +e
  chroot "$root" "$shell" -l
  local rc=$?
  set -e

  # Cleanup bind mounts after exiting chroot.
  umount "${root}/run" 2>/dev/null || true
  umount "${root}/sys" 2>/dev/null || true
  umount "${root}/proc" 2>/dev/null || true
  umount "${root}/dev" 2>/dev/null || true

  exit "$rc"
}

main() {
  need_root

  local cmd="${1:-help}"
  shift || true

  case "$cmd" in
  mount) cmd_mount "$@" ;;
  umount | unmount) cmd_umount "$@" ;;
  status) cmd_status "$@" ;;
  chroot) cmd_chroot "$@" ;;
  help | -h | --help) usage ;;
  *)
    usage
    die "Unknown command: $cmd"
    ;;
  esac
}

main "$@"
