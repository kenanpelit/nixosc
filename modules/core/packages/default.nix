# modules/core/packages/default.nix
# ==============================================================================
# System Core Packages Configuration
# ==============================================================================
#
# Sistem seviyesinde gerekli temel paketlerin yapılandırması:
# - Kritik sistem servisleri ve daemon'lar
# - Güvenlik ve kimlik doğrulama altyapısı
# - Donanım yönetimi ve firmware
# - Kernel modülleri ve sürücüler
# - Sanallaştırma altyapısı
# - Sistem kütüphaneleri
#
# Bu paketler sistem genelinde kurulur ve tüm kullanıcılar tarafından erişilebilir.
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # ==============================================================================
    # Temel Sistem Araçları ve Kütüphaneler
    # ==============================================================================
    # Core System Tools
    coreutils          # GNU temel araçları (sistem için kritik)
    procps             # Süreç yönetimi araçları
    sysstat            # Sistem performans monitörü
    acl                # Dosya erişim kontrol listeleri
    lsb-release        # Linux Standard Base bilgisi
    man-pages          # Sistem manual sayfaları
    gzip               # Temel sıkıştırma (sistem logları)
    gnutar             # Arşivleme (sistem yedekleme)
    
    # Build Tools (Kernel modülleri için)
    gcc                # GNU C derleyici
    gnumake            # Make build sistemi
    nodejs             # Node.js runtime 
    
    # System Libraries
    libdrm             # Direct Rendering Manager (GPU)
    libinput           # Input device yönetimi
    libnotify          # Sistem bildirimleri altyapısı
    openssl            # SSL/TLS kütüphanesi (sistem servisleri)

    # ==============================================================================
    # Boot ve Sistem Yönetimi
    # ==============================================================================
    # Boot Management
    grub2              # GRUB bootloader
    catppuccin-grub    # GRUB tema dosyaları
    
    # System Management
    home-manager       # Kullanıcı ortam yönetimi
    dconf              # Sistem yapılandırma veritabanı
    dconf-editor       # dconf editörü
    
    # Firmware Updates
    fwupd              # UEFI/BIOS firmware güncellemeleri
    
    # Language Support (Sistem scriptleri için)
    perl               # Sistem scriptleri
    perlPackages.FilePath  # File::Path modülü

    # ==============================================================================
    # Sistem Güvenliği ve Şifreleme
    # ==============================================================================
    # System Security
    sops               # Sistem sırları yönetimi
    gnupg              # GPG şifreleme (paket imzaları)
    
    # GNOME Security Services (Sistem servisi olarak)
    gcr                # Sertifika ve anahtar yönetimi
    gnome-keyring      # Sistem geneli parola deposu
    pinentry-gnome3    # GNOME için PIN girişi
    
    # Network Security
    iptables           # Kernel firewall yönetimi
    hblock             # Host-based ad blocker

    # ==============================================================================
    # Ağ Altyapısı ve Bağlantı
    # ==============================================================================
    # Network Management
    networkmanagerapplet  # NetworkManager sistem tray
    iwd                # Intel Wireless Daemon
    iw                 # Wireless kernel araçları
    
    # Network Services
    bind               # DNS server araçları
    openssh            # SSH daemon ve istemci
    autossh            # Otomatik SSH tünel yönetimi
    
    # System Network Tools
    impala             # Ağ sorgu motoru
    socat              # Çok amaçlı relay (sistem servisleri)
    rsync              # Dosya senkronizasyon (sistem yedekleme)

    # ==============================================================================
    # Sanallaştırma ve Container Teknolojileri
    # ==============================================================================
    # Virtual Machine Management
    virt-manager       # Libvirt GUI yönetici
    virt-viewer        # SPICE/VNC görüntüleyici
    qemu               # QEMU hypervisor
    
    # VM Support Tools
    spice-gtk          # SPICE protokol desteği
    win-virtio         # VirtIO Windows sürücüleri
    win-spice          # SPICE Windows araçları
    swtpm              # Software TPM emülatörü
    
    # Container Technology
    podman             # Container daemon (rootless)

    # ==============================================================================
    # Güç Yönetimi ve Donanım
    # ==============================================================================
    # Power Management
    upower             # Güç yönetimi daemon'ı
    acpi               # ACPI kernel arayüzü
    powertop           # Intel güç optimizasyonu
    poweralertd        # Güç olayları daemon'ı
    
    # Thermal Management
    lm_sensors         # Donanım sensör sürücüleri
    linuxPackages.turbostat  # Intel Turbo Boost monitör
    linuxPackages.cpupower   # CPU güç yönetimi (kernel)
    auto-cpufreq       # CPU frekans daemon'ı
    
    # Hardware Management
    ddcutil            # DDC/CI monitör kontrolü
    fwupd              # Firmware güncelleyici
    android-tools      # ADB/Fastboot (udev kuralları)
    smartmontools      # Disk S.M.A.R.T. daemon
    nvme-cli           # NVMe kernel sürücü arayüzü
    dmidecode          # BIOS/UEFI DMI bilgileri
    usbutils           # USB bus yönetimi
    intel-gpu-tools    # Intel GPU kernel araçları

    # ==============================================================================
    # Masaüstü Entegrasyonu ve Servisler
    # ==============================================================================
    # Desktop Integration Services
    xdg-utils          # XDG spesifikasyon araçları
    xdg-desktop-portal # Portal servisi
    xdg-desktop-portal-gtk # GTK portal backend

    # ==============================================================================
    # Sistem Görevleri ve Zamanlama
    # ==============================================================================
    at                 # Sistem görev zamanlayıcı
    logger             # Syslog mesaj gönderici
  ];
}

