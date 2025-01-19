# modules/home/security/gnupg/default.nix
# ==============================================================================
# GnuPG Configuration Root
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  imports = [
    #./gpgunlock.nix
    ./gnupg.nix
  ];

  # Ortak yapılandırma ve bağımlılıklar buraya gelebilir
  home.packages = with pkgs; [
    gnupg
    pinentry-gnome3
  ];
}
