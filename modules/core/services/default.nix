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
#   - Power management (TLP)
#
# Design Notes:
#   - Security/firewall ports managed in security module (not here)
#   - Single environment.systemPackages definition to avoid conflicts
#   - Services grouped by functionality for easier maintenance
#
# ==============================================================================

{ lib, pkgs, inputs, username, system, ... }:

{
  # ============================================================================
  # Flatpak Module Import
  # ============================================================================
  
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  # ============================================================================
  # Base System Services
  # ============================================================================
  
  services = {
    # --------------------------------------------------------------------------
    # File System & Storage
    # --------------------------------------------------------------------------
    gvfs.enable   = true;        # Virtual filesystem (MTP, SMB, Google Drive, archives)
    fstrim.enable = true;        # Weekly SSD TRIM for performance
    
    # --------------------------------------------------------------------------
    # Desktop Integration
    # --------------------------------------------------------------------------
    dbus = {
      enable = true;
      packages = with pkgs; [
        gcr                      # Certificate/key management
        gnome-keyring           # Password storage
      ];
    };
    
    blueman.enable = true;       # Bluetooth GUI manager
    touchegg.enable = false;     # Touch gestures (enable if needed)
    tumbler.enable = true;       # Thumbnail service
    
    # --------------------------------------------------------------------------
    # Hardware & Firmware
    # --------------------------------------------------------------------------
    fwupd.enable = true;         # Firmware update daemon
    spice-vdagentd.enable = true; # SPICE guest agent
    
    # --------------------------------------------------------------------------
    # Printing (Disabled by Default)
    # --------------------------------------------------------------------------
    printing.enable = false;     # CUPS printing
    avahi = {
      enable   = false;          # Network printer discovery
      nssmdns4 = false;
    };
    
    # --------------------------------------------------------------------------
    # Flatpak Configuration
    # --------------------------------------------------------------------------
    flatpak = {
      enable = true;
      
      # Package repositories
      remotes = [{
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }];
      
      # Pre-installed packages
      packages = [
        "com.github.tchx84.Flatseal"      # Flatpak permissions manager
        "io.github.everestapi.Olympus"     # Celeste mod manager
      ];
      
      # Wayland-first overrides (disable X11 fallback)
      overrides.global.Context.sockets = [
        "wayland"
        "!x11"
        "!fallback-x11"
      ];
    };
  };
  
  # Disable auto-install on activation (manual control preferred)
  systemd.services.flatpak-managed-install.enable = false;

  # ============================================================================
  # System Programs
  # ============================================================================
  
  programs = {
    # --------------------------------------------------------------------------
    # Gaming Stack
    # --------------------------------------------------------------------------
    steam = {
      enable = true;
      remotePlay.openFirewall      = true;   # Steam Remote Play
      dedicatedServer.openFirewall = false;  # No dedicated server
      gamescopeSession.enable      = true;   # Gamescope compositor session
      extraCompatPackages = [ pkgs.proton-ge-bin ];  # Proton GE
    };
    
    gamescope = {
      enable = true;
      capSysNice = true;         # Allow nice priority adjustment
      args = [
        "--rt"                   # Real-time scheduling
        "--expose-wayland"       # Wayland support
        "--adaptive-sync"        # VRR/FreeSync
        "--immediate-flips"      # Reduce latency
        "--force-grab-cursor"    # Better mouse capture
      ];
    };
    
    # --------------------------------------------------------------------------
    # Core System Programs
    # --------------------------------------------------------------------------
    dconf.enable = true;         # GNOME/GTK settings database
    zsh.enable = true;           # Z shell (user config separate)
    
    # Foreign binary support
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ ];  # Add libs as needed
    };
  };

  # ============================================================================
  # System Packages
  # ============================================================================
  
  environment.systemPackages = with pkgs; [
    # Power management
    #tlp                          # TLP power manager CLI
    
    # SPICE/Virtualization tools
    spice-gtk                    # SPICE GTK client
    spice-protocol               # SPICE protocol definitions
    virt-viewer                  # Virtual machine viewer
  ];
  
  ## Log TLP version on system switch (for verification)
  #system.activationScripts.tlpVersion = ''
  #  echo "[nixos-switch] $(date -Is) TLP: $(${pkgs.tlp}/bin/tlp --version || true)"
  #'';

  # ============================================================================
  # Virtualization Stack
  # ============================================================================
  
  virtualisation = {
    # --------------------------------------------------------------------------
    # Container Runtime
    # --------------------------------------------------------------------------
    containers = {
      enable = true;
      registries = {
        search   = [ "docker.io" "quay.io" ];
        insecure = [ ];
        block    = [ ];
      };
    };
    
    # Podman (Docker-compatible)
    podman = {
      enable = true;
      dockerCompat = true;       # Docker CLI compatibility
      defaultNetwork.settings.dns_enabled = true;
      
      # Automatic cleanup
      autoPrune = {
        enable = true;
        flags  = [ "--all" ];
        dates  = "weekly";
      };
      
      # Required packages
      extraPackages = with pkgs; [
        runc                     # OCI runtime
        conmon                   # Container monitor
        skopeo                   # Container image operations
        slirp4netns              # User-mode networking
      ];
    };
    
    # --------------------------------------------------------------------------
    # Virtual Machine Infrastructure
    # --------------------------------------------------------------------------
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;     # Software TPM emulation
        ovmf.enable = true;      # UEFI firmware (otomatik yüklenir)
      };
    };
    
    # USB passthrough for VMs
    spiceUSBRedirection.enable = true;
  };

  # ============================================================================
  # Udev Rules for Virtualization
  # ============================================================================
  
  services.udev.extraRules = ''
    # USB devices accessible to libvirt group (for guest passthrough)
    SUBSYSTEM=="usb", ATTR{idVendor}=="*", ATTR{idProduct}=="*", GROUP="libvirtd"
    
    # VFIO devices (GPU passthrough preparation)
    SUBSYSTEM=="vfio", GROUP="libvirtd"
    
    # KVM & vhost-net permissions
    KERNEL=="kvm", GROUP="kvm", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="vhost-net", GROUP="kvm", MODE="0664"
  '';
  
  # SPICE security wrapper for USB redirection
  security.wrappers.spice-client-glib-usb-acl-helper.source =
    "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
}

