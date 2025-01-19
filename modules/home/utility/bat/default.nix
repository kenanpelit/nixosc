# modules/home/bat/default.nix
# ==============================================================================
# Bat (Cat Clone) Configuration
# ==============================================================================
{ pkgs, ... }:
{
  # =============================================================================
  # Program Configuration
  # =============================================================================
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      theme = "Catppuccin-mocha";
    };

    # =============================================================================
    # Theme Configuration
    # =============================================================================
    themes = {
      Catppuccin-mocha = {
        src = ./../../../../themes/bat;  # Tema dosyasının bulunduğu dizin
        file = "Catppuccin-mocha.tmTheme";  # Tema dosyasının adı
      };
    };
  };
}
