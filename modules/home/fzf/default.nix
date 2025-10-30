# modules/home/fzf/default.nix
# ==============================================================================
# FZF (Fuzzy Finder) Configuration - Auto Catppuccin Theme
# ==============================================================================
# This configuration manages FZF setup including:
# - Advanced file and directory previews with multiple formats
# - Dynamic Catppuccin theme from central module
# - Shell integration (Zsh)
# - Custom preview handlers for images, PDFs, videos, archives
# - Optimized search commands with fd integration
#
# Author: Kenan Pelit
# ==============================================================================
{ config, pkgs, lib, ... }:
let
  cfg = config.my.tools.fzf;
  
  # Catppuccin modülünden otomatik renk alımı
  inherit (config.catppuccin) sources;
  
  # Palette JSON'dan renkler
  colors = (lib.importJSON "${sources.palette}/palette.json").${config.catppuccin.flavor}.colors;
  
  # Dynamic Catppuccin theme - flavor'a göre değişir
  dynamicCatppuccinTheme = {
    colors = [
      "--color=bg+:${colors.surface0.hex},bg:${colors.base.hex},spinner:${colors.rosewater.hex},hl:${colors.red.hex}"
      "--color=fg:${colors.text.hex},header:${colors.red.hex},info:${colors.mauve.hex},pointer:${colors.rosewater.hex}"
      "--color=marker:${colors.green.hex},fg+:${colors.text.hex},prompt:${colors.mauve.hex},hl+:${colors.red.hex}"
      "--color=border:${colors.overlay0.hex},label:${colors.text.hex},query:${colors.text.hex}"
      "--color=selected-bg:${colors.surface0.hex},selected-fg:${colors.text.hex}"
    ];
    ui = [
      "--border=sharp" "--border-label=" "--preview-window=border-sharp"
      "--prompt=❯ " "--marker=❯" "--pointer=❯" "--separator=─" "--scrollbar=│" "--info=right"
    ];
  };
in
{
  options.my.tools.fzf = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable FZF fuzzy finder with advanced previews";
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
      
      # Basic search commands
      defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
      
      # Advanced preview settings
      fileWidgetOptions = [
        "--preview 'bat -n --color=always --line-range :500 {} 2>/dev/null || cat {}'"
        "--height=50%"
        "--layout=reverse"
        "--info=inline"
      ];
      
      # Directory change settings with enhanced preview
      changeDirWidgetCommand = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
      changeDirWidgetOptions = [
        "--preview 'eza --tree --color=always --level=2 {} 2>/dev/null || ls -la {}'"
        "--height=50%"
        "--layout=reverse"
        "--info=inline"
      ];
      
      # Enhanced history widget
      historyWidgetOptions = [
        "--height=50%"
        "--layout=reverse"
        "--info=inline"
        "--tiebreak=index"
      ];
      
      # Dynamic Catppuccin theme - flavor'a göre otomatik değişir
      defaultOptions = (dynamicCatppuccinTheme.colors ++ dynamicCatppuccinTheme.ui ++ [
        "--height=50%"
        "--layout=reverse"
        "--info=inline"
        "--multi"
        "--preview-window=right:50%:wrap"
        "--bind=ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all"
        "--bind=ctrl-u:preview-page-up,ctrl-d:preview-page-down"
        "--bind=ctrl-f:page-down,ctrl-b:page-up"
        "--cycle"
      ]);
    };
    
    # Enhanced shell integration with dynamic Catppuccin colors
    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
      # FZF Dynamic Catppuccin Theme (${config.catppuccin.flavor})
      export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
        --color=bg+:${colors.surface0.hex},bg:${colors.base.hex},spinner:${colors.rosewater.hex},hl:${colors.red.hex} \
        --color=fg:${colors.text.hex},header:${colors.red.hex},info:${colors.mauve.hex},pointer:${colors.rosewater.hex} \
        --color=marker:${colors.green.hex},fg+:${colors.text.hex},prompt:${colors.mauve.hex},hl+:${colors.red.hex} \
        --color=border:${colors.overlay0.hex},label:${colors.text.hex},query:${colors.text.hex} \
        --color=selected-bg:${colors.surface0.hex},selected-fg:${colors.text.hex}"
      
      # Advanced search commands
      export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
      export FZF_CTRL_T_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
      export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
      
      # Enhanced preview commands
      export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {} 2>/dev/null || cat {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
      export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window up:3:hidden:wrap --bind 'ctrl-/:toggle-preview'"
    '';
    
    # Environment variables
    home.sessionVariables = {
      FZF_PREVIEW_IMAGE_HANDLER = cfg.previewImageHandler;
    };
    
    # Required packages with additional tools
    home.packages = with pkgs; [
      fd              # Fast file finder
      bat             # Better cat with syntax highlighting
      eza             # Better ls with tree view
      chafa           # Image preview in terminal
      glow            # Markdown preview
      atool           # Archive listing
      ffmpegthumbnailer # Video thumbnails
      poppler-utils   # PDF tools
      odt2txt         # Office document converter
      tree            # Directory tree viewer
      mediainfo       # Media file information
      exiftool        # Image metadata viewer
    ];
  };
}

