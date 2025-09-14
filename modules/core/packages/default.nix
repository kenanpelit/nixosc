# modules/core/packages/default.nix
# ==============================================================================
# System Core Packages Configuration
# ==============================================================================
#
# Module: modules/core/packages
# Author: Kenan Pelit
#
# Purpose: System-level essential packages for NixOS infrastructure
#
# Categories:
#   - Critical system services and daemons
#   - Security and authentication infrastructure
#   - Hardware management and firmware
#   - Kernel modules and drivers
#   - Virtualization infrastructure
#   - System libraries and dependencies
#
# Note: These packages are installed system-wide and accessible to all users
#
# ==============================================================================

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ============================================================================
    # Core System Utilities
    # ============================================================================
    
    # Essential GNU/Linux Tools
    coreutils                    # GNU core utilities (critical for system)
    procps                       # Process management tools
    sysstat                      # System performance monitoring
    acl                          # File access control lists
    lsb-release                  # Linux Standard Base information
    man-pages                    # System manual pages
    gzip                         # Compression (system logs)
    gnutar                       # Archiving (system backups)
    
    # Build Essentials (for kernel modules)
    gcc                          # GNU C compiler
    gnumake                      # Make build system
    nodejs                       # Node.js runtime
    
    # Core System Libraries
    libdrm                       # Direct Rendering Manager (GPU interface)
    libinput                     # Input device management library
    libnotify                    # System notifications infrastructure
    openssl                      # SSL/TLS library (system services)

    # ============================================================================
    # Boot & System Management
    # ============================================================================
    
    # Boot Infrastructure
    grub2                        # GRUB bootloader
    catppuccin-grub             # GRUB theme files
    
    # System Configuration
    home-manager                 # User environment management
    dconf                        # System configuration database
    dconf-editor                 # GUI for dconf
    
    # Firmware Management
    fwupd                        # UEFI/BIOS firmware updates
    
    # Scripting Support
    perl                         # System scripts runtime
    perlPackages.FilePath        # File::Path module for scripts

    # ============================================================================
    # Security & Encryption
    # ============================================================================
    
    # Core Security
    sops                         # Secrets management
    gnupg                        # GPG encryption (package signatures)
    
    # GNOME Security Services
    gcr                          # Certificate and key management
    gnome-keyring               # System-wide password store
    pinentry-gnome3             # PIN entry for GNOME
    
    # Network Security
    iptables                     # Kernel firewall management
    hblock                       # Host-based ad blocker

    # ============================================================================
    # Network Infrastructure
    # ============================================================================
    
    # Network Management
    networkmanagerapplet         # NetworkManager system tray
    iwd                          # Intel Wireless Daemon
    iw                           # Wireless kernel tools
    
    # Network Services
    bind                         # DNS server utilities
    openssh                      # SSH daemon and client
    autossh                      # Automatic SSH tunnel management
    
    # Network Tools
    impala                       # Network query engine
    socat                        # Multipurpose relay for services
    rsync                        # File synchronization (backups)

    # ============================================================================
    # Virtualization & Containers
    # ============================================================================
    
    # Virtual Machine Management
    virt-manager                 # Libvirt GUI manager
    virt-viewer                  # SPICE/VNC viewer
    qemu                         # QEMU hypervisor
    
    # VM Support Infrastructure
    spice-gtk                    # SPICE protocol support
    win-virtio                   # VirtIO Windows drivers
    win-spice                    # SPICE Windows tools
    swtpm                        # Software TPM emulator
    
    # Container Runtime
    podman                       # Rootless container daemon

    # ============================================================================
    # Power & Thermal Management
    # ============================================================================
    
    # Power Management
    upower                       # Power management daemon
    acpi                         # ACPI kernel interface
    powertop                     # Intel power optimization
    poweralertd                  # Power events daemon
    
    # Thermal Control
    lm_sensors                   # Hardware sensor drivers
    linuxPackages.turbostat      # Intel Turbo Boost monitor
    linuxPackages.cpupower       # CPU power management (kernel)
    auto-cpufreq                 # CPU frequency scaling daemon
    
    # ============================================================================
    # Hardware Management
    # ============================================================================
    
    # Display & Graphics
    ddcutil                      # DDC/CI monitor control
    intel-gpu-tools              # Intel GPU kernel tools
    
    # Storage
    smartmontools                # Disk S.M.A.R.T. daemon
    nvme-cli                     # NVMe kernel driver interface
    
    # System Information
    dmidecode                    # BIOS/UEFI DMI information
    
    # USB & Peripherals
    usbutils                     # USB bus management
    android-tools                # ADB/Fastboot (udev rules)

    # ============================================================================
    # Desktop Integration
    # ============================================================================
    
    # XDG Desktop Standards
    xdg-utils                    # XDG specification tools
    xdg-desktop-portal           # Portal service
    xdg-desktop-portal-gtk       # GTK portal backend

    # ============================================================================
    # System Services & Scheduling
    # ============================================================================
    
    at                           # System task scheduler
    logger                       # Syslog message sender
  ];
}
