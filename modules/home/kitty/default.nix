# modules/home/kitty/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for kitty.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ pkgs, lib, config, ... }:
let
  cfg = config.my.user.kitty;

  # Typography configuration
  typography = {
    family = "Maple Mono NF";
    size = 13;
    features = [ "liga" "calt" ];
  };
  
  # Performance settings
  performance = {
    repaint_delay = 10;
    input_delay = 3;
    scrollback_lines = 10000;
  };
in {
  options.my.user.kitty = {
    enable = lib.mkEnableOption "kitty terminal";
  };

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      
      # Font configuration
      font = {
        name = typography.family;
        size = typography.size;
      };
      
      # Core settings - Catppuccin modülü renkleri yönetecek
      settings = {
        # =======================================================================
        # Terminal Configuration
        # =======================================================================
        term = "xterm-256color";
        editor = "nvim";
        
        # Font rendering
        adjust_line_height = "2";
        adjust_column_width = "0";
        box_drawing_scale = "0.001, 1, 1.5, 2";
        disable_ligatures = "never";
        force_ltr = "no";
        
        # =======================================================================
        # Cursor Configuration
        # =======================================================================
        cursor_shape = "block";
        cursor_blink_interval = "0.5";
        cursor_beam_thickness = "1.5";
        
        # =======================================================================
        # Window & Layout
        # =======================================================================
        window_padding_width = "8";
        scrollback_lines = toString performance.scrollback_lines;
        wheel_scroll_multiplier = "5.0";
        touch_scroll_multiplier = "1.0";
        
        # =======================================================================
        # Performance & Responsiveness
        # =======================================================================
        repaint_delay = toString performance.repaint_delay;
        input_delay = toString performance.input_delay;
        sync_to_monitor = "yes";
        
        # =======================================================================
        # Audio & Visual Feedback
        # =======================================================================
        enable_audio_bell = "no";
        visual_bell_duration = "0.0";
        window_alert_on_bell = "yes";
        
        # =======================================================================
        # Tab Bar Styling
        # =======================================================================
        tab_bar_style = "powerline";
        tab_powerline_style = "angled";
        active_tab_font_style = "bold";
        inactive_tab_font_style = "normal";
        
        # =======================================================================
        # URL & Selection
        # =======================================================================
        url_style = "curly";
        detect_urls = "yes";
        copy_on_select = "yes";
      };
      
      # ==========================================================================
      # Advanced Font Configuration
      # ==========================================================================
      extraConfig = ''
        # Font variants
        bold_font        ${typography.family} Bold
        italic_font      ${typography.family} Italic
        bold_italic_font ${typography.family} Bold Italic
        
        # Icon and symbol fonts  
        symbol_map U+E0A0-U+E0A2,U+E0B0-U+E0B3 ${typography.family}
        symbol_map U+F000-U+F2E0 ${typography.family}
        
        # Font features
        font_features ${lib.concatStringsSep "," (map (f: "+" + f) typography.features)}
        
        # Performance optimizations
        input_delay ${toString performance.input_delay}
        repaint_delay ${toString performance.repaint_delay}
      '';
      
      # ==========================================================================
      # Keyboard Shortcuts
      # ==========================================================================
      keybindings = {
        # Tab navigation
        "alt+1" = "goto_tab 1";
        "alt+2" = "goto_tab 2";
        "alt+3" = "goto_tab 3";
        "alt+4" = "goto_tab 4";
        "alt+5" = "goto_tab 5";
        "alt+6" = "goto_tab 6";
        "alt+7" = "goto_tab 7";
        "alt+8" = "goto_tab 8";
        "alt+9" = "goto_tab 9";
        
        # New tab/window
        "ctrl+shift+t" = "new_tab";
        "ctrl+shift+n" = "new_os_window";
        
        # Window management
        "ctrl+shift+w" = "close_window";
        "ctrl+shift+q" = "quit";
        
        # Text operations
        "ctrl+shift+c" = "copy_to_clipboard";
        "ctrl+shift+v" = "paste_from_clipboard";
        
        # Font size
        "ctrl+shift+equal" = "increase_font_size";
        "ctrl+shift+minus" = "decrease_font_size";
        "ctrl+shift+backspace" = "restore_font_size";
        
        # Scrolling
        "shift+page_up" = "scroll_page_up";
        "shift+page_down" = "scroll_page_down";
        "ctrl+shift+home" = "scroll_home";
        "ctrl+shift+end" = "scroll_end";
        
        # Disable unwanted shortcuts
        "ctrl+shift+left" = "no_op";
        "ctrl+shift+right" = "no_op";
      };
    };
  };
}
