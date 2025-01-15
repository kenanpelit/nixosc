# modules/home/fzf/default.nix
# ==============================================================================
# FZF Configuration
# ==============================================================================
{ pkgs, ... }:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    
    # Temel arama komutları
    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
    
    # Dosya önizleme ayarları
    fileWidgetOptions = [
      "--preview 'if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi'"
    ];
    
    # Dizin değiştirme ayarları
    changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'eza --tree --color=always {} | head -200'"
    ];

    # Tokyo Night tema renkleri
    defaultOptions = [
      # Ana renkler
      "--color=fg:#a9b1d6,fg+:#c0caf5,bg:#1a1b26,bg+:#292e42"
      # Vurgular ve bilgi
      "--color=hl:#7aa2f7,hl+:#7dcfff,info:#7aa2f7,marker:#9ece6a"
      # UI elementleri
      "--color=prompt:#f7768e,spinner:#9ece6a,pointer:#9ece6a,header:#7aa2f7"
      # Sınırlar ve etiketler
      "--color=border:#565f89,label:#c0caf5,query:#c0caf5"
      # UI stili
      "--border='sharp' --border-label='' --preview-window='border-sharp' --prompt='❯ '"
      # İşaretçiler ve ayırıcılar
      "--marker='❯' --pointer='❯' --separator='─' --scrollbar='│'"
      # Bilgi konumu
      "--info='right'"
    ];

  };
}
