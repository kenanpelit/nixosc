{ pkgs, lib, config, inputs, ... }:

{
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      # Temel ayarlar
      clock = true;
      timestr = "%H:%M";
      datestr = "%d.%m.%Y";
      screenshots = true;
      ignore-empty-password = true;
      show-failed-attempts = true;
      
      # Görsel efektler
      effect-blur = "8x5";
      effect-vignette = "0.4:0.4";
      effect-pixelate = 5;

      # Gösterge ayarları
      indicator = true;
      indicator-radius = 100;
      indicator-thickness = 10;
      indicator-caps-lock = true;

      # Font ayarları - Hack ile değiştirildi
      font = "Hack";
      font-size = 20;

      # Tokyo Night renk teması
      key-hl-color = "7aa2f7ff";          # Mavi vurgu
      bs-hl-color = "f7768eff";           # Kırmızı
      
      # Halka renkleri
      ring-color = "1a1b26aa";            # Koyu arkaplan
      ring-clear-color = "e0af68ff";      # Turuncu
      ring-caps-lock-color = "bb9af7ff";  # Mor
      ring-ver-color = "9ece6aff";        # Yeşil
      ring-wrong-color = "db4b4bff";      # Parlak kırmızı
      
      # İç renkler
      inside-color = "16161ecc";          # Tokyo Night en koyu ton
      inside-clear-color = "16161edd";
      inside-caps-lock-color = "16161edd";
      inside-ver-color = "16161edd";
      inside-wrong-color = "16161edd";
      
      # Metin renkleri
      text-color = "a9b1d6ff";            # Açık gri
      text-clear-color = "e0af68ff";      # Turuncu
      text-caps-lock-color = "bb9af7ff";  # Mor
      text-ver-color = "9ece6aff";        # Yeşil
      text-wrong-color = "f7768eff";      # Kırmızı
      
      # Şeffaf UI elemanları
      separator-color = "00000000";
      line-color = "00000000";
      line-clear-color = "00000000";
      line-caps-lock-color = "00000000";
      line-ver-color = "00000000";
      line-wrong-color = "00000000";
      
      # Layout ayarları
      layout-bg-color = "16161ecc";       # En koyu ton
      layout-text-color = "c0caf5ff";     # Açık mavi
    };
  };
}
