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

  # =============================================================================
  # Bootloader Configuration for VM
  # =============================================================================
  boot = {
    loader.grub = {
      enable = true;
      device = "/dev/vda";         # Install GRUB on main virtual disk
      useOSProber = true;          # Enable OS prober for multi-boot
    };
    # Latest kernel packages
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # =============================================================================
  # Networking Configuration
  # =============================================================================
  networking = {
    hostName = "vhay";             # Virtual machine hostname
    networkmanager.enable = true;   # Enable NetworkManager
  };

  # =============================================================================
  # Timezone and Localization
  # =============================================================================
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

  # =============================================================================
  # Keyboard Configuration
  # =============================================================================
  services.xserver.xkb = {
    layout = "tr";    # Turkish keyboard layout
    variant = "f";    # F-keyboard variant
    options = "ctrl:nocaps";  # Use Caps Lock as Ctrl
  };
  console.keyMap = "trf";  # Turkish-F console keymap
 
  # =============================================================================
  # User Account Configuration
  # =============================================================================
  users.users.kenan = {
    isNormalUser = true;
    description = "Kenan Pelit";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    openssh.authorizedKeys.keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXTOGB+8R7VW3WXiBJwCikHblt7GIce7SgFHcaq2mjm kenan@hay" 
    ];
  };

  # =============================================================================
  # Package Management Configuration
  # =============================================================================
  nixpkgs.config = {
    allowUnfree = true;
  };

  # =============================================================================
  # Program Configurations
  # =============================================================================
  programs = {
    tmux.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # =============================================================================
  # System Packages
  # =============================================================================
  environment.systemPackages = with pkgs; [
    # System tools
    wget        # File downloader
    vim         # Text editor
    git         # Version control
    htop        # System monitor
    tmux        # Terminal multiplexer
    sops        # Secrets management
    age         # File encryption
    assh        # SSH config manager
    ncurses     # Terminal UI library
    pv          # Pipe viewer
    file        # File type identifier
    # Security and encryption
    gnupg       # GNU Privacy Guard
    openssl     # SSL/TLS toolkit
  ];

  # =============================================================================
  # Service Configuration
  # =============================================================================
  services.openssh.enable = true;    # Enable OpenSSH daemon

  # =============================================================================
  # System Version
  # =============================================================================
  system.stateVersion = "25.11";
}
