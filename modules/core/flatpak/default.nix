# modules/core/flatpak/default.nix
# ==============================================================================
# Flatpak Service Configuration
# ==============================================================================
# This configuration manages Flatpak settings including:
# - Repository management (Flathub integration)
# - Default package installation
# - System-wide overrides and permissions
# - Wayland-first configuration

# Author: Kenan Pelit
# ==============================================================================

{ inputs, ... }:
{
  # Import Flatpak Module
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

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

  # Disable Automatic Installation Service
  systemd.services.flatpak-managed-install.enable = false;
}
