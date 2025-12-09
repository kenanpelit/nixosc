# modules/nixos/common/default.nix
# ------------------------------------------------------------------------------
# NixOS module for common (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

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
