# modules/home/terminal/foot/default.nix
# ==============================================================================
# Foot Terminal Emulator Configuration
# ==============================================================================
{ config, pkgs, lib, ... }:
let
  colors = import ./../../../themes/default.nix;
  inherit (colors) kenp;
  # Renk kodlarından # karakterini kaldıran yardımcı fonksiyon
  stripHash = color: builtins.substring 1 6 color;
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
        font = "${colors.fonts.notifications.family}:size=${toString colors.fonts.sizes.sm}";
        font-bold = "${colors.fonts.notifications.family}:weight=Bold:size=${toString colors.fonts.sizes.sm}";
        font-italic = "${colors.fonts.notifications.family}:slant=italic:size=${toString colors.fonts.sizes.sm}";
        font-bold-italic = "${colors.fonts.notifications.family}:weight=Bold:slant=italic:size=${toString colors.fonts.sizes.sm}";
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
        color = "${kenp.pink}";
        border-width = "0";
        border-color = "${kenp.surface1}";
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
        color = "${kenp.mauve} ${kenp.surface2}";
      };
      url = {
        protocols = "http,https,file,mailto,news,gemini";
        launch = "xdg-open \${url}";
      };
      mouse = {
        hide-when-typing = "yes";
      };
      colors = {
        alpha = colors.effects.opacity;
        background = "${lib.strings.removePrefix "#" kenp.base}";
        foreground = "${lib.strings.removePrefix "#" kenp.text}";
        selection-foreground = "${lib.strings.removePrefix "#" kenp.crust}";
        selection-background = "${lib.strings.removePrefix "#" kenp.mauve}";
        urls = "${lib.strings.removePrefix "#" kenp.sky}";
        regular0 = "${lib.strings.removePrefix "#" kenp.surface1}";    # Black
        regular1 = "${lib.strings.removePrefix "#" kenp.red}";         # Red
        regular2 = "${lib.strings.removePrefix "#" kenp.green}";       # Green
        regular3 = "${lib.strings.removePrefix "#" kenp.yellow}";      # Yellow
        regular4 = "${lib.strings.removePrefix "#" kenp.mauve}";       # Blue
        regular5 = "${lib.strings.removePrefix "#" kenp.pink}";        # Magenta
        regular6 = "${lib.strings.removePrefix "#" kenp.sky}";         # Cyan
        regular7 = "${lib.strings.removePrefix "#" kenp.text}";        # White
        bright0 = "${lib.strings.removePrefix "#" kenp.surface2}";     # Bright Black
        bright1 = "${lib.strings.removePrefix "#" kenp.red}";          # Bright Red
        bright2 = "${lib.strings.removePrefix "#" kenp.green}";        # Bright Green
        bright3 = "${lib.strings.removePrefix "#" kenp.yellow}";       # Bright Yellow
        bright4 = "${lib.strings.removePrefix "#" kenp.mauve}";        # Bright Blue
        bright5 = "${lib.strings.removePrefix "#" kenp.pink}";         # Bright Magenta
        bright6 = "${lib.strings.removePrefix "#" kenp.sky}";          # Bright Cyan
        bright7 = "${lib.strings.removePrefix "#" kenp.text}";         # Bright White
      };
    };
  };
}
