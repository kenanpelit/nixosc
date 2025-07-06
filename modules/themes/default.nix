# modules/themes/default.nix
# ==============================================================================
# Theme Configuration
# Author: Kenan Pelit
# ==============================================================================
#
# This module defines the theme configuration for the system, including:
# - Color schemes (based on Tokyo Night theme)
# - Visual effects settings
# - Font configurations and sizes
#
# The configuration is organized into three main sections:
# 1. Color Palette (kenp)
# 2. Visual Effects
# 3. Font Settings
# ==============================================================================

{
  # ==============================================================================
  # Color Palette Configuration
  # Based on Tokyo Night theme with custom modifications
  # ==============================================================================
  kenp = {
    # Background Colors
    # ---------------------------------------------------------------------------
    base = "#24283b";     # Primary background color
    mantle = "#1f2335";   # Secondary background, slightly darker
    crust = "#1a1b26";    # Tertiary background, darkest shade
    
    # Text Colors
    # ---------------------------------------------------------------------------
    text = "#c0caf5";     # Primary text color
    subtext0 = "#9aa5ce"; # Secondary text, slightly muted
    subtext1 = "#a9b1d6"; # Tertiary text, more muted
    
    # Surface Colors
    # ---------------------------------------------------------------------------
    surface0 = "#292e42"; # Light surface for UI elements
    surface1 = "#414868"; # Medium surface for contrasts
    surface2 = "#565f89"; # Dark surface for emphasis
    
    # Accent Colors
    # ---------------------------------------------------------------------------
    rosewater = "#f7768e"; # Soft red for highlights
    flamingo = "#ff9e64";  # Warm orange for warnings
    pink = "#ff75a0";      # Vibrant pink for emphasis
    mauve = "#bb9af7";     # Rich purple for selection
    red = "#f7768e";       # Pure red for errors
    maroon = "#e0af68";    # Warm yellow for annotations
    peach = "#ff9e64";     # Soft orange for comments
    yellow = "#e0af68";    # Bold yellow for warnings
    green = "#9ece6a";     # Fresh green for success
    teal = "#73daca";      # Calm teal for info
    sky = "#7dcfff";       # Light blue for links
    sapphire = "#2ac3de";  # Bright cyan for special elements
    blue = "#7aa2f7";      # Strong blue for keywords
    lavender = "#b4f9f8";  # Soft cyan for terminals
  };

  # ==============================================================================
  # Visual Effects Configuration
  # ==============================================================================
  effects = {
    shadow = "rgba(0, 0, 0, 0.25)"; # Window and element shadows
    opacity = "1.0";                 # Global opacity setting
    blur = "8px";                    # Blur effect for transparency
    radius = "8px";                  # Border radius
  };

  # ==============================================================================
  # Font Configuration
  # Defines font sizes and families for different UI elements
  # ==============================================================================
  fonts = let
    # Font Sizes (numeric values)
    # ---------------------------------------------------------------------------
    sizes = {
      xs = 11;      # Extra small text
      sm = 12;      # Small text
      md = 13;      # Medium text
      base = 13.3;  # Base text size
      lg = 14;      # Large text
      xl = 15;      # Extra large text
      "2xl" = 16;   # Double extra large text
      "3xl" = 18;   # Triple extra large text
      "4xl" = 20;   # Quadruple extra large text
    };

    # Font Sizes (string values for specific use cases)
    # ---------------------------------------------------------------------------
    sizesStr = {
      xs = "11";
      sm = "12";
      md = "13";
      base = "13.3";
      lg = "14";
      xl = "15";
      "2xl" = "16";
      "3xl" = "18";
      "4xl" = "20";
    };
  in {
    # Size Configurations
    sizes = sizes;
    sizesStr = sizesStr;

    # Font Family and Size Configurations
    # ---------------------------------------------------------------------------
    main = {
      family = "Maple Mono";        # Primary font for UI
      size = sizes."2xl";
      weight = "bold";
    };
    
    editor = {
      family = "Maple Mono";        # Code editor font
      size = sizes.xl;
      weight = "normal";
    };
    
    terminal = {
      family = "Hack Nerd Font";    # Terminal font with icons
      size = sizes.base;
      weight = "normal";
    };
    
    mono = {
      family = "Hack Nerd Font";    # Monospace font for code
      size = sizes.sm;
      weight = "normal";
    };
    
    notifications = {
      family = "Hack Nerd Font";    # Notification font
      size = sizes.md;
      weight = "500";
    };
    
    # UI elements
    ui = {
      family = "Inter";             # UI font
      size = sizes.sm;
      weight = "400";
    };
    
    # Headings
    headings = {
      family = "Inter";
      sizes = {
        h1 = sizes."4xl";
        h2 = sizes."3xl";
        h3 = sizes."2xl";
        h4 = sizes.xl;
        h5 = sizes.lg;
        h6 = sizes.base;
      };
      weight = "600";
    };
  };
  
  # ==============================================================================
  # Spacing Configuration
  # ==============================================================================
  spacing = {
    xs = "4px";
    sm = "8px";
    md = "12px";
    lg = "16px";
    xl = "24px";
    "2xl" = "32px";
    "3xl" = "48px";
    "4xl" = "64px";
  };
}
# ==============================================================================

