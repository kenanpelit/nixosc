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
        theme = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "grub";
          rev = "v1.0.0";
          hash = "sha256-/bSolCta8GCZ4lP0u5NVqYQ9Y3ZooYCNdTwORNvR7M0=";  # Düzeltilmiş hash
        } + "/src/catppuccin-mocha-grub-theme";
        gfxmodeEfi = "1920x1080";
        gfxmodeBios = "1920x1080";
      };
      efi = if hostname == "hay" then {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      } else {};
    };
  };
}
