# ==============================================================================
# VHAY - Sanal Makine Konfigürasyonu
# Açıklama: Geliştirme ortamı için VM yapılandırması
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
  # Temel Sistem Paketleri (VM ortamı)
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
  # SSH / Güvenlik (Geliştirme odaklı, gevşek ayarlar)
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
  # Zaman & Locale (hay ile uyumlu tutmak istersen buraya alabilirsin)
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
  # System State Version
  # ============================================================================
  system.stateVersion = "25.11";
}
