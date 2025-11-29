# ==============================================================================
# VHAY - NixOS Host Configuration
# Main system configuration for the "vhay" virtual machine
# ==============================================================================
{ pkgs, lib, inputs, username, ... }:

{
  # ============================================================================
  # Imports
  # ============================================================================
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
  ];

  # ============================================================================
  # Host Identity
  # ============================================================================
  networking.hostName = "vhay";

  # ============================================================================
  # Networking
  # ============================================================================
  networking = {
    networkmanager.enable = true;
  };

  # ============================================================================
  # Time & Locale
  # (core/system ile aynı değerlere sahip; merge ederken tutarlı kalıyor)
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
  # SSH / Security
  # (Geliştirme odaklı, gevşek ayarlar)
  # ============================================================================
  services.openssh = {
    enable = true;
    ports  = [ 22 ];

    settings = {
      PasswordAuthentication = true;
      PermitRootLogin        = "yes";
      AllowUsers             = [ username ];
    };
  };

  # ============================================================================
  # System Packages
  # (Temel VM paketleri)
  # ============================================================================
  environment.systemPackages = with pkgs; [
    tmux
    ncurses
    git
    neovim
    htop
    networkmanager
  ];

  # ============================================================================
  # System State Version
  # ============================================================================
  system.stateVersion = "25.11";
}