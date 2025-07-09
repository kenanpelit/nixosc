# ==============================================================================
# VHAY - Sanal Makine Konfigürasyonu
# Açıklama: Geliştirme ortamı için VM yapılandırması
# ==============================================================================
{ pkgs, config, lib, inputs, username, ... }:
{
  # -------------------------------------------------------
  # Temel Sistem İmportları
  # -------------------------------------------------------
  imports = [
    ./hardware-configuration.nix         # VM donanım yapılandırması
    ./../../modules/core                 # Çekirdek modüller
    inputs.home-manager.nixosModules.home-manager  # Home Manager modülü
  ];

  # -------------------------------------------------------
  # Home Manager Temel Ayarları
  # -------------------------------------------------------
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs username; };
  };
  
  # -------------------------------------------------------
  # Sistem Paketleri
  # -------------------------------------------------------
  environment.systemPackages = with pkgs; [
    # Terminal ve Geliştirme Araçları
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
      PermitRootLogin = "yes";       # Root girişine izin ver
      # NOT: Bu ayarlar sadece geliştirme ortamı için uygundur
    };
  };

  # -------------------------------------------------------
  # Home Manager Kullanıcı Yapılandırması
  # -------------------------------------------------------
  home-manager.users.${username} = { ... }: {
    imports = [
      ../../modules/home      # Tüm home modüllerini import eder
    ];

    # Temel Ayarlar
    home.stateVersion = "25.11";
    
    # Tmux Modülü Aktivasyonu
    modules.tmux = {
      enable = true;
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
  # VM Özel Ayarları
  # -------------------------------------------------------
  # - VM performans optimizasyonları
  # - Snapshot politikaları
  # - Paylaşılan klasör ayarları
  # buraya eklenebilir

  # -------------------------------------------------------
  # NOT: Geliştirme Ortamı Özellikleri
  # -------------------------------------------------------
  # - Docker/Podman yapılandırması
  # - Geliştirme araçları
  # - Test ortamı ayarları
  # buraya eklenebilir
}
