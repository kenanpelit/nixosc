# ==============================================================================
# Bat (Cat Clone) Configuration - ÇAKIŞMA DÜZELTMESİ
# ==============================================================================
{ pkgs, lib, ... }:
{
  # =============================================================================
  # Program Configuration
  # =============================================================================
  programs.bat = {
    enable = true;
    config = {
      pager = "less -FR";
      theme = "Catppuccin Mocha";
    };
    
    # =============================================================================
    # Theme Configuration - Çakışmayı önlemek için lib.mkForce kullanıyoruz
    # =============================================================================
    themes = {
      "Catppuccin Mocha" = lib.mkForce {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "d3feec47b16a8e99eabb34cdfbaa115541d374fc";
          sha256 = "sha256-s1Ay5n8/H5hy2Vgp6jM8Y9M0CpIXi9LAj1h2TcoBZW0=";
        };
        file = "themes/Catppuccin Mocha.tmTheme";
      };
    };
  };
}

