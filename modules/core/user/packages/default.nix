# modules/core/user/packages/default.nix
# ==============================================================================
# System Packages Configuration
# ==============================================================================
# This configuration manages system-wide packages including:
# - Core system utilities
# - Development tools
# - Network utilities
# - Security tools
# - Media tools
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:
let
  # Custom Python Environment
  pythonWithLibtmux = pkgs.python3.withPackages (ps: with ps; [
    ipython
    libtmux
  ]);
in
{
  environment.systemPackages = with pkgs; [
    # Core System Utilities
    home-manager catppuccin-grub blueman dconf dconf-editor
    libnotify poweralertd xdg-utils gzip gcc gnumake
    coreutils libinput fusuma touchegg

    # Terminal and Shell Tools
    curl wget tmux man-pages socat

    # Python Environment
    pythonWithLibtmux

    # System Monitoring
    htop powertop sysstat procps

    # Networking Tools
    iptables tcpdump nethogs bind iwd impala iwgtk
    libnotify gawk iw iftop mtr nmap speedtest-cli
    iperf rsync

    # Security Tools
    age openssl sops hblock gnupg gcr
    gnome-keyring pinentry-gnome3

    # Development Tools
    git gdb nvd ncdu du-dust cachix nix-output-monitor

    # SSH Tools
    assh openssh

    # Virtualization
    virt-manager virt-viewer qemu spice-gtk
    win-virtio win-spice swtpm podman

    # Power Management
    upower acpi powertop

    # Desktop Integration
    flatpak xdg-desktop-portal xdg-desktop-portal-gtk

    # Media Tools
    mpc-cli rmpc acl

    # Remote Access
    tigervnc
  ];
}
