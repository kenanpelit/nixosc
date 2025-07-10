# modules/home/rofi/default.nix
# ==============================================================================
# Rofi Root Configuration - Catppuccin Mauve Theme
# ==============================================================================
{ pkgs, ... }:
let
  # Catppuccin Mocha tema renkleri (mor/eflatun vurgusu) - Açık ton
  colors = {
    crust = "#1e1e2e";      # Daha açık ana arka plan
    base = "#313244";       # Daha açık ikincil arka plan
    mantle = "#181825";
    surface0 = "#45475a";   # Daha açık seçili alan
    surface1 = "#585b70";   # Daha açık kenarlık
    surface2 = "#6c7086";
    text = "#cdd6f4";
    subtext1 = "#bac2de";
    subtext0 = "#a6adc8";
    overlay2 = "#9399b2";
    overlay1 = "#7f849c";
    overlay0 = "#6c7086";
    mauve = "#cba6f7";      # Ana mor renk
    lavender = "#b4befe";   # Açık mor
    sapphire = "#74c7ec";   # Mavi vurgu
    sky = "#89dceb";        # Açık mavi
    teal = "#94e2d5";       # Yeşil-mavi
    green = "#a6e3a1";      # Yeşil
    yellow = "#f9e2af";     # Sarı
    peach = "#fab387";      # Turuncu
    maroon = "#eba0ac";     # Kırmızı-pembe
    red = "#f38ba8";        # Kırmızı
    pink = "#f5c2e7";       # Pembe
    flamingo = "#f2cdcd";   # Açık pembe
    rosewater = "#f5e0dc";  # Çok açık pembe
  };
  
  # Rofi tema CSS'i
  rofiTheme = {
    theme = ''
      * {
        bg-col: ${colors.crust};
        bg-col-light: ${colors.base};
        border-col: ${colors.surface1};
        selected-col: ${colors.surface0};
        green: ${colors.mauve};           // Ana vurgu rengi artık mor
        fg-col: ${colors.text};
        fg-col2: ${colors.subtext1};
        grey: ${colors.surface2};
        highlight: ${colors.lavender};    // Highlight için açık mor
        
        /* Ekstra Catppuccin renkleri */
        mauve: ${colors.mauve};
        lavender: ${colors.lavender};
        sapphire: ${colors.sapphire};
        accent: ${colors.mauve};
        accent-light: ${colors.lavender};
        accent-dark: ${colors.mauve};
      }
    '';
  };
in
{
  # =============================================================================
  # Module Imports
  # =============================================================================
  imports = [
    ./config.nix   # Main configuration
  ];
  
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = (with pkgs; [ rofi-wayland ]);
  
  # =============================================================================
  # Theme Configuration
  # =============================================================================
  xdg.configFile."rofi/theme.rasi".text = rofiTheme.theme;
}

