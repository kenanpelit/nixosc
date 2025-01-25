# modules/core/desktop/fonts/default.nix
# ==============================================================================
# Font Configuration
# ==============================================================================
# This configuration manages font settings including:
# - Font packages
# - Font rendering
# - Font defaults
# - User application fonts
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, username, ... }:
{
  fonts = {
    # Font Packages
    packages = with pkgs; [
      nerd-fonts.hack
    ];

    # Font Settings
    fontconfig = {
      # Default Fonts
      defaultFonts = {
        monospace = [ "Hack Nerd Font Mono" ];
        sansSerif = [ "Hack Nerd Font" ];
        serif = [ "Hack Nerd Font" ];
      };

      # Rendering Settings
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      # Hinting Configuration
      hinting = {
        enable = true;
        autohint = true;
      };

      # Anti-aliasing
      antialias = true;

      # Custom Font Configuration
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

  environment = {
    variables = {
      FONTCONFIG_PATH = "/etc/fonts";
    };
  };

  home-manager.users.${username} = {
    home.stateVersion = "25.05";
    
    # Dunst notification font
    services.dunst.settings.global = {
      font = "Hack Nerd Font 13";
    };

    # Rofi font setting
    programs.rofi.font = "Hack Nerd Font 13";
  };
}
