# themes/colors.nix
{
   # Base Tokyo Night colors
   kenp = {
       # Base colors
       base = "#24283b";     # Background
       mantle = "#1f2335";   # Darker background
       crust = "#1a1b26";    # Darkest background
       
       # Text colors
       text = "#c0caf5";     # Primary text
       subtext0 = "#9aa5ce"; # Secondary text
       subtext1 = "#a9b1d6"; # Tertiary text
       
       # Surface colors
       surface0 = "#292e42"; # Light surface
       surface1 = "#414868"; # Medium surface
       surface2 = "#565f89"; # Dark surface
       
       # Accent colors
       rosewater = "#f7768e"; # Light Red
       flamingo = "#ff9e64";  # Orange
       pink = "#ff75a0";      # Pink
       mauve = "#bb9af7";     # Purple
       red = "#f7768e";       # Red
       maroon = "#e0af68";    # Yellow
       peach = "#ff9e64";     # Light Orange
       yellow = "#e0af68";    # Yellow
       green = "#9ece6a";     # Green
       teal = "#73daca";      # Teal
       sky = "#7dcfff";       # Light Blue
       sapphire = "#2ac3de";  # Cyan
       blue = "#7aa2f7";      # Blue
       lavender = "#b4f9f8";  # Terminal Cyan
   };

   # Effects
   effects = {
       shadow = "rgba(0, 0, 0, 0.25)";
       opacity = "1.0";
   };

   # Fonts
   fonts = {
       main = {
           family = "Maple Mono";
           size = "16px";
           weight = "bold";
       };
       notifications = {
           family = "Hack Nerd Font";
       };
   };

   # Theme generator
   mkTheme = { kenp, effects, fonts }: {
       # Waybar theme
       waybar = {
           custom = {
               font = fonts.main.family;
               font_size = fonts.main.size;
               font_weight = fonts.main.weight;
               text_color = kenp.text;
               background_0 = kenp.crust;
               background_1 = kenp.base;
               border_color = kenp.surface1;
               red = kenp.red;
               green = kenp.green;
               yellow = kenp.yellow;
               blue = kenp.blue;
               magenta = kenp.mauve;
               cyan = kenp.sky;
               orange = kenp.peach;
               orange_bright = kenp.peach;
               opacity = effects.opacity;
               indicator_height = "2px";
           };
       };

       # SwayNC theme
       swaync = {
           style = ''
               @define-color shadow ${effects.shadow};
               @define-color base ${kenp.base};
               @define-color mantle ${kenp.mantle};
               @define-color crust ${kenp.crust};
               @define-color text ${kenp.text};
               @define-color subtext0 ${kenp.subtext0};
               @define-color subtext1 ${kenp.subtext1};
               @define-color surface0 ${kenp.surface0};
               @define-color surface1 ${kenp.surface1};
               @define-color surface2 ${kenp.surface2};
               @define-color blue ${kenp.blue};
               * {
                   font-family: "${fonts.notifications.family}";
                   background-clip: border-box;
               }

               .floating-notifications {
                   background: transparent;
               }

               .notification-row {
                   outline: none;
                   margin: 10px;
                   padding: 0;
               }

               .notification {
                   background: @base;
                   border: 2px solid @surface1;
                   border-radius: 8px;
                   margin: 5px;
                   box-shadow: 0 0 8px 0 @shadow;
               }

               .notification-content {
                   padding: 10px;
                   margin: 0;
               }

               .close-button {
                   background: @surface0;
                   color: @text;
                   text-shadow: none;
                   padding: 0;
                   border-radius: 100%;
                   margin-top: 10px;
                   margin-right: 10px;
                   box-shadow: none;
                   border: none;
                   min-width: 24px;
                   min-height: 24px;
               }

               .notification-default-action {
                   margin: 0;
                   padding: 0;
                   border-radius: 8px;
               }

               .notification-default-action:hover {
                   background: @surface0;
               }

               .notification-label {
                   color: @text;
               }

               .notification-background {
                   background: @base;
               }

               .control-center {
                   background: @base;
                   border: 2px solid @surface1;
                   border-radius: 8px;
                   margin: 10px;
                   box-shadow: 0 0 8px 0 @shadow;
               }
           '';
       };
       
       # Kitty terminal theme
       kitty = {
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
               color15 = "#ffffff";            # Bright White
           };
       };

       # Discord theme
       discord = {
           css = ''
               /**
                * @name TokyoNight
                * @author kenanpelit
                * @version 1.0
                * @description Discord theme using TokyoNight colors
                */
               :root {
                   --interactive-normal: ${kenp.text};
                   --text-normal: ${kenp.text}; 
                   --background-primary: ${kenp.base};
                   --background-secondary: ${kenp.mantle};
                   --background-tertiary: ${kenp.crust};
                   --channels-default: ${kenp.blue};
                   --deprecated-panel-background: ${kenp.crust};
                   --channeltextarea-background: ${kenp.surface0};
                   --background-floating: ${kenp.base};
                   --background-mobile-primary: ${kenp.base};
                   --background-mobile-secondary: ${kenp.mantle};
                   --background-accent: ${kenp.sapphire};
                   --background-message-hover: ${kenp.surface0};
                   --text-muted: ${kenp.subtext0};
                   --text-link: ${kenp.blue};
                   --button-background: ${kenp.surface0};
                   --brand-experiment: ${kenp.blue};
               }

               /* App Elements */
               .theme-dark {
                   --header-primary: ${kenp.text};
                   --header-secondary: ${kenp.subtext0};
                   --background-primary: ${kenp.base};
                   --background-secondary: ${kenp.mantle};
                   --background-secondary-alt: ${kenp.crust};
                   --channeltextarea-background: ${kenp.surface0};
               }

               /* Message Area */
               .chat-2ZfjoI {
                   background-color: var(--background-primary);
               }

               .message-2CShn3 {
                   background-color: var(--background-primary);
               }

               /* Emoji Picker & GIF Tab */
               .contentWrapper-3vHNP2 {
                   background-color: var(--background-secondary);
               }

               .wrapper-1NNaWG {
                   background-color: var(--background-secondary);
               }

               /* Code Blocks */
               .hljs {
                   background-color: ${kenp.mantle} !important;
                   color: ${kenp.text};
               }

               /* Syntax Highlighting */
               .hljs-keyword { color: ${kenp.red}; }
               .hljs-built_in { color: ${kenp.blue}; }
               .hljs-type { color: ${kenp.yellow}; }
               .hljs-literal { color: ${kenp.mauve}; }
               .hljs-number { color: ${kenp.peach}; }
               .hljs-string { color: ${kenp.green}; }
               .hljs-function { color: ${kenp.teal}; }
               .hljs-comment { color: ${kenp.surface2}; font-style: italic; }
               .hljs-deletion { color: ${kenp.red}; }
               .hljs-addition { color: ${kenp.green}; }
               .hljs-emphasis { font-style: italic; }
               .hljs-strong { font-weight: bold; }

               /* UI Elements */
               .scroller::-webkit-scrollbar-thumb { 
                   background-color: ${kenp.surface0} !important;
                   border-radius: 4px;
               }
               .scroller::-webkit-scrollbar-track {
                   background-color: ${kenp.crust} !important;
               }
           '';
       };

       # Rofi theme
       rofi = {
           theme = ''
               * {
                   bg-col: ${kenp.crust};
                   bg-col-light: ${kenp.base};
                   border-col: ${kenp.surface1};
                   selected-col: ${kenp.surface0};
                   blue: ${kenp.blue};
                   fg-col: ${kenp.text};
                   fg-col2: ${kenp.subtext1};
                   grey: ${kenp.surface2};
               }
           '';

           config = ''
               configuration {
                   modi: "run,drun,window";
                   lines: 5;
                   font: "${fonts.main.family} Bold 13";
                   show-icons: true;
                   icon-theme: "a-candy-beauty-icon-theme";
                   terminal: "kitty";
                   drun-display-format: "{icon} {name}";
                   location: 0;
                   disable-history: false;
                   hide-scrollbar: true;
                   display-drun: "   Apps ";
                   display-run: "   Run ";
                   display-window: " 﩯  Window";
                   display-Network: " 󰤨  Network";
                   sidebar-mode: true;
               }

               @theme "theme"

               element-text, element-icon, mode-switcher {
                   background-color: inherit;
                   text-color: inherit;
               }

               window {
                   height: 600px;
                   width: 900px;
                   border: 2px;
                   border-color: @border-col;
                   background-color: @bg-col;
               }

               mainbox {
                   background-color: @bg-col;
               }

               inputbar {
                   children: [prompt,entry];
                   background-color: @bg-col-light;
                   border-radius: 5px;
                   padding: 2px;
               }

               prompt {
                   background-color: @blue;
                   padding: 6px;
                   text-color: @bg-col;
                   border-radius: 3px;
                   margin: 20px 0px 0px 20px;
               }

               textbox-prompt-colon {
                   expand: false;
                   str: ":";
               }

               entry {
                   padding: 6px;
                   margin: 20px 0px 0px 10px;
                   text-color: @fg-col;
                   background-color: @bg-col;
               }

               listview {
                   border: 0px 0px 0px;
                   padding: 6px 0px 0px;
                   margin: 10px 0px 0px 20px;
                   columns: 3;
                   spacing: 5px;
                   background-color: @bg-col;
               }

               element {
                   padding: 5px;
                   background-color: @bg-col;
                   text-color: @fg-col;
               }

               element-icon {
                   size: 25px;
               }

               element selected {
                   background-color: @selected-col;
                   text-color: @fg-col2;
               }

               mode-switcher {
                   spacing: 0;
               }

               button {
                   padding: 10px;
                   background-color: @bg-col-light;
                   text-color: @grey;
                   vertical-align: 0.5; 
                   horizontal-align: 0.5;
               }

               button selected {
                   background-color: @bg-col;
                   text-color: @blue;
               }
           '';
       };
   };
}

