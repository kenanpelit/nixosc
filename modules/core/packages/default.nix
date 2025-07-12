# modules/core/user/packages/default.nix
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
    gdb                # GNU hata ayıklayıcı
    
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
    # Terminal ve Shell Araçları
    # ==============================================================================
    tmux               # Terminal çoklayıcı
    yq                 # YAML/JSON işlemci
    gawk               # Metin işleme

    # ==============================================================================
    # Sistem Güvenliği ve Şifreleme
    # ==============================================================================
    # Encryption & Security
    age                # Şifreleme
    openssl            # SSL/TLS araçları
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
    
    # Network Analysis & Monitoring
    tcpdump            # Paket analizi
    nethogs            # Bant genişliği izleme
    iftop              # Ağ kullanım izleme
    mtr                # Ağ teşhis
    nmap               # Ağ keşif
    speedtest-cli      # İnternet hız testi
    iperf              # Ağ performans
    
    # Network Services
    bind               # DNS araçları
    impala             # Ağ sorgu motoru
    
    # Data Transfer
    rsync              # Dosya senkronizasyon
    curl               # URL veri transfer
    wget               # Ağ dosya indirme
    socat              # Çok amaçlı relay
    
    # Remote Access & SSH
    assh               # SSH yapılandırma
    openssh            # SSH istemci/sunucu
    autossh            # SSH sessions and tunnels
    tigervnc           # VNC uygulaması

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
    
    # Hardware Management
    ddcutil            # Monitor settings
    fwupd              # Firmware güncelleyici
    
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
    # Geliştirme Araçları ve Diller
    # ==============================================================================
    # Version Control
    git                # Versiyon kontrol
    
    # Nix Development Tools
    nvd                # Nix versiyon diff
    cachix             # İkili önbellek
    nix-output-monitor # Nix inşa izleyici
    
    # Programming Languages
    go                 # Go çalışma zamanı
    customPython       # Özel Python kurulumu
    
    # AI/ML Tools
    ollama             # LLM çalıştırıcı

    # ==============================================================================
    # Sistem Görevleri ve Zamanlama
    # ==============================================================================
    at                 # job scheduling command

    # ==============================================================================
    # Commented Out / Optional Packages
    # ==============================================================================
    # iwgtk              # Kablosuz yapılandırma
  ];
}

