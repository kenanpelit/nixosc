# modules/core/services/default.nix
# ==============================================================================
# System Services & Virtualization Configuration
# ==============================================================================
#
# Module:      modules/core/services
# Purpose:     Unified system services, virtualization, gaming, and containerization
# Author:      Kenan Pelit
# Created:     2025-09-04
# Modified:    2025-11-29
#
# Architecture:
#   Base Services → Desktop Integration → Gaming Stack → Containers → VMs
#
# Service Categories:
#   1. Base Services       - GVFS, TRIM, D-Bus
#   2. Desktop Integration - Bluetooth, thumbnailer, Flatpak
#   3. Gaming Stack        - Steam, Gamescope, Proton-GE (physical host only)
#   4. Containers          - Podman + registries (physical host only)
#   5. Virtualization      - Libvirt/QEMU, SPICE, VFIO plumbing (physical host only)
#
# Design Principles:
#   • Only "host-level" services live here (no user apps)
#   • Security by default, performance where it matters (games / VMs / containers)
#   • Keep responsibilities separated: firewall/security live in security module
#
# ==============================================================================

{ lib, pkgs, inputs, username, system, hostRole ? "unknown", isPhysicalHost ? false, isVirtualHost ? false, ... }:

{
  # ============================================================================
  # Module Imports
  # ============================================================================
  # Declarative Flatpak management (remotes, apps, overrides)
  imports = [
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];

  # ============================================================================
  # Base System Services (Layer 1: Core Functionality)
  # ============================================================================
  services = {
    # --------------------------------------------------------------------------
    # File System & Storage
    # --------------------------------------------------------------------------
    # GVFS: virtual filesystems (MTP, SMB, archive mounts, Google Drive, etc.)
    gvfs.enable = true;

    # SSD TRIM: keep SSD performance consistent over time
    fstrim.enable = true;

    # --------------------------------------------------------------------------
    # Desktop Integration
    # --------------------------------------------------------------------------
    dbus = {
      enable = true;

      # Register GNOME crypto/key services on the system bus.
      # Not full keyring integration – PAM side is controlled in security module.
      packages = with pkgs; [
        gcr
        gnome-keyring
      ];
    };

    # Blueman: system tray Bluetooth manager (BlueZ backend)
    blueman.enable = true;

    # Touchegg: multi-touch gestures (disabled by default; opt-in per host)
    touchegg.enable = false;

    # Thumbnails for file managers (images, videos, PDFs, etc.)
    tumbler.enable = true;

    # --------------------------------------------------------------------------
    # Hardware & Firmware
    # --------------------------------------------------------------------------
    # fwupd: LVFS firmware updates (UEFI, SSD, peripherals)
    fwupd.enable = true;

    # SPICE guest agent – only useful *inside* VMs; keep defaulted off here.
    spice-vdagentd.enable = lib.mkDefault false;

    # --------------------------------------------------------------------------
    # Printing (off by default)
    # --------------------------------------------------------------------------
    printing.enable = false;

    avahi = {
      enable   = false;
      nssmdns4 = false;
    };

    # --------------------------------------------------------------------------
    # Accessibility Services (DISABLED)
    # --------------------------------------------------------------------------
    # Speech-dispatcher: System-wide TTS/screen reader service
    # Disabled to prevent auto-reading in browsers and applications
    # Affects: Orca screen reader, browser TTS, system announcements
    speechd.enable = lib.mkForce false;

    # --------------------------------------------------------------------------
    # Flatpak (via nix-flatpak)
    # --------------------------------------------------------------------------
    flatpak = {
      enable = true;

      remotes = [
        {
          name     = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];

      # System-wide Flatpaks (user apps → home-manager side)
      packages = [
        "com.github.tchx84.Flatseal"   # Permissions editor (practically mandatory)
        "io.github.everestapi.Olympus" # Celeste mod manager
      ];

      # Global sandbox defaults – Wayland first, X11 fallback.
      overrides.global = {
        Context = {
          sockets = [ "wayland" ];

          # If X11 should be completely disabled:
          # "!sockets" = [ "x11" "fallback-x11" ];
        };
      };
    };
  };

  # nix-flatpak managed install service – cut unnecessary I/O during rebuild.
  systemd.services.flatpak-managed-install.enable = false;

  # ============================================================================
  # Systemd Service Hardening (Layer 1.5: Prevent unwanted activation)
  # ============================================================================
  # Ensure speech-dispatcher cannot be socket-activated or started by D-Bus
  systemd.user.services.speech-dispatcher = {
    enable = false;
    unitConfig = {
      ConditionPathExists = "!/dev/null";  # Never start
    };
  };

  systemd.user.sockets.speech-dispatcher = {
    enable = false;
    unitConfig = {
      ConditionPathExists = "!/dev/null";  # Never start socket
    };
  };

  # ============================================================================
  # Environment Variables (Layer 1.6: Disable accessibility stack)
  # ============================================================================
  # Disable GTK/GNOME accessibility bridge to prevent TTS activation
  environment.sessionVariables = {
    GTK_A11Y = "none";        # Disable GTK accessibility
    NO_AT_BRIDGE = "1";       # Disable AT-SPI bridge
  };

  # ============================================================================
  # Core Programs (Layer 2: Desktop / Gaming / Foreign binaries)
  # ============================================================================
  programs = {
    # --------------------------------------------------------------------------
    # Gaming Stack: Steam + Gamescope
    # --------------------------------------------------------------------------
    steam = lib.mkIf isPhysicalHost {
      enable = true;

      # Steam Remote Play ports (UDP 27031–27036, TCP 27036–27037)
      remotePlay.openFirewall      = true;
      dedicatedServer.openFirewall = false;

      # Gamescope session (selectable "Gamescope Session" from login manager)
      gamescopeSession.enable = true;

      # Proton-GE: community Proton for game compatibility
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    gamescope = lib.mkIf isPhysicalHost {
      enable    = true;
      capSysNice = true;  # capability required for RT scheduling

      args = [
        "--rt"                # RT scheduler
        "--expose-wayland"    # Expose Wayland socket
        "--adaptive-sync"     # VRR/FreeSync/G-Sync
        "--immediate-flips"   # Minimum latency
        "--force-grab-cursor" # Force cursor grab in FPS games
      ];
    };

    # --------------------------------------------------------------------------
    # Desktop Core
    # --------------------------------------------------------------------------
    dconf.enable = true;  # GNOME / GTK settings database

    # Enables shell system-wide only; configs are in home-manager.
    zsh.enable = true;

    # --------------------------------------------------------------------------
    # Foreign Binary Support (nix-ld)
    # --------------------------------------------------------------------------
    nix-ld = {
      enable = true;

      # "Parking lot" to fill as missing libraries appear.
      libraries = with pkgs; [
        # stdenv.cc.cc.lib
        # zlib
        # xorg.libX11
        # mesa
        # vulkan-loader
      ];
    };
  };

  # ============================================================================
  # Host-level Packages (Layer 3: VM / SPICE clients)
  # ============================================================================
  environment.systemPackages = with pkgs; [
    spice-gtk
    spice-protocol
    virt-viewer
    # virt-manager  # Located in core packages module; no need to add again here.
  ];

  # ============================================================================
  # Virtualisation (Layer 4: Containers & VMs)
  # ============================================================================
  virtualisation = lib.mkIf isPhysicalHost {
    # --------------------------------------------------------------------------
    # Podman (rootless Docker alternative)
    # --------------------------------------------------------------------------
    podman = {
      enable = true;

      # Docker socket compatibility – to break "docker" obsession in tooling.
      dockerCompat = true;

      # Rootless network DNS
      defaultNetwork.settings.dns_enabled = true;

      # Weekly auto-prune – prevent disk bloat.
      autoPrune = {
        enable = true;
        flags  = [ "--all" ];
        dates  = "weekly";
      };

      extraPackages = with pkgs; [
        runc
        conmon
        skopeo
        slirp4netns
      ];
    };

    # Container registry configuration – let this be the SINGLE authority.
    containers.registries = {
      search = [ "docker.io" "quay.io" ];
      insecure = [
        # "registry.internal.example"
      ];
      block = [
        # "sketchy-registry.com"
      ];
    };

    # --------------------------------------------------------------------------
    # Libvirt / QEMU (full virtualization)
    # --------------------------------------------------------------------------
    libvirtd = {
      enable = true;

      qemu.swtpm.enable = true;

      # OVMF note:
      # - You are carrying the OVMF package in core packages.
      # - OVMF is auto enabled/detected, don't touch unless extra override needed.
      # qemu.ovmf.enable = true;
    };

    # SPICE USB redirection – to pass USB to VM via libvirt
    spiceUSBRedirection.enable = true;
  };

  # ============================================================================
  # Udev Rules (Layer 5: KVM / VFIO permissions)
  # ============================================================================
  services.udev.extraRules = ''
    # --------------------------------------------------------------------------
    # VFIO (GPU Passthrough)
    # --------------------------------------------------------------------------
    SUBSYSTEM=="vfio", GROUP="libvirtd"

    # --------------------------------------------------------------------------
    # KVM & vhost-net – acceleration
    # --------------------------------------------------------------------------
    KERNEL=="kvm",            GROUP="kvm", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="vhost-net", GROUP="kvm", MODE="0664"

    # --------------------------------------------------------------------------
    # Example USB passthrough rules (disabled)
    # --------------------------------------------------------------------------
    # SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c534", GROUP="libvirtd"
    # SUBSYSTEM=="usb", ATTR{idVendor}=="1050", ATTR{idProduct}=="0407", GROUP="libvirtd"
  '';

  # ============================================================================
  # Security wrappers
  # ============================================================================
  # SPICE USB wrapper is already handled by spiceUSBRedirection.enable.
}