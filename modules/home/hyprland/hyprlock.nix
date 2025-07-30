# modules/home/hyprland/hyprlock.nix
# ==============================================================================
# Hyprlock Configuration with Dynamic Catppuccin Theme
# ==============================================================================
# This configuration manages hyprlock screen locker including:
# - Dynamic Catppuccin color scheme (supports all flavors)
# - Background and avatar configuration  
# - Clock and system information display
# - Authentication input field
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, username, ... }:
let
  # Catppuccin modülünden otomatik renk alımı
  inherit (config.catppuccin) sources;
  
  # Palette JSON'dan renkler - dinamik flavor desteği
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;
  
  # Convert RGB set to string and create RGBA
  mkRgba = color: alpha: "rgba(${toString color.r}, ${toString color.g}, ${toString color.b}, ${toString alpha})";
  
  # Dynamic color palette based on current flavor
  dynamicColors = {
    # Background colors - adapts to flavor
    base = mkRgba colors.base.rgb 1.0;
    surface0 = mkRgba colors.surface0.rgb 0.8;
    surface1 = mkRgba colors.surface1.rgb 0.9;
    mantle = mkRgba colors.mantle.rgb 0.6;
    
    # Text colors - adapts to flavor (light/dark)
    text = mkRgba colors.text.rgb 0.95;
    subtext0 = mkRgba colors.subtext0.rgb 0.8;
    subtext1 = mkRgba colors.subtext1.rgb 0.7;
    
    # Accent colors - flavor dependent
    blue = mkRgba colors.blue.rgb 0.9;
    cyan = mkRgba colors.sky.rgb 0.8;
    teal = mkRgba colors.teal.rgb 0.7;
    purple = mkRgba colors.mauve.rgb 0.8;
    
    # Status colors
    green = mkRgba colors.green.rgb 0.9;
    yellow = mkRgba colors.yellow.rgb 0.8;
    orange = mkRgba colors.peach.rgb 0.8;
    red = mkRgba colors.red.rgb 0.9;
    
    # Special colors
    border = mkRgba colors.overlay0.rgb 0.8;
    overlay = mkRgba colors.mantle.rgb 0.6;
  };
in
{
  home.packages = [ pkgs.hyprlock ];
  
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # Background - Dynamic Catppuccin
    background {
      monitor =
      path = /home/${username}/Pictures/wallpapers/nixos/nixos.png
      blur_passes = 3
      contrast = ${if (config.catppuccin.flavor == "latte") then "1.1" else "0.85"}
      brightness = ${if (config.catppuccin.flavor == "latte") then "1.1" else "0.75"}
      vibrancy = ${if (config.catppuccin.flavor == "latte") then "0.2" else "0.15"}
      color = ${dynamicColors.base}
    }
    
    # General settings
    general {
      no_fade_in = false
      grace = 0
      disable_loading_bar = true
    }
    
    # Day of week - Dynamic Blue
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%A")"
      color = ${dynamicColors.blue}
      font_size = 42
      font_family = Hack Nerd Font
      position = 0, 300
      halign = center
      valign = center
    }
    
    # Date - Dynamic Sky/Cyan
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%d %B %Y")"
      color = ${dynamicColors.cyan}
      font_size = 26
      font_family = Hack Nerd Font
      position = 0, 250
      halign = center
      valign = center
    }
    
    # Time - Dynamic Text Color
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%H:%M")"
      color = ${dynamicColors.text}
      font_size = 22
      font_family = Hack Nerd Font
      position = 0, 200
      halign = center
      valign = center
    }
    
    # Avatar - Dynamic Mauve/Purple Border
    image {
      monitor =
      path = /home/${username}/Pictures/wallpapers/nixos/avatar.png
      border_size = 3
      border_color = ${dynamicColors.purple}
      size = 120
      rounding = 60
      position = 0, 50
      halign = center
      valign = center
    }
    
    # Username background - Dynamic Surface1
    shape {
      monitor =
      size = 250, 50
      color = ${dynamicColors.surface1}
      rounding = 12
      position = 0, -130
      halign = center
      valign = center
    }
    
    # Username - Dynamic Text
    label {
      monitor =
      text = $USER
      color = ${dynamicColors.text}
      font_size = 16
      font_family = Hack Nerd Font
      position = 0, -130
      halign = center
      valign = center
    }
    
    # Password input - Dynamic Theme
    input-field {
      monitor =
      size = 250, 50
      outline_thickness = 2
      dots_size = 0.2
      dots_spacing = 0.2
      dots_center = true
      outer_color = ${dynamicColors.border}
      inner_color = ${dynamicColors.surface0}
      font_color = ${dynamicColors.text}
      fade_on_empty = true
      font_family = Hack Nerd Font
      placeholder_text = <span foreground="${colors.subtext0.hex}">Enter Password</span>
      check_color = ${dynamicColors.green}
      fail_color = ${dynamicColors.red}
      capslock_color = ${dynamicColors.yellow}
      position = 0, -200
      halign = center
      valign = center
    }
    
    # System uptime - Dynamic Subtext0
    label {
      monitor =
      text = cmd[update:60000] echo "⏱ Uptime: $(cat /proc/uptime | awk '{printf "%.0f hours", $1/3600}')"
      color = ${dynamicColors.subtext0}
      font_size = 14
      font_family = Hack Nerd Font
      position = 0, -320
      halign = center
      valign = center
    }
    
    # Music status - Dynamic Teal
    label {
      monitor =
      text = cmd[update:5000] if pgrep -f spotify > /dev/null; then echo "🎵 $(playerctl --player=spotify metadata title 2>/dev/null || echo 'Spotify Running')"; else echo "🎵 No Player"; fi
      color = ${dynamicColors.teal}
      font_size = 14
      font_family = Hack Nerd Font
      position = 0, -350
      halign = center
      valign = center
    }
    
    # Battery status (if laptop) - Dynamic Peach/Orange
    label {
      monitor =
      text = cmd[update:30000] if [ -f /sys/class/power_supply/BAT0/capacity ]; then echo "🔋 $(cat /sys/class/power_supply/BAT0/capacity)%"; else echo ""; fi
      color = ${dynamicColors.orange}
      font_size = 14
      font_family = Hack Nerd Font
      position = 0, -380
      halign = center
      valign = center
    }
    
    # Bottom action icons - Dynamic Text
    label {
      monitor =
      text = 󰐥  󰜉  󰤄
      color = ${dynamicColors.text}
      font_size = 40
      font_family = Hack Nerd Font
      position = 0, 100
      halign = center
      valign = bottom
    }
    
    # Lock screen hint - Dynamic Purple/Mauve
    label {
      monitor =
      text = Press Enter to unlock
      color = ${dynamicColors.purple}
      font_size = 12
      font_family = Hack Nerd Font
      position = 0, -260
      halign = center
      valign = center
    }
    
    # Weather info - Istanbul - Dynamic Sky/Cyan
    label {
      monitor =
      text = cmd[update:300000] curl -s "wttr.in/Istanbul?format=3" 2>/dev/null | head -1 || echo "🌤 Weather unavailable"
      color = ${dynamicColors.cyan}
      font_size = 14
      font_family = Hack Nerd Font
      position = 0, -410
      halign = center
      valign = center
    }
    
    # Flavor indicator - Shows current Catppuccin flavor
    label {
      monitor =
      text = Catppuccin ${lib.strings.toUpper config.catppuccin.flavor}
      color = ${dynamicColors.subtext1}
      font_size = 10
      font_family = Hack Nerd Font
      position = 20, 20
      halign = left
      valign = top
    }
  '';
}

