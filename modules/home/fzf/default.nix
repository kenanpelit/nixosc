# modules/home/fzf/default.nix
# ==============================================================================
# FZF (Fuzzy Finder) Configuration - Catppuccin Mocha Theme
# ==============================================================================
# This configuration manages FZF setup including:
# - Advanced file and directory previews with multiple formats
# - Catppuccin Mocha theme - tmux compatible
# - Shell integration (Zsh)
# - Custom preview handlers for images, PDFs, videos, archives
# - Optimized search commands with fd integration
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, inputs, lib, config, ... }:
let
  cfg = config.my.tools.fzf;
  
  # Catppuccin Mocha theme - Enhanced with tmux style
  catppuccinMochaTheme = {
    colors = [
      "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
      "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
      "--color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
      "--color=border:#6c7086,label:#cdd6f4,query:#cdd6f4"
      "--color=selected-bg:#313244,selected-fg:#cdd6f4"
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
    
    theme = lib.mkOption {
      type = lib.types.enum [ "catppuccin-mocha" "default" ];
      default = "catppuccin-mocha";
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
      
      # Basic search commands
      defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
      
      # Advanced preview settings with Catppuccin Mocha colors
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
      
      # Theme settings - Catppuccin Mocha
      defaultOptions = 
        if cfg.theme == "catppuccin-mocha" then 
          (catppuccinMochaTheme.colors ++ catppuccinMochaTheme.ui ++ [
            "--height=50%"
            "--layout=reverse"
            "--info=inline"
            "--multi"
            "--preview-window=right:50%:wrap"
            "--bind=ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all"
            "--bind=ctrl-u:preview-page-up,ctrl-d:preview-page-down"
            "--bind=ctrl-f:page-down,ctrl-b:page-up"
            "--cycle"
          ])
        else [
          "--border=sharp" "--border-label=" "--preview-window=border-sharp"
          "--prompt=❯ " "--marker=❯" "--pointer=❯" "--separator=─" "--scrollbar=│" "--info=right"
          "--height=50%"
          "--layout=reverse"
          "--info=inline"
          "--multi"
          "--preview-window=right:50%:wrap"
          "--bind=ctrl-a:select-all,ctrl-d:deselect-all,ctrl-t:toggle-all"
          "--bind=ctrl-u:preview-page-up,ctrl-d:preview-page-down"
          "--bind=ctrl-f:page-down,ctrl-b:page-up"
          "--cycle"
        ];
    };
    
    # Enhanced shell integration with Catppuccin Mocha colors
    programs.zsh.initContent = lib.mkIf cfg.enableZshIntegration (
      if cfg.theme == "catppuccin-mocha" then ''
        # FZF Catppuccin Mocha Theme (Tmux Compatible)
        export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
          --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
          --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
          --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
          --color=border:#6c7086,label:#cdd6f4,query:#cdd6f4 \
          --color=selected-bg:#313244,selected-fg:#cdd6f4"
        
        # Advanced search commands
        export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
        export FZF_CTRL_T_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
        export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
        
        # Enhanced preview commands
        export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {} 2>/dev/null || cat {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
        export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window up:3:hidden:wrap --bind 'ctrl-/:toggle-preview'"
      '' else ""
    );
    
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
      poppler_utils   # PDF tools
      odt2txt         # Office document converter
      tree            # Directory tree viewer
      mediainfo       # Media file information
      exiftool        # Image metadata viewer
    ];
  };
}

