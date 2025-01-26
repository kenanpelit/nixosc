# themes/colors.nix
{
   # Tokyo Night colors
   tokyonight = {
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
   mkTheme = { tokyonight, effects, fonts }: {
       # Waybar theme
       waybar = {
           custom = {
               font = fonts.main.family;
               font_size = fonts.main.size;
               font_weight = fonts.main.weight;
               text_color = tokyonight.text;
               background_0 = tokyonight.crust;
               background_1 = tokyonight.base;
               border_color = tokyonight.surface1;
               red = tokyonight.red;
               green = tokyonight.green;
               yellow = tokyonight.yellow;
               blue = tokyonight.blue;
               magenta = tokyonight.mauve;
               cyan = tokyonight.sky;
               orange = tokyonight.peach;
               orange_bright = tokyonight.peach;
               opacity = effects.opacity;
               indicator_height = "2px";
           };
       };

       # SwayNC theme
       swaync = {
           style = ''
               @define-color shadow ${effects.shadow};
               @define-color base ${tokyonight.base};
               @define-color mantle ${tokyonight.mantle};
               @define-color crust ${tokyonight.crust};
               @define-color text ${tokyonight.text};
               @define-color subtext0 ${tokyonight.subtext0};
               @define-color subtext1 ${tokyonight.subtext1};
               @define-color surface0 ${tokyonight.surface0};
               @define-color surface1 ${tokyonight.surface1};
               @define-color surface2 ${tokyonight.surface2};
               @define-color blue ${tokyonight.blue};
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
               background = tokyonight.base;
               foreground = tokyonight.text;
               selection_foreground = tokyonight.crust;
               selection_background = tokyonight.mauve;
               
               cursor = tokyonight.mauve;
               cursor_text_color = tokyonight.crust;
               
               url_color = tokyonight.sky;
               
               # Window borders
               active_border_color = tokyonight.mauve;
               inactive_border_color = tokyonight.surface1;
               bell_border_color = tokyonight.yellow;
               
               # Tab bar
               active_tab_foreground = tokyonight.crust;
               active_tab_background = tokyonight.mauve;
               inactive_tab_foreground = tokyonight.text;
               inactive_tab_background = tokyonight.crust;
               tab_bar_background = tokyonight.mantle;
               
               # Marks
               mark1_foreground = tokyonight.crust;
               mark1_background = tokyonight.mauve;
               mark2_foreground = tokyonight.crust;
               mark2_background = tokyonight.pink;
               mark3_foreground = tokyonight.crust;
               mark3_background = tokyonight.sky;
               
               # Standard colors
               color0 = tokyonight.surface1;   # Black
               color8 = tokyonight.surface2;   # Bright Black
               color1 = tokyonight.red;        # Red
               color9 = tokyonight.red;        # Bright Red
               color2 = tokyonight.green;      # Green
               color10 = tokyonight.green;     # Bright Green
               color3 = tokyonight.yellow;     # Yellow
               color11 = tokyonight.yellow;    # Bright Yellow
               color4 = tokyonight.blue;       # Blue
               color12 = tokyonight.blue;      # Bright Blue
               color5 = tokyonight.pink;       # Magenta
               color13 = tokyonight.pink;      # Bright Magenta
               color6 = tokyonight.sky;        # Cyan
               color14 = tokyonight.sky;       # Bright Cyan
               color7 = tokyonight.text;       # White
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
                   --interactive-normal: ${tokyonight.text};
                   --text-normal: ${tokyonight.text}; 
                   --background-primary: ${tokyonight.base};
                   --background-secondary: ${tokyonight.mantle};
                   --background-tertiary: ${tokyonight.crust};
                   --channels-default: ${tokyonight.blue};
                   --deprecated-panel-background: ${tokyonight.crust};
                   --channeltextarea-background: ${tokyonight.surface0};
                   --background-floating: ${tokyonight.base};
                   --background-mobile-primary: ${tokyonight.base};
                   --background-mobile-secondary: ${tokyonight.mantle};
                   --background-accent: ${tokyonight.sapphire};
                   --background-message-hover: ${tokyonight.surface0};
                   --text-muted: ${tokyonight.subtext0};
                   --text-link: ${tokyonight.blue};
                   --button-background: ${tokyonight.surface0};
                   --brand-experiment: ${tokyonight.blue};
               }

               /* App Elements */
               .theme-dark {
                   --header-primary: ${tokyonight.text};
                   --header-secondary: ${tokyonight.subtext0};
                   --background-primary: ${tokyonight.base};
                   --background-secondary: ${tokyonight.mantle};
                   --background-secondary-alt: ${tokyonight.crust};
                   --channeltextarea-background: ${tokyonight.surface0};
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
                   background-color: ${tokyonight.mantle} !important;
                   color: ${tokyonight.text};
               }

               /* Syntax Highlighting */
               .hljs-keyword { color: ${tokyonight.red}; }
               .hljs-built_in { color: ${tokyonight.blue}; }
               .hljs-type { color: ${tokyonight.yellow}; }
               .hljs-literal { color: ${tokyonight.mauve}; }
               .hljs-number { color: ${tokyonight.peach}; }
               .hljs-string { color: ${tokyonight.green}; }
               .hljs-function { color: ${tokyonight.teal}; }
               .hljs-comment { color: ${tokyonight.surface2}; font-style: italic; }
               .hljs-deletion { color: ${tokyonight.red}; }
               .hljs-addition { color: ${tokyonight.green}; }
               .hljs-emphasis { font-style: italic; }
               .hljs-strong { font-weight: bold; }

               /* UI Elements */
               .scroller::-webkit-scrollbar-thumb { 
                   background-color: ${tokyonight.surface0} !important;
                   border-radius: 4px;
               }
               .scroller::-webkit-scrollbar-track {
                   background-color: ${tokyonight.crust} !important;
               }
           '';
       };

       # Rofi theme
       rofi = {
           theme = ''
               * {
                   bg-col: ${tokyonight.crust};
                   bg-col-light: ${tokyonight.base};
                   border-col: ${tokyonight.surface1};
                   selected-col: ${tokyonight.surface0};
                   blue: ${tokyonight.blue};
                   fg-col: ${tokyonight.text};
                   fg-col2: ${tokyonight.subtext1};
                   grey: ${tokyonight.surface2};
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

