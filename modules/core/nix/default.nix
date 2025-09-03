# modules/core/nix/default.nix
# ==============================================================================
# AMAÇ:
# - Nix daemon, GC/optimizasyon, deneysel özellikler, Nixpkgs ayarları **ve**
#   binary cache/substituter yapılandırmasını **tek dosyada** toplamak.
#
# TASARIM NOTLARI:
# - "Cache" (substituters + public keys) doğrudan `nix.settings` altındadır;
#   Nix'in gerçek okuma noktası zaten burasıdır. Ayrı modüle gerek yok.
# - `programs.nh.clean.enable` açık olduğunda, iki ayrı GC zamanlayıcısı
#   çakışmasın diye `nix.gc.automatic`'i otomatik kapatıyoruz (mkIf ile).
# - Overlays ve unfree izinleri `nixpkgs` altında net.
#
# KAPSAM:
# - Daemon ayarları (allowed-users/trusted-users, sandboxing, keep-* bayrakları)
# - GC zamanlama & optimizasyon (nh ile entegre)
# - Deneysel özellikler (nix-command + flakes)
# - Nixpkgs config & overlays
# - Substituters & trusted-public-keys & connect-timeout
# - NH (Nix Helper) ayarları
# - Faydalı araçlar (nix-tree)
#
# Author: Kenan Pelit
# Last merged: 2025-09-03
# ==============================================================================

{ config, lib, pkgs, inputs, username, ... }:
{
  # =============================================================================
  # NIX DAEMON & STORE AYARLARI
  # =============================================================================
  nix = {
    settings = {
      # Kullanıcı erişimleri — root ve ana kullanıcı güvenilir olsun
      allowed-users = [ "${username}" "root" ];
      trusted-users = [ "${username}" "root" ];

      # Mağaza & sandbox tutarlılığı
      auto-optimise-store = true;   # dedup & store optimizasyonu
      keep-outputs       = true;    # output GC koruması
      keep-derivations   = true;    # drv GC koruması
      sandbox            = true;    # reproducible build'ler

      # ------------------------------------------------------------------------
      # CACHE (ÖNCEKİ modules/core/cache/default.nix BURAYA TAŞINDI)
      # ------------------------------------------------------------------------
      # Ağ zaman aşımı (uzak cache'e yavaş bağlanan ağlarda faydalı)
      connect-timeout = 100;

      # Substituters — binary cache kaynakları
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://nix-gaming.cachix.org"
      ];

      # Güvenilen public key'ler (sırasıyle cache kaynaklarına karşılık gelir)
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
    };

    # Çöp toplama — nh temizliği açıksa iki kez koşmasın
    gc = {
      automatic = lib.mkIf (!config.programs.nh.clean.enable) true;
      dates     = "weekly";
      options   = "--delete-older-than 30d";
    };

    # Store optimizasyon cron’u
    optimise = {
      automatic = true;
      dates = [ "03:00" ];
    };

    # Deneysel özellikler — flakes + yeni komut seti
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # =============================================================================
  # NIXPKGS AYARLARI (unfree + overlays)
  # =============================================================================
  nixpkgs = {
    config = {
      allowUnfree = true;  # Spotify, Chrome gibi paketler için
    };
    overlays = [
      inputs.nur.overlays.default  # NUR overlay
      # Başka overlay'lerin varsa buraya ekleyebilirsin.
    ];
  };

  # =============================================================================
  # NH (Nix Helper) — Flake yolu ve temizlik politikası
  # =============================================================================
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      # Son 7 günden beri kullanılan profilleri sakla, en az 5 profil tut.
      extraArgs = "--keep-since 7d --keep 5";
    };
    # Flake kökünü sabitle — CLI’de kolaylık sağlar (nh os switch vb.)
    flake = "/home/${username}/.nixosc";
  };

  # =============================================================================
  # Faydalı araçlar
  # =============================================================================
  environment.systemPackages = with pkgs; [
    nix-tree  # dependency graph keşfi için
  ];
}


