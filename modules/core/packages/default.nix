# modules/core/packages/default.nix
# ==============================================================================
# System Core Packages - Infrastructure & Services
# ==============================================================================
#
# Module:      modules/core/packages
# Purpose:     System-wide essential packages for NixOS infrastructure
# Author:      Kenan Pelit
# Created:     2025-10-09
# Modified:    2025-10-18
#
# Architecture:
#   System Packages → System Services → Hardware Support → Infrastructure
#
# Design Philosophy:
#   • System-wide availability (all users can access)
#   • Essential services only (not user applications)
#   • Infrastructure components (daemons, libraries, drivers)
#   • Security-critical packages (GPG, keyring, firewall)
#
# Categories:
#   1. Core System Utilities    - GNU coreutils, build tools
#   2. Boot & Initialization    - GRUB, firmware, systemd tools
#   3. Security & Encryption    - GPG, keyring, secrets management
#   4. Network Infrastructure   - NetworkManager, SSH, DNS
#   5. Virtualization           - QEMU, libvirt, Podman
#   6. Power Management         - Thermal control, CPU scaling
#   7. Hardware Support         - GPU tools, sensors, storage
#   8. Desktop Integration      - XDG portals, system notifications
#
# Scope:
#   ✓ System daemons and services
#   ✓ Kernel modules and drivers
#   ✓ Security infrastructure
#   ✓ Hardware management tools
#   ✗ User applications (managed via home-manager)
#   ✗ Development tools (user-specific)
#
# ==============================================================================

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ==========================================================================
    # Core System Utilities
    # ==========================================================================
    # Essential GNU/Linux infrastructure - required for system operation
    
    # ---- GNU Core Utilities ----
    coreutils                    # ls, cp, mv, rm, cat, etc. (CRITICAL)
    procps                       # ps, top, kill, vmstat (process management)
    sysstat                      # sar, iostat, mpstat (performance monitoring)
    acl                          # getfacl, setfacl (POSIX access control)
    lsb-release                  # Distribution information (LSB standard)
    man-pages                    # System manual pages (section 1-8)
    
    # ---- Compression & Archiving ----
    gzip                         # System log rotation compression
    gnutar                       # System backup archiving (tar format)
    
    # ---- Build Infrastructure ----
    # Required for kernel module compilation (DKMS)
    gcc                          # GNU C compiler (kernel builds)
    gnumake                      # Build system (kernel modules)
    nodejs                       # Node.js runtime (build scripts)
    
    # ---- System Libraries ----
    # Low-level infrastructure libraries
    libdrm                       # Direct Rendering Manager (GPU kernel interface)
    libinput                     # Input device handling (Wayland/X11)
    libnotify                    # Desktop notification protocol (D-Bus)
    openssl                      # SSL/TLS crypto (system services, certificates)

    # ==========================================================================
    # Boot & System Initialization
    # ==========================================================================
    # Boot loader, firmware, and early system setup
    
    # ---- Bootloader ----
    grub2                        # GRUB bootloader (UEFI/BIOS)
    catppuccin-grub              # GRUB theme (Catppuccin color scheme)
    
    # ---- System Configuration ----
    home-manager                 # User environment management (CLI)
    dconf                        # GNOME configuration database (GSettings)
    dconf-editor                 # GUI editor for dconf database
    
    # ---- Firmware Management ----
    fwupd                        # UEFI/BIOS/device firmware updates (LVFS)
    
    # ---- Scripting Runtime ----
    perl                         # System maintenance scripts
    perlPackages.FilePath        # File::Path module (path manipulation)

    # ==========================================================================
    # Security & Encryption Infrastructure
    # ==========================================================================
    # Critical security components - handle with care
    
    # ---- Core Cryptography ----
    sops                         # Secrets OPerationS (encrypted config files)
    gnupg                        # GPG encryption (package signing, secrets)
    
    # ---- GNOME Security Stack ----
    # Integrates with GDM and session management
    gcr                          # GNOME Certificate/Key management (D-Bus)
    gnome-keyring                # Password storage daemon (Secret Service API)
    pinentry-gnome3              # GPG PIN entry dialog (GNOME integration)
    
    # ---- Network Security ----
    iptables                     # Kernel packet filter (firewall rules)
    hblock                       # DNS-based ad/tracker blocking (hosts file)

    # ==========================================================================
    # Network Infrastructure
    # ==========================================================================
    # Network services, daemons, and management tools
    
    # ---- Network Management ----
    networkmanagerapplet         # System tray applet (WiFi/VPN control)
    iwd                          # Intel Wireless Daemon (modern WiFi backend)
    iw                           # Wireless kernel configuration tool
    
    # ---- Network Services ----
    bind                         # DNS server utilities (dig, nslookup, named)
    openssh                      # SSH daemon and client (secure shell)
    autossh                      # Automatic SSH tunnel keeper (reconnects)
    
    # ---- Network Utilities ----
    impala                       # Network query engine (distributed SQL)
    socat                        # Multipurpose relay (TCP/UDP/Unix sockets)
    rsync                        # File synchronization (backups, mirroring)

    # ==========================================================================
    # Virtualization & Container Infrastructure
    # ==========================================================================
    # QEMU/KVM virtual machines and containerization
    
    # ---- Virtual Machine Management ----
    virt-manager                 # Libvirt GUI (manage VMs graphically)
    virt-viewer                  # VM console viewer (SPICE/VNC client)
    qemu                         # QEMU hypervisor (full system emulation)
    
    # ---- VM Guest Support ----
    # Tools and drivers for Windows/Linux guests
    spice-gtk                    # SPICE protocol GTK widget (remote display)
    win-virtio                   # VirtIO drivers ISO for Windows guests
    win-spice                    # SPICE guest tools for Windows
    swtpm                        # Software TPM emulator (TPM 2.0 for VMs)
    
    # ---- Container Runtime ----
    podman                       # Rootless OCI containers (Docker alternative)
    # Note: No Docker - Podman is more secure (rootless by default)

    # ==========================================================================
    # Power & Thermal Management
    # ==========================================================================
    # Battery, CPU, and thermal control for laptops
    
    # ---- Power Management ----
    upower                       # Battery/power state daemon (D-Bus interface)
    acpi                         # ACPI kernel interface tools (battery info)
    powertop                     # Intel power optimization analyzer
    poweralertd                  # Power event notification daemon (low battery)
    
    # ---- Thermal & CPU Control ----
    lm_sensors                   # Hardware sensor kernel drivers (temp, fan)
    linuxPackages.turbostat      # Intel Turbo Boost monitoring (kernel tool)
    linuxPackages.cpupower       # CPU frequency scaling control (kernel)
    auto-cpufreq                 # Automatic CPU frequency daemon (battery saver)
    
    # ==========================================================================
    # Hardware Management & Monitoring
    # ==========================================================================
    # Low-level hardware access and monitoring tools
    
    # ---- Display & Graphics ----
    ddcutil                      # DDC/CI monitor control (brightness, input)
    intel-gpu-tools              # Intel GPU debugging (intel_gpu_top, etc.)
    
    # ---- Storage Management ----
    smartmontools                # S.M.A.R.T. disk health daemon (smartd)
    nvme-cli                     # NVMe SSD management (nvme-cli commands)
    
    # ---- System Information ----
    dmidecode                    # DMI/SMBIOS table reader (hardware info)
    
    # ---- USB & Peripherals ----
    usbutils                     # USB device management (lsusb, usb-devices)
    android-tools                # ADB/Fastboot (Android debugging, udev rules)

    # ==========================================================================
    # Desktop Integration & Standards
    # ==========================================================================
    # XDG specifications and desktop portal services
    
    # ---- XDG Standards ----
    xdg-utils                    # xdg-open, xdg-mime (file associations)
    xdg-desktop-portal           # Desktop portal service (D-Bus API)
    xdg-desktop-portal-gtk       # GTK portal backend (file picker, notifications)
    # Note: Hyprland/GNOME/COSMIC portals managed in display module

    # ==========================================================================
    # System Services & Task Scheduling
    # ==========================================================================
    # Background job scheduling and logging
    
    at                           # System task scheduler (atd daemon)
    logger                       # Syslog message sender (log to journal)
  ];
}

# ==============================================================================
# Package Scope Guidelines
# ==============================================================================
#
# INCLUDE in this module:
#   ✓ System daemons (need root privileges)
#   ✓ Kernel modules and drivers
#   ✓ Security infrastructure (GPG, keyring)
#   ✓ Hardware management tools
#   ✓ Network services (SSH, DNS)
#   ✓ Boot/firmware tools
#
# EXCLUDE from this module (use home-manager instead):
#   ✗ User applications (browsers, editors, terminals)
#   ✗ Development tools (unless needed for kernel builds)
#   ✗ Desktop apps (file managers, media players)
#   ✗ CLI productivity tools (unless system-critical)
#
# Decision Framework:
#   Ask: "Does this package require root privileges or system-wide availability?"
#   Yes → Include here (environment.systemPackages)
#   No  → Move to home-manager (home.packages)
#
# ==============================================================================
# Maintenance Notes
# ==============================================================================
#
# Check for orphaned packages:
#   nix-store --gc --print-roots | grep /nix/store
#
# List all system packages:
#   nix-env -qa --installed
#
# Find which package provides a file:
#   nix-locate bin/gcc
#
# Update packages:
#   nix flake update
#   sudo nixos-rebuild switch --flake .#hay
#
# ==============================================================================

