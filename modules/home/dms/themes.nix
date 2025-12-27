{ config, lib, ... }:

let
  # Catppuccin Mocha Palette
  mocha = {
    rosewater = "#f5e0dc";
    flamingo  = "#f2cdcd";
    pink      = "#f5c2e7";
    mauve     = "#cba6f7";
    red       = "#f38ba8";
    maroon    = "#eba0ac";
    peach     = "#fab387";
    yellow    = "#f9e2af";
    green     = "#a6e3a1";
    teal      = "#94e2d5";
    sky       = "#89dceb";
    sapphire  = "#74c7ec";
    blue      = "#89b4fa";
    lavender  = "#b4befe";
    text      = "#cdd6f4";
    subtext1  = "#bac2de";
    subtext0  = "#a6adc8";
    overlay2  = "#9399b2";
    overlay1  = "#7f849c";
    overlay0  = "#6c7086";
    surface2  = "#585b70";
    surface1  = "#45475a";
    surface0  = "#313244";
    base      = "#1e1e2e";
    mantle    = "#181825";
    crust     = "#11111b";
  };

  # Theme Template Generator
  mkTheme = { id, name, accent, accentText, desc }: {
    inherit id name;
    version = "1.0.0";
    author = "Kenan";
    description = desc;
    # Kaynak dizin ismi ile ID aynı olmalı DMS mantığında
    sourceDir = id; 
    
    dark = {
      primary = accent;
      primaryText = accentText;       # Accent üzerindeki yazı (genelde base veya crust)
      primaryContainer = "${accent}33"; # %20 opacity
      
      secondary = mocha.lavender;
      
      surface = mocha.base;           # Ana zemin
      surfaceText = mocha.text;       # Ana yazı
      
      surfaceVariant = mocha.surface0; 
      surfaceVariantText = mocha.subtext0;
      
      surfaceTint = accent;
      
      background = mocha.base;
      backgroundText = mocha.text;
      
      outline = mocha.overlay0;
      
      surfaceContainer = mocha.mantle;
      surfaceContainerHigh = mocha.surface0;
      
      error = mocha.red;
      warning = mocha.peach;
      info = mocha.sky;
    };
    
    # Light theme is fallback (using same mocha but maybe inverted? 
    # For now keeping it dark-ish or Latte could be better but let's stick to Mocha consistency)
    light = {
      primary = accent;
      primaryText = mocha.base;
      primaryContainer = "${accent}40";
      secondary = mocha.lavender;
      surface = "#eff1f5"; # Latte Base
      surfaceText = "#4c4f69"; # Latte Text
      surfaceVariant = "#e6e9ef";
      surfaceVariantText = "#5c5f77";
      surfaceTint = accent;
      background = "#eff1f5";
      backgroundText = "#4c4f69";
      outline = "#bcc0cc";
      surfaceContainer = "#e6e9ef";
      surfaceContainerHigh = "#bcc0cc";
      error = "#d20f39";
      warning = "#fe640b";
      info = "#04a5e5";
    };
  };

  themeMauve = mkTheme {
    id = "catppuccinMochaMauve";
    name = "Catppuccin Mocha Mauve";
    desc = "Soothing pastel theme with Mauve accents";
    accent = mocha.mauve;
    accentText = mocha.base;
  };

  themeCyan = mkTheme {
    id = "catppuccinMochaCyan";
    name = "Catppuccin Mocha Cyan";
    desc = "Soothing pastel theme with Sky/Cyan accents";
    accent = "#00b4d8";
    accentText = mocha.base;
  };

in
{
  # Write the theme JSON files to XDG Config
  xdg.configFile."DankMaterialShell/themes/catppuccinMochaMauve/theme.json".text = builtins.toJSON themeMauve;
  xdg.configFile."DankMaterialShell/themes/catppuccinMochaCyan/theme.json".text = builtins.toJSON themeCyan;
}
