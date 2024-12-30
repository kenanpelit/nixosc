{
  config,
  pkgs,
  lib,
  ...
}:

let
  mainFont = "Hack Nerd Font";
  termFont = "Maple Mono";
in
{
  fonts = {
    packages = with pkgs; [
      (nerdfonts.override {
        fonts = [
          "Hack"
          "Maple"
        ];
      })
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "${termFont}" "${mainFont} Mono" ];
        sansSerif = [ "${mainFont}" ];
        serif = [ "${mainFont}" ];
      };

      subpixel = {
        rgba = "rgb";
        lcdfilter = "light";
      };
    };

    enableDefaultPackages = true;
  };

  home-manager.users.${config.user} = {
    # Terminal ayarları
    programs.kitty.font = {
      name = termFont;
      size = 13;
    };

    # Dunst bildirim ayarları
    services.dunst.settings.global = {
      font = "${mainFont} 12";
    };

    # Rofi uygulama başlatıcı
    programs.rofi.font = "${mainFont} 12";
  };
}
