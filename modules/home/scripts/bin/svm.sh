#!/usr/bin/env bash
# svm.sh — SVM (Simple VM) multi-profile manager (QEMU/KVM)
#
# Usage:
#   svm <profile> [command] [options]
#   svm menu [command] [options]   # interactive profile picker
#
# Profiles:
#   arch | nixos | ubuntu | cachy
#
# Commands:
#   install    Boot from ISO (first install)
#   start      Normal start (default)
#   stop       Shutdown the VM (graceful, then force)
#   status     Show whether PID is alive
#   connect    SSH into the guest (user networking port-forward)
#   console    QEMU monitor console (unix socket)
#   reset      Remove disk/vars files (DANGEROUS)
#
# Notes:
# - This file intentionally keeps the original SVM “core” logic in one place and
#   switches defaults via profile selection.
# - Wayland/TTY friendly defaults are preserved (for Sway/Hyprland/Niri usage).

set -euo pipefail

# ============================================================================
# Environment Setup for Wayland (fast; called only when starting a GUI VM)
# ============================================================================
setup_wayland_environment() {
  export NO_AT_BRIDGE=1
  export GVFS_DISABLE_FUSE=1

  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    export QT_QPA_PLATFORM=wayland
    export GDK_BACKEND=wayland
    export SDL_VIDEODRIVER=wayland
    export CLUTTER_BACKEND=wayland
  fi
}

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

readonly SCRIPT_NAME="$(basename "$0")"
PROFILE=""

profiles_list() {
  cat <<'EOF'
  arch    - Arch Linux
  nixos   - NixOS
  ubuntu  - Ubuntu
  cachy   - CachyOS
EOF
}

show_help() {
  cat <<EOF
SVM - Simple VM Manager (multi-profile)

Usage:
  ${SCRIPT_NAME} <profile> [command] [options]
  ${SCRIPT_NAME} menu [command] [options]

Profiles:
$(profiles_list)

Commands:
  install            Start the VM in installer mode (boot from ISO)
  start              Start the VM (default)
  stop               Stop the VM
  status             Show VM status
  connect            Connect via SSH
  console            Connect to QEMU monitor console
  reset              Reset VM configuration (DANGEROUS)

Options:
  -n, --name NAME        Set VM name
  -m, --memory SIZE      Set memory size (e.g. 16G)
  -c, --cpus NUM         Set number of CPUs
  -p, --port PORT        Set SSH port
  -s, --size SIZE        Set disk size (e.g. 128G)
  --boot MODE            Boot mode: bios|uefi
  --boot-order ORDER     Boot order: auto|disk|cdrom
  -d, --daemon           Run in background (implies headless by default)
  --headless             Run without display
  --spice                Use SPICE display
  --vnc [PORT]           Use VNC display (default port: 5900)
  --base-dir DIR         VM base directory (default depends on profile)
  --iso-file PATH        Use custom ISO file (marks ISO as explicit)
  --iso-url URL          Use custom ISO URL
  --checksum HASH        SHA256 checksum for ISO verification
  --shared-dir DIR       Shared directory path (default: /run/user/\$(id -u))
  --no-iso               Do not attach ISO (after install)
  --dry-run              Print QEMU command, do not start
  -v, --verbose          Shell debug (set -x)
  -h, --help             Show help

Env overrides (generic):
  VM_BASE_DIR, VM_MEMORY, VM_CPUS, VM_SSH_PORT, VM_BOOT_MODE

Examples:
  ${SCRIPT_NAME} arch
  ${SCRIPT_NAME} nixos install --boot uefi
  ${SCRIPT_NAME} ubuntu start --vnc 5901
  ${SCRIPT_NAME} menu
EOF
}

# Configuration (filled by profile defaults)
declare -A CONFIG=()
DRY_RUN=0
HAVE_KVM="false"

set_profile_defaults() {
  local profile="$1"

  CONFIG=(
    [base_dir]="/nixos/san/${profile}"
    [ovmf_code]="/usr/share/edk2-ovmf/x64/OVMF.4m.fd"
    [ovmf_vars_template]="/usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd"
    [vm_name]="${profile}"
    [memory]="16G"
    [cpus]="8"
    [disk_size]="128G"
    [ssh_port]="2200"
    [vnc_port]="5900"
    [iso_url]=""
    [iso_checksum]=""
    [display_mode]="gtk"
    [boot_mode]="bios"
    [boot_order]="auto" # auto|disk|cdrom
    [shared_dir]="/run/user/$(id -u)"
    [attach_iso]="true"
    [daemonize]="false"
    [iso_file_explicit]="false"
    [iso_file]=""
    [vars_file]=""
    [disk_file]=""
    [monitor_sock]=""
    [pid_file]=""
    [log_file]=""
  )

  case "$profile" in
    arch)
      CONFIG[base_dir]="/nixos/san/arch"
      CONFIG[vm_name]="arch"
      CONFIG[ssh_port]="2244"
      CONFIG[iso_url]="https://archlinux.doridian.net/iso/2026.01.01/archlinux-2026.01.01-x86_64.iso"
      ;;
    nixos)
      CONFIG[base_dir]="/nixos/san/nixos"
      CONFIG[vm_name]="nixos"
      CONFIG[memory]="24G"
      CONFIG[ssh_port]="2288"
      CONFIG[iso_url]="https://channels.nixos.org/nixos-25.11/latest-nixos-graphical-x86_64-linux.iso"
      ;;
    ubuntu)
      CONFIG[base_dir]="/nixos/san/ubuntu"
      CONFIG[vm_name]="ubuntu"
      CONFIG[ssh_port]="2255"
      CONFIG[iso_url]="https://mirror.rabisu.com/ubuntu/ubuntu-releases/24.04.2/ubuntu-24.04.2-desktop-amd64.iso"
      ;;
    cachy|cachyos)
      CONFIG[base_dir]="/nixos/san/cachy"
      CONFIG[vm_name]="cachy"
      CONFIG[ssh_port]="2265"
      CONFIG[iso_url]="https://cdn77.cachyos.org/ISO/desktop/260124/cachyos-desktop-linux-260124.iso"
      ;;
    *)
      log_error "Unknown profile: $profile"
      show_help >&2
      exit 2
      ;;
  esac
}

pick_profile_interactive() {
  if ! [[ -t 0 ]]; then
    log_error "Interactive profile picker requires a TTY"
    exit 2
  fi

  echo "Select VM profile:"
  echo "  1) arch"
  echo "  2) nixos"
  echo "  3) ubuntu"
  echo "  4) cachy"
  echo "  q) quit"
  echo -n "Choice: "

  local choice=""
  read -r choice
  case "$choice" in
    1|arch) echo "arch" ;;
    2|nixos) echo "nixos" ;;
    3|ubuntu) echo "ubuntu" ;;
    4|cachy|cachyos) echo "cachy" ;;
    q|Q) exit 0 ;;
    *)
      log_error "Invalid choice: $choice"
      exit 2
      ;;
  esac
}

apply_env_overrides() {
  [[ -n "${VM_BASE_DIR:-}" ]] && CONFIG[base_dir]="$VM_BASE_DIR"
  [[ -n "${VM_MEMORY:-}" ]] && CONFIG[memory]="$VM_MEMORY"
  [[ -n "${VM_CPUS:-}" ]] && CONFIG[cpus]="$VM_CPUS"
  [[ -n "${VM_SSH_PORT:-}" ]] && CONFIG[ssh_port]="$VM_SSH_PORT"
  [[ -n "${VM_BOOT_MODE:-}" ]] && CONFIG[boot_mode]="$VM_BOOT_MODE"
  return 0
}

refresh_derived_paths() {
  local default_iso="${CONFIG[base_dir]}/$(basename "${CONFIG[iso_url]}")"
  if [[ "${CONFIG[iso_file_explicit]}" != "true" ]]; then
    CONFIG[iso_file]="$default_iso"
  fi

  CONFIG[vars_file]="${CONFIG[base_dir]}/OVMF_VARS.fd"
  CONFIG[disk_file]="${CONFIG[base_dir]}/disk.qcow2"
  CONFIG[monitor_sock]="${CONFIG[base_dir]}/monitor.sock"
  CONFIG[pid_file]="${CONFIG[base_dir]}/${CONFIG[vm_name]}.pid"
  CONFIG[log_file]="${CONFIG[base_dir]}/${CONFIG[vm_name]}.log"
}

prepare_environment() {
  refresh_derived_paths
  mkdir -p "${CONFIG[base_dir]}"
}

check_dependencies() {
  local deps=(qemu-system-x86_64 wget socat ssh qemu-img timeout)
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing required dependencies: ${missing[*]}"
    exit 1
  fi

  if [[ ! -r /dev/kvm ]]; then
    HAVE_KVM="false"
    log_warn "KVM not available, VM will run without hardware acceleration"
    log_warn "Add your user to kvm group: sudo usermod -a -G kvm \$USER"
  else
    HAVE_KVM="true"
  fi
}

verify_iso() {
  local iso_file="$1"
  local checksum="${CONFIG[iso_checksum]}"

  if [[ -n "$checksum" && -f "$iso_file" ]]; then
    log_info "Verifying ISO checksum..."
    local actual_checksum
    actual_checksum=$(sha256sum "$iso_file" | cut -d' ' -f1)
    if [[ "$actual_checksum" != "$checksum" ]]; then
      log_error "ISO checksum mismatch!"
      log_error "Expected: $checksum"
      log_error "Actual:   $actual_checksum"
      return 1
    fi
    log_success "ISO checksum verified"
  fi
}

setup_vm_files() {
  if [[ ! -f "${CONFIG[disk_file]}" ]]; then
    log_info "Creating new disk image (${CONFIG[disk_size]})..."
    if [[ "${CONFIG[boot_mode]}" == "bios" ]]; then
      qemu-img create -f qcow2 -o compat=0.10 "${CONFIG[disk_file]}" "${CONFIG[disk_size]}"
    else
      qemu-img create -f qcow2 "${CONFIG[disk_file]}" "${CONFIG[disk_size]}"
    fi
    log_success "Disk image created"
  fi

  if [[ "${CONFIG[boot_mode]}" == "uefi" && ! -f "${CONFIG[vars_file]}" ]]; then
    if [[ ! -f "${CONFIG[ovmf_vars_template]}" ]]; then
      log_error "OVMF template not found: ${CONFIG[ovmf_vars_template]}"
      exit 1
    fi
    log_info "Creating UEFI vars file..."
    cp "${CONFIG[ovmf_vars_template]}" "${CONFIG[vars_file]}"
    log_success "UEFI vars file created"
  fi

  if [[ "${CONFIG[attach_iso]}" == "true" ]]; then
    if [[ ! -f "${CONFIG[iso_file]}" ]]; then
      log_info "Downloading ISO from ${CONFIG[iso_url]}..."
      if ! wget --progress=bar:force:noscroll "${CONFIG[iso_url]}" -O "${CONFIG[iso_file]}"; then
        log_error "Failed to download ISO"
        rm -f "${CONFIG[iso_file]}"
        exit 1
      fi
      log_success "ISO downloaded"
    fi
    verify_iso "${CONFIG[iso_file]}"
  fi
}

build_qemu_command() {
  local -n out="$1"
  out=(qemu-system-x86_64)

  local accel="tcg"
  if [[ "$HAVE_KVM" == "true" ]]; then
    out+=(-enable-kvm)
    accel="kvm"
  fi

  out+=(-m "${CONFIG[memory]}")
  out+=(-smp "${CONFIG[cpus]}")
  out+=(-name "${CONFIG[vm_name]}")

  if [[ "${CONFIG[boot_mode]}" == "uefi" ]]; then
    out+=(-machine "type=q35,accel=${accel}")
  else
    out+=(-machine "type=pc,accel=${accel}")
  fi

  case "${CONFIG[boot_order]}" in
    disk) out+=(-boot order=c) ;;
    cdrom) out+=(-boot order=dc) ;;
    auto) : ;;
    *) log_error "Invalid boot order: ${CONFIG[boot_order]} (expected: auto|disk|cdrom)" && exit 1 ;;
  esac

  if [[ "${CONFIG[boot_mode]}" == "uefi" ]]; then
    out+=(-drive "file=${CONFIG[ovmf_code]},if=pflash,format=raw,readonly=on")
    out+=(-drive "file=${CONFIG[vars_file]},if=pflash,format=raw")
  fi

  out+=(-drive "file=${CONFIG[disk_file]},if=virtio,cache=writeback")
  if [[ "${CONFIG[attach_iso]}" == "true" ]]; then
    out+=(-cdrom "${CONFIG[iso_file]}")
  fi

  out+=(-netdev "user,id=net0,hostfwd=tcp::${CONFIG[ssh_port]}-:22")
  out+=(-device "virtio-net-pci,netdev=net0")

  case "${CONFIG[display_mode]}" in
    gtk)
      out+=(-device virtio-vga-gl)
      out+=(-display "gtk,gl=on")
      ;;
    spice)
      out+=(-device "qxl-vga,vgamem_mb=64")
      out+=(-spice "port=5930,addr=127.0.0.1,disable-ticketing=on")
      out+=(-device virtio-serial-pci)
      out+=(-chardev "spicevmc,id=vdagent,name=vdagent")
      out+=(-device "virtserialport,chardev=vdagent,name=com.redhat.spice.0")
      ;;
    vnc)
      out+=(-device virtio-vga)
      out+=(-vnc ":$((CONFIG[vnc_port] - 5900))")
      ;;
    none)
      out+=(-nographic)
      ;;
    *)
      log_error "Invalid display mode: ${CONFIG[display_mode]} (expected: gtk|spice|vnc|none)"
      exit 1
      ;;
  esac

  if [[ "${CONFIG[display_mode]}" != "none" ]]; then
    out+=(-device qemu-xhci,id=xhci)
    out+=(-device usb-tablet)
    out+=(-device usb-kbd)
  fi

  if [[ "$HAVE_KVM" == "true" ]]; then
    out+=(-cpu host)
  else
    out+=(-cpu max)
  fi
  out+=(-device virtio-balloon-pci)
  out+=(-device virtio-rng-pci)

  if [[ -d "${CONFIG[shared_dir]}" ]]; then
    out+=(-fsdev "local,security_model=passthrough,id=fsdev0,path=${CONFIG[shared_dir]}")
    out+=(-device "virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare")
  fi

  if [[ "${CONFIG[display_mode]}" != "none" ]]; then
    out+=(-audiodev pa,id=snd0)
    out+=(-device intel-hda)
    out+=(-device hda-duplex,audiodev=snd0)
  fi

  out+=(-pidfile "${CONFIG[pid_file]}")

  if [[ "${CONFIG[daemonize]}" == "true" ]]; then
    out+=(-daemonize)
  fi

  out+=(-monitor "unix:${CONFIG[monitor_sock]},server,nowait")
}

vm_status() {
  if [[ -f "${CONFIG[pid_file]}" ]]; then
    local pid
    pid=$(cat "${CONFIG[pid_file]}")
    if kill -0 "$pid" 2>/dev/null; then
      log_success "VM is running (PID: $pid)"
      return 0
    fi
    log_warn "PID file exists but process not running"
    rm -f "${CONFIG[pid_file]}"
  fi
  log_info "VM is not running"
  return 1
}

vm_stop() {
  if vm_status >/dev/null 2>&1; then
    local pid
    pid=$(cat "${CONFIG[pid_file]}")
    log_info "Stopping VM (PID: $pid)..."

    if [[ -S "${CONFIG[monitor_sock]}" ]]; then
      echo "system_powerdown" | socat - "unix:${CONFIG[monitor_sock]}" 2>/dev/null || true
    fi
    sleep 5

    if kill -0 "$pid" 2>/dev/null; then
      log_warn "Forcing VM shutdown..."
      kill -TERM "$pid" || true
      sleep 2
      kill -KILL "$pid" 2>/dev/null || true
    fi

    rm -f "${CONFIG[pid_file]}"
    rm -f "${CONFIG[monitor_sock]}" 2>/dev/null || true
    log_success "VM stopped"
  else
    log_info "VM is not running"
  fi
}

vm_connect() {
  if ! vm_status >/dev/null 2>&1; then
    log_error "VM is not running"
    exit 1
  fi

  log_info "Connecting to VM via SSH (port ${CONFIG[ssh_port]})..."
  if timeout 5 bash -c "cat < /dev/null > /dev/tcp/localhost/${CONFIG[ssh_port]}" 2>/dev/null; then
    ssh -p "${CONFIG[ssh_port]}" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" localhost
  else
    log_error "SSH port ${CONFIG[ssh_port]} is not responding"
  fi
}

vm_console() {
  if ! vm_status >/dev/null 2>&1; then
    log_error "VM is not running"
    exit 1
  fi
  log_info "Connecting to QEMU monitor console..."
  socat - "unix:${CONFIG[monitor_sock]}"
}

vm_reset() {
  log_warn "This will remove all VM data for profile '${PROFILE}'!"
  read -p "Are you sure? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    vm_stop
    rm -f "${CONFIG[disk_file]}" "${CONFIG[vars_file]}"
    log_success "VM reset completed"
  else
    log_info "Reset cancelled"
  fi
}

require_arg() {
  local opt="$1"
  local val="${2:-}"
  if [[ -z "$val" || "$val" == "-"* ]]; then
    log_error "Missing value for $opt"
    exit 1
  fi
}

parse_arguments() {
  local command="start"

  for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
      show_help
      exit 0
    fi
  done

  if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
    command="$1"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case $1 in
      -n|--name)
        require_arg "$1" "${2:-}"
        CONFIG[vm_name]="$2"
        shift 2
        ;;
      -m|--memory)
        require_arg "$1" "${2:-}"
        CONFIG[memory]="$2"
        shift 2
        ;;
      -c|--cpus)
        require_arg "$1" "${2:-}"
        CONFIG[cpus]="$2"
        shift 2
        ;;
      -p|--port)
        require_arg "$1" "${2:-}"
        CONFIG[ssh_port]="$2"
        shift 2
        ;;
      -s|--size)
        require_arg "$1" "${2:-}"
        CONFIG[disk_size]="$2"
        shift 2
        ;;
      --boot)
        require_arg "$1" "${2:-}"
        [[ "$2" != "bios" && "$2" != "uefi" ]] && {
          log_error "Boot mode must be 'bios' or 'uefi'"
          exit 1
        }
        CONFIG[boot_mode]="$2"
        shift 2
        ;;
      --boot-order)
        require_arg "$1" "${2:-}"
        CONFIG[boot_order]="$2"
        shift 2
        ;;
      -d|--daemon)
        CONFIG[daemonize]="true"
        [[ ${CONFIG[display_mode]} == "gtk" ]] && CONFIG[display_mode]="none"
        shift
        ;;
      --headless)
        CONFIG[display_mode]="none"
        shift
        ;;
      --spice)
        CONFIG[display_mode]="spice"
        shift
        ;;
      --vnc)
        CONFIG[display_mode]="vnc"
        [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]] && {
          CONFIG[vnc_port]="$2"
          shift
        }
        shift
        ;;
      --base-dir)
        require_arg "$1" "${2:-}"
        CONFIG[base_dir]="$2"
        shift 2
        ;;
      --iso-file)
        require_arg "$1" "${2:-}"
        CONFIG[iso_file]="$2"
        CONFIG[iso_file_explicit]="true"
        shift 2
        ;;
      --iso-url)
        require_arg "$1" "${2:-}"
        CONFIG[iso_url]="$2"
        shift 2
        ;;
      --checksum)
        require_arg "$1" "${2:-}"
        CONFIG[iso_checksum]="$2"
        shift 2
        ;;
      --shared-dir)
        require_arg "$1" "${2:-}"
        CONFIG[shared_dir]="$2"
        shift 2
        ;;
      --no-iso)
        CONFIG[attach_iso]="false"
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      -v|--verbose)
        set -x
        shift
        ;;
      *)
        log_error "Unknown option: $1"
        exit 1
        ;;
    esac
  done

  echo "$command"
}

print_cmd() {
  local -a cmd=("$@")
  printf '%q ' "${cmd[@]}"
  echo
}

svm_run() {
  local command

  apply_env_overrides
  command="$(parse_arguments "$@")"
  prepare_environment

  case "$command" in
    install)
      [[ "${CONFIG[attach_iso]}" == "false" ]] && CONFIG[attach_iso]="true"
      [[ "${CONFIG[boot_order]}" == "auto" ]] && CONFIG[boot_order]="cdrom"
      check_dependencies
      if vm_status >/dev/null 2>&1; then
        log_warn "VM is already running"
        exit 1
      fi
      setup_vm_files

      local -a qemu_cmd
      build_qemu_command qemu_cmd

      if ((DRY_RUN)); then
        log_info "QEMU command:"
        print_cmd "${qemu_cmd[@]}"
      else
        [[ "${CONFIG[display_mode]}" != "none" ]] && setup_wayland_environment
        log_info "Starting VM (install mode)..."
        "${qemu_cmd[@]}"
      fi
      ;;
    start)
      check_dependencies
      if vm_status >/dev/null 2>&1; then
        log_warn "VM is already running"
        exit 1
      fi
      setup_vm_files

      local -a qemu_cmd
      build_qemu_command qemu_cmd

      if ((DRY_RUN)); then
        log_info "QEMU command:"
        print_cmd "${qemu_cmd[@]}"
      else
        [[ "${CONFIG[display_mode]}" != "none" ]] && setup_wayland_environment
        log_info "Starting VM..."
        "${qemu_cmd[@]}"
      fi
      ;;
    stop) vm_stop ;;
    status) vm_status ;;
    connect) vm_connect ;;
    console) vm_console ;;
    reset) vm_reset ;;
    *)
      log_error "Unknown command: $command"
      log_info "Use --help to see available commands"
      exit 1
      ;;
  esac
}

main() {
  local first="${1:-}"

  case "$first" in
    -h|--help|help)
      show_help
      exit 0
      ;;
  esac

  if [[ -z "$first" ]]; then
    PROFILE="$(pick_profile_interactive)"
  elif [[ "$first" == "menu" ]]; then
    shift
    PROFILE="$(pick_profile_interactive)"
  else
    case "$first" in
      arch|nixos|ubuntu|cachy|cachyos)
        PROFILE="$first"
        shift
        ;;
      *)
        log_error "Missing/invalid profile: $first"
        show_help >&2
        exit 2
        ;;
    esac
  fi

  set_profile_defaults "$PROFILE"
  svm_run "$@"
}

trap 'log_info "Interrupted"; exit 130' INT TERM
main "$@"
