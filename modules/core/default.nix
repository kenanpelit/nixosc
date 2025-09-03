# modules/core/default.nix
# ==============================================================================
# Core System Configuration (Consolidated Imports)
# ==============================================================================
# AMAÇ:
#   Tüm çekirdek modülleri tek yerden, tutarlı bir sıra ile içe aktarmak.
#   Bu dosya SADECE "ne nereden geliyor?" bilgisini taşır; asıl ayarlar
#   ilgili modüllerin kendi default.nix dosyalarındadır.
#
# TEK OTORİTE İLKELERİ (çok önemli):
#   - Güvenlik duvarı/portlar  →  modules/core/security   (başka yerde TANIMLAMA)
#   - TCP/IP kernel ayarları   →  modules/core/networking (eski tcp burada birleşik)
#   - Sanallaştırma/Oyun/Flatpak → modules/core/services  (tek yerde)
#   - Kullanıcı/uid/gruplar + Home-Manager → modules/core/account
#     (DBus/Keyring ise services’ta — account’a koymuyoruz)
#
# SIRALAMA (pratik bağımlılıkları gözetir):
#   1) Kimlik/hesap ve temel sistem (account, system)
#   2) Nix ekosistemi (nix) ve temel paketler (packages)
#   3) Görsel yığın (display) — (Wayland/Hyprland/Fonts/XDG)
#   4) Ağ (networking) — (NM/resolved/VPN + TCP sysctl)
#   5) Güvenlik (security/sops) — (firewall tek otorite)
#   6) Servis ekosistemi (services) — (flatpak + virt + gaming + core programs)
#
# KULLANIM İPUÇLARI:
#   - Port açacaksanız: SADECE ./security altında yapın.
#   - TCP tuningi değiştirecekseniz: SADECE ./networking altında yapın.
#   - Flatpak/Steam/Libvirt/Podman ve dconf/zsh/nix-ld: SADECE ./services altında.
#   - Home-Manager: Kullanıcıyla birlikte ./account içinde tanımlı (tek otorite).
#
# BAĞIMLILIK:
#   - Bazı modüller `inputs` ister:
#       • ./display  → inputs.hyprland
#       • ./services → inputs.nix-flatpak
#       • ./account  → home-manager için inputs/username/host geçer
#     Flake’te `specialArgs = { inherit inputs username host; };` verildiğinden emin olun.
#
# Author: Kenan Pelit
# Last updated: 2025-09-03
# ==============================================================================
{ inputs, nixpkgs, self, username, host, lib, ... }:
{
  imports = [
    # ==========================================================================
    # 1) System Foundation
    # ==========================================================================
    ./account       # Kullanıcı/UID/gruplar + Home-Manager (DBus/Keyring services’ta)
    ./system        # Çekirdek sistem: (boot + donanım + termal + güç yönetimi)

    # ==========================================================================
    # 2) Package Management & Development
    # ==========================================================================
    ./nix           # Nix daemon/GC/optimize, NUR overlay, NH, substituter’lar
    ./packages      # Sistem çapında temel araçlar ve kütüphaneler

    # ==========================================================================
    # 3) Desktop Environment & Media
    # ==========================================================================
    ./display       # X11/Wayland/Hyprland, GDM/GNOME, fonts & XDG portal seti

    # ==========================================================================
    # 4) Network & Connectivity
    # ==========================================================================
    ./networking    # NM + resolved + Mullvad/WG + DNS; TCP sysctl’ler (eski tcp)

    # ==========================================================================
    # 5) Security & Authentication
    # ==========================================================================
    ./security      # Firewall (TEK otorite), PAM/Polkit, AppArmor, SSH, hBlock
    ./sops          # Secrets yönetimi (sops-nix, anahtar yaşam döngüsü)

    # ==========================================================================
    # 6) Services & Applications
    # ==========================================================================
    ./services      # Flatpak (inputs.nix-flatpak), Podman/Libvirt/SPICE, Steam/Gamescope, core programs
  ];
}


