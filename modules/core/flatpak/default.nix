{ inputs, pkgs, ... }:
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
    overrides = {
      global = {
        Context.sockets = [
          "wayland"
          "!x11"
          "!fallback-x11"
        ];
      };
    };
  };

  # Flatpak yönetilen kurulum servisini devre dışı bırak
  systemd.services.flatpak-managed-install.enable = false;

}
