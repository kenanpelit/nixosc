# modules/home/foot/default.nix
# ==============================================================================
# Foot Terminal Emulator Configuration - Catppuccin Mocha
# ==============================================================================
{ config, pkgs, lib, ... }:
let
  # Catppuccin Mocha tema renkleri
  colors = {
    base = "#1e1e2e";
    crust = "#11111b";
    text = "#cdd6f4";
    surface1 = "#45475a";
    surface2 = "#585b70";
    mauve = "#cba6f7";
    sky = "#89dceb";
    red = "#f38ba8";
    green = "#a6e3a1";
    yellow = "#f9e2af";
    pink = "#f5c2e7";
  };

  # Font ve efekt ayarları
  fonts = {
    notifications = {
      family = "Hack Nerd Font";
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
  # =============================================================================
  # Program Configuration
  # =============================================================================
  programs.foot = {
    enable = true;
    settings = {
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
        color = "${lib.strings.removePrefix "#" colors.pink}";
        border-width = "0";
        border-color = "${lib.strings.removePrefix "#" colors.surface1}";
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
        background = "${lib.strings.removePrefix "#" colors.base}";
        foreground = "${lib.strings.removePrefix "#" colors.text}";
        selection-foreground = "${lib.strings.removePrefix "#" colors.crust}";
        selection-background = "${lib.strings.removePrefix "#" colors.mauve}";
        urls = "${lib.strings.removePrefix "#" colors.sky}";
        regular0 = "${lib.strings.removePrefix "#" colors.surface1}";    # Black
        regular1 = "${lib.strings.removePrefix "#" colors.red}";         # Red
        regular2 = "${lib.strings.removePrefix "#" colors.green}";       # Green
        regular3 = "${lib.strings.removePrefix "#" colors.yellow}";      # Yellow
        regular4 = "${lib.strings.removePrefix "#" colors.mauve}";       # Blue
        regular5 = "${lib.strings.removePrefix "#" colors.pink}";        # Magenta
        regular6 = "${lib.strings.removePrefix "#" colors.sky}";         # Cyan
        regular7 = "${lib.strings.removePrefix "#" colors.text}";        # White
        bright0 = "${lib.strings.removePrefix "#" colors.surface2}";     # Bright Black
        bright1 = "${lib.strings.removePrefix "#" colors.red}";          # Bright Red
        bright2 = "${lib.strings.removePrefix "#" colors.green}";        # Bright Green
        bright3 = "${lib.strings.removePrefix "#" colors.yellow}";       # Bright Yellow
        bright4 = "${lib.strings.removePrefix "#" colors.mauve}";        # Bright Blue
        bright5 = "${lib.strings.removePrefix "#" colors.pink}";         # Bright Magenta
        bright6 = "${lib.strings.removePrefix "#" colors.sky}";          # Bright Cyan
        bright7 = "${lib.strings.removePrefix "#" colors.text}";         # Bright White
      };
    };
  };
}

