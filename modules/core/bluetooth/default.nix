# modules/core/bluetooth/default.nix
# ==============================================================================
# Bluetooth Configuration
# ==============================================================================
# Configures Bluetooth stack and services for physical hosts.
# - Enables hardware support
# - Configures settings (Experimental features)
# - Enables Blueman service
#
# ==============================================================================

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
