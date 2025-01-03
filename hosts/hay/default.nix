{ pkgs, config, lib, inputs, ... }:
{
  # -------------------------------------------------------
  # Konfigürasyon dosyaları
  # -------------------------------------------------------
  imports = [
    ./hardware-configuration.nix        # Donanım yapılandırması
    ./../../modules/core                # Çekirdek modüller
    inputs.home-manager.nixosModules.home-manager  # Home Manager modülü
  ];
  
  # -------------------------------------------------------
  # Bootloader Ayarları
  # -------------------------------------------------------
  # GRUB yerine systemd-boot devre dışı bırakıldı.
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;  # systemd-boot devre dışı
  };

  # -------------------------------------------------------
  # SSH Servisi Ayarları
  # -------------------------------------------------------
  services.openssh = {
    enable = true;                     # SSH servisi etkin
    ports = [ 22 ];                    # Varsayılan SSH portu
    settings = {
      PasswordAuthentication = true;   # Şifre ile girişe izin ver
      AllowUsers = null;               # Kullanıcı kısıtlaması yok
      PermitRootLogin = "yes";         # Root ile girişe izin ver
    };
  };

  # -------------------------------------------------------
  # Home Manager Yapılandırması
  # -------------------------------------------------------
  home-manager = {
    users = {
      kenan = {
        home.stateVersion = "24.11";    # Home Manager sürümü
        home.packages = with pkgs; [
          git                        # Git sürüm kontrol sistemi
          htop                       # Sistem monitörü
          zoxide
          ncurses
          terminfo
        ];
      };
    };
  };

  # -------------------------------------------------------
  # Gelişmiş Ayarlar ve Servisler
  # -------------------------------------------------------
  # Eklenmesi istenen b aşka ayarlar buraya eklenebilir
}
