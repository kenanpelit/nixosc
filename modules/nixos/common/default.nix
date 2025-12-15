# modules/nixos/common/default.nix
# ==============================================================================
# Shared NixOS defaults imported by every host (base packages, nix settings).
# Keep cross-host tweaks here to reduce duplication in individual configs.
# Extend this file for values that should apply everywhere.
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
