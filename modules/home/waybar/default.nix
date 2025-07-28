# modules/home/waybar/default.nix
{ pkgs, config, lib, ... }:
let
  # Catppuccin Mocha - Premium dark theme with extended color palette
  catppuccin_mocha = {
    # Background layers (darkest to lightest)
    bg = "#1e1e2e";         # Base - Primary background
    bg_dark = "#181825";    # Mantle - Darker background
    bg_float = "#11111b";   # Crust - Deepest background
    bg_highlight = "#313244"; # Surface0 - Highlighted elements
    bg_popup = "#181825";   # Mantle - Popup backgrounds
    bg_statusline = "#181825"; # Mantle - Status line
    bg_visual = "#313244";  # Surface0 - Visual selections
    border = "#45475a";     # Surface1 - Default borders
    border_highlight = "#89b4fa"; # Blue - Active borders
    
    # Text colors with better hierarchy
    fg = "#cdd6f4";         # Text - Primary text
    fg_dark = "#bac2de";    # Subtext1 - Secondary text
    fg_gutter = "#6c7086";  # Overlay0 - Gutter text
    comment = "#6c7086";    # Overlay0 - Comments
    dark3 = "#585b70";      # Surface2 - Dark elements
    dark5 = "#7f849c";      # Overlay1 - Darker elements
    
    # Semantic colors - carefully chosen for accessibility
    blue = "#89b4fa";       # Blue - Primary actions, links
    cyan = "#89dceb";       # Sky - Info, highlights
    green = "#a6e3a1";      # Green - Success, positive states
    magenta = "#cba6f7";    # Mauve - Special, focus states
    purple = "#cba6f7";     # Mauve - Secondary accent
    red = "#f38ba8";        # Pink - Errors, warnings
    orange = "#fab387";     # Peach - Alerts, notifications
    yellow = "#f9e2af";     # Yellow - Cautions, pending states
    teal = "#94e2d5";       # Teal - Network, connectivity
    
    # Extended semantic colors for better UX
    pink = "#f5c2e7";       # Pink - Alternative accent
    peach = "#fab387";      # Peach - Warm accent
    lavender = "#b4befe";   # Lavender - Soft accent
    sky = "#89dceb";        # Sky - Light accent
    
    # Surface layers for depth
    surface0 = "#313244";   # Surface0 - Base surface
    surface1 = "#45475a";   # Surface1 - Elevated surface
    surface2 = "#585b70";   # Surface2 - Highest surface
    
    # Compatibility aliases
    crust = "#11111b";      # Crust - Deepest layer
    base = "#1e1e2e";       # Base - Primary background
    mantle = "#181825";     # Mantle - Secondary background
    text = "#cdd6f4";       # Text - Primary text
    subtext1 = "#bac2de";   # Subtext1 - Secondary text
    subtext0 = "#a6adc8";   # Subtext0 - Tertiary text
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
    text_color = catppuccin_mocha.fg;
    text_secondary = catppuccin_mocha.fg_dark;
    text_muted = catppuccin_mocha.comment;
    text_disabled = catppuccin_mocha.dark3;
    
    # Backward compatibility aliases
    subtext_color = catppuccin_mocha.fg_dark;  # Legacy alias for text_secondary
    
    # Background system with proper layering
    background_0 = catppuccin_mocha.crust;      # Deepest layer
    background_1 = catppuccin_mocha.base;       # Primary background
    background_2 = catppuccin_mocha.mantle;     # Secondary background
    background_3 = catppuccin_mocha.bg_dark;    # Elevated background
    
    # Surface system for interactive elements
    surface_0 = catppuccin_mocha.surface0;      # Base surface
    surface_1 = catppuccin_mocha.surface1;      # Elevated surface
    surface_2 = catppuccin_mocha.surface2;      # Highest surface
    
    # Border and spacing system
    border_color = "rgba(69, 71, 90, 0.8)";     # Surface1 with transparency
    border_color_active = "rgba(137, 180, 250, 0.6)";  # Blue with transparency
    border_color_hover = "rgba(137, 220, 235, 0.4)";   # Sky with transparency
    
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
    red = catppuccin_mocha.red;
    green = catppuccin_mocha.green;
    yellow = catppuccin_mocha.yellow;
    blue = catppuccin_mocha.blue;
    magenta = catppuccin_mocha.magenta;
    cyan = catppuccin_mocha.cyan;
    orange = catppuccin_mocha.orange;
    purple = catppuccin_mocha.purple;
    teal = catppuccin_mocha.teal;
    pink = catppuccin_mocha.pink;
    
    # State-based color system
    accent_primary = catppuccin_mocha.blue;
    accent_secondary = catppuccin_mocha.magenta;
    accent_tertiary = catppuccin_mocha.cyan;
    
    # Status colors
    status_success = catppuccin_mocha.green;
    status_warning = catppuccin_mocha.yellow;
    status_error = catppuccin_mocha.red;
    status_info = catppuccin_mocha.cyan;
    status_neutral = catppuccin_mocha.fg_dark;
    
    # Interactive states
    hover_overlay = "rgba(137, 180, 250, 0.1)";      # Blue hover
    active_overlay = "rgba(203, 166, 247, 0.15)";    # Mauve active
    focus_overlay = "rgba(137, 220, 235, 0.2)";      # Sky focus
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

