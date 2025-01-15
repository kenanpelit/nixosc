# ==============================================================================
# HAY - Ana Bilgisayar Konfigürasyonu
# Açıklama: Birincil sistemin temel yapılandırma dosyası
# ==============================================================================
{ pkgs, config, lib, inputs, ... }:
{
  # -------------------------------------------------------
  # Temel Sistem İmportları
  # -------------------------------------------------------
  imports = [
    ./hardware-configuration.nix         # Donanım yapılandırması
    ./../../modules/core                 # Çekirdek modüller
    inputs.home-manager.nixosModules.home-manager  # Home Manager
  ];
  
  # -------------------------------------------------------
  # Home Manager Temel Ayarları
  # -------------------------------------------------------
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "backup";  # Bu satırı ekleyin
  };

  # -------------------------------------------------------
  # Önyükleme ve GRUB Ayarları
  # -------------------------------------------------------
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;  # systemd-boot devre dışı
    # NOT: GRUB ayarlarınız buraya eklenebilir
  };

  # -------------------------------------------------------
  # Sistem Paketleri
  # -------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # Terminal ve Sistem Araçları
    tmux      # Terminal multiplexer
    ncurses   # Terminal GUI desteği
  ];

  # -------------------------------------------------------
  # Ağ ve Güvenlik Servisleri
  # -------------------------------------------------------
  services.openssh = {
    enable = true;                    # SSH servisini etkinleştir
    ports = [ 22 ];                   # Standart SSH portu
    settings = {
      PasswordAuthentication = true;  # Şifre ile kimlik doğrulama
      AllowUsers = null;             # Tüm kullanıcılara izin ver
      PermitRootLogin = "yes";       # Root girişine izin ver
      # NOT: Üretim ortamında bu ayarlar gözden geçirilmeli
    };
  };

  # -------------------------------------------------------
  # Home Manager Kullanıcı Yapılandırması
  # -------------------------------------------------------
  home-manager.users.kenan = { ... }: {
    imports = [
      ../../modules/home      # Tüm home modüllerini import eder
    ];

    # Temel Ayarlar
    home.stateVersion = "24.11";
    
    # Modül Aktivasyonları
    modules = {
      tmux.enable = true;
      mpv.enable = true;   # MPV modülünü etkinleştir
    };
  
    # Kullanıcı Paketleri
    home.packages = with pkgs; [
      # Geliştirme Araçları
      git         # Versiyon kontrol sistemi
      # Sistem Araçları
      htop        # İnteraktif sistem monitörü
      zsh         # Z shell
      zoxide      # Akıllı cd alternatifi
    ];
  };

  # -------------------------------------------------------
  # Sistem Optimizasyonları
  # -------------------------------------------------------
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
  };
  # Örnek: Bellek ve CPU optimizasyonları buraya eklenebilir
  # Örnek: I/O scheduler ayarları
  # Örnek: Sistem limitleri

  # -------------------------------------------------------
  # NOT: Ek Servisler ve Özellikler
  # -------------------------------------------------------
  # - systemd servisleri
  # - Cron görevleri
  # - Ağ ayarları
  # - Güvenlik duvarı kuralları
  # buraya eklenebilir
}
