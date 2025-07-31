# modules/home/vlc/default.nix
# ==============================================================================
# VLC Media Player Catppuccin Configuration
# ==============================================================================
# This configuration manages VLC with Catppuccin-inspired theming including:
# - Dark interface themes
# - Custom configuration with Catppuccin colors
# - Integration with system color scheme
#
# Author: Kenan Pelit
# ==============================================================================
{ config, pkgs, lib, ... }:
let
  # Merkezi catppuccin konfigürasyonundan ayarları al
  flavor = config.catppuccin.flavor or "mocha";
  accent = config.catppuccin.accent or "mauve";
  
  # Catppuccin renk paleti
  catppuccinColors = {
    mocha = {
      base = "1e1e2e"; text = "cdd6f4"; 
      surface0 = "313244"; surface1 = "45475a";
      blue = "89b4fa"; mauve = "cba6f7";
      red = "f38ba8"; green = "a6e3a1";
      yellow = "f9e2af"; peach = "fab387";
    };
    macchiato = {
      base = "24273a"; text = "cad3f5";
      surface0 = "363a4f"; surface1 = "494d64";
      blue = "8aadf4"; mauve = "c6a0f6";
      red = "ed8796"; green = "a6da95";
      yellow = "eed49f"; peach = "f5a97f";
    };
    frappe = {
      base = "303446"; text = "c6d0f5";
      surface0 = "414559"; surface1 = "51576d";
      blue = "8caaee"; mauve = "ca9ee6";
      red = "e78284"; green = "a6d189";
      yellow = "e5c890"; peach = "ef9f76";
    };
    latte = {
      base = "eff1f5"; text = "4c4f69";
      surface0 = "ccd0da"; surface1 = "bcc0cc";
      blue = "1e66f5"; mauve = "8839ef";
      red = "d20f39"; green = "40a02b";
      yellow = "df8e1d"; peach = "fe640b";
    };
  };
  
  colors = catppuccinColors.${flavor};
  
  # VLC konfigürasyon dosyası
  vlcConfig = ''
    [qt4] # Qt interface
    qt-opacity=1.000000
    qt-fs-opacity=0.800000
    qt-system-tray=1
    qt-notification=0
    qt-start-minimized=0
    qt-pause-minimized=0
    qt-close-to-systray=0
    qt-continue=0
    qt-updates-notif=0
    qt-volume-complete=0
    qt-autosave-volume=1
    qt-embedded-open=0
    qt-recentplay=1
    qt-save-path=/home/$USER/Videos
    qt-filter-toolbar=1
    qt-adv-options=0
    qt-advanced-pref=0
    qt-error-dialogs=1
    qt-slider-colors=255;255;255;20;210;20;255;199;15;245;39;29
    qt-titlebar=1
    qt-name-in-title=1
    qt-fs-controller=1
    qt-recentplay-filter=0
    qt-menubar=1
    qt-minimal-view=0
    qt-bgcone=1
    qt-bgcone-expands=0
    qt-icon-change=1
    qt-max-volume=125

    [skins2] # Skins interface
    skins2-last=/usr/share/vlc/skins2/default.vlt
    skins2-config=[{"id":"main","visible":true,"x":26,"y":26,"width":580,"height":421}]

    [core] # Core settings
    intf=qt
    extraintf=
    
    # Catppuccin-inspired interface colors
    qt-display-mode=0
    qt-privacy-ask=0
    
    # Media library
    ml-show=0
    
    # Playlist settings
    playlist-autostart=1
    play-and-pause=0
    
    # Video settings
    video=1
    fullscreen=0
    
    # Audio settings
    audio=1
    volume=256
    
    # Subtitle settings
    sub-autodetect-file=1
    sub-autodetect-path=./Subtitles, ./subtitles, ./Subs, ./subs
  '';
  
  # Custom VLC skin creation (Catppuccin-inspired)
  catppuccinSkin = pkgs.writeText "catppuccin-vlc.vlt" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE Theme PUBLIC "-//VideoLAN//DTD VLC Skins V2.0//EN" "skin.dtd">
    <Theme version="2.0" magnet="15" alpha="255" movealpha="255">
      <ThemeInfo name="Catppuccin ${flavor}" author="NixOS Config" email="nix@catppuccin.com"/>
      
      <!-- Catppuccin color definitions -->
      <BitmapFont id="text.font" file="text.font.png" type="digits"/>
      
      <!-- Main window -->
      <Window id="main" x="100" y="100" width="580" height="421" 
              dragdrop="true" playondrop="true">
        <Layout id="normal" width="580" height="421">
          <!-- Background -->
          <Rectangle x="0" y="0" width="580" height="421" 
                     color="#${colors.base}" filled="true"/>
          
          <!-- Title bar -->
          <Rectangle x="0" y="0" width="580" height="30" 
                     color="#${colors.surface0}" filled="true"/>
          
          <!-- Control area -->
          <Rectangle x="0" y="30" width="580" height="60" 
                     color="#${colors.surface1}" filled="true"/>
          
          <!-- Progress bar background -->
          <Rectangle x="10" y="380" width="560" height="30" 
                     color="#${colors.surface0}" filled="true"/>
          
          <!-- Window controls -->
          <Button x="540" y="5" width="15" height="15" 
                  up="close.up.png" down="close.down.png" 
                  action="vlc.quit()"/>
          <Button x="520" y="5" width="15" height="15" 
                  up="minimize.up.png" down="minimize.down.png" 
                  action="vlc.minimize()"/>
        </Layout>
      </Window>
    </Theme>
  '';
  
in
{
  # =============================================================================
  # VLC Package Installation
  # =============================================================================
  home.packages = with pkgs; [
    vlc
  ];
  
  # =============================================================================
  # VLC Configuration with Catppuccin Colors
  # =============================================================================
  xdg.configFile = {
    "vlc/vlcrc".text = vlcConfig;
    
    # Custom Catppuccin-inspired skin (placeholder)
    "vlc/skins2/catppuccin-${flavor}.vlt".source = catppuccinSkin;
  };
  
  # =============================================================================
  # Desktop Integration
  # =============================================================================
  xdg.mimeApps.defaultApplications = {
    "video/mp4" = ["vlc.desktop"];
    "video/x-matroska" = ["vlc.desktop"];
    "video/webm" = ["vlc.desktop"];
    "video/x-msvideo" = ["vlc.desktop"];
    "audio/mpeg" = ["vlc.desktop"];
    "audio/flac" = ["vlc.desktop"];
    "audio/x-wav" = ["vlc.desktop"];
  };
  
  # =============================================================================
  # QT Theme Integration (VLC QT interface için)
  # =============================================================================
  home.sessionVariables = {
    # VLC'nin sistem temasını kullanması için
    VLC_QT_THEME = "dark";
  };
}

