# modules/nixos/bluetooth/default.nix
# ==============================================================================
# NixOS Bluetooth stack: BlueZ services, power tweaks, controller defaults.
# One place to enable/disable adapters and audio integration per machine.
# Keep BT policy here to avoid scattered per-host overrides.
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  isPhysicalHost = config.my.host.isPhysicalHost;
in
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
