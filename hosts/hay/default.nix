# hosts/hay/default.nix
# ==============================================================================
# HAY - Ana Bilgisayar Konfigürasyonu
# Main computer configuration for HAY system
# ==============================================================================
{ pkgs, config, lib, inputs, username, ... }:
{
  # -------------------------------------------------------
  # Temel Sistem İmportları
  # Core System Imports
  # -------------------------------------------------------
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
    inputs.home-manager.nixosModules.home-manager
  ];

  # -------------------------------------------------------
  # Home Manager Entegrasyonu (Tekilleştirilmiş)
  # Home Manager Integration (Unified)
  # -------------------------------------------------------
  home-manager = {
    useGlobalPkgs = true;      # Use system-level packages
    useUserPackages = true;    # Enable user-specific packages
    extraSpecialArgs = { inherit inputs username; };
    
    # Kullanıcıya Özel Ayarlar
    # User-Specific Settings
    users.${username} = {
      imports = [ 
        ../../modules/home 
      ];
      home = {
        stateVersion = "25.11";
        packages = with pkgs; [
          git         # Version control
          htop        # System monitoring
          zsh        # Advanced shell
          zoxide     # Smarter cd command
        ];
      };
      # Modül Aktivasyonları
      # Module Activations
      modules = {
        tmux.enable = true;  # Terminal multiplexer
        mpv.enable = true;   # Media player
      };
    };
  };

  # -------------------------------------------------------
  # Önyükleme Ayarları
  # Boot Settings
  # -------------------------------------------------------
  boot.loader.systemd-boot.enable = lib.mkForce false;

  # -------------------------------------------------------
  # Sistem Paketleri
  # System Packages
  # -------------------------------------------------------
  environment.systemPackages = with pkgs; [
    tmux      # Terminal multiplexer
    ncurses   # Terminal UI library
  ];

  # -------------------------------------------------------
  # Ağ ve Güvenlik
  # Network and Security
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
  # System Optimizations
  # -------------------------------------------------------
  zramSwap = {
    enable = true;          # Enable ZRAM swap
    algorithm = "zstd";     # Use ZSTD compression
    memoryPercent = 30;     # Use 30% of RAM for ZRAM
  };

  # -------------------------------------------------------
  # Ek Servisler (Opsiyonel)
  # Additional Services (Optional)
  # -------------------------------------------------------
  # services.nginx.enable = true;
  # networking.firewall.allowedTCPPorts = [ 80 443 ];
}

