# modules/core/services/default.nix
# ==============================================================================
# Base System Services (Merged: services + virtualisation + gaming + flatpak)
# ==============================================================================
# AMAÇ (Neden tek dosya?):
# - “Servis ekosistemi”ni tek yerde yönetmek: sistem servisleri, Flatpak, oyun
#   yığını (Steam/Gamescope) ve sanallaştırma (Podman/Libvirt/SPICE).
# - “Nerede ne vardı?” sorusunu bitirmek ve çakışmaları önlemek.
#
# TASARIM İLKELERİ:
# 1) **Temel servisler**: GVFS, TRIM, D-Bus + keyring, Bluetooth, fwupd, tumbler.
# 2) **Flatpak**: inputs tabanlı modül import’u (nix-flatpak), Wayland-first.
# 3) **Gaming**: Steam + Gamescope (düşük gecikme argümanları ile).
# 4) **Sanallaştırma**: Podman (dockerCompat), Libvirt+QEMU (TPM/OVMF), SPICE.
# 5) **Core Programs**: dconf/zsh/nix-ld gibi çekirdek program toggles’ları da
#    burada — çünkü pratikte desktop ekosistemi ve servislerle birlikte ele alınıyor.
#
# ÖNEMLİ NOTLAR:
# - Firewall/port yönetimi **security** modülünde (TEK otorite). Burada port açmayız.
# - hBlock **security** modülünde; burada enable etmiyoruz (çifte tanımı önlemek için).
#   listeleri birleştirir (append); çakışma olmaz.
# - NixOS’ta “servisi mask’la” için `systemd.services.<name>.enable = lib.mkForce false`.
#
# BAĞIMLILIK:
# - Bu dosya `inputs.nix-flatpak.nixosModules.nix-flatpak` modülünü import eder.
# - Flake’te `specialArgs = { inherit inputs username host; };` verilmiş olmalı.
#
# Author: Kenan Pelit
# Last merged: 2025-09-03
# ==============================================================================

{ lib, pkgs, inputs, username, ... }:

{
  # ============================================================================
  # FLATPAK — inputs üzerinden modül import’u
  # NEDEN: nix-flatpak kendi NixOS modülünü sağlar; bu dosyada tek noktadan
  # import edip yapılandırıyoruz. Wayland-first politika uygulanır.
  # ============================================================================
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  # ============================================================================
  # TEMEL SİSTEM SERVİSLERİ
  # ============================================================================
  services = {
    # ------------------ Dosya sistemi / depolama ------------------------------
    gvfs.enable   = true;    # Sanal dosya sistemi (MTP, smb, Google Drive vb.)
    fstrim.enable = true;    # Haftalık TRIM (SSD ömrü ve performans)

    # ------------------ D-Bus & Keyring --------------------------------------
    dbus = {
      enable = true;
      packages = with pkgs; [
        gcr            # crypto/GPG entegrasyon yardımcıları
        gnome-keyring  # birçok uygulama tarafından kullanılan secrets depoları
      ];
    };

    # ------------------ Bluetooth --------------------------------------------
    blueman.enable = true;   # BlueZ ile iyi çalışan GUI yöneticisi

    # ------------------ Giriş jestleri ----------------------------------------
    touchegg.enable = false; # Varsayılan kapalı; ihtiyaç varsa aç

    # ------------------ Güvenlik & bakım -------------------------------------
    fwupd.enable  = true;    # LVFS üzerinden firmware güncellemeleri

    # ------------------ Küçük ama yararlı ------------------------------------
    tumbler.enable = true;   # Thumbnails (Nemo/Thunar vb. dosya yöneticileri)

    # ------------------ Yazdırma (isteğe bağlı) -------------------------------
    printing.enable = false; # Gerçekten yazıcı kullanıyorsan true yap
    avahi = {
      enable   = false;      # mDNS/Bonjour (ağ yazıcı keşfi)
      nssmdns4 = false;
    };

    # ==========================================================================
    # FLATPAK — Wayland-first yapılandırma
    # ==========================================================================
    flatpak = {
      enable = true;

      remotes = [{
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }];

      # Varsayılan kurulumlar — örnekler korundu
      packages = [
        "com.github.tchx84.Flatseal"   # Flatpak izin yöneticisi
        "io.github.everestapi.Olympus" # Celeste mod loader
      ];

      # Global Wayland-first bağlamı
      overrides.global.Context.sockets = [
        "wayland"
        "!x11"
        "!fallback-x11"
      ];
    };
  };

  # Flatpak’ın “managed-install” servisinin otomatik kurulumunu kapat
  systemd.services.flatpak-managed-install.enable = false;

  # ============================================================================
  # PROGRAMS — Gaming (Steam/Gamescope) + Core Toggles (dconf, zsh, nix-ld)
  # ============================================================================
  programs = {
    # ------------------ Gaming stack ------------------------------------------
    steam = {
      enable = true;
      remotePlay.openFirewall      = true;  # Remote Play için gerekli portlar
      dedicatedServer.openFirewall = false; # Sunucu portlarını açma
      gamescopeSession.enable      = true;  # Steam’i Gamescope oturumunda çalıştır
      extraCompatPackages = [ pkgs.proton-ge-bin ]; # Ek Proton sürümleri (GE)
    };

    gamescope = {
      enable = true;
      capSysNice = true;    # Proses önceliği için yetki (daha stabil FPS/latency)
      # Latency/VRR odaklı başlatma argümanları:
      args = [
        "--rt"               # Realtime priority
        "--expose-wayland"   # Wayland compositing
        "--adaptive-sync"    # VRR / freesync
        "--immediate-flips"  # Input gecikmesini azalt
        "--force-grab-cursor"
      ];
    };

    # ------------------ Core program toggles ----------------------------------
    # NEDEN BURADA?
    # - dconf/zsh/nix-ld gibi çekirdek program davranışları, servis ekosistemiyle
    #   birlikte ele alındığında (özellikle desktop ve third-party binary’lerle)
    #   daha kolay yönetilir. Tek yerden “programs.*” görünürlüğü sağlar.
    dconf.enable = true;   # GNOME/GTK ayar veritabanı – birçok app buna yaslanır
    zsh.enable   = true;   # Sistem kabuğu olarak Zsh (home-manager tarafı ayrı)

    # Sistem editörlerini kapatma (tercih bilinçli): kullanıcı-level editor kullan
    vim.enable  = false;
    nano.enable = false;

    # ------------------ nix-ld: foreign/portable binary’ler için çözüm --------
    # Yabancı binary’ler (ör. prebuilt CLI’lar) eksik .so yüzünden patlamasın diye
    # “makul” bir kütüphane tabanı sağlıyoruz. İhtiyaca göre bu listeyi
    # genişletebilirsin; burada “genel geçer” bir çekirdek var.
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ ];
    #  libraries = with pkgs; [
    #    # C/C++ runtime
    #    stdenv.cc.cc           # libstdc++, libgcc_s içeriği
    #    zlib
    #    bzip2
    #    xz
    #    zstd
    #    util-linux             # libuuid vb.
    #    libudev-zero           # udev bağımlılıklarına “null” sağlayıcı (bazı CLI’lar)
    #    libxcrypt
    #    attr                   # libattr
    #    acl                    # libacl
    #    expat
    #    libxml2
    #     glib
    #     pcre2
    #  ];
    };
  };

  # ============================================================================
  # SANALLAŞTIRMA — Container + VM katmanı
  # ============================================================================
  virtualisation = {
    # ------------------ Container altyapısı -----------------------------------
    containers = {
      enable = true;
      registries = {
        search   = [ "docker.io" "quay.io" ];
        insecure = [];
        block    = [];
      };
    };

    # Podman (Docker uyumluluğu)
    podman = {
      enable = true;
      dockerCompat = true;  # `docker` CLI ile uyumluluk (alias/compat)
      defaultNetwork.settings.dns_enabled = true;

      autoPrune = {
        enable = true;
        flags  = [ "--all" ];
        dates  = "weekly";
      };

      extraPackages = with pkgs; [
        runc
        conmon
        skopeo
        slirp4netns
      ];
    };

    # ------------------ VM altyapısı -----------------------------------------
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;  # TPM emülasyonu (Windows/BitLocker vb. için)
        ovmf = {
          enable   = true;
          packages = [ pkgs.OVMFFull.fd ];  # UEFI firmware
        };
      };
    };

    # SPICE USB yönlendirme (guest içinde USB passthrough)
    spiceUSBRedirection.enable = true;
  };

  # ------------------ SPICE guest agent --------------------------------------
  services.spice-vdagentd.enable = true;

  # ------------------ Sanallaştırma için udev kuralları ----------------------
  services.udev.extraRules = ''
    # Genel USB cihazlarını libvirtd grubuna ata (virt misafire aktarım için)
    SUBSYSTEM=="usb", ATTR{idVendor}=="*", ATTR{idProduct}=="*", GROUP="libvirtd"

    # VFIO cihazları (GPU passthrough hazırlığı)
    SUBSYSTEM=="vfio", GROUP="libvirtd"

    # KVM & vhost-net izinleri
    KERNEL=="kvm", GROUP="kvm", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="vhost-net", GROUP="kvm", MODE="0664"
  '';

  # ------------------ SPICE güvenlik wrapper’ı --------------------------------
  security.wrappers.spice-client-glib-usb-acl-helper.source =
    "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";

  # ------------------ Sanallaştırma araçları ---------------------------------
  environment.systemPackages = with pkgs; [
    spice-gtk
    spice-protocol
    virt-viewer
  ];
}
