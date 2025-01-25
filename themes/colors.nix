# themes/colors.nix
{
    # Tokyo Night colors
    mocha = {
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
    mkTheme = { mocha, effects, fonts }: {
        # Waybar theme
        waybar = {
            custom = {
                font = fonts.main.family;
                font_size = fonts.main.size;
                font_weight = fonts.main.weight;
                text_color = mocha.text;
                background_0 = mocha.crust;
                background_1 = mocha.base;
                border_color = mocha.surface1;
                red = mocha.red;
                green = mocha.green;
                yellow = mocha.yellow;
                blue = mocha.blue;
                magenta = mocha.mauve;
                cyan = mocha.sky;
                orange = mocha.peach;
                orange_bright = mocha.peach;
                opacity = effects.opacity;
                indicator_height = "2px";
            };
        };

        # SwayNC theme
        swaync = {
            style = ''
                @define-color shadow ${effects.shadow};
                @define-color base ${mocha.base};
                @define-color mantle ${mocha.mantle};
                @define-color crust ${mocha.crust};
                @define-color text ${mocha.text};
                @define-color subtext0 ${mocha.subtext0};
                @define-color subtext1 ${mocha.subtext1};
                @define-color surface0 ${mocha.surface0};
                @define-color surface1 ${mocha.surface1};
                @define-color surface2 ${mocha.surface2};
                @define-color blue ${mocha.blue};
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
                background = mocha.base;
                foreground = mocha.text;
                selection_foreground = mocha.crust;
                selection_background = mocha.mauve;
                
                cursor = mocha.mauve;
                cursor_text_color = mocha.crust;
                
                url_color = mocha.sky;
                
                # Window borders
                active_border_color = mocha.mauve;
                inactive_border_color = mocha.surface1;
                bell_border_color = mocha.yellow;
                
                # Tab bar
                active_tab_foreground = mocha.crust;
                active_tab_background = mocha.mauve;
                inactive_tab_foreground = mocha.text;
                inactive_tab_background = mocha.crust;
                tab_bar_background = mocha.mantle;
                
                # Marks
                mark1_foreground = mocha.crust;
                mark1_background = mocha.mauve;
                mark2_foreground = mocha.crust;
                mark2_background = mocha.pink;
                mark3_foreground = mocha.crust;
                mark3_background = mocha.sky;
                
                # Standard colors
                color0 = mocha.surface1;   # Black
                color8 = mocha.surface2;   # Bright Black
                color1 = mocha.red;        # Red
                color9 = mocha.red;        # Bright Red
                color2 = mocha.green;      # Green
                color10 = mocha.green;     # Bright Green
                color3 = mocha.yellow;     # Yellow
                color11 = mocha.yellow;    # Bright Yellow
                color4 = mocha.blue;       # Blue
                color12 = mocha.blue;      # Bright Blue
                color5 = mocha.pink;       # Magenta
                color13 = mocha.pink;      # Bright Magenta
                color6 = mocha.sky;        # Cyan
                color14 = mocha.sky;       # Bright Cyan
                color7 = mocha.text;       # White
                color15 = "#ffffff";       # Bright White
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
                    --interactive-normal: ${mocha.text};
                    --text-normal: ${mocha.text}; 
                    --background-primary: ${mocha.base};
                    --background-secondary: ${mocha.mantle};
                    --background-tertiary: ${mocha.crust};
                    --channels-default: ${mocha.blue};
                    --deprecated-panel-background: ${mocha.crust};
                    --channeltextarea-background: ${mocha.surface0};
                    --background-floating: ${mocha.base};
                    --background-mobile-primary: ${mocha.base};
                    --background-mobile-secondary: ${mocha.mantle};
                    --background-accent: ${mocha.sapphire};
                    --background-message-hover: ${mocha.surface0};
                    --text-muted: ${mocha.subtext0};
                    --text-link: ${mocha.blue};
                    --button-background: ${mocha.surface0};
                    --brand-experiment: ${mocha.blue};
                }

                /* App Elements */
                .theme-dark {
                    --header-primary: ${mocha.text};
                    --header-secondary: ${mocha.subtext0};
                    --background-primary: ${mocha.base};
                    --background-secondary: ${mocha.mantle};
                    --background-secondary-alt: ${mocha.crust};
                    --channeltextarea-background: ${mocha.surface0};
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
                    background-color: ${mocha.mantle} !important;
                    color: ${mocha.text};
                }

                /* Syntax Highlighting */
                .hljs-keyword { color: ${mocha.red}; }
                .hljs-built_in { color: ${mocha.blue}; }
                .hljs-type { color: ${mocha.yellow}; }
                .hljs-literal { color: ${mocha.mauve}; }
                .hljs-number { color: ${mocha.peach}; }
                .hljs-string { color: ${mocha.green}; }
                .hljs-function { color: ${mocha.teal}; }
                .hljs-comment { color: ${mocha.surface2}; font-style: italic; }
                .hljs-deletion { color: ${mocha.red}; }
                .hljs-addition { color: ${mocha.green}; }
                .hljs-emphasis { font-style: italic; }
                .hljs-strong { font-weight: bold; }

                /* UI Elements */
                .scroller::-webkit-scrollbar-thumb { 
                    background-color: ${mocha.surface0} !important;
                    border-radius: 4px;
                }
                .scroller::-webkit-scrollbar-track {
                    background-color: ${mocha.crust} !important;
                }
            '';
        };

        # Rofi theme
        rofi = {
            theme = ''
                * {
                    bg-col: ${mocha.crust};
                    bg-col-light: ${mocha.base};
                    border-col: ${mocha.surface1};
                    selected-col: ${mocha.surface0};
                    blue: ${mocha.blue};
                    fg-col: ${mocha.text};
                    fg-col2: ${mocha.subtext1};
                    grey: ${mocha.surface2};
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

