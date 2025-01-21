# hosts/vhay/templates/initial-configuration.nix
# ==============================================================================
# !!! IMPORTANT - PLEASE READ BEFORE PROCEEDING !!!
# Before building your system, make sure to adjust the following settings
# according to your preferences and location:
#
# 1. Time Zone: Currently set to "Europe/Istanbul"
# 2. System Language: Currently set to "en_US.UTF-8"
# 3. Regional Settings: Currently configured for Turkish (tr_TR.UTF-8)
# 4. Keyboard Layout: Currently set to Turkish-F layout
#
# You can find your timezone from: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
# For keyboard layouts: run 'localectl list-x11-keymap-layouts' for available options
# ==============================================================================
{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader for VM
  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/vda";
      useOSProber = true;
    };
    # Latest kernel packages
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
    layout = "tr";    # Change this to your preferred keyboard layout (e.g., "us", "de", "fr")
    variant = "f";    # Change or remove this line based on your keyboard variant
    options = "ctrl:nocaps";  # Optional: Makes Caps Lock an additional Ctrl key
  };
  console.keyMap = "trf";  # Change this to match your keyboard layout
 
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
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # Base system packages for VM
  environment.systemPackages = with pkgs; [
    # System tools
    wget
    vim
    git
    htop
    tmux
    sops
    age
    assh
    ncurses
    pv

    # Security and encryption
    gnupg
    openssl
  ];

  # Enable OpenSSH server
  services.openssh.enable = true;

  system.stateVersion = "25.05";
}
