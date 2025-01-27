# modules/home/apps/discord/theme.nix
{ kenp, effects, fonts }:
{
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
}

