# hosts/hay/templates/bootstrap.nix
# ==============================================================================
# PRE-INSTALL CONFIGURATION (BOOTSTRAP)
# ==============================================================================
# This file is used to bootstrap the system from the NixOS installation media.
# It provides a minimal, working configuration to boot the system and enable
# Flakes, allowing the full configuration (modules/core) to be applied later.
#
# USAGE:
# 1. Copy this file to /etc/nixos/configuration.nix
# 2. Generate hardware-config: nixos-generate-config
# 3. Install: nixos-install
# ==============================================================================

{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================================
  # Boot Loader (GRUB + EFI)
  # ============================================================================
  boot.loader = {
    systemd-boot.enable = false;
    
    grub = {
      enable      = true;
      device      = "nodev";
      useOSProber = true;
      efiSupport  = true;
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint     = "/boot";
    };
  };

  # ============================================================================
  # Networking & Hostname
  # ============================================================================
  networking = {
    hostName              = "hay";
    networkmanager.enable = true;
  };

  # ============================================================================
  # Locale & Time
  # ============================================================================
  time.timeZone = "Europe/Istanbul";
  
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "tr_TR.UTF-8";
    LC_IDENTIFICATION = "tr_TR.UTF-8";
    LC_MEASUREMENT    = "tr_TR.UTF-8";
    LC_MONETARY       = "tr_TR.UTF-8";
    LC_NAME           = "tr_TR.UTF-8";
    LC_NUMERIC        = "tr_TR.UTF-8";
    LC_PAPER          = "tr_TR.UTF-8";
    LC_TELEPHONE      = "tr_TR.UTF-8";
    LC_TIME           = "tr_TR.UTF-8";
  };

  # ============================================================================
  # Keyboard (TR-F)
  # ============================================================================
  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };
  console.keyMap = "trf";

  # ============================================================================
  # User Account
  # ============================================================================
  users.users.kenan = {
    isNormalUser = true;
    description  = "Kenan Pelit";
    extraGroups  = [ "networkmanager" "wheel" ];
    # Set a password with 'passwd' after booting or use initialHashedPassword here
  };

  # ============================================================================
  # Essential System Packages
  # ============================================================================
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
    # System tools
    wget        # File downloader
    neovim      # Text editor
    git         # Version control
    htop        # System monitor
    tmux        # Terminal multiplexer
    sops        # Secrets management
    age         # File encryption
    assh        # SSH config manager
    ncurses     # Terminal UI library
    pv          # Pipe viewer
    file        # File type identifier
    bc          # GNU software calculator
    # Security and encryption
    gnupg       # GNU Privacy Guard
    openssl     # SSL/TLS toolkit
  ];

  # ============================================================================
  # Flakes Support (CRITICAL FOR BOOTSTRAP)
  # ============================================================================
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ============================================================================
  # Services
  # ============================================================================
  services.openssh.enable = true;

  # ============================================================================
  # State Version
  # ============================================================================
  system.stateVersion = "25.11";
}
