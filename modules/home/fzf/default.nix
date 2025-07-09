# modules/home/fzf/default.nix
# ==============================================================================
# FZF (Fuzzy Finder) Configuration
# ==============================================================================
# This configuration manages FZF setup including:
# - Advanced file and directory previews with multiple formats
# - Tokyo Night color theme integration
# - Shell integration (Zsh)
# - Custom preview handlers for images, PDFs, videos, archives
# - Optimized search commands with fd integration
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, inputs, lib, config, ... }:
let
  cfg = config.my.tools.fzf;
in {
  options.my.tools.fzf = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable FZF fuzzy finder with advanced previews";
    };
    
    theme = lib.mkOption {
      type = lib.types.enum [ "tokyo-night" "catppuccin" "default" ];
      default = "tokyo-night";
      description = "Color theme for FZF interface";
    };
    
    enableZshIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Zsh shell integration";
    };
    
    previewImageHandler = lib.mkOption {
      type = lib.types.enum [ "chafa" "sixel" ];
      default = "chafa";
      description = "Image preview handler (chafa for most terminals, sixel for advanced terminals)";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = cfg.enableZshIntegration;
      
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
            ${cfg.previewImageHandler} --format symbols \"$FILE\";
          elif [[ \"$FILE\" =~ \\.(pdf)$ ]]; then
            pdftoppm -png -f 1 -l 1 \"$FILE\" - | ${cfg.previewImageHandler} -;
          elif [[ \"$FILE\" =~ \\.(mp4|webm|mkv)$ ]]; then
            ffmpegthumbnailer -i \"$FILE\" -o - -s 0 | ${cfg.previewImageHandler} -;
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
      
      # Tema ayarları
      defaultOptions = 
        if cfg.theme == "tokyo-night" then [
          # Ana renkler (Tokyo Night)
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
        ] else if cfg.theme == "catppuccin" then [
          # Catppuccin Mocha theme
          "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
          "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6ac,pointer:#f5e0dc"
          "--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6ac,hl+:#f38ba8"
          "--border='sharp' --border-label='' --preview-window='border-sharp' --prompt='❯ '"
          "--marker='❯' --pointer='❯' --separator='─' --scrollbar='│'"
          "--info='right'"
        ] else [
          # Default FZF colors
          "--border='sharp' --border-label='' --preview-window='border-sharp' --prompt='❯ '"
          "--marker='❯' --pointer='❯' --separator='─' --scrollbar='│'"
          "--info='right'"
        ];
    };
    
    # Önizleme için ortam değişkenleri
    home.sessionVariables = {
      FZF_PREVIEW_IMAGE_HANDLER = cfg.previewImageHandler;
    };
    
    # Required packages for advanced previews
    home.packages = with pkgs; [
      fd              # Fast file finder
      bat             # Better cat with syntax highlighting
      eza             # Better ls
      chafa           # Image preview in terminal
      glow            # Markdown preview
      atool           # Archive listing
      ffmpegthumbnailer # Video thumbnails
      poppler_utils   # PDF tools (pdftoppm)
    ] ++ lib.optionals (cfg.previewImageHandler == "sixel") [
      # Additional packages for sixel support if needed
    ];
  };
}

