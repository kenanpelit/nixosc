# modules/nixos/flatpak/default.nix
# ==============================================================================
# NixOS module for flatpak (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
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
