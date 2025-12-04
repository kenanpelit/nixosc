# modules/home/foot/default.nix
# ==============================================================================
# Foot Terminal Emulator Configuration - Tamamen Temiz Catppuccin
# ==============================================================================
{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.foot;

  # Catppuccin modülünden otomatik renk alımı
  inherit (config.catppuccin) sources;
  
  # Palette JSON'dan renkler
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;

  # Font ve efekt ayarları
  fonts = {
    notifications = {
      family = "Maple Mono NF";
    };
    sizes = {
      sm = 12;
    };
  };

  effects = {
    opacity = "1.0";
  };
in
{
  options.my.user.foot = {
    enable = lib.mkEnableOption "Foot terminal emulator";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Catppuccin modülünü devre dışı bırak, kendi renklerimizi kullan
    # =============================================================================
    
    programs.foot = {
      enable = true;
      settings = {
        # Include yerine direkt olarak renkler bölümünde tanımlayalım
        # ===========================================================================
        # Main Settings
        # ===========================================================================
        main = {
          font = "${fonts.notifications.family}:size=${toString fonts.sizes.sm}";
          font-bold = "${fonts.notifications.family}:weight=Bold:size=${toString fonts.sizes.sm}";
          font-italic = "${fonts.notifications.family}:slant=italic:size=${toString fonts.sizes.sm}";
          font-bold-italic = "${fonts.notifications.family}:weight=Bold:slant=italic:size=${toString fonts.sizes.sm}";
          letter-spacing = "0.5";
          horizontal-letter-offset = "0.5";
          vertical-letter-offset = "0";
          dpi-aware = "yes";
          font-size-adjustment = "0.75";
          app-id = "foot";
          title = "Terminal";
          pad = "4x4";
        };
        
        tweak = {
          grapheme-shaping = "yes";
          grapheme-width-method = "double-width";
        };
        
        csd = {
          preferred = "none";
          size = "0";
          border-width = "0";
          button-width = "0";
        };
        
        environment = {
          FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
          WINIT_UNIX_BACKEND = "wayland";
          WINIT_X11_SCALE_FACTOR = "1";
          GDK_SCALE = "1";
          QT_AUTO_SCREEN_SCALE_FACTOR = "0";
          LIBGL_DRI3_DISABLE = "1";
          WLR_NO_HARDWARE_CURSORS = "1";
          XCURSOR_SIZE = "24";
          MESA_GL_VERSION_OVERRIDE = "4.6";
          MESA_LOADER_DRIVER_OVERRIDE = "iris";
          LIBVA_DRIVER_NAME = "iHD";
          "__GL_GSYNC_ALLOWED" = "0";
          "__GL_VRR_ALLOWED" = "0";
        };
        
        scrollback = {
          lines = "10000";
          multiplier = "3.0";
        };
        
        cursor = {
          style = "block";
          blink = "yes";
          beam-thickness = "1.5";
          underline-thickness = "2";
        };
        
        url = {
          launch = "xdg-open \${url}";
        };
        
        mouse = {
          hide-when-typing = "yes";
        };
        
        colors = {
          alpha = effects.opacity;
          
          # Kendi Catppuccin renkleri - deprecated olmadan
          foreground = "${lib.strings.removePrefix "#" colors.text.hex}";
          background = "${lib.strings.removePrefix "#" colors.base.hex}";
          
          selection-foreground = "${lib.strings.removePrefix "#" colors.text.hex}";
          selection-background = "${lib.strings.removePrefix "#" colors.surface2.hex}";
          
          urls = "${lib.strings.removePrefix "#" colors.rosewater.hex}";
          
          # Modern cursor format - deprecated değil
          cursor = "${lib.strings.removePrefix "#" colors.rosewater.hex} ${lib.strings.removePrefix "#" colors.base.hex}";
          
          # ANSI colors
          regular0 = "${lib.strings.removePrefix "#" colors.surface1.hex}";
          regular1 = "${lib.strings.removePrefix "#" colors.red.hex}";
          regular2 = "${lib.strings.removePrefix "#" colors.green.hex}";
          regular3 = "${lib.strings.removePrefix "#" colors.yellow.hex}";
          regular4 = "${lib.strings.removePrefix "#" colors.blue.hex}";
          regular5 = "${lib.strings.removePrefix "#" colors.pink.hex}";
          regular6 = "${lib.strings.removePrefix "#" colors.teal.hex}";
          regular7 = "${lib.strings.removePrefix "#" colors.subtext1.hex}";
          
          bright0 = "${lib.strings.removePrefix "#" colors.surface2.hex}";
          bright1 = "${lib.strings.removePrefix "#" colors.red.hex}";
          bright2 = "${lib.strings.removePrefix "#" colors.green.hex}";
          bright3 = "${lib.strings.removePrefix "#" colors.yellow.hex}";
          bright4 = "${lib.strings.removePrefix "#" colors.blue.hex}";
          bright5 = "${lib.strings.removePrefix "#" colors.pink.hex}";
          bright6 = "${lib.strings.removePrefix "#" colors.teal.hex}";
          bright7 = "${lib.strings.removePrefix "#" colors.subtext0.hex}";
          
          # Indexed colors
          "16" = "${lib.strings.removePrefix "#" colors.peach.hex}";
          "17" = "${lib.strings.removePrefix "#" colors.rosewater.hex}";
        };
      };
    };
  };
}
