{ pkgs, ... }:
{
  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver  # Yeni nesil Intel grafik sürücüsü
        vaapiVdpau
        libvdpau-va-gl
        mesa
        intel-compute-runtime
        intel-ocl
      ];
    };

    # Firmware desteği
    enableRedistributableFirmware = true;
    enableAllFirmware = true;

    # CPU mikrokod güncellemeleri
    cpu.intel.updateMicrocode = true;

    # Bluetooth desteği
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # PulseAudio ayarı services altına taşındı
  services.pulseaudio.enable = false; 

  # Firmware ve ilgili paketler
  environment.systemPackages = with pkgs; [
    linux-firmware
    wireless-regdb
    firmware-updater
    lm_sensors
  ];
}
