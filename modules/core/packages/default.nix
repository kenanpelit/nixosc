# modules/core/packages/default.nix
# ==============================================================================
# System Core Packages — Infrastructure & Services
# ==============================================================================
#
# Module:      modules/core/packages
# Purpose:     System-wide essential packages for NixOS infrastructure
# Author:      Kenan Pelit
# Created:     2025-10-09
# Modified:    2025-11-15
#
# Architecture:
#   System Packages → System Services → Hardware Support → Infrastructure
#
# Design Philosophy:
#   • System-wide availability for critical infrastructure
#   • Only packages that make sense at *system* scope
#   • Focus on daemons, low-level tooling, drivers, security stack
#   • User applications belong in home-manager (this module violates that a bit;
#     see TODO notes below, but behaviour is preserved for now)
#
# Categories:
#   1. Core System Utilities
#   2. Boot & Initialization
#   3. Security & Encryption
#   4. Network Infrastructure
#   5. Virtualization & Containers
#   6. Power & Thermal Management
#   7. Hardware Management & Monitoring
#   8. Desktop Integration (XDG/portals)
#   9. System Services & Scheduling
#
# Scope:
#   ✓ System daemons and services
#   ✓ Kernel-related tools and drivers
#   ✓ Security infrastructure (GPG, keyring, firewall)
#   ✓ Hardware management and monitoring tools
#   ✗ Day-to-day user applications  → home-manager
#   ✗ Per-user dev tools            → home-manager
#
# ==============================================================================

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ==========================================================================
    # 1) Core System Utilities
    # ==========================================================================
    # Essential infrastructure tools; effectively part of the base system.

    # ---- Core GNU / Proc / ACL ----
    coreutils                    # Basic file/stream utilities (ls, cp, mv, rm, cat, …)
    procps                       # ps, top, kill, vmstat (process monitoring)
    sysstat                      # sar, iostat, mpstat (perf history & metrics)
    acl                          # POSIX ACL tools (getfacl, setfacl)
    lsb-release                  # LSB distro information helper
    man-pages                    # Manual pages (sections 1–8)

    # ---- Compression & Archiving ----
    gzip                         # gzip compression (logs, backups)
    gnutar                       # GNU tar (archive handling)

    # ---- Build Infrastructure ----
    # NOTE: These are system-wide to support things like DKMS or
    #       system-level tooling that may compile modules.
    gcc                          # GNU C compiler (kernel modules, low-level tools)
    gnumake                      # Make (build system)
    nodejs                       # Node.js runtime (used by some build chains)

    # ---- Core Libraries / Plumbing ----
    libdrm                       # Direct Rendering Manager userspace lib (GPU)
    libinput                     # Input device handling (Wayland/X11)
    libnotify                    # Desktop notifications (D-Bus)
    openssl                      # SSL/TLS crypto library (system-wide)

    # ==========================================================================
    # 2) Boot & System Initialization
    # ==========================================================================
    # Bootloader, firmware support and basic configuration tooling.

    # ---- Bootloader & Theming ----
    grub2                        # GRUB bootloader (UEFI/BIOS)
    catppuccin-grub              # Catppuccin GRUB theme

    # ---- System Configuration Stack ----
    home-manager                 # User environment manager (CLI)
    dconf                        # GNOME configuration database backend
    dconf-editor                 # GUI editor for dconf
    # TODO: dconf-editor is a pure user app; ideally move to home-manager.

    # ---- Firmware Management ----
    fwupd                        # LVFS-based firmware updates (UEFI/BIOS/devices)

    # ---- Scripting Runtime ----
    perl                         # Perl runtime for maintenance scripts
    perlPackages.FilePath        # File::Path (directory operations)

    # ==========================================================================
    # 3) Security & Encryption Infrastructure
    # ==========================================================================
    # Core cryptography, key management and basic firewall tooling.

    # ---- Cryptography & Secrets ----
    sops                         # Secret management (YAML/JSON/Nix with age/GPG)
    gnupg                        # GPG (crypto, signing, secret storage)

    # ---- GNOME Security Stack ----
    gcr                          # GNOME crypto/key management (D-Bus services)
    gnome-keyring                # Secret Service API implementation (keyring)
    pinentry-gnome3              # Graphical PIN entry for GPG (GNOME integration)

    # ---- Network Security / Filtering ----
    iptables                     # Traditional netfilter userspace tooling
    hblock                       # Hosts-based ad/tracker blocking

    # ==========================================================================
    # 4) Network Infrastructure
    # ==========================================================================
    # Network managers, SSH, DNS tools, and low-level helpers.

    # ---- Network Management ----
    networkmanagerapplet         # NM tray applet (WiFi/VPN UI)
    # TODO: This is clearly “user app” territory; behaviour kept, but
    #       long term it belongs in home-manager with your DE.
    iwd                          # iNet Wireless Daemon (modern WiFi backend)
    iw                           # Wireless configuration CLI

    # ---- Network Services ----
    bind                         # DNS tools/server (named, dig, nslookup, …)
    openssh                      # SSH client & server
    autossh                      # Auto-restarting SSH tunnels

    # ---- Network Utilities ----
    impala                       # Distributed SQL / networked query engine
    socat                        # Generic stream multiplexer (TCP/UDP/Unix)
    rsync                        # Delta file synchronization

    # ==========================================================================
    # 5) Virtualization & Container Infrastructure
    # ==========================================================================
    # VM tooling and containers. These *could* be host-specific, but you’ve
    # elected to keep them global; we respect that here.

    # ---- VM Management GUI / CLI ----
    virt-manager                 # Libvirt GUI (define/start/manage VMs)
    virt-viewer                  # SPICE/VNC viewer for VMs
    qemu                         # QEMU hypervisor (system/user-mode)

    # ---- Guest Integration / Drivers ----
    spice-gtk                    # SPICE GTK widget (used by virt-viewer, etc.)
    virtio-win                   # VirtIO drivers ISO for Windows guests
    win-spice                    # SPICE guest tools for Windows
    swtpm                        # Software TPM emulator (TPM 2.0 for VMs)

    # ---- Containers ----
    podman                       # Rootless OCI container engine (Docker alt.)
    # NOTE: Docker intentionally not present; Podman covers the use case.

    # ==========================================================================
    # 6) Power & Thermal Management
    # ==========================================================================
    # Power management / battery health / CPU power control.

    # ---- Power Management ----
    upower                       # Power/battery D-Bus interface
    acpi                         # ACPI battery/thermal reporting
    powertop                     # Intel power usage tuner
    poweralertd                  # Power/battery alert daemon

    # ---- Thermal & CPU Control ----
    lm_sensors                   # Hardware temps/fan sensors
    linuxPackages.turbostat      # Intel Turbo statistics
    linuxPackages.cpupower       # CPU frequency scaling tools
    auto-cpufreq                 # Automatic CPU freq governor daemon

    # ==========================================================================
    # 7) Hardware Management & Monitoring
    # ==========================================================================
    # GPU, storage, platform identification, USB/Android, etc.

    # ---- Display & GPU ----
    ddcutil                      # Control external monitor settings via DDC/CI
    intel-gpu-tools              # Intel GPU debugging/monitoring tools

    # ---- Storage / SSD ----
    smartmontools                # S.M.A.R.T. monitoring (smartctl/smartd)
    nvme-cli                     # NVMe SSD management & diagnostics

    # ---- System Information ----
    dmidecode                    # Read DMI/SMBIOS hardware tables

    # ---- USB & Android ----
    usbutils                     # lsusb + helpers
    android-tools                # ADB/Fastboot (Android; also useful infra-wise)

    # ==========================================================================
    # 8) Desktop Integration & XDG Stack
    # ==========================================================================
    # XDG specs and generic portals. DE-specific backends live in display module.

    xdg-utils                    # xdg-open, xdg-mime, etc.
    xdg-desktop-portal           # Generic portal service (D-Bus)
    xdg-desktop-portal-gtk       # GTK backend for portals
    # Note: Hyprland/GNOME/COSMIC specific portal backends are configured
    #       in the display module(s), not here.

    # ==========================================================================
    # 9) System Services & Task Scheduling
    # ==========================================================================
    # Scheduling and simple logging helpers.

    at                           # One-shot task scheduling (atd)
    logger                       # Syslog logger helper (if available in pkgs)
  ];
}

# ==============================================================================
# Package Scope Guidelines
# ==============================================================================
#
# INCLUDE here when:
#   ✓ The package provides a *system-level* daemon or service
#   ✓ It’s required for hardware support / monitoring / tuning
#   ✓ It’s part of security, crypto or keyring infrastructure
#   ✓ It must be available to all users by design (infra tooling)
#
# MOVE to home-manager when:
#   ✗ It’s a day-to-day GUI/CLI app (browser, editor, terminal, etc.)
#   ✗ It’s primarily per-user dev tooling (language runtimes, IDEs)
#   ✗ It’s DE-specific or user-preference-specific
#
# Quick sanity check:
#   “If I remove this from systemPackages and put it in home-manager,
#    does anything *system* break, or is it just less convenient for me?”
#   • System breakage  → Keep here
#   • Only personal convenience → Move to home-manager
#
# ==============================================================================
# Maintenance Notes
# ==============================================================================
#
# List all *system* packages:
#   $ nix-env -qa --installed
#
# Find system roots:
#   $ nix-store --gc --print-roots | grep /nix/store
#
# Find which package provides a file:
#   $ nix-locate bin/gcc
#
# Typical update flow:
#   $ nix flake update
#   $ sudo nixos-rebuild switch --flake .#hay
#
# Long-term TODO (when you feel like cleaning house):
#   • Move: dconf-editor, networkmanagerapplet, virt-manager, virt-viewer
#           and other pure user-facing apps into home-manager.
#   • Decide host-specific virtualization/container stacks instead of
#     installing everything on every host by default.
#
# ==============================================================================

