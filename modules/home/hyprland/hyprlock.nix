# modules/home/hyprland/hyprlock.nix
# ==============================================================================
# Hyprlock Configuration with Tokyo Night Storm Theme
# ==============================================================================
# This configuration manages hyprlock screen locker including:
# - Tokyo Night Storm color scheme
# - Background and avatar configuration  
# - Clock and system information display
# - Authentication input field
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, username, ... }:
let
  # Tokyo Night Storm Color Palette
  colors = {
    # Background colors
    base = "rgba(24, 28, 47, 1.0)";           # #181c2f - storm background
    surface0 = "rgba(30, 35, 57, 0.8)";       # #1e2339 - storm surface
    surface1 = "rgba(41, 46, 68, 0.9)";       # #292e44 - storm surface1
    
    # Text colors
    text = "rgba(192, 202, 245, 0.95)";       # #c0caf5 - storm foreground
    subtext0 = "rgba(169, 177, 214, 0.8)";    # #a9b1d6 - storm comment
    subtext1 = "rgba(118, 124, 163, 0.7)";    # #767ba3 - muted text
    
    # Accent colors
    blue = "rgba(122, 162, 247, 0.9)";        # #7aa2f7 - storm blue
    cyan = "rgba(42, 195, 222, 0.8)";         # #2ac3de - storm cyan
    teal = "rgba(29, 233, 182, 0.7)";         # #1de9b6 - storm teal
    purple = "rgba(187, 154, 247, 0.8)";      # #bb9af7 - storm purple
    magenta = "rgba(199, 146, 234, 0.7)";     # #c792ea - storm magenta
    
    # Status colors
    green = "rgba(158, 206, 106, 0.9)";       # #9ece6a - storm green
    yellow = "rgba(224, 175, 104, 0.8)";      # #e0af68 - storm yellow
    orange = "rgba(255, 158, 100, 0.8)";      # #ff9e64 - storm orange
    red = "rgba(247, 118, 142, 0.9)";         # #f7768e - storm red
    
    # Special colors
    border = "rgba(65, 72, 104, 0.8)";        # #414868 - storm border
    overlay = "rgba(36, 40, 59, 0.6)";        # overlay background
  };
in
{
  home.packages = [ pkgs.hyprlock ];
  
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # Background - Tokyo Night Storm
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
    
    # Day of week - Storm Blue
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
    
    # Date - Storm Cyan
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
    
    # Time - Storm Text
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
    
    # Avatar - Storm Purple Border
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
    
    # Username background - Storm Surface
    shape {
      monitor =
      size = 250, 50
      color = ${colors.surface1}
      rounding = 12
      position = 0, -130
      halign = center
      valign = center
    }
    
    # Username - Storm Text
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
    
    # Password input - Storm Theme (HTML span tags kaldırıldı)
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
    
    # System uptime - Storm Subtext
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
    
    # Music status - Storm Teal
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
    
    # Battery status (if laptop) - Storm Orange
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
    
    # Bottom action icons - Storm Colors (HTML span tags kaldırıldı)
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
    
    # Lock screen hint - Storm Purple
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
    
    # Weather info - Frankfurt - Storm Cyan
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
