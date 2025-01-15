#!/usr/bin/env bash

#===============================================================================
#
#   Version: 1.0.0
#   Date: 2024-12-27
#   Author: Kenan Pelit
#   Description: NixOS VM Manager
#                Manages QEMU/KVM based NixOS virtual machines
#
#   Features:
#   - Easy VM creation and management
#   - Automated ISO downloads
#   - Multiple display backends (GTK, SPICE, Headless)
#   - Configurable resources (CPU, Memory, Disk)
#   - SSH port forwarding
#   - UEFI boot support
#   - 9P filesystem sharing
#
#   License: MIT
#
#===============================================================================

# Configuration
declare -A CONFIG=(
  #[base_dir]="${HOME}/.local/share/vmnixos"
  [base_dir]="/repo/san/nixos"
  [ovmf_code]="/usr/share/edk2-ovmf/x64/OVMF.4m.fd"
  [ovmf_vars_template]="/usr/share/edk2-ovmf/x64/OVMF_VARS.4m.fd"
  [vm_name]="nixos"
  [memory]="8G"
  [cpus]="2"
  [disk_size]="128G"
  [ssh_port]="2288"
  [iso_url]="https://channels.nixos.org/nixos-24.11/latest-nixos-gnome-x86_64-linux.iso"
  [display_mode]="gtk"
)

# Derived paths
#CONFIG[iso_file]="${CONFIG[base_dir]}/nixos.iso"
CONFIG[iso_file]="${CONFIG[base_dir]}/latest-nixos-gnome-x86_64-linux.iso"
CONFIG[vars_file]="${CONFIG[base_dir]}/OVMF_VARS.fd"
CONFIG[disk_file]="${CONFIG[base_dir]}/disk.qcow2"

show_help() {
  cat <<EOF
NixOS VM Manager - Easily create and manage NixOS virtual machines

Usage: $(basename "$0") [OPTIONS]

Basic Options:
    -n, --name NAME        Set VM name (default: ${CONFIG[vm_name]})
    -m, --memory SIZE      Set memory size (default: ${CONFIG[memory]})
    -c, --cpus NUM        Set number of CPUs (default: ${CONFIG[cpus]})
    -p, --port PORT        Set SSH port (default: ${CONFIG[ssh_port]})
    -s, --size SIZE        Set disk size (default: ${CONFIG[disk_size]})
    
Display Options:
    -d, --daemon           Run in background
    --headless            Run without display
    --spice               Use SPICE display instead of GTK
    
Path Options:
    --base-dir DIR        Set base directory (default: ${CONFIG[base_dir]})
    --iso-file PATH       Use custom ISO file
    --iso-url URL         Use custom ISO URL
    
Other Options:
    -h, --help            Show this help message
    --dry-run            Show QEMU command without executing
    --reset              Reset VM configuration to defaults

Environment Variables:
    VMNIXOS_BASE_DIR     Override base directory
    VMNIXOS_MEMORY       Override memory size
    VMNIXOS_CPUS         Override CPU count
    VMNIXOS_SSH_PORT     Override SSH port

Examples:
    # Start VM with default settings
    $(basename "$0")
    
    # Start VM with custom configuration
    $(basename "$0") --name dev-vm --memory 8G --cpus 8 --port 2222
    
    # Run VM in background without display
    $(basename "$0") --daemon --headless
    
    # Use custom ISO file
    $(basename "$0") --iso-file /path/to/nixos.iso
EOF
}

setup_environment() {
  # Create base directory if it doesn't exist
  mkdir -p "${CONFIG[base_dir]}"

  # Check for environment variable overrides
  [[ -n "$VMNIXOS_BASE_DIR" ]] && CONFIG[base_dir]="$VMNIXOS_BASE_DIR"
  [[ -n "$VMNIXOS_MEMORY" ]] && CONFIG[memory]="$VMNIXOS_MEMORY"
  [[ -n "$VMNIXOS_CPUS" ]] && CONFIG[cpus]="$VMNIXOS_CPUS"
  [[ -n "$VMNIXOS_SSH_PORT" ]] && CONFIG[ssh_port]="$VMNIXOS_SSH_PORT"
}

check_dependencies() {
  # Check if qemu-full is installed
  if ! pacman -Qi qemu-full >/dev/null 2>&1; then
    echo "Error: qemu-full package is not installed"
    echo "Please install it using: sudo pacman -S qemu-full"
    exit 1
  fi

  local deps=(wget)
  local missing=()

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: Missing required dependencies: ${missing[*]}"
    echo "Please install them using your package manager"
    exit 1
  fi
}

setup_vm_files() {
  # Create disk image if it doesn't exist
  if [[ ! -f "${CONFIG[disk_file]}" ]]; then
    echo "Creating new disk image (${CONFIG[disk_size]})..."
    qemu-img create -f qcow2 "${CONFIG[disk_file]}" "${CONFIG[disk_size]}"
  fi

  # Copy VARS template if it doesn't exist
  if [[ ! -f "${CONFIG[vars_file]}" ]]; then
    echo "Creating new VARS file..."
    cp "${CONFIG[ovmf_vars_template]}" "${CONFIG[vars_file]}"
  fi

  # Download ISO if needed
  if [[ ! -f "${CONFIG[iso_file]}" ]]; then
    echo "Downloading NixOS ISO..."
    wget "${CONFIG[iso_url]}" -O "${CONFIG[iso_file]}"
  fi
}

build_qemu_command() {
  local cmd="qemu-system-x86_64"

  # Basic configuration
  cmd+=" -enable-kvm"
  cmd+=" -m ${CONFIG[memory]}"
  cmd+=" -smp ${CONFIG[cpus]}"
  cmd+=" -name \"${CONFIG[vm_name]}\""

  # Drive configuration
  cmd+=" -drive file=\"${CONFIG[ovmf_code]}\",if=pflash,format=raw,readonly=on"
  cmd+=" -drive file=\"${CONFIG[vars_file]}\",if=pflash,format=raw"
  cmd+=" -drive file=\"${CONFIG[disk_file]}\",if=virtio"
  cmd+=" -cdrom \"${CONFIG[iso_file]}\""

  # Network configuration
  cmd+=" -netdev user,id=net0,hostfwd=tcp::${CONFIG[ssh_port]}-:22"
  cmd+=" -device virtio-net-pci,netdev=net0"

  # Display configuration
  case "${CONFIG[display_mode]}" in
  gtk)
    cmd+=" -device virtio-vga-gl"
    cmd+=" -display gtk,gl=on"
    ;;
  spice)
    cmd+=" -device qxl-vga"
    cmd+=" -spice port=5930,addr=127.0.0.1"
    ;;
  none)
    cmd+=" -nographic"
    ;;
  esac

  # Additional features
  cmd+=" -cpu host"
  cmd+=" -device virtio-9p-pci,id=fs0,fsdev=fsdev0,mount_tag=hostshare"
  cmd+=" -fsdev local,security_model=passthrough,id=fsdev0,path=/run/user/1000/"

  echo "$cmd"
}

parse_arguments() {
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
    -d | --daemon)
      [[ ${CONFIG[display_mode]} != "none" ]] && CONFIG[display_mode]="gtk"
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
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h | --help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
    esac
  done
}

main() {
  setup_environment
  check_dependencies
  parse_arguments "$@"
  setup_vm_files

  local qemu_cmd
  qemu_cmd=$(build_qemu_command)

  if [[ -n "$DRY_RUN" ]]; then
    echo "QEMU command:"
    echo "$qemu_cmd"
  else
    eval "$qemu_cmd"
  fi
}

main "$@"
