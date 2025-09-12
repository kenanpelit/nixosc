# modules/core/services/default.nix
# ==============================================================================
# Base System Services (Merged: services + virtualisation + gaming + flatpak)
# ==============================================================================
# AMAÇ:
# - Sistem servisleri, Flatpak, oyun yığını ve sanallaştırmayı **tek dosyada**
#   birleştirip çakışmaları azaltmak ve bakımını kolaylaştırmak.
#
# İÇERİK:
# - Temel servisler: GVFS, TRIM, D-Bus+keyring, Bluetooth, fwupd, tumbler
# - Flatpak (inputs.nix-flatpak modülü, Wayland-first overrides)
# - Gaming: Steam + Gamescope (düşük gecikme argümanları)
# - Sanallaştırma: Podman (dockerCompat), Libvirt/QEMU (TPM/OVMF), SPICE
# - Core programs: dconf, zsh, nix-ld
# - TLP CLI (PATH’e ek) + switch sırasında sürüm log’u
# - SPICE udev kuralları ve wrapper
#
# NOTLAR:
# - Güvenlik/firewall port işleri **security** modülünde. Burada port açmıyoruz.
# - Bu dosyada `environment.systemPackages` **tek kez** tanımlıdır (önceki hata buydu).
#
# Author: Kenan Pelit
# Last merged: 2025-09-04
# ==============================================================================

{ lib, pkgs, inputs, username, system, ... }:

{
  # ============================================================================
  # FLATPAK — Modül import’u (Wayland-first yaklaşım)
  # ============================================================================
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  # ============================================================================
  # TEMEL SİSTEM SERVİSLERİ
  # ============================================================================
  services = {
    # Dosya sistemi / depolama
    gvfs.enable   = true;   # MTP, SMB, Google Drive, archive, vs.
    fstrim.enable = true;   # Haftalık TRIM

    # D-Bus & Keyring
    dbus = {
      enable = true;
      packages = with pkgs; [
        gcr
        gnome-keyring
      ];
    };

    # Bluetooth GUI
    blueman.enable = true;

    # Giriş jestleri (ihtiyaç olursa açarsın)
    touchegg.enable = false;

    # Firmware güncellemeleri
    fwupd.enable = true;

    # Thumbnailer
    tumbler.enable = true;

    # Yazdırma (isteğe bağlı)
    printing.enable = false;
    avahi = {
      enable   = false; # ağ yazıcı keşfi
      nssmdns4 = false;
    };

    # ---------------- Flatpak ----------------
    flatpak = {
      enable = true;

      remotes = [{
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }];

      packages = [
        "com.github.tchx84.Flatseal"
        "io.github.everestapi.Olympus"
      ];

      # Wayland-first
      overrides.global.Context.sockets = [
        "wayland"
        "!x11"
        "!fallback-x11"
      ];
    };
  };

  # Flatpak “managed-install” servisinin otomatik kurulumunu kapat
  systemd.services.flatpak-managed-install.enable = false;

  # ============================================================================
  # PROGRAMS — Gaming + Core toggles
  # ============================================================================
  programs = {
    # Steam / Gamescope
    steam = {
      enable = true;
      remotePlay.openFirewall      = true;
      dedicatedServer.openFirewall = false;
      gamescopeSession.enable      = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };

    gamescope = {
      enable = true;
      capSysNice = true;
      args = [
        "--rt"
        "--expose-wayland"
        "--adaptive-sync"
        "--immediate-flips"
        "--force-grab-cursor"
      ];
    };

    # GNOME/GTK ayar veritabanı
    dconf.enable = true;

    # Sistem kabuğu (home tarafı ayrı)
    zsh.enable = true;

    # Yabancı binary’ler için kütüphaneler
    nix-ld = {
      enable = true;
      libraries = with pkgs; [ ];
    };

  };

  # ============================================================================
  # PAKETLER — Tek noktadan ekle (TLP + SPICE araçları)
  # (ÖNEMLİ: Bu dosyada environment.systemPackages **TEK** kez tanımlanır.)
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Güç yönetimi CLI
    tlp

    # SPICE araçları
    spice-gtk
    spice-protocol
    virt-viewer
  ];

  # Switch sırasında TLP sürümünü logla (hızlı doğrulama)
  system.activationScripts.tlpVersion = ''
    echo "[nixos-switch] $(date -Is) TLP: $(${pkgs.tlp}/bin/tlp --version || true)"
  '';

  # ============================================================================
  # SANALLAŞTIRMA — Container + VM katmanı
  # ============================================================================
  virtualisation = {
    # Containers
    containers = {
      enable = true;
      registries = {
        search   = [ "docker.io" "quay.io" ];
        insecure = [ ];
        block    = [ ];
      };
    };

    # Podman (Docker uyumluluğu)
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;

      autoPrune = {
        enable = true;
        flags  = [ "--all" ];
        dates  = "weekly";
      };

      extraPackages = with pkgs; [ runc conmon skopeo slirp4netns ];
    };

    # Libvirt/QEMU (UEFI + TPM)
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf = {
          enable   = true;
          packages = [ pkgs.OVMFFull.fd ];
        };
      };
    };

    # SPICE USB yönlendirme
    spiceUSBRedirection.enable = true;
  };

  # Guest agent
  services.spice-vdagentd.enable = true;

  # Udev kuralları (SPICE / VFIO / KVM)
  services.udev.extraRules = ''
    # Genel USB cihazlarını libvirtd grubuna ata (guest passthrough için)
    SUBSYSTEM=="usb", ATTR{idVendor}=="*", ATTR{idProduct}=="*", GROUP="libvirtd"

    # VFIO cihazları (GPU passthrough hazırlığı)
    SUBSYSTEM=="vfio", GROUP="libvirtd"

    # KVM & vhost-net izinleri
    KERNEL=="kvm", GROUP="kvm", MODE="0664"
    SUBSYSTEM=="misc", KERNEL=="vhost-net", GROUP="kvm", MODE="0664"
  '';

  # SPICE güvenlik wrapper’ı
  security.wrappers.spice-client-glib-usb-acl-helper.source =
    "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
}
