# modules/home/xdg/default.nix
# ==============================================================================
# XDG User Directories Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:

{
  xdg = {
    # XDG kullanıcı dizinlerini yapılandır
    userDirs = {
      enable = true;
      createDirectories = true;  # Olmayan dizinleri oluştur
      
      # Standart XDG dizinleri
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
      
      # Özel dizinler için extraConfig kullan
      extraConfig = {
        XDG_WORK_DIR = "$HOME/Work";
        XDG_BACKUP_DIR = "$HOME/.backup";
        XDG_PROJECTS_DIR = "$HOME/Projects";
        XDG_TMP_DIR = "$HOME/Tmp";
      };
    };
    
    # XDG temel dizinleri açıkça belirt
    configHome = "$HOME/.config";
    dataHome = "$HOME/.local/share";
    stateHome = "$HOME/.local/state";
    cacheHome = "$HOME/.cache";
    
    # Özel XDG dizini ekle (not: home-manager'ın varsayılan XDG değişkenlerinin dışında)
    backupHome = "$HOME/.backup";
  };
}

