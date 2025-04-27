# modules/home/xdg-dirs/default.nix
# ==============================================================================
# XDG User Directories Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # XDG kullanıcı dizinlerini yapılandır
  xdg.userDirs = {
    enable = true;
    createDirectories = true;  # Olmayan dizinleri oluştur
    
    # Temel dizinler
    desktop = "$HOME/Desktop";
    documents = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
    
    # Özel dizinler
    extraConfig = {
     # XDG_BACKUP_DIR = "$HOME/.backup";
      XDG_PROJECTS_DIR = "$HOME/.projects";
      XDG_TMP_DIR = "$HOME/.tmp";
      XDG_CONFIG_DIR = "$HOME/.config";
      XDG_DATA_DIR = "$HOME/.local/share";
      XDG_STATE_DIR = "$HOME/.local/state";
    };
  };
}
