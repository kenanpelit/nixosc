# modules/home/xdg-dirs/default.nix
# ==============================================================================
# XDG User Directories Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # XDG Base Directory kullanımını etkinleştir
  xdg.enable = true;

  # XDG kullanıcı dizinlerini yapılandır
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    
    # Temel dizinler
    desktop = "$HOME/desktop";
    documents = "$HOME/documents";
    download = "$HOME/downloads";
    music = "$HOME/music";
    pictures = "$HOME/pictures";
    videos = "$HOME/videos";
    templates = "$HOME/templates";
    publicShare = "$HOME/public";
    
    # Özel dizinler
    extraConfig = {
      XDG_BACKUP_DIR = "$HOME/.backup";
      XDG_PROJECTS_DIR = "$HOME/.projects";
      XDG_TMP_DIR = "$HOME/tmp";
      XDG_CONFIG_DIR = "$HOME/.config";
      XDG_CACHE_DIR = "$HOME/.cache";
      XDG_DATA_DIR = "$HOME/.local/share";
      XDG_STATE_DIR = "$HOME/.local/state";
    };
  };

  # XDG_CONFIG_HOME ortam değişkenini ayarla
  home.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };
}
