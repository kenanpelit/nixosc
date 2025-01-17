# hosts/hay/templates/initial-configuration.nix
{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  
  # Bootloader configuration
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    device = "nodev";
    useOSProber = true;
    efiSupport = true;
  };
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };
  
  # Use latest kernel packages
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # Networking
  networking.hostName = "hay";
  networking.networkmanager.enable = true;
  
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
  
  # User account
  users.users.kenan = {
    isNormalUser = true;
    description = "Kenan Pelit";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Base system packages
  environment.systemPackages = with pkgs; [
    wget
    git
    tmux
    sops
    age
    assh
    vim
    ncurses
  ];
  
  # Enable GnuPG agent
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  
  system.stateVersion = "24.11";
}
