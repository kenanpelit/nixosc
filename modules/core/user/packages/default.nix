# modules/core/user/packages/default.nix
# ==============================================================================
# System Core Packages Configuration
# modules/core/user/packages/default.nix
# ==============================================================================
#
# This configuration manages system-level packages required for core functionality:
# - System utilities and services
# - Core development tools
# - Hardware management
# - System security
# - Virtualization support
# - Network infrastructure
#
# These packages are installed system-wide and are available to all users.
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:

let
  # ==============================================================================
  # Custom Python Environment Configuration
  # Python packages required for system automation and management
  # ==============================================================================
  pythonWithLibtmux = pkgs.python3.withPackages (ps: with ps; [
    ipython        # Enhanced interactive Python shell
    libtmux        # Python API for tmux
    pip            # Python package installer
    pipx           # Install and run Python applications in isolated environments
  ]);
in
{
  environment.systemPackages = with pkgs; [
    # ==============================================================================
    # Core System Utilities
    # Essential system management and configuration tools
    # ==============================================================================
    home-manager           # User environment management
    catppuccin-grub       # Theme for GRUB bootloader
    dconf                 # Low-level configuration system
    dconf-editor          # Configuration editor for dconf
    libnotify            # Desktop notification library
    poweralertd          # Power management notifications
    xdg-utils            # Desktop integration utilities
    gzip                 # Compression utility
    gcc                  # GNU Compiler Collection
    gnumake              # Build automation tool
    coreutils           # GNU core utilities
    libinput            # Input device management
    fusuma              # Multitouch gestures
    touchegg            # Multitouch gesture recognizer

    # ==============================================================================
    # Terminal and Shell Tools
    # Command-line utilities and shell enhancements
    # ==============================================================================
    curl                 # URL data transfer tool
    wget                # Network file retriever
    tmux                # Terminal multiplexer
    man-pages           # System manual pages
    socat               # Multipurpose relay tool

    # ==============================================================================
    # Custom Python Environment
    # Python installation with specific packages
    # ==============================================================================
    pythonWithLibtmux    # Custom Python with tmux support

    # ==============================================================================
    # System Monitoring
    # System performance and resource monitoring tools
    # ==============================================================================
    htop                # Interactive process viewer
    powertop            # Power consumption monitor
    sysstat            # System performance tools
    procps              # Process monitoring tools

    # ==============================================================================
    # Network Infrastructure
    # Core networking tools and utilities
    # ==============================================================================
    iptables            # Firewall management
    tcpdump             # Network packet analyzer
    nethogs             # Net bandwidth monitor
    bind                # DNS tools
    iwd                 # Wireless daemon
    impala              # Network query engine
    iwgtk               # Wireless configuration
    libnotify           # Desktop notifications
    gawk                # Pattern scanning tool
    iw                  # Wireless tools
    iftop               # Network usage monitor
    mtr                 # Network diagnostic tool
    nmap                # Network exploration tool
    speedtest-cli       # Internet speed test
    iperf               # Network performance tool
    rsync               # File synchronization

    # ==============================================================================
    # Security Tools
    # System security and encryption utilities
    # ==============================================================================
    age                 # Modern encryption tool
    openssl             # SSL/TLS toolkit
    sops                # Secrets management
    hblock              # Adblocker
    gnupg               # GNU Privacy Guard
    gcr                 # GNOME crypto services
    gnome-keyring       # Password management
    pinentry-gnome3     # PIN entry dialog

    # ==============================================================================
    # Development Tools
    # Programming and development utilities
    # ==============================================================================
    git                 # Version control
    gdb                 # GNU debugger
    nvd                 # Nix version diff
    ncdu                # Disk usage analyzer
    du-dust             # Disk usage utility
    cachix              # Binary cache
    nix-output-monitor  # Nix build monitor
    ollama              # LLM Runner
    go                  # Go runtime
    #ollama-webui        # Web arayüzü

    # ==============================================================================
    # SSH Tools
    # Secure shell utilities
    # ==============================================================================
    assh                # SSH configuration manager
    openssh             # OpenSSH client/server

    # ==============================================================================
    # Virtualization
    # Virtual machine and container support
    # ==============================================================================
    virt-manager        # VM management GUI
    virt-viewer         # VM display client
    qemu                # Machine emulator
    spice-gtk           # Remote display client
    win-virtio          # Windows drivers
    win-spice          # Windows guest tools
    swtpm               # TPM emulator
    podman              # Container engine

    # ==============================================================================
    # Power Management
    # Power control and monitoring
    # ==============================================================================
    upower              # Power management service
    acpi                # ACPI utilities
    powertop            # Power monitoring tool

    # ==============================================================================
    # Desktop Integration
    # System and desktop environment integration
    # ==============================================================================
    flatpak             # Application sandboxing
    xdg-desktop-portal  # Desktop integration portal
    xdg-desktop-portal-gtk # GTK portal backend

    # ==============================================================================
    # Media Tools
    # Audio and media utilities
    # ==============================================================================
    mpc-cli             # MPD client
    rmpc                # Rich MPD client
    acl                 # Access control lists
    lsb-release         # Distribution information

    # ==============================================================================
    # Remote Access
    # Remote desktop and access tools
    # ==============================================================================
    tigervnc            # VNC implementation
  ];
}
