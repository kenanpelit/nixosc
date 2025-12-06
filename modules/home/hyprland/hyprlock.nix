# modules/home/hyprland/hyprlock.nix
# ==============================================================================
# Hyprlock Screen Locker - Dynamic Catppuccin Theme Support
# ==============================================================================
# 
# FEATURES:
#   - Dynamic Catppuccin theming (auto-adapts to flavor changes)
#   - Static wallpaper background (no screenshot to avoid screencopy bugs)
#   - System information display (uptime, battery, weather, music)
#   - Secure password input with visual feedback
#   - Responsive to light/dark flavor variants
#
# USAGE:
#   - Lock manually: hyprlock
#   - Lock with no grace period: hyprlock --grace 0
#   - Config regenerates on flavor change via home-manager
#
# REQUIREMENTS:
#   - Wallpaper: /home/${username}/Pictures/wallpapers/nixos/nixos.png
#   - Avatar: /home/${username}/Pictures/wallpapers/nixos/avatar.png
#   - Font: Maple Mono NF (installed via system config)
#
# Author: Kenan Pelit
# Date:   2025-10-04
# ==============================================================================

{ config, lib, pkgs, username, ... }:

let
  # Import Catppuccin palette for dynamic theming
  inherit (config.catppuccin) sources;
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;
  
  # Helper function: Convert RGB values to RGBA string
  # Usage: mkRgba colors.base.rgb 1.0 → "rgba(30, 30, 46, 1.0)"
  mkRgba = color: alpha: 
    "rgba(${toString color.r}, ${toString color.g}, ${toString color.b}, ${toString alpha})";
  
  # Dynamic color palette - adapts to current Catppuccin flavor
  # Alpha values tuned for optimal visibility and aesthetics
  dynamicColors = {
    # Base colors - background and surfaces
    base      = mkRgba colors.base.rgb 1.0;      # Main background
    surface0  = mkRgba colors.surface0.rgb 0.8;  # Input field background
    surface1  = mkRgba colors.surface1.rgb 0.9;  # Username background
    mantle    = mkRgba colors.mantle.rgb 0.6;    # Overlay effects
    
    # Text colors - automatically inverted for light/dark flavors
    text      = mkRgba colors.text.rgb 0.95;     # Primary text
    subtext0  = mkRgba colors.subtext0.rgb 0.8;  # Secondary text
    subtext1  = mkRgba colors.subtext1.rgb 0.7;  # Tertiary text
    
    # Accent colors - flavor-specific highlights
    blue      = mkRgba colors.blue.rgb 0.9;      # Day of week
    cyan      = mkRgba colors.sky.rgb 0.8;       # Date & weather
    teal      = mkRgba colors.teal.rgb 0.7;      # Music info
    purple    = mkRgba colors.mauve.rgb 0.8;     # Hints & borders
    
    # Status colors - visual feedback
    green     = mkRgba colors.green.rgb 0.9;     # Success state
    yellow    = mkRgba colors.yellow.rgb 0.8;    # Caps Lock warning
    orange    = mkRgba colors.peach.rgb 0.8;     # Battery info
    red       = mkRgba colors.red.rgb 0.9;       # Error state
    
    # UI elements
    border    = mkRgba colors.overlay0.rgb 0.8;  # Input borders
  };

  cfg = config.my.desktop.hyprland;
in
lib.mkIf cfg.enable {
  # Generate hyprlock configuration with dynamic colors
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # ==========================================================================
    # BACKGROUND
    # ==========================================================================
    # Uses static wallpaper instead of screenshot to avoid screencopy protocol
    # issues with Hyprland. Contrast/brightness adapt to light/dark flavors.
    
    background {
      monitor =
      path = /home/${username}/Pictures/wallpapers/nixos/nixos.png
      blur_passes = 3
      contrast = ${if (config.catppuccin.flavor == "latte") then "1.1" else "0.85"}
      brightness = ${if (config.catppuccin.flavor == "latte") then "1.1" else "0.75"}
      vibrancy = ${if (config.catppuccin.flavor == "latte") then "0.2" else "0.15"}
      color = ${dynamicColors.base}
    }
    
    # ==========================================================================
    # DATE & TIME DISPLAY
    # ==========================================================================
    # Updates every second for accurate time display
    
    # Day of week - Large, prominent display
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%A")"
      color = ${dynamicColors.text}
      font_size = 42
      font_family = Maple Mono NF
      position = 0, 300
      halign = center
      valign = center
    }
    
    # Full date - Month name and year
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%d %B %Y")"
      color = ${dynamicColors.subtext0}
      font_size = 26
      font_family = Maple Mono NF
      position = 0, 250
      halign = center
      valign = center
    }
    
    # Current time - 24-hour format
    label {
      monitor =
      text = cmd[update:1000] echo "$(date +"%H:%M")"
      color = ${dynamicColors.subtext0}
      font_size = 22
      font_family = Maple Mono NF
      position = 0, 200
      halign = center
      valign = center
    }
    
    # ==========================================================================
    # USER AVATAR
    # ==========================================================================
    # Circular avatar with dynamic purple border matching flavor
    
    image {
      monitor =
      path = /home/${username}/Pictures/wallpapers/nixos/avatar.png
      border_size = 3
      border_color = ${dynamicColors.border}
      size = 120
      rounding = 60
      position = 0, 50
      halign = center
      valign = center
    }
    
    # ==========================================================================
    # USERNAME DISPLAY
    # ==========================================================================
    # Username with background shape for better visibility
    
    # Background shape behind username
    shape {
      monitor =
      size = 250, 50
      color = ${dynamicColors.surface1}
      rounding = 12
      position = 0, -130
      halign = center
      valign = center
    }
    
    # Username text - automatically shows current user
    label {
      monitor =
      text = $USER
      color = ${dynamicColors.text}
      font_size = 16
      font_family = Maple Mono NF
      position = 0, -130
      halign = center
      valign = center
    }
    
    # ==========================================================================
    # PASSWORD INPUT FIELD
    # ==========================================================================
    # Secure password entry with visual state feedback
    # Colors change based on: idle, typing, success, failure, caps lock
    
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
      font_family = Maple Mono NF
      placeholder_text = 
      hide_input = false
      check_color = ${dynamicColors.green}      # Correct password
      fail_color = ${dynamicColors.red}         # Wrong password
      capslock_color = ${dynamicColors.yellow}  # Caps Lock active
      position = 0, -200
      halign = center
      valign = center
    }
    
    # Hint text below password field
    label {
      monitor =
      text = Press Enter to unlock
      color = ${dynamicColors.subtext1}
      font_size = 12
      font_family = Maple Mono NF
      position = 0, -260
      halign = center
      valign = center
    }
    
    # ==========================================================================
    # SYSTEM INFORMATION
    # ==========================================================================
    # Dynamic system stats with varying update intervals for efficiency
    
    # System uptime - Updates every minute
    label {
      monitor =
      text = cmd[update:60000] echo "⏱ Uptime: $(cat /proc/uptime | awk '{printf "%.0f hours", $1/3600}')"
      color = ${dynamicColors.subtext1}
      font_size = 14
      font_family = Maple Mono NF
      position = 0, -320
      halign = center
      valign = center
    }
    
    # Currently playing music - Updates every 5 seconds
    # Checks for Spotify player, shows title or status
    label {
      monitor =
      text = cmd[update:5000] if pgrep -f spotify > /dev/null; then echo "🎵 $(playerctl --player=spotify metadata title 2>/dev/null || echo 'Spotify Running')"; else echo "🎵 No Player"; fi
      color = ${dynamicColors.subtext1}
      font_size = 14
      font_family = Maple Mono NF
      position = 0, -350
      halign = center
      valign = center
    }
    
    # Battery percentage - Updates every 30 seconds
    # Only shown if battery exists (laptops)
    label {
      monitor =
      text = cmd[update:30000] if [ -f /sys/class/power_supply/BAT0/capacity ]; then echo "🔋 $(cat /sys/class/power_supply/BAT0/capacity)%"; else echo ""; fi
      color = ${dynamicColors.subtext1}
      font_size = 14
      font_family = Maple Mono NF
      position = 0, -380
      halign = center
      valign = center
    }
    
    # ==========================================================================
    # FOOTER ELEMENTS
    # ==========================================================================
    
    # Action icons - Symbolic representation of lock/power/network
    label {
      monitor =
      text = 󰐥  󰜉  󰤄
      color = ${dynamicColors.text}
      font_size = 40
      font_family = Maple Mono NF
      position = 0, 100
      halign = center
      valign = bottom
    }
    
    # Current Catppuccin flavor indicator - Top left corner
    # Useful for debugging theme issues
    label {
      monitor =
      text = Catppuccin ${lib.strings.toUpper config.catppuccin.flavor}
      color = ${dynamicColors.subtext1}
      font_size = 10
      font_family = Maple Mono NF
      position = 20, 20
      halign = left
      valign = top
    }
  '';
}
