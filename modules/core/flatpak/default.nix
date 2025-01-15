# modules/core/flatpak/default.nix
# ==============================================================================
# Flatpak Integration Configuration
# ==============================================================================
{ inputs, pkgs, ... }:
{
  # Nix-Flatpak Modülü
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
  
  # Flatpak Servis Yapılandırması
  services.flatpak = {
    enable = true;

    # Flatpak Kaynakları
    remotes = [{
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
    }];

    # Öntanımlı Paketler
    packages = [
      "com.github.tchx84.Flatseal"     # Flatpak izin yöneticisi
      "io.github.everestapi.Olympus"    # Celeste mod yükleyici
    ];

    # Sistem Geneli Geçersiz Kılmalar
    overrides = {
      global = {
        Context.sockets = [
          "wayland"           # Wayland desteğini etkinleştir
          "!x11"             # X11 desteğini devre dışı bırak
          "!fallback-x11"    # X11 yedeğini devre dışı bırak
        ];
      };
    };
  };

  # Otomatik Kurulum Servisi Devre Dışı
  systemd.services.flatpak-managed-install.enable = false;
}
