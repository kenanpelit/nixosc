# modules/home/flatpak/default.nix
{ pkgs, lib, inputs, ... }:

{
  # nix-flatpak'in Home Manager modülünü içe al
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  # Kullanıcı düzeyinde Flatpak yönetimi
  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    # Kullanıcıya kurulacak Flatpak uygulamaları
    packages = [
      "flathub:app/io.ente.auth/x86_64/stable"
    ];
  };
}


