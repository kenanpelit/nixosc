# hosts/vhay/templates/initial-configuration.nix
{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader configuration for VM
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/vda";  # VM'de direkt diski kullanıyoruz
        useOSProber = true;
      };
    };
    # En son kernel paketlerini kullan (hay'dan alındı)
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Networking
  networking = {
    hostName = "vhay";
    networkmanager.enable = true;
  };

  # Timezone and localization
  time.timeZone = "Europe/Istanbul";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "tr_TR.UTF-8";
    LC_IDENTIFICATION = "tr_TR.UTF-8";
    LC_MEASUREMENT = "tr_TR.UTF-8";
    LC_MONETARY = "tr_TR.UTF-8";
    LC_NAME = "tr_TR.UTF-8";
    LC_NUMERIC = "tr_TR.UTF-8";
    LC_PAPER = "tr_TR.UTF-8";
    LC_TELEPHONE = "tr_TR.UTF-8";
    LC_TIME = "tr_TR.UTF-8";
  };

  # Keyboard layouts
  services.xserver.xkb = {
    layout = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };
  console.keyMap = "trf";

  # User account for VM
  users.users.kenan = {
    isNormalUser = true;
    description = "Kenan Pelit";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXTOGB+8R7VW3WXiBJwCikHblt7GIce7SgFHcaq2mjm kenan@hay" 
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Program configurations
  programs = {
    tmux.enable = true;
    byobu.enable = false;
    # hay'dan alınan GnuPG agent konfigürasyonu
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # Base system packages for VM
  environment.systemPackages = with pkgs; [
    wget
    vim
    git
    htop
    tmux
    sops
    age
    assh
    ncurses
  ];

  # Enable OpenSSH server
  services.openssh = {
    enable = true;
    # Güvenlik için şifre ile girişi kapatıp sadece SSH key ile giriş yapılmasını sağlayabiliriz
    # passwordAuthentication = false;
    # permitRootLogin = "no";
  };

  system.stateVersion = "24.11";
}
