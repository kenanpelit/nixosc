# module/home/terminal/kitty/default.nix
# ==============================================================================
# Kitty Terminal Emülatör Konfigürasyonu
# ==============================================================================
{ pkgs, host, ... }:
let
  colors = import ./../../../../themes/colors.nix;
  theme = colors.mkTheme {
    inherit (colors) kenp effects fonts;
  };
in
{
  programs.kitty = {
    enable = true;
    font = {
      name = "Hack Nerd Font";
      size = 13.3;
    };
    settings = 
      theme.kitty.colors //
      {
        term = "xterm-256color";
        adjust_line_height = "2";
        adjust_column_width = "0";
        box_drawing_scale = "0.001, 1, 1.5, 2";
        disable_ligatures = "never";
        force_ltr = "no";
        
        cursor_shape = "block";
        cursor_blink_interval = "0.5";
        cursor_beam_thickness = "1.5";
        window_padding_width = "8";
        scrollback_lines = "10000";
        wheel_scroll_multiplier = "5.0";
        touch_scroll_multiplier = "1.0";
        repaint_delay = "10";
        input_delay = "3";
        sync_to_monitor = "yes";
        
        enable_audio_bell = "no";
        visual_bell_duration = "0.0";
        window_alert_on_bell = "yes";
        
        tab_bar_style = "powerline";
        tab_powerline_style = "angled";
        active_tab_font_style = "bold";
        inactive_tab_font_style = "normal";
        
        url_style = "curly";
        detect_urls = "yes";
        copy_on_select = "yes";
      };
    
    extraConfig = ''
      bold_font        Hack Nerd Font Bold
      italic_font      Hack Nerd Font Italic
      bold_italic_font Hack Nerd Font Bold Italic
      symbol_map U+E0A0-U+E0A2,U+E0B0-U+E0B3 Hack Nerd Font
      font_features +liga,+calt
    '';
    
    keybindings = {
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";
      
      "ctrl+shift+left" = "no_op";
      "ctrl+shift+right" = "no_op";
    };
  };
}
