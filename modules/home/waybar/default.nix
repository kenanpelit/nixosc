# modules/home/waybar/default.nix
{ pkgs, config, lib, ... }:
let
  # Tokyo Night Storm - Premium dark theme with extended color palette
  tokyo_night_storm = {
    # Background layers (darkest to lightest)
    bg = "#24283b";
    bg_dark = "#1f2335";
    bg_float = "#1d202f";
    bg_highlight = "#292e42";
    bg_popup = "#1d202f";
    bg_statusline = "#1d202f";
    bg_visual = "#283457";
    border = "#1d202f";
    border_highlight = "#27a1b9";
    
    # Text colors with better hierarchy
    fg = "#c0caf5";
    fg_dark = "#a9b1d6";
    fg_gutter = "#3b4261";
    comment = "#565f89";
    dark3 = "#545c7e";
    dark5 = "#737aa2";
    
    # Semantic colors - carefully chosen for accessibility
    blue = "#7aa2f7";      # Primary actions, links
    cyan = "#7dcfff";      # Info, highlights
    green = "#9ece6a";     # Success, positive states
    magenta = "#bb9af7";   # Special, focus states
    purple = "#9d7cd8";    # Secondary accent
    red = "#f7768e";       # Errors, warnings
    orange = "#ff9e64";    # Alerts, notifications
    yellow = "#e0af68";    # Cautions, pending states
    teal = "#1abc9c";      # Network, connectivity
    
    # Extended semantic colors for better UX
    pink = "#f7768e";      # Alternative accent
    peach = "#ff9e64";     # Warm accent
    lavender = "#bb9af7";  # Soft accent
    sky = "#7dcfff";       # Light accent
    
    # Surface layers for depth
    surface0 = "#363a4f";
    surface1 = "#414868";
    surface2 = "#565f89";
    
    # Compatibility aliases
    crust = "#1a1b26";
    base = "#24283b";
    mantle = "#16161e";
    text = "#c0caf5";
    subtext1 = "#a9b1d6";
    subtext0 = "#9aa5ce";
  };
  
  # Enhanced configuration with responsive design
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
    
    # Text colors with semantic meaning
    text_color = tokyo_night_storm.fg;
    text_secondary = tokyo_night_storm.fg_dark;
    text_muted = tokyo_night_storm.comment;
    text_disabled = tokyo_night_storm.dark3;
    
    # Backward compatibility aliases
    subtext_color = tokyo_night_storm.fg_dark;  # Legacy alias for text_secondary
    
    # Background system with proper layering
    background_0 = tokyo_night_storm.crust;      # Deepest layer
    background_1 = tokyo_night_storm.base;       # Primary background
    background_2 = tokyo_night_storm.mantle;     # Secondary background
    background_3 = tokyo_night_storm.bg_dark;    # Elevated background
    
    # Surface system for interactive elements
    surface_0 = tokyo_night_storm.surface0;      # Base surface
    surface_1 = tokyo_night_storm.surface1;      # Elevated surface
    surface_2 = tokyo_night_storm.surface2;      # Highest surface
    
    # Border and spacing system
    border_color = "rgba(69, 71, 90, 0.8)";
    border_color_active = "rgba(122, 162, 247, 0.6)";
    border_color_hover = "rgba(125, 207, 255, 0.4)";
    
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
    
    # Semantic colors with consistent naming
    red = tokyo_night_storm.red;
    green = tokyo_night_storm.green;
    yellow = tokyo_night_storm.yellow;
    blue = tokyo_night_storm.blue;
    magenta = tokyo_night_storm.magenta;
    cyan = tokyo_night_storm.cyan;
    orange = tokyo_night_storm.orange;
    purple = tokyo_night_storm.purple;
    teal = tokyo_night_storm.teal;
    pink = tokyo_night_storm.pink;
    
    # State-based color system
    accent_primary = tokyo_night_storm.blue;
    accent_secondary = tokyo_night_storm.magenta;
    accent_tertiary = tokyo_night_storm.cyan;
    
    # Status colors
    status_success = tokyo_night_storm.green;
    status_warning = tokyo_night_storm.yellow;
    status_error = tokyo_night_storm.red;
    status_info = tokyo_night_storm.cyan;
    status_neutral = tokyo_night_storm.fg_dark;
    
    # Interactive states
    hover_overlay = "rgba(122, 162, 247, 0.1)";
    active_overlay = "rgba(187, 154, 247, 0.15)";
    focus_overlay = "rgba(125, 207, 255, 0.2)";
  };
  
  # Utility function for consistent RGBA color generation
  mkRgba = color: alpha: 
    let
      # Extract RGB values from hex color
      r = lib.toInt "0x${builtins.substring 1 2 color}";
      g = lib.toInt "0x${builtins.substring 3 2 color}";
      b = lib.toInt "0x${builtins.substring 5 2 color}";
    in "rgba(${toString r}, ${toString g}, ${toString b}, ${toString alpha})";

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
    
    # Enhanced styling with design system
    style = import ./style.nix { 
      inherit custom;
    };
  };

  # Systemd servis
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar - Modern Wayland bar";
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
      ];
    };
    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
}

