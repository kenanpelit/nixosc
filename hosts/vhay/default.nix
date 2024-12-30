{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];
  
  # BIOS/GRUB configuration 
  boot.loader.systemd-boot.enable = lib.mkForce false;
  # GRUB ayarlarını bootloader.nix'e taşıyalım
  # boot.loader.grub bölümünü kaldırıyoruz

  # SSH configuration
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      PermitRootLogin = "yes";
    };
  };
}
