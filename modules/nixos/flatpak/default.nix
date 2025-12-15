# modules/nixos/flatpak/default.nix
# ==============================================================================
# NixOS Flatpak integration: system-wide remotes, overrides, and portals.
# Manage Flatpak enablement and permissions centrally for all hosts.
# Edit here to keep Flatpak policy consistent instead of per-user tweaks.
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
