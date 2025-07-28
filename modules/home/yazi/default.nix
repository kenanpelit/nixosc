# modules/home/yazi/default.nix
# ==============================================================================
# Yazi File Manager Configuration - Catppuccin Mocha Theme
# ==============================================================================
{ inputs, pkgs, ... }:
{
  # =============================================================================
  # Program Configuration
  # =============================================================================
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    
    # ---------------------------------------------------------------------------
    # Manager Settings
    # ---------------------------------------------------------------------------
    settings = {
      mgr = {
        ratio = [1 3 4];
        linemode = "size";
        show_hidden = true;
        show_symlink = true;
        sort_by = "natural";
        sort_dir_first = true;
        sort_reverse = false;
        sort_sensitive = false;
      };
    };
    
    # ---------------------------------------------------------------------------
    # Plugin Configuration
    # ---------------------------------------------------------------------------
    plugins = {
      full-border = "${inputs.yazi-plugins}/full-border.yazi";
    };
    
    # ---------------------------------------------------------------------------
    # Theme Configuration - Catppuccin Mocha
    # ---------------------------------------------------------------------------
    theme = {
      mgr = {
        cwd = { fg = "#94e2d5"; };  # teal
        
        # Hovered
        hovered = { fg = "#1e1e2e"; bg = "#cba6f7"; };  # base on mauve
        preview_hovered = { underline = true; };
        
        # Find
        find_keyword = { fg = "#f9e2af"; italic = true; };  # yellow
        find_position = { fg = "#f38ba8"; bg = "reset"; italic = true; };  # pink
        
        # Marker
        marker_selected = { fg = "#a6e3a1"; bg = "#a6e3a1"; };  # green
        marker_copied = { fg = "#f9e2af"; bg = "#f9e2af"; };  # yellow
        marker_cut = { fg = "#f38ba8"; bg = "#f38ba8"; };  # pink
        
        # Tab
        tab_active = { fg = "#1e1e2e"; bg = "#cba6f7"; };  # base on mauve
        tab_inactive = { fg = "#cdd6f4"; bg = "#45475a"; };  # text on surface1
        tab_width = 1;
        
        # Count
        count_copied = { fg = "#1e1e2e"; bg = "#f9e2af"; };  # base on yellow
        count_cut = { fg = "#1e1e2e"; bg = "#f38ba8"; };  # base on pink
        count_selected = { fg = "#1e1e2e"; bg = "#a6e3a1"; };  # base on green
        
        # Border
        border_symbol = "│";
        border_style = { fg = "#6c7086"; };  # overlay0
        
        # Highlighting
        syntect_theme = "";
      };
      
      status = {
        separator_open = "";
        separator_close = "";
        separator_style = { fg = "#45475a"; bg = "#45475a"; };  # surface1
        
        # Mode
        mode_normal = { fg = "#1e1e2e"; bg = "#89b4fa"; bold = true; };  # base on blue
        mode_select = { fg = "#1e1e2e"; bg = "#a6e3a1"; bold = true; };  # base on green
        mode_unset = { fg = "#1e1e2e"; bg = "#f2cdcd"; bold = true; };  # base on flamingo
        
        # Progress
        progress_label = { fg = "#cdd6f4"; bold = true; };  # text
        progress_normal = { fg = "#89b4fa"; bg = "#313244"; };  # blue on surface0
        progress_error = { fg = "#f38ba8"; bg = "#313244"; };  # pink on surface0
        
        # Permissions
        permissions_t = { fg = "#a6e3a1"; };  # green
        permissions_r = { fg = "#f9e2af"; };  # yellow
        permissions_w = { fg = "#f38ba8"; };  # pink
        permissions_x = { fg = "#94e2d5"; };  # teal
        permissions_s = { fg = "#6c7086"; };  # overlay0
      };
      
      input = {
        border = { fg = "#cba6f7"; };  # mauve
        title = {};
        value = {};
        selected = { reversed = true; };
      };
      
      select = {
        border = { fg = "#89b4fa"; };  # blue
        active = { fg = "#f38ba8"; };  # pink
        inactive = {};
      };
      
      tasks = {
        border = { fg = "#89b4fa"; };  # blue
        title = {};
        hovered = { underline = true; };
      };
      
      which = {
        mask = { bg = "#181825"; };  # mantle
        cand = { fg = "#94e2d5"; };  # teal
        rest = { fg = "#9399b2"; };  # overlay2
        desc = { fg = "#f38ba8"; };  # pink
        separator = "  ";
        separator_style = { fg = "#585b70"; };  # surface2
      };
      
      help = {
        on = { fg = "#f38ba8"; };  # pink
        exec = { fg = "#94e2d5"; };  # teal
        desc = { fg = "#9399b2"; };  # overlay2
        hovered = { bg = "#585b70"; bold = true; };  # surface2
        footer = { fg = "#45475a"; bg = "#cdd6f4"; };  # surface1 on text
      };
      
      filetype = {
        rules = [
          # Images
          { mime = "image/*"; fg = "#94e2d5"; }  # teal
          
          # Videos
          { mime = "video/*"; fg = "#f9e2af"; }  # yellow
          { mime = "audio/*"; fg = "#f9e2af"; }  # yellow
          
          # Archives
          { mime = "application/zip"; fg = "#f38ba8"; }  # pink
          { mime = "application/gzip"; fg = "#f38ba8"; }  # pink
          { mime = "application/x-tar"; fg = "#f38ba8"; }  # pink
          { mime = "application/x-bzip"; fg = "#f38ba8"; }  # pink
          { mime = "application/x-bzip2"; fg = "#f38ba8"; }  # pink
          { mime = "application/x-7z-compressed"; fg = "#f38ba8"; }  # pink
          { mime = "application/x-rar"; fg = "#f38ba8"; }  # pink
          { mime = "application/xz"; fg = "#f38ba8"; }  # pink
          
          # Text
          { mime = "text/*"; fg = "#a6e3a1"; }  # green
          { mime = "application/json"; fg = "#f9e2af"; }  # yellow
          { mime = "*/xml"; fg = "#fab387"; }  # peach
          
          # Programming
          { name = "*.*sh"; fg = "#a6e3a1"; }  # green
          { name = "*.tmux"; fg = "#a6e3a1"; }  # green
          { name = "*.py"; fg = "#f9e2af"; }  # yellow
          { name = "*.js"; fg = "#f9e2af"; }  # yellow
          { name = "*.ts"; fg = "#89b4fa"; }  # blue
          { name = "*.rs"; fg = "#fab387"; }  # peach
          { name = "*.go"; fg = "#94e2d5"; }  # teal
          { name = "*.c"; fg = "#89b4fa"; }  # blue
          { name = "*.cpp"; fg = "#89b4fa"; }  # blue
          { name = "*.h"; fg = "#89b4fa"; }  # blue
          { name = "*.hpp"; fg = "#89b4fa"; }  # blue
          
          # Configs
          { name = "*.toml"; fg = "#fab387"; }  # peach
          { name = "*.yaml"; fg = "#f9e2af"; }  # yellow
          { name = "*.yml"; fg = "#f9e2af"; }  # yellow
          { name = "*.ini"; fg = "#6c7086"; }  # overlay0
          { name = "*.conf"; fg = "#6c7086"; }  # overlay0
          
          # Documents
          { name = "*.pdf"; fg = "#f38ba8"; }  # pink
          { name = "*.doc"; fg = "#89b4fa"; }  # blue
          { name = "*.docx"; fg = "#89b4fa"; }  # blue
          { name = "*.xls"; fg = "#a6e3a1"; }  # green
          { name = "*.xlsx"; fg = "#a6e3a1"; }  # green
          { name = "*.ppt"; fg = "#fab387"; }  # peach
          { name = "*.pptx"; fg = "#fab387"; }  # peach
          
          # Special files
          { name = "*/"; fg = "#cba6f7"; }  # mauve for directories
          { name = ".*"; fg = "#6c7086"; }  # overlay0 for hidden files
        ];
      };
    };
  };
  
  # =============================================================================
  # Additional Configuration
  # =============================================================================
  xdg.configFile."yazi/init.lua".text = ''
    require("full-border"):setup()
  '';
}

