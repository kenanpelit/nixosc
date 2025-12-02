# modules/core/flatpak/default.nix
# ==============================================================================
# Flatpak Configuration
# ==============================================================================
# Enables Flatpak support via the nix-flatpak module.
# - Configures Flathub remote
# - Installs base Flatpak applications (Flatseal, Olympus)
# - Sets global overrides (Wayland socket)
#
# ==============================================================================

{ inputs, lib, ... }:

{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  services.flatpak = {
    enable = true;
    remotes = [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];
    packages = [
      "com.github.tchx84.Flatseal"
      "io.github.everestapi.Olympus"
    ];
    overrides.global.Context.sockets = [ "wayland" ];
  };

  systemd.services.flatpak-managed-install.enable = false;
}
