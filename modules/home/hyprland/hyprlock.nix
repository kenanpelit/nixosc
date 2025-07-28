# modules/home/hyprland/hyprlock.nix
# ==============================================================================
# Hyprlock Configuration with Catppuccin Mocha Theme
# ==============================================================================
# This configuration manages hyprlock screen locker including:
# - Catppuccin Mocha color scheme
# - Background and avatar configuration  
# - Clock and system information display
# - Authentication input field
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, username, ... }:
let
  # Catppuccin Mocha Color Palette
  colors = {
    # Background colors
    base = "rgba(30, 30, 46, 1.0)";           # #1e1e2e - mocha base
    surface0 = "rgba(49, 50, 68, 0.8)";       # #313244 - mocha surface0
    surface1 = "rgba(69, 71, 90, 0.9)";       # #45475a - mocha surface1
    
    # Text colors
    text = "rgba(205, 214, 244, 0.95)";       # #cdd6f4 - mocha text
    subtext0 = "rgba(166, 173, 200, 0.8)";    # #a6adc8 - mocha subtext0
    subtext1 = "rgba(186, 194, 222, 0.7)";    # #bac2de - mocha subtext1
    
    # Accent colors
    blue = "rgba(137, 180, 250, 0.9)";        # #89b4fa - mocha blue
    cyan = "rgba(137, 220, 235, 0.8)";        # #89dceb - mocha sky
    teal = "rgba(148, 226, 213, 0.7)";        # #94e2d5 - mocha teal
    purple = "rgba(203, 166, 247, 0.8)";      # #cba6f7 - mocha mauve
    magenta = "rgba(203, 166, 247, 0.7)";     # #cba6f7 - mocha mauve
    
    # Status colors
    green = "rgba(166, 227, 161, 0.9)";       # #a6e3a1 - mocha green
    yellow = "rgba(249, 226, 175, 0.8)";      # #f9e2af - mocha yellow
    orange = "rgba(250, 179, 135, 0.8)";      # #fab387 - mocha peach
    red = "rgba(243, 139, 168, 0.9)";         # #f38ba8 - mocha pink
    
    # Special colors
    border = "rgba(108, 112, 134, 0.8)";      # #6c7086 - mocha overlay0
    overlay = "rgba(24, 24, 37, 0.6)";        # #181825 - mocha mantle
  };
in
{
  home.packages = [ pkgs.hyprlock ];
  
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # Background - Catppuccin Mocha
    background {
      monitor =
      path = /home/${username}/Pictures/wallpapers/nixos/nixos.png
      blur_passes = 3
      contrast = 0.85
      brightness = 0.75
      vibrancy = 0.15
      color = ${colors.base}
    }
    
    # General settings
    general {
      no_fade_in = false
      grace = 0
      disable_loading_bar = true
    }
    
    # Day of week - Mocha Blue
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%A")"
      color = ${colors.blue}
      font_size = 42
      font_family = Hack Nerd Font
      position = 0, 300
      halign = center
      valign = center
    }
    
    # Date - Mocha Sky (Cyan)
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%d %B %Y")"
      color = ${colors.cyan}
      font_size = 26
      font_family = Hack Nerd Font
      position = 0, 250
      halign = center
      valign = center
    }
    
    # Time - Mocha Text
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%H:%M")"
      color = ${colors.text}
      font_size = 22
      font_family = Hack Nerd Font
      position = 0, 200
      halign = center
      valign = center
    }
    
    # Avatar - Mocha Mauve (Purple) Border
    image {
      monitor =
      path = /home/${username}/Pictures/wallpapers/nixos/avatar.png
      border_size = 3
      border_color = ${colors.purple}
      size = 120
      rounding = 60
      position = 0, 50
      halign = center
      valign = center
    }
    
    # Username background - Mocha Surface1
    shape {
      monitor =
      size = 250, 50
      color = ${colors.surface1}
      rounding = 12
      position = 0, -130
      halign = center
      valign = center
    }
    
    # Username - Mocha Text
    label {
      monitor =
      text = $USER
      color = ${colors.text}
      font_size = 16
      font_family = Hack Nerd Font
      position = 0, -130
      halign = center
      valign = center
    }
    
    # Password input - Mocha Theme
    input-field {
      monitor =
      size = 250, 50
      outline_thickness = 2
      dots_size = 0.2
      dots_spacing = 0.2
      dots_center = true
      outer_color = ${colors.border}
      inner_color = ${colors.surface0}
      font_color = ${colors.text}
      fade_on_empty = true
      font_family = Hack Nerd Font
      placeholder_text = Enter Password
      check_color = ${colors.green}
      fail_color = ${colors.red}
      capslock_color = ${colors.yellow}
      position = 0, -200
      halign = center
      valign = center
    }
    
    # System uptime - Mocha Subtext0
    label {
      monitor =
      text = cmd[update:60000] echo "⏱ Uptime: $(cat /proc/uptime | awk '{printf "%.0f hours", $1/3600}')"
      color = ${colors.subtext0}
      font_size = 14
      font_family = Hack Nerd Font
      position = 0, -320
      halign = center
      valign = center
    }
    
    # Music status - Mocha Teal
    label {
      monitor =
      text = cmd[update:5000] if pgrep -f spotify > /dev/null; then echo "🎵 $(playerctl --player=spotify metadata title 2>/dev/null || echo 'Spotify Running')"; else echo "🎵 No Player"; fi
      color = ${colors.teal}
      font_size = 14
      font_family = Hack Nerd Font
      position = 0, -350
      halign = center
      valign = center
    }
    
    # Battery status (if laptop) - Mocha Peach (Orange)
    label {
      monitor =
      text = cmd[update:30000] if [ -f /sys/class/power_supply/BAT0/capacity ]; then echo "🔋 $(cat /sys/class/power_supply/BAT0/capacity)%"; else echo ""; fi
      color = ${colors.orange}
      font_size = 14
      font_family = Hack Nerd Font
      position = 0, -380
      halign = center
      valign = center
    }
    
    # Bottom action icons - Mocha Text
    label {
      monitor =
      text = 󰐥  󰜉  󰤄
      color = ${colors.text}
      font_size = 40
      font_family = Hack Nerd Font
      position = 0, 100
      halign = center
      valign = bottom
    }
    
    # Lock screen hint - Mocha Mauve (Purple)
    label {
      monitor =
      text = Press Enter to unlock
      color = ${colors.purple}
      font_size = 12
      font_family = Hack Nerd Font
      position = 0, -260
      halign = center
      valign = center
    }
    
    # Weather info - Istanbul - Mocha Sky (Cyan)
    label {
      monitor =
      text = cmd[update:300000] curl -s "wttr.in/Istanbul?format=3" 2>/dev/null | head -1 || echo "🌤 Weather unavailable"
      color = ${colors.cyan}
      font_size = 14
      font_family = Hack Nerd Font
      position = 0, -410
      halign = center
      valign = center
    }
  '';
}

