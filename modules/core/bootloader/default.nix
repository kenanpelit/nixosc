# modules/core/bootloader/default.nix
# ==============================================================================
# System Bootloader Configuration
# ==============================================================================
{ pkgs, config, lib, inputs, system, ... }:
let
  hostname = config.networking.hostName;
  isPhysicalMachine = hostname == "hay";
in
{
  boot = {
    # Çekirdek Paketi Seçimi
    kernelPackages = pkgs.linuxPackages_latest;

    # Önyükleyici Yapılandırması
    loader = {
      grub = {
        enable = true;
        device = lib.mkForce (if isPhysicalMachine then "nodev" else "/dev/vda");
        efiSupport = isPhysicalMachine;
        useOSProber = true;
        configurationLimit = 10;

        # Görsel Yapılandırma
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
        splashImage = "${inputs.distro-grub-themes.packages.${system}.nixos-grub-theme}/splash_image.jpg";
        gfxmodeEfi = "1920x1080";
        gfxmodeBios = "1920x1080";
      };

      # EFI Yapılandırması
      efi = if isPhysicalMachine then {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      } else {};
    };
  };
}
