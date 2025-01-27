# modules/themes/default.nix
{
  kenp = {
    # Base Tokyo Night colors
    base = "#24283b";     # Background
    mantle = "#1f2335";   # Darker background
    crust = "#1a1b26";    # Darkest background
    
    # Text colors
    text = "#c0caf5";     # Primary text
    subtext0 = "#9aa5ce"; # Secondary text
    subtext1 = "#a9b1d6"; # Tertiary text
    
    # Surface colors
    surface0 = "#292e42"; # Light surface
    surface1 = "#414868"; # Medium surface
    surface2 = "#565f89"; # Dark surface
    
    # Accent colors
    rosewater = "#f7768e"; # Light Red
    flamingo = "#ff9e64";  # Orange
    pink = "#ff75a0";      # Pink
    mauve = "#bb9af7";     # Purple
    red = "#f7768e";       # Red
    maroon = "#e0af68";    # Yellow
    peach = "#ff9e64";     # Light Orange
    yellow = "#e0af68";    # Yellow
    green = "#9ece6a";     # Green
    teal = "#73daca";      # Teal
    sky = "#7dcfff";       # Light Blue
    sapphire = "#2ac3de";  # Cyan
    blue = "#7aa2f7";      # Blue
    lavender = "#b4f9f8";  # Terminal Cyan
  };

  effects = {
    shadow = "rgba(0, 0, 0, 0.25)";
    opacity = "1.0";
  };

  fonts = let
    sizes = {
      xs = 11;
      sm = 12;
      md = 13;
      base = 13.3;
      lg = 14;
      xl = 15;
      "2xl" = 16;
    };
    sizesStr = {
      xs = "11";
      sm = "12";
      md = "13";
      base = "13.3";
      lg = "14";
      xl = "15";
      "2xl" = "16";
    };
  in {
    sizes = sizes;
    sizesStr = sizesStr;
    main = {
      family = "Maple Mono";
      size = sizes."2xl";
      weight = "bold";
    };
    editor = {
      family = "Maple Mono";
      size = sizes.xl;
    };
    terminal = {
      family = "Hack Nerd Font";
      size = sizes.base;
    };
    mono = {
      family = "Hack Nerd Font";
      size = sizes.sm;
    };
    notifications = {
      family = "Hack Nerd Font";
      size = sizes.md;
    };
  };
}
