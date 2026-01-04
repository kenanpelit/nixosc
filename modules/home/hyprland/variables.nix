# modules/home/hyprland/variables.nix
# ==============================================================================
# Hyprland Environment & Theming Variables
#
# Defines Catppuccin-based color schemes, cursor themes, and a comprehensive
# set of environment variables for the Wayland session.
# Imported by default.nix
# ==============================================================================
{ config, lib, ... }:

let
  inherit (config.catppuccin) sources;
  flavor = config.catppuccin.flavor;
  accent = config.catppuccin.accent;
  colors = (lib.importJSON "${sources.palette}/palette.json").${flavor}.colors;

  # Color format converter (Hex -> 0xAARRGGBB)
  mkColor = color: alpha:
    let
      hex = lib.removePrefix "#" color;
      alphaInt =
        let x = builtins.floor (alpha * 255);
        in if x < 0 then 0 else if x > 255 then 255 else x;
      toHex = n:
        let
          hexDigits = ["0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "a" "b" "c" "d" "e" "f"];
          hi = builtins.div n 16;
          lo = n - 16 * hi;
        in "${builtins.elemAt hexDigits hi}${builtins.elemAt hexDigits lo}";
    in "0x${toHex alphaInt}${hex}";

in
rec {
  inherit mkColor colors flavor accent;
  
  themeName = "catppuccin-${flavor}-${accent}";
  cursorName = "catppuccin-${flavor}-${accent}-cursors";
  cursorSize = 24;

  activeBorder = "${mkColor colors.blue.hex 0.93} ${mkColor colors.mauve.hex 0.93} 45deg";
  inactiveBorder = mkColor colors.overlay0.hex 0.66;
  inactiveGroupBorder = "${mkColor colors.surface1.hex 0.66} ${mkColor colors.overlay0.hex 0.66} 45deg";

  envVars = [
    "XDG_SESSION_TYPE,wayland"
    "XDG_SESSION_DESKTOP,Hyprland"
    "XDG_CURRENT_DESKTOP,Hyprland"
    "DESKTOP_SESSION,Hyprland"
    "GDK_BACKEND,wayland,x11"
    "SDL_VIDEODRIVER,wayland"
    "CLUTTER_BACKEND,wayland"
    "OZONE_PLATFORM,wayland"
    "HYPRLAND_LOG_WLR,1"
    "HYPRLAND_NO_RT,1"
    "HYPRLAND_NO_SD_NOTIFY,1"
    "HYPRLAND_NO_WATCHDOG_WARNING,1"
    "GTK_THEME,catppuccin-${flavor}-${accent}-standard+normal"
    "GTK_USE_PORTAL,1"
    "GTK_APPLICATION_PREFER_DARK_THEME,${if (flavor == "latte") then "0" else "1"}"
    "GDK_SCALE,1"
    "HYPRCURSOR_SIZE,${toString cursorSize}"
    "XCURSOR_THEME,catppuccin-${flavor}-${accent}-cursors"
    "XCURSOR_SIZE,${toString cursorSize}"
    "QT_QPA_PLATFORM,wayland;xcb"
    "QT_QPA_PLATFORMTHEME,gtk3"
    "QT_QPA_PLATFORMTHEME_QT6,gtk3"
    "QT_STYLE_OVERRIDE,kvantum"
    "QT_AUTO_SCREEN_SCALE_FACTOR,1"
    "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
    "QT_WAYLAND_FORCE_DPI,96"
    "MOZ_ENABLE_WAYLAND,1"
    "MOZ_WEBRENDER,1"
    "MOZ_USE_XINPUT2,1"
    "MOZ_CRASHREPORTER_DISABLE,1"
    "FREETYPE_PROPERTIES,truetype:interpreter-version=40"
    "WLR_RENDERER,vulkan"
    "LIBVA_DRIVER_NAME,iHD"
    "EDITOR,nvim"
    "VISUAL,nvim"
    "TERMINAL,kitty"
    "TERM,xterm-256color"
    "BROWSER,brave"
    "CATPPUCCIN_FLAVOR,${flavor}"
  ];
}
