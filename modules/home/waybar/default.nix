# modules/home/waybar/default.nix
{ config, pkgs, lib, ... }:
let
  # Catppuccin modülünden otomatik renk alımı
  inherit (config.catppuccin) sources;
  
  # Utility function for hex to RGBA conversion - SIMPLIFIED
  mkRgba = color: alpha: 
    let
      # Remove # prefix 
      hex = lib.removePrefix "#" color;
      # Use fromTOML to parse hex values (more reliable than toInt)
      r = lib.toInt (builtins.fromTOML "value = 0x${builtins.substring 0 2 hex}").value;
      g = lib.toInt (builtins.fromTOML "value = 0x${builtins.substring 2 2 hex}").value;
      b = lib.toInt (builtins.fromTOML "value = 0x${builtins.substring 4 2 hex}").value;
    in "rgba(${toString r}, ${toString g}, ${toString b}, ${toString alpha})";

  # Palette JSON'dan renkler - dinamik flavor desteği
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;
  
  # Enhanced configuration with dynamic Catppuccin colors
  custom = {
    # Typography with fallbacks
    font = "JetBrainsMono Nerd Font";
    font_fallback = "Fira Code Nerd Font, Hack Nerd Font, monospace";
    font_size = "15px";
    font_size_small = "13px";
    font_size_large = "17px";
    font_weight = "600";
    font_weight_light = "400";
    font_weight_bold = "700";
    
    # Dynamic text colors - flavor'a göre değişir
    text_color = colors.text.hex;
    text_secondary = colors.subtext1.hex;
    text_muted = colors.overlay0.hex;
    text_disabled = colors.surface2.hex;
    
    # Backward compatibility aliases
    subtext_color = colors.subtext1.hex;  # Legacy alias for text_secondary
    
    # Dynamic background system - flavor'a göre değişir
    background_0 = colors.crust.hex;      # Deepest layer
    background_1 = colors.base.hex;       # Primary background
    background_2 = colors.mantle.hex;     # Secondary background
    background_3 = colors.mantle.hex;     # Elevated background
    
    # Dynamic surface system
    surface_0 = colors.surface0.hex;      # Base surface
    surface_1 = colors.surface1.hex;      # Elevated surface
    surface_2 = colors.surface2.hex;      # Highest surface
    
    # Dynamic border colors - Simplified (no RGBA)
    border_color = colors.surface1.hex;
    border_color_active = colors.blue.hex;
    border_color_hover = colors.sky.hex;
    
    # Responsive design values
    opacity = "0.95";
    opacity_hover = "1.0";
    opacity_disabled = "0.6";
    
    # Border radius system
    border_radius = "8px";
    border_radius_small = "4px";
    border_radius_large = "12px";
    inner_radius = "6px";
    
    # Spacing system
    padding_xs = "2px 4px";
    padding_sm = "2px 6px";
    padding_md = "4px 8px";
    padding_lg = "6px 12px";
    
    margin_xs = "1px";
    margin_sm = "2px";
    margin_md = "4px";
    
    # Dynamic semantic colors - flavor'a göre değişir
    red = colors.red.hex;
    green = colors.green.hex;
    yellow = colors.yellow.hex;
    blue = colors.blue.hex;
    magenta = colors.mauve.hex;
    cyan = colors.sky.hex;
    orange = colors.peach.hex;
    purple = colors.mauve.hex;
    teal = colors.teal.hex;
    pink = colors.pink.hex;
    
    # Dynamic state-based color system
    accent_primary = colors.blue.hex;
    accent_secondary = colors.mauve.hex;
    accent_tertiary = colors.sky.hex;
    
    # Dynamic status colors
    status_success = colors.green.hex;
    status_warning = colors.yellow.hex;
    status_error = colors.red.hex;
    status_info = colors.sky.hex;
    status_neutral = colors.subtext1.hex;
    
    # Dynamic interactive states - Simplified (no RGBA)  
    hover_overlay = colors.blue.hex;
    active_overlay = colors.mauve.hex;
    focus_overlay = colors.sky.hex;
    
    # Compatibility aliases for existing settings/style files
    bg = colors.base.hex;
    bg_dark = colors.mantle.hex;
    bg_float = colors.crust.hex;
    bg_highlight = colors.surface0.hex;
    fg = colors.text.hex;
    fg_dark = colors.subtext1.hex;
    comment = colors.overlay0.hex;
    border = colors.surface1.hex;
    border_highlight = colors.blue.hex;
  };

in
{
  # Enhanced Waybar program configuration
  programs.waybar = {
    enable = true;
    
    # Extended package with additional features
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or [ ]) ++ [ 
        "-Dexperimental=true"     # Enable experimental features
        "-Dcava=enabled"          # Audio visualizer support
        "-Dmpris=enabled"         # Media player integration
        "-Dpulseaudio=enabled"    # PulseAudio support
        "-Drfkill=enabled"        # RF kill switch support
        "-Dsndio=disabled"        # Disable sndio (not needed)
      ];
      
      # Add additional build inputs for enhanced functionality
      buildInputs = (oa.buildInputs or []) ++ (with pkgs; [
        playerctl    # For better MPRIS control
        libpulseaudio # Enhanced audio support
      ]);
    });
    
    # Configuration files with enhanced structure
    settings = import ./settings.nix { 
      inherit custom;
    };
    
    # Enhanced styling with dynamic design system
    style = import ./style.nix { 
      inherit custom;
    };
  };

  # Systemd servis
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar - Modern Wayland bar with Dynamic Catppuccin Theme (${config.catppuccin.flavor})";
      Documentation = "https://github.com/Alexays/Waybar/wiki";
      After = ["hyprland-session.target" "graphical-session.target"];
      PartOf = ["hyprland-session.target"];
      Wants = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.waybar}/bin/waybar --log-level error";
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = "2s";
      KillMode = "mixed";
      Environment = [
        "XDG_CURRENT_DESKTOP=Hyprland"
        "XDG_SESSION_TYPE=wayland"
        "CATPPUCCIN_FLAVOR=${config.catppuccin.flavor}"  # Debug için
      ];
    };
    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
}

