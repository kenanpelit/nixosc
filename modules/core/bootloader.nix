{ pkgs, ... }:
{
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.systemd-boot.configurationLimit = 10;
  #boot.kernelPackages = pkgs.linuxPackages_latest;
  # GRUB bootloader yapılandırması
  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "nodev";     # EFI için "nodev" kullanılır
    efiSupport = true;
    useOSProber = false;  # Diğer işletim sistemlerini tarama
    configurationLimit = 10;
  };
  
  # EFI değişkenlerini düzenleme izni
  boot.loader.efi.canTouchEfiVariables = true;

  # En son kernel paketlerini kullan
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
