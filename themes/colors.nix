# themes/colors.nix
{
  # Tokyo Night colors as the base theme
  mocha = {
    # Base colors
    base = "#24283b";     # Tokyo Night background
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

  # Effects that can be used across different components
  effects = {
    shadow = "rgba(0, 0, 0, 0.25)";
    opacity = "1.0";
  };

  # Font configurations
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

  # Function to generate component-specific themes
  mkTheme = { mocha, effects, fonts }: {
    # Waybar specific theme
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

    # SwayNC specific theme
    swaync = {
      style = ''
        @define-color shadow ${effects.shadow};
        /* Catppuccin Mocha Colors */
        @define-color base ${mocha.base};
        @define-color mantle ${mocha.mantle};
        @define-color crust ${mocha.crust};
        @define-color text ${mocha.text};
        @define-color subtext0 ${mocha.subtext0};
        @define-color subtext1 ${mocha.subtext1};
        @define-color surface0 ${mocha.surface0};
        @define-color surface1 ${mocha.surface1};
        @define-color surface2 ${mocha.surface2};
        @define-color green ${mocha.green};
        * {
            font-family: "${fonts.notifications.family}";
            background-clip: border-box;
        }
      '';
    };
    
    # Kitty terminal theme
    kitty = {
      colors = {
        background = "#24283B";  # Override default background for Kitty
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
        # Black
        color0 = mocha.surface1;
        color8 = mocha.surface2;
        
        # Red
        color1 = mocha.red;
        color9 = mocha.red;
        
        # Green
        color2 = mocha.green;
        color10 = mocha.green;
        
        # Yellow
        color3 = mocha.yellow;
        color11 = mocha.yellow;
        
        # Blue
        color4 = mocha.blue;
        color12 = mocha.blue;
        
        # Magenta
        color5 = mocha.pink;
        color13 = mocha.pink;
        
        # Cyan
        color6 = mocha.sky;
        color14 = mocha.sky;
        
        # White
        color7 = mocha.text;
        color15 = "#ffffff";
      };
    };

    # Discord theme configuration
    discord = {
      css = ''
        /**
         * @name Catppuccin Mocha
         * @author Original: Ethan McTague, Modified for Catppuccin
         * @version 1.0
         * @description Discord theme using Catppuccin Mocha colors
         * @source https://github.com/catppuccin/discord
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
        }

        /* Syntax Highlighting */
        .hljs-deletion, .hljs-formula, .hljs-keyword, .hljs-link, .hljs-selector-tag {
          color: ${mocha.red};
        }
        .hljs-built_in, .hljs-emphasis, .hljs-name, .hljs-quote, .hljs-strong, .hljs-title, .hljs-variable {
          color: ${mocha.blue};
        }
        .hljs-attr, .hljs-params, .hljs-template-tag, .hljs-type {
          color: ${mocha.yellow};
        }
        .hljs-builtin-name, .hljs-doctag, .hljs-literal, .hljs-number {
          color: ${mocha.mauve};
        }
        .hljs-code, .hljs-meta, .hljs-regexp, .hljs-selector-id, .hljs-template-variable {
          color: ${mocha.peach};
        }
        .hljs-addition, .hljs-meta-string, .hljs-section, .hljs-selector-attr, .hljs-selector-class, .hljs-string, .hljs-symbol {
          color: ${mocha.green};
        }
        .hljs-attribute, .hljs-bullet, .hljs-class, .hljs-function, .hljs-function .hljs-keyword, .hljs-meta-keyword, .hljs-selector-pseudo, .hljs-tag {
          color: ${mocha.teal};
        }
        .hljs-comment {
          color: ${mocha.surface2};
        }
        .hljs-link_label, .hljs-literal, .hljs-number {
          color: ${mocha.pink};
        }

        /* Rest of your existing CSS rules */
        .da-popouts .da-container,
        .da-friendsTableHeader,
        .da-friendsTable,
        .da-autocomplete,
        .da-themedPopout,
        .da-header,
        .da-footer,
        .da-userPopout>*,
        .da-systemPad,
        .da-autocompleteHeaderBackground {
            background-color: var(--background-secondary) !important;
            border-color: transparent !important;
        }

        .theme-dark .da-messageGroupWrapper {
            background-color: var(--background-tertiary) !important;
            border-color: transparent;
        }

        .theme-dark .da-option:after {
            background-image: none !important;
        }

        .theme-dark #bd-settings-sidebar .ui-tab-bar-item {
            color: var(--interactive-normal);
        }

        .theme-dark #bd-settings-sidebar .ui-tab-bar-header,
        div[style*="color: rgb(114, 137, 218);"],
        .da-addButtonIcon {
            color: var(--channels-default) !important;
        }

        .theme-dark #bd-settings-sidebar .ui-tab-bar-item.selected,
        .theme-dark .da-autocompleteRow .da-selectorSelected {
            background-color: var(--background-modifier-selected);
            color: var(--interactive-active);
        }

        .da-emojiButtonNormal .da-contents .da-sprite {
            filter: sepia(1) !important;
        }

        .da-messagesWrapper .da-scroller::-webkit-scrollbar,
        .da-messagesWrapper .da-scroller::-webkit-scrollbar-track-piece {
            background-color: var(--background-tertiary) !important;
            border-color: rgba(0, 0, 0, 0) !important;
        }

        .da-scrollerThemed .da-scroller::-webkit-scrollbar-thumb,
        .da-scrollerWrap .da-scroller::-webkit-scrollbar-thumb {
            background-color: var(--background-secondary) !important;
            border-color: var(--background-tertiary) !important;
        }

        .hljs-comment, .hljs-emphasis {
            font-style: italic;
        }

        .hljs-section, .hljs-strong, .hljs-tag {
            font-weight: bold;
        }
      '';
    };

    # Rofi theme configuration
    rofi = {
      theme = ''
        * {
          bg-col: ${mocha.crust};
          bg-col-light: ${mocha.base};
          border-col: ${mocha.surface1};
          selected-col: ${mocha.surface0};
          green: ${mocha.green};
          fg-col: ${mocha.text};
          fg-col2: ${mocha.subtext1};
          grey: ${mocha.surface2};
          highlight: @green;
        }
      '';

      config = ''
        configuration{
          modi: "run,drun,window";
          lines: 5;
          cycle: false;
          font: "${fonts.main.family} Bold 13";
          show-icons: true;
          icon-theme: "a-candy-beauty-icon-theme";
          terminal: "kitty";
          drun-display-format: "{icon} {name}";
          location: 0;
          disable-history: true;
          hide-scrollbar: true;
          display-drun: " Apps ";
          display-run: " Run ";
          display-window: " Window ";
          sidebar-mode: true;
          sorting-method: "fzf";
        }
        @theme "theme"
        element-text, element-icon , mode-switcher {
          background-color: inherit;
          text-color:       inherit;
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
          padding: 0px;
        }
        prompt {
          background-color: @green;
          padding: 4px;
          text-color: @bg-col-light;
          border-radius: 3px;
          margin: 10px 0px 10px 10px;
        }
        textbox-prompt-colon {
          expand: false;
          str: ":";
        }
        entry {
          padding: 6px;
          margin: 10px 10px 10px 5px;
          text-color: @fg-col;
          background-color: @bg-col;
          border-radius: 3px;
        }
        listview {
          border: 0px 0px 0px;
          padding: 6px 0px 0px;
          margin: 10px 0px 0px 6px;
          columns: 3;
          background-color: @bg-col;
          cycle: true;
        }
        element {
          padding: 8px;
          margin: 0px 10px 4px 4px;
          background-color: @bg-col;
          text-color: @fg-col;
        }
        element-icon {
          size: 28px;
        }
        element selected {
          background-color:  @selected-col;
          text-color: @fg-col2;
          border-radius: 3px;
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
          text-color: @green;
        }
      '';
    };

    # Add other component themes here as needed
  };
}
