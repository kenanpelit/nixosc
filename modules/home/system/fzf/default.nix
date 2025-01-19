# modules/home/fzf/default.nix
# ==============================================================================
# FZF Configuration
# ==============================================================================
# modules/home/fzf/default.nix
{ pkgs, inputs, lib, ... }:

let
  previewDeps = with pkgs; [
    # Temel araçlar
    file
    jq
    bat
    glow
    w3m
    eza
    openssl
    
    # Arşiv araçları
    atool
    p7zip
    libcdio
    
    # Doküman araçları
    odt2txt
    catdoc
    gnumeric
    
    # Medya araçları
    exiftool
    chafa
    mediainfo
    ffmpegthumbnailer
    poppler_utils
  ];
in
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Temel arama komutları
    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";

    # Gelişmiş önizleme ayarları
    fileWidgetOptions = [
      "--preview '
        FILE=\"{}\"; 
        if [ -L \"$FILE\" ]; then 
          FILE=$(readlink -f \"$FILE\"); 
        fi;
        if [ -d \"$FILE\" ]; then 
          eza --tree --color=always \"$FILE\" | head -200;
        elif [[ \"$FILE\" =~ \\.(jpg|jpeg|png|gif|bmp)$ ]]; then
          chafa --format symbols \"$FILE\";
        elif [[ \"$FILE\" =~ \\.(pdf)$ ]]; then
          pdftoppm -png -f 1 -l 1 \"$FILE\" - | chafa -;
        elif [[ \"$FILE\" =~ \\.(mp4|webm|mkv)$ ]]; then
          ffmpegthumbnailer -i \"$FILE\" -o - -s 0 | chafa -;
        elif [[ \"$FILE\" =~ \\.(zip|tar|gz|bz2|rar|7z)$ ]]; then
          atool --list \"$FILE\";
        elif [[ \"$FILE\" =~ \\.(docx?|odt|xlsx?|ods)$ ]]; then
          odt2txt \"$FILE\";
        elif [[ \"$FILE\" =~ \\.(md|markdown)$ ]]; then
          glow -s dark \"$FILE\";
        else 
          bat -n --color=always --line-range :500 \"$FILE\"; 
        fi'"
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

  # Önizleme için gerekli bağımlılıkları yükle
  home.packages = previewDeps;

  # Önizleme için ortam değişkenleri
  home.sessionVariables = {
    FZF_PREVIEW_IMAGE_HANDLER = "chafa";  # veya "sixel" için terminalde sixel desteği varsa
  };
}

