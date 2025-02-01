# modules/home/hyprland/hyprlock.nix
# ==============================================================================
# Hyprlock Configuration with Tokyo Night Theme
# ==============================================================================
{ pkgs, ... }:
let
  colors = {
    base = "rgba(36, 40, 59, 1.0)";         # Primary background
    surface0 = "rgba(41, 46, 66, 0.7)";     # Surface for elements
    text = "rgba(192, 202, 245, 0.9)";      # Primary text
    subtext0 = "rgba(154, 165, 206, 0.8)";  # Secondary text
    blue = "rgba(122, 162, 247, 0.9)";      # Accents
    lavender = "rgba(180, 249, 248, 0.6)";  # Button hover
    white_trans = "rgba(255, 255, 255, 0.15)"; # Transparent white for inputs
  };
in
{
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = [ pkgs.hyprlock ];

  # =============================================================================
  # Lock Screen Configuration
  # =============================================================================
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # ---------------------------------------------------------------------------
    # Background Configuration
    # ---------------------------------------------------------------------------
    background {
      monitor =
      path = ${./../../../../wallpapers/nixos/nixos.png}
      blur_passes = 2
      contrast = 0.89
      brightness = 0.82
      vibrancy = 0.17
      vibrancy_darkness = 0.0
      color = ${colors.base}
    }

    # ---------------------------------------------------------------------------
    # General Settings
    # ---------------------------------------------------------------------------
    general {
      no_fade_in = false
      grace = 0
      disable_loading_bar = true
    }

    # ---------------------------------------------------------------------------
    # Time and Date Labels
    # ---------------------------------------------------------------------------
    label {
      monitor =
      text = cmd[update:1000] echo -e "$(date +"%A")"
      color = ${colors.text}
      font_size = 40
      font_family = Hack
      position = 0, 300
      halign = center
      valign = center
    }
    label {
      monitor =
      text = cmd[update:1000] echo -e "$(date +"%d %B")"
      color = ${colors.text}
      font_size = 25
      font_family = Hack
      position = 0, 250
      halign = center
      valign = center
    }
    label {
      monitor =
      text = cmd[update:1000] echo "<span>$(date +"- %R -")</span>"
      color = ${colors.text}
      font_size = 20
      font_family = Hack
      position = 0, 200
      halign = center
      valign = center
    }
    image {
      monitor =
      path = ${./../../../../wallpapers/nixos/avatar.png}
      border_size = 3
      border_color = ${colors.blue}
      size = 120
      rounding = 60
      position = 0, 50
      halign = center
      valign = center
    }
    shape {
      monitor =
      size = 250, 50
      color = ${colors.surface0}
      rounding = 10
      position = 0, -130
      halign = center
      valign = center
    }
    label {
      monitor =
      text = $USER
      color = ${colors.text}
      font_size = 16
      font_family = Hack
      position = 0, -130
      halign = center
      valign = center
    }
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
      font_family = Hack
      placeholder_text = <i><span foreground="##ffffff99">🔒 Enter Pass</span></i>
      position = 0, -200
      halign = center
      valign = center
    }
    label {
      monitor =
      text = cmd[update:1000] echo "Up $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
      color = ${colors.subtext0}
      font_size = 14
      font_family = Hack
      position = 0, -350
      halign = center
      valign = center
    }
    label {
      monitor =
      text = 󰐥  󰜉  󰤄
      color = ${colors.text}
      font_size = 40
      position = 0, 100
      halign = center
      valign = bottom
    }
  '';
}

