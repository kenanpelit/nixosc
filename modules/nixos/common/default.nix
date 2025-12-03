# modules/nixos/common/default.nix
# ==============================================================================
# Common System Configuration
# ==============================================================================
# This module contains configuration applied to ALL hosts managed by this flake.
# ==============================================================================

{ pkgs, lib, config, ... }:

{
  # -- Time & Locale -----------------------------------------------------------
  time.timeZone = lib.mkDefault "Europe/Istanbul";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # -- SSH / Security ----------------------------------------------------------
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkDefault "no";
    };
  };

  # -- Core Packages -----------------------------------------------------------
  environment.systemPackages = with pkgs; [
    git
    tmux
    neovim # or vim
    htop
    wget
    curl
    ripgrep
    fd
    file
    sops
    age
    pv
  ];
}
