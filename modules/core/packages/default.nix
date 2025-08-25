# modules/core/packages/default.nix
# ==============================================================================
# System Core Packages Configuration
# ==============================================================================
#
# Sistem seviyesinde gerekli temel paketlerin yapılandırması:
# - Sistem yönetimi ve temel araçlar
# - Sistem güvenliği ve servisler
# - Donanım ve sürücü yönetimi
# - Ağ altyapısı ve güvenliği
# - Sanallaştırma ve container
# - Sistem entegrasyonu
#
# Bu paketler sistem genelinde kurulur ve tüm kullanıcılar tarafından erişilebilir.
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:

let
  # ==============================================================================
  # Python Ortam Yapılandırması
  # ==============================================================================
  customPython = pkgs.python3.withPackages (ps: with ps; [
    ipython        # Gelişmiş Python shell
    libtmux        # Tmux için Python API
    pip            # Paket yükleyici
    pipx           # İzole ortam yükleyici
    subliminal     # Altyazı indirici
  ]);
in
{
  environment.systemPackages = with pkgs; [
    # ==============================================================================
    # Temel Sistem Araçları ve Kütüphaneler
    # ==============================================================================
    # Core System Tools
    coreutils          # GNU temel araçları
    procps             # Süreç izleme
    sysstat            # Sistem performans
    acl                # Erişim kontrol
    lsb-release        # Dağıtım bilgisi
    man-pages          # Sistem kılavuzları
    gzip               # Sıkıştırma
    gnutar             # Arşivleyici
    
    # Build Tools
    gcc                # GNU derleyici
    gnumake            # İnşa otomasyon
    
    # System Libraries
    libdrm             # Direct Rendering Manager library and headers
    libinput           # Giriş aygıtı yönetimi
    libnotify          # Masaüstü bildirim

    # ==============================================================================
    # Boot ve Sistem Yönetimi
    # ==============================================================================
    # Boot Management
    grub2              # GRUB bootloader
    catppuccin-grub    # GRUB teması
    ventoy             # New bootable USB solution
    
    # System Management
    home-manager       # Kullanıcı ortam yönetimi
    dconf              # Yapılandırma sistemi
    dconf-editor       # dconf editörü
    
    # Language Support
    perl                      # Temel Perl kurulumu
    perlPackages.FilePath     # File::Path modülü (rmtree için)

    # ==============================================================================
    # Sistem Güvenliği ve Şifreleme
    # ==============================================================================
    # System Security
    openssl            # SSL/TLS araçları (sistem kütüphanesi)
    sops               # Gizli yönetimi
    gnupg              # GNU Privacy Guard
    
    # GNOME Security Services
    gcr                # GNOME kriptografi
    gnome-keyring      # Parola yönetimi
    pinentry-gnome3    # PIN girişi
    
    # Network Security
    iptables           # Güvenlik duvarı
    hblock             # Reklam engelleyici

    # ==============================================================================
    # Ağ Altyapısı ve Bağlantı
    # ==============================================================================
    # Network Management
    networkmanagerapplet
    iwd                # Kablosuz daemon
    iw                 # Kablosuz araçları
    
    # Network Analysis & Monitoring (System Level)
    tcpdump            # Paket analizi
    nethogs            # Bant genişliği izleme
    iftop              # Ağ kullanım izleme
    
    # Network Services
    bind               # DNS araçları
    impala             # Ağ sorgu motoru
    dig                # DNS sorgu aracı (sistem seviyesi)
    
    # Data Transfer (System Services)
    rsync              # Dosya senkronizasyon
    socat              # Çok amaçlı relay
    
    # SSH Services
    openssh            # SSH istemci/sunucu
    autossh            # SSH sessions and tunnels

    # ==============================================================================
    # Sanallaştırma ve Container Teknolojileri
    # ==============================================================================
    # Virtual Machine Management
    virt-manager       # VM yönetim GUI
    virt-viewer        # VM görüntüleyici
    qemu               # Makine emülatörü
    
    # VM Support Tools
    spice-gtk          # Uzak görüntüleme
    win-virtio         # Windows sürücüleri
    win-spice          # Windows konuk araçları
    swtpm              # TPM emülatörü
    
    # Container Technology
    podman             # Container motoru

    # ==============================================================================
    # Güç Yönetimi ve Donanım
    # ==============================================================================
    # Power Management
    upower             # Güç yönetim servisi
    acpi               # ACPI araçları
    powertop           # Güç izleme
    poweralertd        # Güç yönetimi bildirimleri
    
    # Thermal Management Tools (Yeni eklenenler)
    lm_sensors         # Hardware sıcaklık sensörleri
    stress-ng          # CPU/RAM stres testi için
    linuxPackages.turbostat  # Intel CPU turbo durumlarını izleme
    linuxPackages.cpupower   # CPU güç yönetimi araçları
    auto-cpufreq       # Otomatik CPU frekans yönetimi
    
    # Hardware Management
    ddcutil            # Monitor settings
    fwupd              # Firmware güncelleyici
    android-tools      # adb (sistem seviyesi)
    smartmontools      # Disk sağlık durumu izleme (SMART)
    
    # Input Devices
    fusuma             # Çoklu dokunma
    touchegg           # Hareket tanıma

    # ==============================================================================
    # Masaüstü Entegrasyonu ve Servisler
    # ==============================================================================
    # Desktop Integration
    xdg-utils          # Masaüstü entegrasyonu
    xdg-desktop-portal # Masaüstü entegrasyon
    xdg-desktop-portal-gtk # GTK arka uç
    
    # Application Management
    flatpak            # Uygulama sanal ortam

    # ==============================================================================
    # Python Ortamı (Sistem Seviyesi)
    # ==============================================================================
    customPython       # Özel Python kurulumu

    # ==============================================================================
    # Sistem Görevleri ve Zamanlama
    # ==============================================================================
    at                 # job scheduling command
    logger

    # ==============================================================================
    # Commented Out / Optional Packages
    # ==============================================================================
    # iwgtk              # Kablosuz yapılandırma
    # intel-undervolt    # Undervolting aracı (Meteor Lake'de çalışmayabilir)
  ];
}

