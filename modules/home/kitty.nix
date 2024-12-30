{ pkgs, host, ... }:
{
  programs.kitty = {
    enable = true;
    themeFile = "gruvbox-dark-hard";
    
    font = {
      name = "Maple Mono";
      size = 14;
    };

    extraConfig = ''
      # Font features configuration
      font_features MapleMono-Regular    +ss01 +ss02 +ss04
      font_features MapleMono-Bold       +ss01 +ss02 +ss04
      font_features MapleMono-Italic     +ss01 +ss02 +ss04
      font_features MapleMono-Light      +ss01 +ss02 +ss04
      
      # Font rendering settings
      disable_ligatures never
      text_composition_strategy 1.0 0
      modify_font cell_height 105%
    '';

    settings = {
      # Window settings
      confirm_os_window_close = 0;
      background_opacity = "1.0";
      scrollback_lines = 10000;
      enable_audio_bell = false;
      mouse_hide_wait = 60;
      window_padding_width = 5;
      term = "xterm-256color";  # For SSH compatibility

      # Font rendering
      adjust_line_height = "0";
      adjust_column_width = "0";
      box_drawing_scale = "0.001, 1, 1.5, 2";
      
      # Tab bar configuration
      tab_title_template = "{index}";
      active_tab_font_style = "normal";
      inactive_tab_font_style = "normal";
      tab_bar_style = "powerline";
      tab_powerline_style = "angled";
      active_tab_foreground = "#FBF1C7";
      active_tab_background = "#7C6F64";
      inactive_tab_foreground = "#FBF1C7";
      inactive_tab_background = "#3C3836";
    };

    keybindings = {
      # Tab navigation
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";
      
      # Disable default keybindings
      "ctrl+shift+left" = "no_op";
      "ctrl+shift+right" = "no_op";
    };
  };
}
