{ pkgs, ... }:
{
  imports = [
    ./theme.nix    # Tema ayarları
    ./config.nix   # Rofi konfigürasyonu
  ];

  home.packages = (with pkgs; [ rofi-wayland ]);
}
