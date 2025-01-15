{ pkgs, ... }:
{
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      theme = "Catppuccin-mocha";
    };
    themes = {
      Catppuccin-mocha = {
        src = ./../../../themes/bat;  # Tema dosyasının bulunduğu dizin
        file = "Catppuccin-mocha.tmTheme";  # Tema dosyasının adı
      };
    };
  };
}
