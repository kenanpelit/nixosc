# modules/home/hyprland/hyprlock.nix
# ==============================================================================
# Hyprlock Configuration with Nord Theme
# ==============================================================================
{ pkgs, ... }:
let
  colors = {
    text = "rgba(216, 222, 233, 0.80)";
    text_bright = "rgba(216, 222, 233, 0.90)";
    white_trans = "rgba(255, 255, 255, 0.15)";
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
      border_color = rgba(255, 255, 255, .75)
      size = 120
      rounding = 60
      position = 0, 50
      halign = center
      valign = center
    }
    shape {
      monitor =
      size = 250, 50
      color = ${colors.white_trans}
      rounding = 10
      position = 0, -130
      halign = center
      valign = center
    }
    label {
      monitor =
      text = $USER
      color = ${colors.text_bright}
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
      outer_color = rgba(255, 255, 255, 0.1)
      inner_color = ${colors.white_trans}
      font_color = rgb(230, 230, 230)
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
      color = rgba(216, 222, 233, 0.70)
      font_size = 14
      font_family = Hack
      position = 0, -350
      halign = center
      valign = center
    }
    label {
      monitor =
      text = 󰐥  󰜉  󰤄
      color = rgba(255, 255, 255, 0.75)
      font_size = 40
      position = 0, 100
      halign = center
      valign = bottom
    }
  '';
}

