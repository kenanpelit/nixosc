# modules/home/foot/default.nix
# ==============================================================================
# Foot Terminal Emulator Configuration
# ==============================================================================
{ config, pkgs, ... }:
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
        font = "Hack Nerd Font:size=12.0";
        font-bold = "Hack Nerd Font:weight=Bold:size=12.0";
        font-italic = "Hack Nerd Font:slant=italic:size=12.0";
        font-bold-italic = "Hack Nerd Font:weight=Bold:slant=italic:size=12.0";
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
        color = "ff79c6";
        border-width = "0";
        border-color = "44475a";
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
        color = "d6acff 6272a4";
      };

      url = {
        protocols = "http,https,file,mailto,news,gemini";
        launch = "xdg-open \${url}";
      };

      mouse = {
        hide-when-typing = "yes";
      };

      colors = {
        alpha = "1.0";
        background = "24283B";
        foreground = "d8dae9";
        selection-foreground = "282a36";
        selection-background = "bd93f9";
        urls = "8be9fd";
        regular0 = "595D71";
        regular1 = "f38ba8";
        regular2 = "50fa7b";
        regular3 = "f1fa8c";
        regular4 = "bd93f9";
        regular5 = "ff79c6";
        regular6 = "8be9fd";
        regular7 = "f8f8f2";
        bright0 = "6272a4";
        bright1 = "e95678";
        bright2 = "69ff94";
        bright3 = "ffffa5";
        bright4 = "d6acff";
        bright5 = "ff92df";
        bright6 = "a4ffff";
        bright7 = "ffffff";
      };
    };
  };
}
