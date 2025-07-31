# modules/home/webcord/default.nix
{ config, pkgs, lib, ... }:
let
  # Catppuccin flavor'ları için renk setleri
  catppuccinColors = {
    mocha = {
      base = "1e1e2e"; mantle = "181825"; crust = "11111b";
      text = "cdd6f4"; subtext1 = "bac2de"; subtext0 = "a6adc8";
      surface0 = "313244"; surface1 = "45475a"; surface2 = "585b70";
      blue = "89b4fa"; lavender = "b4befe"; sapphire = "74c7ec";
      sky = "89dceb"; teal = "94e2d5"; green = "a6e3a1";
      yellow = "f9e2af"; peach = "fab387"; maroon = "eba0ac";
      red = "f38ba8"; mauve = "cba6f7"; pink = "f5c2e7";
      flamingo = "f2cdcd"; rosewater = "f5e0dc";
    };
    macchiato = {
      base = "24273a"; mantle = "1e2030"; crust = "181926";
      text = "cad3f5"; subtext1 = "b5bfe2"; subtext0 = "a5adcb";
      surface0 = "363a4f"; surface1 = "494d64"; surface2 = "5b6078";
      blue = "8aadf4"; lavender = "b7bdf8"; sapphire = "7dc4e4";
      sky = "91d7e3"; teal = "8bd5ca"; green = "a6da95";
      yellow = "eed49f"; peach = "f5a97f"; maroon = "ee99a0";
      red = "ed8796"; mauve = "c6a0f6"; pink = "f5bde6";
      flamingo = "f0c6c6"; rosewater = "f4dbd6";
    };
    frappe = {
      base = "303446"; mantle = "292c3c"; crust = "232634";
      text = "c6d0f5"; subtext1 = "b5bfe2"; subtext0 = "a5adce";
      surface0 = "414559"; surface1 = "51576d"; surface2 = "626880";
      blue = "8caaee"; lavender = "babbf1"; sapphire = "85c1dc";
      sky = "99d1db"; teal = "81c8be"; green = "a6d189";
      yellow = "e5c890"; peach = "ef9f76"; maroon = "ea999c";
      red = "e78284"; mauve = "ca9ee6"; pink = "f4b8e4";
      flamingo = "eebebe"; rosewater = "f2d5cf";
    };
    latte = {
      base = "eff1f5"; mantle = "e6e9ef"; crust = "dce0e8";
      text = "4c4f69"; subtext1 = "5c5f77"; subtext0 = "6c6f85";
      surface0 = "ccd0da"; surface1 = "bcc0cc"; surface2 = "acb0be";
      blue = "1e66f5"; lavender = "7287fd"; sapphire = "209fb5";
      sky = "04a5e5"; teal = "179299"; green = "40a02b";
      yellow = "df8e1d"; peach = "fe640b"; maroon = "e64553";
      red = "d20f39"; mauve = "8839ef"; pink = "ea76cb";
      flamingo = "dd7878"; rosewater = "dc8a78";
    };
  };

  # Merkezi konfigürasyondan flavor ve accent al
  flavor = config.catppuccin.flavor or "mocha";
  accent = config.catppuccin.accent or "mauve";
  
  # Seçilen flavor'ın renklerini al
  colors = catppuccinColors.${flavor};
  
  # Discord Catppuccin tema CSS'i
  discordTheme = {
    css = ''
      /**
       * @name Catppuccin ${flavor}
       * @author kenanpelit 
       * @version 2.0
       * @description Discord theme using Catppuccin ${flavor} with ${accent} accent
       */
      :root {
        /* Primary Colors */
        --interactive-normal: #${colors.text};
        --text-normal: #${colors.text}; 
        --text-muted: #${colors.subtext0};
        --text-link: #${colors.${accent}};
        --header-primary: #${colors.text};
        --header-secondary: #${colors.subtext1};
        
        /* Background Colors */
        --background-primary: #${colors.base};
        --background-secondary: #${colors.mantle};
        --background-tertiary: #${colors.crust};
        --background-secondary-alt: #${colors.crust};
        --background-floating: #${colors.base};
        --background-mobile-primary: #${colors.base};
        --background-mobile-secondary: #${colors.mantle};
        --background-accent: #${colors.${accent}};
        --background-message-hover: #${colors.surface0};
        
        /* Surface Colors */
        --channeltextarea-background: #${colors.surface0};
        --deprecated-panel-background: #${colors.crust};
        --button-background: #${colors.surface0};
        
        /* Brand Colors */
        --brand-experiment: #${colors.${accent}};
        --channels-default: #${colors.${accent}};
      }
      
      /* App Elements */
      .theme-dark {
        --header-primary: #${colors.text};
        --header-secondary: #${colors.subtext0};
        --background-primary: #${colors.base};
        --background-secondary: #${colors.mantle};
        --background-secondary-alt: #${colors.crust};
        --channeltextarea-background: #${colors.surface0};
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
        background-color: #${colors.mantle} !important;
        color: #${colors.text};
      }
      
      /* Syntax Highlighting - Catppuccin colors */
      .hljs-keyword { color: #${colors.red}; }
      .hljs-built_in { color: #${colors.blue}; }
      .hljs-type { color: #${colors.yellow}; }
      .hljs-literal { color: #${colors.mauve}; }
      .hljs-number { color: #${colors.peach}; }
      .hljs-string { color: #${colors.green}; }
      .hljs-function { color: #${colors.teal}; }
      .hljs-comment { color: #${colors.surface2}; font-style: italic; }
      .hljs-deletion { color: #${colors.red}; }
      .hljs-addition { color: #${colors.green}; }
      .hljs-emphasis { font-style: italic; }
      .hljs-strong { font-weight: bold; }
      
      /* UI Elements */
      .scroller::-webkit-scrollbar-thumb { 
        background-color: #${colors.surface0} !important;
        border-radius: 4px;
      }
      .scroller::-webkit-scrollbar-track {
        background-color: #${colors.crust} !important;
      }
      
      /* Accent color highlights */
      .selected-2TbFuo, .clickable-25tGDB:hover {
        background-color: #${colors.${accent}}20 !important;
      }
      
      /* Status indicators */
      .status-1AY8su[fill="#43b581"] { fill: #${colors.green}; }
      .status-1AY8su[fill="#faa61a"] { fill: #${colors.yellow}; }
      .status-1AY8su[fill="#f04747"] { fill: #${colors.red}; }
      .status-1AY8su[fill="#593695"] { fill: #${colors.mauve}; }
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
  # Theme Configuration - Merkezi Catppuccin ile
  # =============================================================================
  xdg.configFile."Vencord/themes/catppuccin-${flavor}.theme.css".text = discordTheme.css;
}

