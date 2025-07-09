# modules/home/hyprland/hyprlock.nix
# ==============================================================================
# Fixed Hyprlock Configuration with Tokyo Night Theme
# ==============================================================================
# This configuration manages hyprlock screen locker including:
# - Tokyo Night color scheme
# - Background and avatar configuration
# - Clock and system information display
# - Authentication input field
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, username, ... }:
let
  colors = {
    base = "rgba(36, 40, 59, 1.0)";
    surface0 = "rgba(41, 46, 66, 0.8)";
    text = "rgba(192, 202, 245, 0.95)";
    subtext0 = "rgba(154, 165, 206, 0.8)";
    blue = "rgba(122, 162, 247, 0.9)";
    lavender = "rgba(180, 249, 248, 0.6)";
    green = "rgba(158, 206, 106, 0.9)";
    red = "rgba(247, 118, 142, 0.9)";
  };
in
{
  home.packages = [ pkgs.hyprlock ];
  
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # Background
    background {
      monitor =
      path = /home/${username}/Pictures/wallpapers/nixos/nixos.png
      blur_passes = 2
      contrast = 0.89
      brightness = 0.82
      vibrancy = 0.17
      color = ${colors.base}
    }
    
    # General settings
    general {
      no_fade_in = false
      grace = 0
      disable_loading_bar = true
    }
    
    # Day of week
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%A")"
      color = ${colors.text}
      font_size = 42
      font_family = Hack Nerd Font
      position = 0, 300
      halign = center
      valign = center
    }
    
    # Date
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%d %B %Y")"
      color = ${colors.blue}
      font_size = 26
      font_family = Hack Nerd Font
      position = 0, 250
      halign = center
      valign = center
    }
    
    # Time
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
    
    # Avatar
    image {
      monitor =
      path = /home/${username}/Pictures/wallpapers/nixos/avatar.png
      border_size = 3
      border_color = ${colors.blue}
      size = 120
      rounding = 60
      position = 0, 50
      halign = center
      valign = center
    }
    
    # Username background
    shape {
      monitor =
      size = 250, 50
      color = ${colors.surface0}
      rounding = 10
      position = 0, -130
      halign = center
      valign = center
    }
    
    # Username
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
    
    # Password input
    input-field {
      monitor =
      size = 250, 50
      outline_thickness = 2
      dots_size = 0.2
      dots_spacing = 0.2
      dots_center = true
      outer_color = ${colors.surface0}
      inner_color = ${colors.lavender}
      font_color = ${colors.text}
      fade_on_empty = true
      font_family = Hack Nerd Font
      placeholder_text = Enter Password
      position = 0, -200
      halign = center
      valign = center
    }
    
    # System uptime
    label {
      monitor =
      text = cmd[update:60000] echo "Uptime: $(cat /proc/uptime | awk '{printf "%.0f hours", $1/3600}')"
      color = ${colors.subtext0}
      font_size = 14
      font_family = Hack Nerd Font
      position = 0, -320
      halign = center
      valign = center
    }
    
    # Music status
    label {
      monitor =
      text = cmd[update:5000] if pgrep -f spotify > /dev/null; then echo "Music: $(playerctl --player=spotify metadata title 2>/dev/null || echo 'Spotify Running')"; else echo "Music: No Player"; fi
      color = ${colors.subtext0}
      font_size = 14
      font_family = Hack Nerd Font
      position = 0, -350
      halign = center
      valign = center
    }
    
    # Bottom action icons - Power, Restart, Sleep
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
  '';
}

