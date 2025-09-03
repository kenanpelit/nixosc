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
#
# ÖNEMLİ NOTLAR:
# - `users.users.<username>.extraGroups` başka yerde de genişletiliyorsa, Nix
#   listeleri birleştireceği için çakışma olmaz.
# - NixOS’ta “servisi mask’la” için `systemd.services.<name>.enable = mkForce false`.
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
  # KULLANICI GRUPLARI — Sanallaştırma erişimleri
  # NEDEN: libvirt yönetimi, KVM erişimi ve docker uyumluluğu için gerekli.
  # Not: Başka yerde de extraGroups veriyorsan Nix birleştirir (append).
  # ============================================================================
  users.users.${username}.extraGroups = [
    "libvirtd"  # Virtual machine management
    "kvm"       # KVM access
    "docker"    # Container-like araçlar için uyumluluk
  ];

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
  # OYUN — Steam + Gamescope (düşük gecikme ve uyumluluk)
  # ============================================================================
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall      = true;  # Remote Play için gerekli portlar
      dedicatedServer.openFirewall = false; # Sunucu portlarını açma
      gamescopeSession.enable      = true;  # Steam’i Gamescope oturumunda başlatma
      extraCompatPackages = [
        pkgs.proton-ge-bin                 # Ek Proton sürümleri (community GE)
      ];
    };

    gamescope = {
      enable = true;
      capSysNice = true;    # Proses önceliği için yetki (daha stabil FPS/latency)
      # Latency/VRR odaklı başlatma argümanları:
      args = [
        "--rt"               # Realtime priority (oyun/dvm kararlı çerçeveler)
        "--expose-wayland"   # Wayland compositing
        "--adaptive-sync"    # VRR / freesync
        "--immediate-flips"  # Input gecikmesini azalt
        "--force-grab-cursor"
      ];
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


