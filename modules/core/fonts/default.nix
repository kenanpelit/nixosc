# ==============================================================================
# Sistem Geneli Font Konfigürasyonu
# ==============================================================================
{ config, pkgs, lib, username, ... }:
{
  # -------------------------------------------------------
  # Font Paketleri ve Ayarları
  # -------------------------------------------------------
  fonts = {
    # Gerekli font paketleri
    packages = with pkgs; [
      nerd-fonts.hack  # Yeni syntax ile Hack Nerd Font
    ];

    # Font yapılandırması
    fontconfig = {
      # Varsayılan font ayarları
      defaultFonts = {
        monospace = [ "Hack Nerd Font Mono" ];
        sansSerif = [ "Hack Nerd Font" ];
        serif = [ "Hack Nerd Font" ];
      };

      # Font rendering ayarları
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      # Hinting ayarları
      hinting = {
        enable = true;
        autohint = true;
      };

      # Anti-aliasing
      antialias = true;

      # Özel font konfigürasyonu
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="font">
            <test name="family" compare="contains">
              <string>Hack Nerd Font</string>
            </test>
            <edit name="antialias" mode="assign">
              <bool>true</bool>
            </edit>
          </match>
        </fontconfig>
      '';
    };

    enableDefaultPackages = true;
  };

  # -------------------------------------------------------
  # Çevre Değişkenleri
  # -------------------------------------------------------
  environment.variables = {
    FONTCONFIG_PATH = "/etc/fonts";
  };

  # -------------------------------------------------------
  # Kullanıcı Uygulamaları Font Ayarları
  # -------------------------------------------------------
  home-manager.users.${username} = {
    home.stateVersion = "24.11";
    
    # Dunst (bildirim) font ayarı
    services.dunst.settings.global = {
      font = "Hack Nerd Font 13";
    };

    # Rofi font ayarı
    programs.rofi.font = "Hack Nerd Font 13";
  };
}
