# modules/core/networking/default.nix
# NetworkManager and basic network defaults.

{ lib, ... }:

{
  networking = {
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    wireless.enable = false;
  };
}
