# modules/core/bluetooth/default.nix
# Bluetooth stack and services.

{ pkgs, lib, isPhysicalHost ? false, ... }:

{
  config = lib.mkIf isPhysicalHost {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };

    services.blueman.enable = true;
  };
}
