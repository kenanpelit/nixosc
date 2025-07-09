# modules/home/apps/webcord/default.nix
{ pkgs, ... }:
let
  # Tokyo Night tema renkleri
  colors = {
    base = "#24283b";
    mantle = "#1f2335";
    crust = "#1a1b26";
    text = "#c0caf5";
    subtext0 = "#9aa5ce";
    surface0 = "#292e42";
    surface2 = "#565f89";
    blue = "#7aa2f7";
    sapphire = "#2ac3de";
    red = "#f7768e";
    yellow = "#e0af68";
    mauve = "#bb9af7";
    peach = "#ff9e64";
    green = "#9ece6a";
    teal = "#73daca";
  };

  # Discord tema CSS'i
  discordTheme = {
    css = ''
      /**
       * @name TokyoNight
       * @author kenanpelit
       * @version 1.0
       * @description Discord theme using TokyoNight colors
       */
      :root {
        --interactive-normal: ${colors.text};
        --text-normal: ${colors.text}; 
        --background-primary: ${colors.base};
        --background-secondary: ${colors.mantle};
        --background-tertiary: ${colors.crust};
        --channels-default: ${colors.blue};
        --deprecated-panel-background: ${colors.crust};
        --channeltextarea-background: ${colors.surface0};
        --background-floating: ${colors.base};
        --background-mobile-primary: ${colors.base};
        --background-mobile-secondary: ${colors.mantle};
        --background-accent: ${colors.sapphire};
        --background-message-hover: ${colors.surface0};
        --text-muted: ${colors.subtext0};
        --text-link: ${colors.blue};
        --button-background: ${colors.surface0};
        --brand-experiment: ${colors.blue};
      }
      
      /* App Elements */
      .theme-dark {
        --header-primary: ${colors.text};
        --header-secondary: ${colors.subtext0};
        --background-primary: ${colors.base};
        --background-secondary: ${colors.mantle};
        --background-secondary-alt: ${colors.crust};
        --channeltextarea-background: ${colors.surface0};
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
        background-color: ${colors.mantle} !important;
        color: ${colors.text};
      }
      
      /* Syntax Highlighting */
      .hljs-keyword { color: ${colors.red}; }
      .hljs-built_in { color: ${colors.blue}; }
      .hljs-type { color: ${colors.yellow}; }
      .hljs-literal { color: ${colors.mauve}; }
      .hljs-number { color: ${colors.peach}; }
      .hljs-string { color: ${colors.green}; }
      .hljs-function { color: ${colors.teal}; }
      .hljs-comment { color: ${colors.surface2}; font-style: italic; }
      .hljs-deletion { color: ${colors.red}; }
      .hljs-addition { color: ${colors.green}; }
      .hljs-emphasis { font-style: italic; }
      .hljs-strong { font-weight: bold; }
      
      /* UI Elements */
      .scroller::-webkit-scrollbar-thumb { 
        background-color: ${colors.surface0} !important;
        border-radius: 4px;
      }
      .scroller::-webkit-scrollbar-track {
        background-color: ${colors.crust} !important;
      }
    '';
  };
in {
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [
    webcord-vencord
  ];
  
  # =============================================================================
  # Theme Configuration
  # =============================================================================
  xdg.configFile."Vencord/themes/kenp.theme.css".text = discordTheme.css;
}

