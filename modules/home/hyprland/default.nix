# modules/home/hyprland/default.nix
{ inputs, ... }:
{
  imports = [
    # 1. Önce Hyprland'in kendi home-manager modülü
    inputs.hyprland.homeManagerModules.default

    # 2. Temel yapılandırma ve değişkenler
    ./hyprland.nix                # Ana Hyprland yapılandırması
    ./config.nix                  # Genel yapılandırma ayarları

    # 3. Ek bileşenler ve uzantılar
    ./hyprlock.nix                # Ekran kilidi
    ./hypridle.nix                # Boşta kalma yönetimi
    ./pyprland.nix                # Python eklentileri
  ];
}
