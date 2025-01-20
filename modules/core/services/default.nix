# modules/core/services/default.nix
# ==============================================================================
# System Services Configuration
# ==============================================================================
# This configuration file manages system services including:
# - Core system services and daemons
# - Flatpak application management
# - Security and authorization services
# - Network service configuration
#
# Key components:
# - Base system services (gvfs, fstrim, dbus)
# - Flatpak integration and package management
# - Security and PolicyKit settings
# - Network service port configuration
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, ... }:
{
  # Import Flatpak Module
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  # =============================================================================
  # Flatpak Configuration
  # =============================================================================
  services.flatpak = {
    enable = true;
    
    # Flatpak Repositories
    remotes = [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];
    
    # Default Packages
    packages = [
      "com.github.tchx84.Flatseal"     # Flatpak permission manager
      "io.github.everestapi.Olympus"    # Celeste mod loader
    ];
    
    # System-wide Overrides
    overrides = {
      global = {
        Context.sockets = [
          "wayland"           # Enable Wayland support
          "!x11"             # Disable X11 support
          "!fallback-x11"    # Disable X11 fallback
        ];
      };
    };
  };

  # =============================================================================
  # Base System Services
  # =============================================================================
  services = {
    gvfs.enable = true;       # Virtual filesystem support
    fstrim.enable = true;     # SSD optimization service
    
    # D-Bus Configuration
    dbus = {
      enable = true;
      packages = [ pkgs.gcr ];  # GPG and encryption infrastructure
    };
    
    # Input Device Services
    touchegg.enable = false;    # Touchscreen gesture service
    
    # Ad Blocking
    hblock.enable = true;      # Enable hBlock for ad blocking
  };

  # =============================================================================
  # Security Configuration
  # =============================================================================
  security.polkit.enable = true;  # PolicyKit authorization manager

  # =============================================================================
  # Network Service Configuration
  # =============================================================================
  networking.firewall = {
    # Transmission Service Ports
    allowedTCPPorts = [ 9091 ];         # Web interface
    allowedTCPPortRanges = [{ 
      from = 51413; 
      to = 51413; 
    }];
    allowedUDPPortRanges = [{ 
      from = 51413; 
      to = 51413; 
    }];
  };

  # =============================================================================
  # Service Management
  # =============================================================================
  # Disable Automatic Installation Service
  systemd.services.flatpak-managed-install.enable = false;
}
