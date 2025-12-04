# modules/home/xdg-dirs/default.nix
# ==============================================================================
# XDG User Directories Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.xdg-dirs;
in
{
  options.my.user.xdg-dirs = {
    enable = lib.mkEnableOption "XDG user directories";
  };

  config = lib.mkIf cfg.enable {
    # XDG kullanıcı dizinlerini yapılandır
    xdg.userDirs = {
      enable = true;
      createDirectories = true;  # Sadece istenen dizinleri oluştur
      
      # Ana dizinler - sadece gerçekten kullanılanlar
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
      
      # İstenmeyen dizinler - null yaparak devre dışı bırak
      desktop = null;           # Desktop klasörü oluşturma
      publicShare = null;       # Public klasörü oluşturma  
      templates = null;         # Templates klasörü oluşturma
      
      # Özel dizinler
      extraConfig = {
        # XDG_BACKUP_DIR = "$HOME/.backup";
        XDG_PROJECTS_DIR = "$HOME/.projects";
        XDG_TMP_DIR = "$HOME/.tmp";
        XDG_CONFIG_DIR = "$HOME/.config";
        XDG_DATA_DIR = "$HOME/.local/share";
        XDG_STATE_DIR = "$HOME/.local/state";
        XDG_WORK_DIR = "$HOME/Work";        # Work dizinini XDG olarak tanımla
      };
    };
    
    # Mevcut istenmeyen klasörleri temizle (isteğe bağlı)
    home.activation.cleanUnwantedDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Boş Desktop, Public, Templates klasörlerini sil
      [ -d "$HOME/Desktop" ] && [ -z "$(ls -A "$HOME/Desktop" 2>/dev/null)" ] && rmdir "$HOME/Desktop" 2>/dev/null || true
      [ -d "$HOME/Public" ] && [ -z "$(ls -A "$HOME/Public" 2>/dev/null)" ] && rmdir "$HOME/Public" 2>/dev/null || true
      [ -d "$HOME/Templates" ] && [ -z "$(ls -A "$HOME/Templates" 2>/dev/null)" ] && rmdir "$HOME/Templates" 2>/dev/null || true
    '';
  };
}

