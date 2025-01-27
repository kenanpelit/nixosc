# modules/home/terminal/kitty/theme.nix
{ kenp, effects, fonts }:
{
  colors = {
    background = kenp.base;
    foreground = kenp.text;
    selection_foreground = kenp.crust;
    selection_background = kenp.mauve;
    
    cursor = kenp.mauve;
    cursor_text_color = kenp.crust;
    
    url_color = kenp.sky;
    
    # Window borders
    active_border_color = kenp.mauve;
    inactive_border_color = kenp.surface1;
    bell_border_color = kenp.yellow;
    
    # Tab bar
    active_tab_foreground = kenp.crust;
    active_tab_background = kenp.mauve;
    inactive_tab_foreground = kenp.text;
    inactive_tab_background = kenp.crust;
    tab_bar_background = kenp.mantle;
    
    # Marks
    mark1_foreground = kenp.crust;
    mark1_background = kenp.mauve;
    mark2_foreground = kenp.crust;
    mark2_background = kenp.pink;
    mark3_foreground = kenp.crust;
    mark3_background = kenp.sky;
    
    # Standard colors
    color0 = kenp.surface1;   # Black
    color8 = kenp.surface2;   # Bright Black
    color1 = kenp.red;        # Red
    color9 = kenp.red;        # Bright Red
    color2 = kenp.green;      # Green
    color10 = kenp.green;     # Bright Green
    color3 = kenp.yellow;     # Yellow
    color11 = kenp.yellow;    # Bright Yellow
    color4 = kenp.blue;       # Blue 
    color12 = kenp.blue;      # Bright Blue
    color5 = kenp.pink;       # Magenta
    color13 = kenp.pink;      # Bright Magenta
    color6 = kenp.sky;        # Cyan
    color14 = kenp.sky;       # Bright Cyan
    color7 = kenp.text;       # White
    color15 = "#ffffff";      # Bright White
  };
}

