# modules/core/services/default.nix
# ==============================================================================
# System Services & Virtualization Module
# ==============================================================================
#
# Module: modules/core/services
# Author: Kenan Pelit
# Date:   2025-09-04
#
# Purpose: Unified configuration for system services, virtualization, gaming, and Flatpak
#
# Scope:
#   - Base services: GVFS, TRIM, D-Bus, Bluetooth, firmware updates
#   - Flatpak with Wayland-first configuration
#   - Gaming: Steam + Gamescope (low-latency optimizations)
#   - Virtualization: Podman (Docker compat), Libvirt/QEMU (TPM/OVMF), SPICE
#   - Core programs: dconf, zsh, nix-ld
#
# Design Notes:
#   - Security/firewall rules live in the security module (not here).
#   - Keep package lists minimal; avoid duplication across modules.
#   - Prefer safe defaults; make aggressive changes opt-in and documented.
#
# ==============================================================================

{ lib, pkgs, inputs, username, system, ... }:

{
  # ============================================================================
  # Flatpak Module Import
  # ----------------------------------------------------------------------------
  # Why: use nix-flatpak for managed remotes, packages, and sandbox overrides.
  # ----------------------------------------------------------------------------
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  # ============================================================================
  # Base System Services
  # ============================================================================
  services = {
    # --------------------------------------------------------------------------
    # File System & Storage
    # --------------------------------------------------------------------------
    gvfs.enable   = true;  # Virtual filesystem (MTP/SMB/Google Drive/archives)
    fstrim.enable = true;  # Weekly SSD TRIM to maintain performance

    # --------------------------------------------------------------------------
    # Desktop Integration
    # --------------------------------------------------------------------------
    dbus.enable = true;
    # NOTE: Adding gnome-keyring to D-Bus packages does not wire PAM/display
    # manager integration by itself. See "programs.gnome-keyring" below.
    dbus.packages = with pkgs; [
      gcr            # Certificate & key management helpers
      gnome-keyring  # Keyring daemon
    ];

    blueman.enable = true;   # Bluetooth tray UI
    touchegg.enable = false; # Touch gestures (opt-in)
    tumbler.enable = true;   # Thumbnailer service

    # --------------------------------------------------------------------------
    # Hardware & Firmware
    # --------------------------------------------------------------------------
    fwupd.enable = true;                           # LVFS firmware updates
    spice-vdagentd.enable = lib.mkDefault false;   # Usually needed on guests, not host

    # --------------------------------------------------------------------------
    # Printing (disabled by default)
    # --------------------------------------------------------------------------
    printing.enable = false;  # CUPS
    avahi = {
      enable   = false;       # mDNS-based printer discovery
      nssmdns4 = false;
    };

    # --------------------------------------------------------------------------
    # Flatpak Configuration
    # --------------------------------------------------------------------------
    flatpak = {
      enable = true;

      # Remote repositories
      remotes = [{
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }];

      # Pre-installed apps
      packages = [
        "com.github.tchx84.Flatseal"   # Flatpak permissions manager
        "io.github.everestapi.Olympus" # Celeste mod manager
      ];

      # Wayland-first defaults; keep X11 fallback enabled for compatibility.
      # If you are sure all apps you need support Wayland, you can remove the
      # X11 sockets via the commented line below.
      overrides = {
        global = {
          Context = {
            sockets = [ "wayland" ];
            # To disable X11 fallbacks entirely, uncomment:
            # "!sockets" = [ "x11" "fallback-x11" ];
          };
        };
      };
    };
  };

  # Prefer manual control over nix-flatpak’s auto-installer on activation.
  systemd.services.flatpak-managed-install.enable = false;

  # ============================================================================
  # Core System Programs
  # ============================================================================
  programs = {
    # --------------------------------------------------------------------------
    # Gaming Stack
    # --------------------------------------------------------------------------
    # NOTE: Ensure 32-bit graphics userspace is enabled elsewhere for Steam:
    #   hardware.graphics.enable = true;
    #   hardware.graphics.enable32Bit = true;
    steam = {
      enable = true;
      remotePlay.openFirewall      = true;   # Steam Remote Play ports
      dedicatedServer.openFirewall = false;  # No server ports
      gamescopeSession.enable      = true;   # Gamescope-backed session
      extraCompatPackages = [ pkgs.proton-ge-bin ];  # Proton-GE for wider compat
    };

    gamescope = {
      enable     = true;
      capSysNice = true;    # Allow RT/nice changes without sudo
      args = [
        "--rt"                # Real-time scheduling for lower latency
        "--expose-wayland"    # Wayland support
        "--adaptive-sync"     # VRR / FreeSync
        "--immediate-flips"   # Reduce latency further
        "--force-grab-cursor" # Better mouse capture
      ];
    };

    # --------------------------------------------------------------------------
    # Desktop/CLI Core
    # --------------------------------------------------------------------------
    dconf.enable = true;  # GNOME/GTK settings database
    zsh.enable   = true;  # System-wide zsh (user dotfiles elsewhere)

    # GNOME Keyring (optional but recommended if you rely on it)
    # This enables PAM/display-manager integration properly.
    # programs.gnome-keyring.enable = true;

    # Foreign binary support: resolve shared libs for non-Nix binaries
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Add libraries here if a foreign binary complains about missing .so's
        # stdenv.cc.cc.lib
        # zlib
      ];
    };
  };

  # ============================================================================
  # System Packages (host-side convenience tools)
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Power management CLI is handled in the power module.
    # tlp

    # SPICE / virtualization clients
    spice-gtk
    spice-protocol
    virt-viewer
  ];

  # Example (disabled): log TLP version after switch
  # system.activationScripts.tlpVersion = ''
  #   echo "[nixos-switch] $(date -Is) TLP: $(${pkgs.tlp}/bin/tlp --version || true)"
  # '';

  # ============================================================================
  # Virtualization Stack
  # ============================================================================
  virtualisation = {
    # --------------------------------------------------------------------------
    # Podman (Docker-compatible)
    # --------------------------------------------------------------------------
    podman = {
      enable = true;
      dockerCompat = true;                     # Provide Docker CLI/socket compat
      defaultNetwork.settings.dns_enabled = true;

      # Automatic cleanup
      autoPrune = {
        enable = true;
        flags  = [ "--all" ];
        dates  = "weekly";
      };

      extraPackages = with pkgs; [
        runc         # OCI runtime
        conmon       # Container monitor
        skopeo       # Image copying/inspecting/signing
        slirp4netns  # Rootless user-mode networking
      ];
    };

    # IMPORTANT: Configure registries via the containers module (this generates
    # /etc/containers/registries.conf). Do not also write environment.etc for it.
    containers.registries = {
      search   = [ "docker.io" "quay.io" ];
      insecure = [ ];
      block    = [ ];
    };

    # --------------------------------------------------------------------------
    # Libvirt / QEMU
    # --------------------------------------------------------------------------
    libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;  # TPM device (e.g., for Windows 11 / BitLocker)
      # OVMF/UEFI firmware is typically provided via pkgs.OVMF in host profiles.
    };

    # SPICE USB redirection helper/wrapper & policies
    spiceUSBRedirection.enable = true;
  };

  # ============================================================================
  # Udev Rules for Virtualization
  # ============================================================================
  # Keep rules minimal and principle-of-least-privilege. Avoid granting all USB
  # devices to libvirtd (overly broad). If needed, scope to specific devices.
  services.udev.extraRules = ''
    # VFIO devices (GPU passthrough preparation)
    SUBSYSTEM=="vfio", GROUP="libvirtd"

    # KVM & vhost-net permissions (for virtio-net acceleration)
    KERNEL=="kvm", GROUP="kvm", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="vhost-net", GROUP="kvm", MODE="0664"

    # Example: allow a specific USB device for passthrough
    # SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c534", GROUP="libvirtd"
  '';

  # ----------------------------------------------------------------------------
  # NOTE: No explicit SPICE wrapper is needed here — spiceUSBRedirection module
  # already installs a secure wrapper and polkit rules for USB redirection.
  # ----------------------------------------------------------------------------
  # security.wrappers.spice-client-glib-usb-acl-helper.source =
  #   "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
}
