{ pkgs, config, lib, ... }:
let
  hostname = config.networking.hostName;
in
{
  boot.loader.grub = {
    enable = true;
    device = lib.mkForce (if hostname == "hay" then "nodev" else "/dev/sda");
    efiSupport = if hostname == "hay" then true else false;
    useOSProber = true;
    configurationLimit = 10;
  };

  boot.loader.efi = if hostname == "hay" then {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot/efi";
  } else {};

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
