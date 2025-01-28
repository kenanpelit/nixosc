# hosts/hay/default.nix
# ==============================================================================
# HAY - Ana Bilgisayar Konfigürasyonu
# ==============================================================================
{ pkgs, config, lib, inputs, username, ... }:
{
  # -------------------------------------------------------
  # Temel Sistem İmportları
  # -------------------------------------------------------
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    inputs.home-manager.nixosModules.home-manager
  ];

  # -------------------------------------------------------
  # Home Manager Entegrasyonu (Tekilleştirilmiş)
  # -------------------------------------------------------
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs username; };
    
    # Kullanıcıya Özel Ayarlar
    users.${username} = {
      imports = [ 
        ../../modules/home 
      ];

      home = {
        stateVersion = "25.05";
        packages = with pkgs; [
          git
          htop
          zsh
          zoxide
        ];
      };

      # Modül Aktivasyonları
      modules = {
        tmux.enable = true;
        mpv.enable = true;
      };
    };
  };

  # -------------------------------------------------------
  # Önyükleme Ayarları
  # -------------------------------------------------------
  boot.loader.systemd-boot.enable = lib.mkForce false;

  # -------------------------------------------------------
  # Sistem Paketleri
  # -------------------------------------------------------
  environment.systemPackages = with pkgs; [
    tmux
    ncurses
  ];

  # -------------------------------------------------------
  # Ağ ve Güvenlik
  # -------------------------------------------------------
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = [ "${username}" ];
      PermitRootLogin = "yes";
    };
  };

  # -------------------------------------------------------
  # Sistem Optimizasyonları
  # -------------------------------------------------------
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 30;
  };

  # -------------------------------------------------------
  # Ek Servisler (Opsiyonel)
  # -------------------------------------------------------
  # services.nginx.enable = true;
  # networking.firewall.allowedTCPPorts = [ 80 443 ];
}
