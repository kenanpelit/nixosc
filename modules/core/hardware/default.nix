# modules/core/hardware/default.nix
# ==============================================================================
# Hardware Configuration
# ==============================================================================
{ pkgs, ... }:
{
  hardware = {
    # Grafik Sürücüleri ve Donanım Hızlandırma
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver    # Modern Intel grafik sürücüsü
        vaapiVdpau           # VA-API to VDPAU köprüsü
        libvdpau-va-gl       # VDPAU için OpenGL desteği
        mesa                 # OpenGL implementasyonu
        intel-compute-runtime # Intel GPU hesaplama desteği
        intel-ocl            # Intel OpenCL desteği
      ];
    };

    # Firmware Yapılandırması
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    
    # CPU Yapılandırması
    cpu.intel.updateMicrocode = true;
    
    # Bluetooth Yapılandırması
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  # Ses Sistemi
  services.pulseaudio.enable = false;  # PipeWire lehine devre dışı

  # Donanım İzleme ve Yönetim Paketleri
  environment.systemPackages = with pkgs; [
    linux-firmware    # Linux firmware koleksiyonu
    wireless-regdb    # Kablosuz düzenleme veritabanı
    firmware-updater  # Firmware güncelleme aracı
    lm_sensors       # Donanım sensör araçları
  ];
}
