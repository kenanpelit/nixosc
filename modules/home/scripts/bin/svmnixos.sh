#!/usr/bin/env bash

#===============================================================================
#
#   Version: 1.2.0
#   Date: 2025-05-26
#   Author: Kenan Pelit (Improved)
#   Description: NixOS VM Manager
#                Manages QEMU/KVM based NixOS virtual machines
#
#   Features:
#   - Easy VM creation and management
#   - Automated ISO downloads with integrity checks
#   - Multiple display backends (GTK, SPICE, Headless, VNC)
#   - Configurable resources (CPU, Memory, Disk)
#   - SSH port forwarding with connection testing
#   - Both BIOS and UEFI boot support
#   - 9P filesystem sharing
#   - VM status monitoring and management
#   - Enhanced input device handling
#   - Improved error handling and logging
#
#   License: MIT
#
#===============================================================================

set -euo pipefail # Strict error handling

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }

# Configuration
declare -A CONFIG=(
  [base_dir]="/nixos/san/nixos"
  [ovmf_code]="/usr/share/edk2-ovmf/x64/OVMF.4m.fd"
  [ovmf_vars_template]="/usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd"
  [vm_name]="nixos"
  [memory]="24G"
  [cpus]="8"
  [disk_size]="128G"
  [ssh_port]="2288"
  [vnc_port]="5900"
  [iso_url]="https://channels.nixos.org/nixos-25.11/latest-nixos-gnome-x86_64-linux.iso"
  [iso_checksum]="" # SHA256 checksum (optional)
  [display_mode]="gtk"
  [boot_mode]="bios"
  [shared_dir]="/run/user/$(id -u)"
  [daemonize]="false"
)

# Derived paths
CONFIG[iso_file]="${CONFIG[base_dir]}/latest-nixos-gnome-x86_64-linux.iso"
CONFIG[vars_file]="${CONFIG[base_dir]}/OVMF_VARS.fd"
CONFIG[disk_file]="${CONFIG[base_dir]}/disk.qcow2"
CONFIG[pid_file]="${CONFIG[base_dir]}/${CONFIG[vm_name]}.pid"
CONFIG[log_file]="${CONFIG[base_dir]}/${CONFIG[vm_name]}.log"

show_help() {
  cat <<EOF
NixOS VM Manager - Easily create and manage NixOS virtual machines

Usage: $(basename "$0") [COMMAND] [OPTIONS]

Commands:
    start              Start the VM (default)
    stop               Stop the VM
    status             Show VM status
    connect            Connect via SSH
    console            Connect to QEMU monitor console
    reset              Reset VM configuration

Basic Options:
    -n, --name NAME        Set VM name (default: ${CONFIG[vm_name]})
    -m, --memory SIZE      Set memory size (default: ${CONFIG[memory]})
    -c, --cpus NUM         Set number of CPUs (default: ${CONFIG[cpus]})
    -p, --port PORT        Set SSH port (default: ${CONFIG[ssh_port]})
    -s, --size SIZE        Set disk size (default: ${CONFIG[disk_size]})
    --boot MODE            Set boot mode (bios or uefi) (default: ${CONFIG[boot_mode]})
    
Display Options:
    -d, --daemon           Run in background
    --headless             Run without display
    --spice                Use SPICE display
    --vnc [PORT]           Use VNC display (default port: ${CONFIG[vnc_port]})
    
Path Options:
    --base-dir DIR         Set base directory (default: ${CONFIG[base_dir]})
    --iso-file PATH        Use custom ISO file
    --iso-url URL          Use custom ISO URL
    --checksum HASH        SHA256 checksum for ISO verification
    --shared-dir DIR       Shared directory path (default: ${CONFIG[shared_dir]})
    
Other Options:
    -h, --help             Show this help message
    --dry-run              Show QEMU command without executing
    -v, --verbose          Enable verbose output

Environment Variables:
    VMNIXOS_BASE_DIR       Override base directory
    VMNIXOS_MEMORY         Override memory size
    VMNIXOS_CPUS           Override CPU count
    VMNIXOS_SSH_PORT       Override SSH port
    VMNIXOS_BOOT_MODE      Override boot mode (bios/uefi)

Examples:
    # Start VM with default settings
    $(basename "$0") start
    
    # Start VM in UEFI mode with more resources
    $(basename "$0") start --boot uefi --memory 16G --cpus 4
    
    # Run VM in background without display
    $(basename "$0") start --daemon --headless
    
    # Connect to running VM via SSH
    $(basename "$0") connect
    
    # Check VM status
    $(basename "$0") status
    
    # Use VNC display on custom port
    $(basename "$0") start --vnc 5901

Note: Use Ctrl+Alt+G to release mouse/keyboard grab in GUI mode
EOF
}

setup_environment() {
  mkdir -p "${CONFIG[base_dir]}"

  # Environment variable overrides
  [[ -n "${VMNIXOS_BASE_DIR:-}" ]] && CONFIG[base_dir]="$VMNIXOS_BASE_DIR"
  [[ -n "${VMNIXOS_MEMORY:-}" ]] && CONFIG[memory]="$VMNIXOS_MEMORY"
  [[ -n "${VMNIXOS_CPUS:-}" ]] && CONFIG[cpus]="$VMNIXOS_CPUS"
  [[ -n "${VMNIXOS_SSH_PORT:-}" ]] && CONFIG[ssh_port]="$VMNIXOS_SSH_PORT"
  [[ -n "${VMNIXOS_BOOT_MODE:-}" ]] && CONFIG[boot_mode]="$VMNIXOS_BOOT_MODE"

  # Update derived paths after potential base_dir change
  CONFIG[iso_file]="${CONFIG[base_dir]}/latest-nixos-gnome-x86_64-linux.iso"
  CONFIG[vars_file]="${CONFIG[base_dir]}/OVMF_VARS.fd"
  CONFIG[disk_file]="${CONFIG[base_dir]}/disk.qcow2"
  CONFIG[pid_file]="${CONFIG[base_dir]}/${CONFIG[vm_name]}.pid"
  CONFIG[log_file]="${CONFIG[base_dir]}/${CONFIG[vm_name]}.log"
}

check_dependencies() {
  local deps=(qemu-system-x86_64 wget)
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Missing required dependencies: ${missing[*]}"
    log_info "Install them using your package manager:"
    log_info "  Arch: sudo pacman -S qemu-full wget"
    log_info "  Ubuntu: sudo apt install qemu-system-x86 wget"
    log_info "  NixOS: Add to your configuration.nix"
    exit 1
  fi

  # Check KVM support
  if [[ ! -r /dev/kvm ]]; then
    log_warn "KVM not available, VM will run without hardware acceleration"
    log_warn "Add your user to kvm group: sudo usermod -a -G kvm \$USER"
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
  # Create disk image if it doesn't exist
  if [[ ! -f "${CONFIG[disk_file]}" ]]; then
    log_info "Creating new disk image (${CONFIG[disk_size]})..."
    if [[ "${CONFIG[boot_mode]}" == "bios" ]]; then
      qemu-img create -f qcow2 -o compat=0.10 "${CONFIG[disk_file]}" "${CONFIG[disk_size]}"
    else
      qemu-img create -f qcow2 "${CONFIG[disk_file]}" "${CONFIG[disk_size]}"
    fi
    log_success "Disk image created"
  fi

  # Setup UEFI vars file
  if [[ "${CONFIG[boot_mode]}" == "uefi" && ! -f "${CONFIG[vars_file]}" ]]; then
    if [[ ! -f "${CONFIG[ovmf_vars_template]}" ]]; then
      log_error "OVMF template not found: ${CONFIG[ovmf_vars_template]}"
      log_info "Install OVMF package (ovmf or edk2-ovmf)"
      exit 1
    fi
    log_info "Creating UEFI vars file..."
    cp "${CONFIG[ovmf_vars_template]}" "${CONFIG[vars_file]}"
    log_success "UEFI vars file created"
  fi

  # Download ISO if needed
  if [[ ! -f "${CONFIG[iso_file]}" ]]; then
    log_info "Downloading NixOS ISO..."
    if ! wget --progress=bar:force:noscroll "${CONFIG[iso_url]}" -O "${CONFIG[iso_file]}"; then
      log_error "Failed to download ISO"
      rm -f "${CONFIG[iso_file]}"
      exit 1
    fi
    log_success "ISO downloaded"
  fi

  # Verify ISO if checksum provided
  verify_iso "${CONFIG[iso_file]}"
}

build_qemu_command() {
  local cmd="qemu-system-x86_64"

  # Basic configuration
  cmd+=" -enable-kvm"
  cmd+=" -m ${CONFIG[memory]}"
  cmd+=" -smp ${CONFIG[cpus]}"
  cmd+=" -name \"${CONFIG[vm_name]}\""

  # Machine configuration
  if [[ "${CONFIG[boot_mode]}" == "uefi" ]]; then
    cmd+=" -machine type=q35,accel=kvm"
  else
    cmd+=" -machine type=pc,accel=kvm"
  fi

  # UEFI boot configuration
  if [[ "${CONFIG[boot_mode]}" == "uefi" ]]; then
    cmd+=" -drive file=\"${CONFIG[ovmf_code]}\",if=pflash,format=raw,readonly=on"
    cmd+=" -drive file=\"${CONFIG[vars_file]}\",if=pflash,format=raw"
  fi

  # Drive configuration
  cmd+=" -drive file=\"${CONFIG[disk_file]}\",if=virtio,cache=writeback"
  cmd+=" -cdrom \"${CONFIG[iso_file]}\""

  # Network configuration with SSH forwarding
  cmd+=" -netdev user,id=net0,hostfwd=tcp::${CONFIG[ssh_port]}-:22"
  cmd+=" -device virtio-net-pci,netdev=net0"

  # Display configuration
  case "${CONFIG[display_mode]}" in
  gtk)
    cmd+=" -device virtio-vga-gl"
    cmd+=" -display gtk,gl=on"
    ;;
  spice)
    cmd+=" -device qxl-vga,vgamem_mb=64"
    cmd+=" -spice port=5930,addr=127.0.0.1,disable-ticketing=on"
    cmd+=" -device virtio-serial-pci"
    cmd+=" -chardev spicevmc,id=vdagent,name=vdagent"
    cmd+=" -device virtserialport,chardev=vdagent,name=com.redhat.spice.0"
    ;;
  vnc)
    cmd+=" -device virtio-vga"
    cmd+=" -vnc :$((${CONFIG[vnc_port]} - 5900))"
    ;;
  none)
    cmd+=" -nographic"
    ;;
  esac

  # Input devices (only for graphical modes)
  if [[ "${CONFIG[display_mode]}" != "none" ]]; then
    cmd+=" -device qemu-xhci,id=xhci"
    cmd+=" -device virtio-tablet-pci"
    cmd+=" -device virtio-keyboard-pci"
  fi

  # Additional features
  cmd+=" -cpu host"
  cmd+=" -device virtio-balloon-pci" # Memory ballooning support
  cmd+=" -device virtio-rng-pci"     # Random number generator

  # Shared directory (9P)
  if [[ -d "${CONFIG[shared_dir]}" ]]; then
    cmd+=" -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare"
    cmd+=" -fsdev local,security_model=passthrough,id=fsdev0,path=\"${CONFIG[shared_dir]}\""
  fi

  # Audio support (only for graphical modes)
  if [[ "${CONFIG[display_mode]}" != "none" ]]; then
    cmd+=" -audiodev pa,id=snd0"
    cmd+=" -device intel-hda"
    cmd+=" -device hda-duplex,audiodev=snd0"
  fi

  # Daemon mode
  if [[ "${CONFIG[daemonize]}" == "true" ]]; then
    cmd+=" -daemonize"
    cmd+=" -pidfile \"${CONFIG[pid_file]}\""
  fi

  # Monitor interface
  cmd+=" -monitor unix:${CONFIG[base_dir]}/monitor.sock,server,nowait"

  echo "$cmd"
}

vm_status() {
  if [[ -f "${CONFIG[pid_file]}" ]]; then
    local pid
    pid=$(cat "${CONFIG[pid_file]}")
    if kill -0 "$pid" 2>/dev/null; then
      log_success "VM is running (PID: $pid)"
      return 0
    else
      log_warn "PID file exists but process not running"
      rm -f "${CONFIG[pid_file]}"
    fi
  fi
  log_info "VM is not running"
  return 1
}

vm_stop() {
  if vm_status >/dev/null 2>&1; then
    local pid
    pid=$(cat "${CONFIG[pid_file]}")
    log_info "Stopping VM (PID: $pid)..."

    # Try graceful shutdown first
    echo "system_powerdown" | socat - "unix:${CONFIG[base_dir]}/monitor.sock" 2>/dev/null || true

    # Wait a bit for graceful shutdown
    sleep 5

    # Force kill if still running
    if kill -0 "$pid" 2>/dev/null; then
      log_warn "Forcing VM shutdown..."
      kill -TERM "$pid"
      sleep 2
      kill -KILL "$pid" 2>/dev/null || true
    fi

    rm -f "${CONFIG[pid_file]}"
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
  log_info "Default credentials may be required for first connection"

  # Test if SSH port is responding
  if timeout 5 bash -c "cat < /dev/null > /dev/tcp/localhost/${CONFIG[ssh_port]}" 2>/dev/null; then
    ssh -p "${CONFIG[ssh_port]}" -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" localhost
  else
    log_error "SSH port ${CONFIG[ssh_port]} is not responding"
    log_info "VM might still be booting or SSH service is not running"
    log_info "Try connecting manually: ssh -p ${CONFIG[ssh_port]} username@localhost"
  fi
}

vm_console() {
  if ! vm_status >/dev/null 2>&1; then
    log_error "VM is not running"
    exit 1
  fi

  log_info "Connecting to QEMU monitor console..."
  log_info "Type 'help' for available commands, 'quit' to exit"
  socat - "unix:${CONFIG[base_dir]}/monitor.sock"
}

vm_reset() {
  log_warn "This will remove all VM data!"
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

parse_arguments() {
  local command="start"

  # Parse command first
  if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
    command="$1"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case $1 in
    -n | --name)
      CONFIG[vm_name]="$2"
      shift 2
      ;;
    -m | --memory)
      CONFIG[memory]="$2"
      shift 2
      ;;
    -c | --cpus)
      CONFIG[cpus]="$2"
      shift 2
      ;;
    -p | --port)
      CONFIG[ssh_port]="$2"
      shift 2
      ;;
    -s | --size)
      CONFIG[disk_size]="$2"
      shift 2
      ;;
    --boot)
      if [[ "$2" != "bios" && "$2" != "uefi" ]]; then
        log_error "Boot mode must be either 'bios' or 'uefi'"
        exit 1
      fi
      CONFIG[boot_mode]="$2"
      shift 2
      ;;
    -d | --daemon)
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
      if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
        CONFIG[vnc_port]="$2"
        shift
      fi
      shift
      ;;
    --base-dir)
      CONFIG[base_dir]="$2"
      shift 2
      ;;
    --iso-file)
      CONFIG[iso_file]="$2"
      shift 2
      ;;
    --iso-url)
      CONFIG[iso_url]="$2"
      shift 2
      ;;
    --checksum)
      CONFIG[iso_checksum]="$2"
      shift 2
      ;;
    --shared-dir)
      CONFIG[shared_dir]="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -v | --verbose)
      set -x
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      show_help
      exit 1
      ;;
    esac
  done

  echo "$command"
}

main() {
  local command

  setup_environment
  command=$(parse_arguments "$@")

  case "$command" in
  start)
    check_dependencies
    if vm_status >/dev/null 2>&1; then
      log_warn "VM is already running"
      exit 1
    fi
    setup_vm_files

    local qemu_cmd
    qemu_cmd=$(build_qemu_command)

    if [[ -n "${DRY_RUN:-}" ]]; then
      log_info "QEMU command:"
      echo "$qemu_cmd"
    else
      log_info "Starting VM..."
      if [[ "${CONFIG[daemonize]}" == "true" ]]; then
        eval "$qemu_cmd" && log_success "VM started in background"
      else
        eval "$qemu_cmd"
      fi
    fi
    ;;
  stop)
    vm_stop
    ;;
  status)
    vm_status
    ;;
  connect)
    vm_connect
    ;;
  console)
    vm_console
    ;;
  reset)
    vm_reset
    ;;
  *)
    log_error "Unknown command: $command"
    show_help
    exit 1
    ;;
  esac
}

# Trap signals for cleanup
trap 'log_info "Interrupted"; exit 130' INT TERM

main "$@"
