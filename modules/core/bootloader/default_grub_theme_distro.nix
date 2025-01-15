# modules/core/bootloader/default.nix
{ pkgs, config, lib, ... }:
let
  hostname = config.networking.hostName;
in
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      grub = {
        enable = true;
        device = lib.mkForce (if hostname == "hay" then "nodev" else "/dev/vda");
        efiSupport = if hostname == "hay" then true else false;
        useOSProber = true;
        configurationLimit = 10;
        # NixOS teması
        theme = pkgs.fetchFromGitHub {
          owner = "AdisonCavani";
          repo = "distro-grub-themes";
          rev = "v3.2";
          hash = "sha256-U5QfwXn4WyCXvv6A/CYv9IkR/uDx4xfdSgbXDl5bp9M=";
        } + "/themes/nixos";
        gfxmodeEfi = "1920x1080";
        gfxmodeBios = "1920x1080";
      };
      efi = if hostname == "hay" then {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      } else {};
    };
  };
}
