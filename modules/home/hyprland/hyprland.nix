# modules/home/hyprland/hyprland.nix
{ inputs, pkgs, ... }:
{
  # Kullanılacak paketlerin listesi
  home.packages = with pkgs; [
    swww                                # Dinamik duvar kağıdı ayarları için araç
    inputs.hypr-contrib.packages.${pkgs.system}.grimblast # Ekran görüntüsü almak için geliştirilmiş araç
    hyprpicker                          # Renk seçici araç
    inputs.hyprmag.packages.${pkgs.system}.hyprmag # Ekran büyüteci aracı
    grim                                # Standart ekran görüntüsü aracı
    slurp                               # Ekran seçme aracı (örneğin ekran görüntüsü için)
    wl-clip-persist                     # Wayland için pano yönetimi
    cliphist                            # Pano geçmişi yönetimi
    wf-recorder                         # Wayland için ekran kaydedici
    glib                                # GLib yardımcı kütüphaneleri
    wayland                             # Wayland oturumları için temel destek
    direnv                              # Ortam değişkenleri yönetimi
  ];

  # Hyprland oturumu için systemd kullanıcı hedefi
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"    # Masaüstü uygulamalarının otomatik başlatılması
  ];

  # Hyprland pencere yöneticisi ayarları
  wayland.windowManager.hyprland = {
    enable = true;                    # Hyprland'ı etkinleştir

    # XWayland ayarları (X11 uygulamalarını çalıştırmak için gereklidir)
    xwayland = {
      enable = true;                  # XWayland desteğini etkinleştir
      #hidpi = true;                  # Yüksek çözünürlük desteği (isteğe bağlı)
    };

    # NVIDIA sürücüleri için yamaları etkinleştirme (isteğe bağlı)
    # enableNvidiaPatches = false;

    systemd.enable = true;            # Hyprland için gerekli systemd entegrasyonunu etkinleştir
  };
}


