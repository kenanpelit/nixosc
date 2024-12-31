{ config, pkgs, lib, username, ... }:
{
  # -------------------------------------------------------
  # Font Konfigürasyonu
  # -------------------------------------------------------
  fonts = {
    # Hack Nerd Fonts'u sisteme ekliyoruz
    packages = with pkgs; [
      pkgs.nerd-fonts.hack  # Hack Nerd Font paketi
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "Hack Nerd Font" ];  # Hack Nerd Font varsayılan monospace font
        sansSerif = [ "Hack Nerd Font" ];
        serif = [ "Hack Nerd Font" ];
      };

      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      hinting = {
        enable = true;
        autohint = true;
      };

      antialias = true;

      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="font">
            <test name="family" compare="contains">
              <string>Hack Nerd Font</string>
            </test>
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
    FONTCONFIG_PATH = "/etc/fonts"; # Varsayılan sistem font dizini
  };

  # -------------------------------------------------------
  # Home Manager Konfigürasyonu
  # -------------------------------------------------------
  home-manager.users.${username} = {
    home.stateVersion = "24.11";

    services.dunst.settings.global = {
      font = "Hack Nerd Font 13";  # Bildirimler için font
    };

    programs.rofi.font = "Hack Nerd Font 13";  # Rofi için font
  };
}

