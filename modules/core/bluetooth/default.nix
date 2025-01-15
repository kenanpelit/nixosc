# modules/core/bluetooth/default.nix
# ==============================================================================
# Bluetooth System Configuration
# ==============================================================================
{ config, lib, pkgs, ... }: {
  # Bluetooth Donanım Yapılandırması
  hardware.bluetooth = {
    enable = true;        # Bluetooth desteğini etkinleştir
    powerOnBoot = true;   # Açılışta otomatik başlat
  };

  # Bluetooth Yönetim Arayüzü
  services.blueman.enable = true;
}
