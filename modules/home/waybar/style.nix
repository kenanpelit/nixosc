# modules/home/waybar/style.nix
{ custom }:
''
  * {
    border: none;
    border-radius: 0;
    font-family: ${custom.font};
    font-weight: ${custom.font_weight};
    font-size: ${custom.font_size};
    min-height: 0;
    transition: all 0.25s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  }

  window#waybar {
    background: ${custom.background_0};
    color: ${custom.text_color};
    border-top: 1px solid ${custom.border_color};
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.12);
  }

  window#waybar.bottom {
    border-top: none;
    border-bottom: 1px solid ${custom.border_color};
    box-shadow: 0 -2px 12px rgba(0, 0, 0, 0.12);
  }

  /* Common style for all modules */
  #workspaces,
  #bluetooth,
  #custom-vpn,
  #custom-todo,
  #custom-weather,
  #custom-waybar-mpris,
  #pulseaudio,
  #pulseaudio#source,
  #pulseaudio#sink,
  #network,
  #cpu,
  #temperature,
  #memory,
  #disk,
  #battery,
  #clock,
  #language,
  #tray,
  #mpris {
    background-color: ${custom.background_1};
    padding: 2px 6px;
    margin: 2px 1px;
    border: 1px solid ${custom.border_color};
    border-radius: 6px;
    transition: all 0.25s cubic-bezier(0.25, 0.46, 0.45, 0.94);
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  }

  /* Workspace specific styles */
  #workspaces {
    margin: 2px 1px;
    padding: 1px;
    background: transparent;
    box-shadow: none;
    border: none;
  }

  #workspaces button {
    min-height: 18px;
    min-width: 18px;
    padding: 1px 5px;
    margin: 0 1px;
    border-radius: 5px;
    color: ${custom.blue};
    background-color: ${custom.background_1};
    transition: all 0.25s cubic-bezier(0.25, 0.46, 0.45, 0.94);
    border: 1px solid ${custom.border_color};
    font-weight: 500;
  }

  #workspaces button.active {
    color: ${custom.magenta};
    background-color: ${custom.magenta}33;  /* Tokyo Night magenta with 20% opacity */
    border-color: ${custom.magenta}66;      /* Tokyo Night magenta with 40% opacity */
    box-shadow: 0 1px 3px ${custom.magenta}33;
  }

  #workspaces button.empty {
    color: ${custom.subtext_color};
    background-color: ${custom.background_1};
    opacity: 0.5;
  }

  #workspaces button.urgent {
    color: ${custom.red};
    background-color: ${custom.red}26;      /* Tokyo Night red with 15% opacity */
    border-color: ${custom.red}66;         /* Tokyo Night red with 40% opacity */
  }

  #workspaces button:hover:not(.active) {
    color: ${custom.cyan};
    background-color: ${custom.cyan}1a;     /* Tokyo Night cyan with 10% opacity */
    border-color: ${custom.cyan}4d;        /* Tokyo Night cyan with 30% opacity */
  }

  /* Module specific colors - Tokyo Night Storm pure */
  #bluetooth { 
    color: ${custom.cyan}; 
  }
  #bluetooth.connected { 
    color: ${custom.blue};
    background-color: ${custom.blue}1a;     /* Tokyo Night blue with 10% opacity */
    border-color: ${custom.blue}4d;        /* Tokyo Night blue with 30% opacity */
  }
  
  #network { 
    color: ${custom.blue}; 
  }
  #network.disconnected { 
    color: ${custom.red};
    background-color: ${custom.red}0d;      /* Tokyo Night red with 5% opacity */
  }
  #network.ethernet,
  #network.wifi { 
    color: ${custom.blue};
    background-color: ${custom.blue}1a;     /* Tokyo Night blue with 10% opacity */
    border-color: ${custom.blue}4d;        /* Tokyo Night blue with 30% opacity */
  }

  #battery { 
    color: ${custom.magenta}; 
  }
  #battery.charging { 
    color: ${custom.cyan};
    background-color: ${custom.cyan}1a;     /* Tokyo Night cyan with 10% opacity */
    border-color: ${custom.cyan}4d;        /* Tokyo Night cyan with 30% opacity */
  }
  #battery.full { 
    color: ${custom.green};
    background-color: ${custom.green}1a;    /* Tokyo Night green with 10% opacity */
    border-color: ${custom.green}4d;       /* Tokyo Night green with 30% opacity */
  }
  #battery.warning:not(.charging) { 
    color: ${custom.orange};
    background-color: ${custom.orange}14;   /* Tokyo Night orange with 8% opacity */
  }
  #battery.critical:not(.charging) { 
    color: ${custom.red};
    background-color: ${custom.red}1a;      /* Tokyo Night red with 10% opacity */
  }

  #pulseaudio { 
    color: ${custom.magenta}; 
  }
  #pulseaudio.muted { 
    color: ${custom.red};
    opacity: 0.6;
  }
  
  #pulseaudio#sink { 
    color: ${custom.magenta}; 
  }
  #pulseaudio#sink.muted { 
    color: ${custom.red};
    opacity: 0.6;
  }
  
  #pulseaudio#source { 
    color: ${custom.cyan}; 
  }
  #pulseaudio#source.muted { 
    color: ${custom.red};
    opacity: 0.6;
  }
  
  #cpu { 
    color: ${custom.green}; 
  }
  
  #memory { 
    color: ${custom.magenta}; 
  }
  
  #disk { 
    color: ${custom.orange}; 
  }
  
  #temperature {
    color: ${custom.green};
  }
  #temperature.critical {
    color: ${custom.red};
    background-color: ${custom.red}1a;      /* Tokyo Night red with 10% opacity */
  }

  /* VPN module specific styles */
  #custom-vpn { 
    color: ${custom.cyan}; 
  }
  #custom-vpn.connected { 
    color: ${custom.green};
    background-color: ${custom.green}1a;    /* Tokyo Night green with 10% opacity */
    border-color: ${custom.green}4d;       /* Tokyo Night green with 30% opacity */
  }
  #custom-vpn.warning { 
    color: ${custom.orange};
    background-color: ${custom.orange}1a;   /* Tokyo Night orange with 10% opacity */
    border-color: ${custom.orange}4d;      /* Tokyo Night orange with 30% opacity */
  }
  #custom-vpn.disconnected { 
    color: ${custom.red};
    background-color: ${custom.red}0d;      /* Tokyo Night red with 5% opacity */
    border-color: ${custom.red}4d;         /* Tokyo Night red with 30% opacity */
  }

  #mpris {
    background-color: ${custom.background_1};
    padding: 2px 8px;
    min-width: 100px;
    font-weight: 500;
  }

  #mpris.playing { 
    color: ${custom.green};
    background-color: ${custom.green}1a;    /* Tokyo Night green with 10% opacity */
    border-color: ${custom.green}4d;       /* Tokyo Night green with 30% opacity */
  }
  #mpris.paused { 
    color: ${custom.blue};
    background-color: ${custom.blue}0d;     /* Tokyo Night blue with 5% opacity */
  }
  #mpris.stopped { 
    color: ${custom.red};
    opacity: 0.7;
  }

  #custom-launcher {
    color: ${custom.cyan};
    font-size: 18px;
    padding: 2px 8px;
    margin: 2px 4px 2px 3px;
    background: ${custom.background_1};
    border: 1px solid ${custom.cyan}4d;     /* Tokyo Night cyan with 30% opacity */
    border-radius: 8px;
    transition: all 0.25s cubic-bezier(0.25, 0.46, 0.45, 0.94);
    box-shadow: 0 1px 4px ${custom.cyan}0d; /* Tokyo Night cyan with 5% opacity */
  }

  #custom-launcher:hover {
    background-color: ${custom.cyan}1a;     /* Tokyo Night cyan with 10% opacity */
    border-color: ${custom.cyan};
    box-shadow: 0 2px 8px ${custom.cyan}26; /* Tokyo Night cyan with 15% opacity */
  }

  /* System icons */
  #custom-notification,
  #custom-power {
    background-color: ${custom.background_1};
    padding: 2px 6px;
    margin: 2px 1px;
    border: 1px solid ${custom.border_color};
    border-radius: 6px;
    min-width: 20px;
    font-size: 14px;
    transition: all 0.25s cubic-bezier(0.25, 0.46, 0.45, 0.94);
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  }

  #custom-notification {
    color: ${custom.orange};
    font-size: 14px;
    margin-right: 3px;
  }

  #custom-notification:hover {
    background-color: ${custom.orange}1a;   /* Tokyo Night orange with 10% opacity */
    border-color: ${custom.orange};
  }

  #custom-power {
    color: ${custom.red};
    font-size: 15px;
    margin: 2px 3px 2px 1px;
  }

  #custom-power:hover {
    background-color: ${custom.red}1a;      /* Tokyo Night red with 10% opacity */
    border-color: ${custom.red};
  }

  #tray {
    margin: 2px 3px;
    padding: 2px 6px;
  }

  #tray menu {
    background: ${custom.background_1};
    border: 1px solid ${custom.border_color};
    border-radius: 6px;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.2);
  }

  #tray menuitem {
    color: ${custom.text_color};
    transition: all 0.2s ease;
    padding: 4px 8px;
  }

  #tray menuitem:hover {
    background-color: ${custom.blue}1a;     /* Tokyo Night blue with 10% opacity */
    border-radius: 4px;
  }

  #clock {
    color: ${custom.cyan};
    font-weight: 600;
    padding: 2px 8px;
    background-color: ${custom.cyan}1a;     /* Tokyo Night cyan with 10% opacity */
    border-color: ${custom.cyan}4d;        /* Tokyo Night cyan with 30% opacity */
    box-shadow: 0 1px 4px ${custom.cyan}0d; /* Tokyo Night cyan with 5% opacity */
  }

  #language {
    color: ${custom.magenta};
    font-weight: 600;
    padding: 2px 6px;
  }

  /* Weather module */
  #custom-weather {
    color: ${custom.blue};
    font-size: 14px;
    padding: 2px 8px;
    min-width: 60px;
    font-weight: 500;
  }
  
  #custom-weather.sunny {
    color: ${custom.yellow};
    background-color: ${custom.yellow}1a;   /* Tokyo Night yellow with 10% opacity */
    border-color: ${custom.yellow}4d;      /* Tokyo Night yellow with 30% opacity */
  }
  
  #custom-weather.cloudy {
    color: ${custom.cyan};
    background-color: ${custom.cyan}1a;     /* Tokyo Night cyan with 10% opacity */
    border-color: ${custom.cyan}4d;        /* Tokyo Night cyan with 30% opacity */
  }
  
  #custom-weather.rainy {
    color: ${custom.blue};
    background-color: ${custom.blue}1a;     /* Tokyo Night blue with 10% opacity */
    border-color: ${custom.blue}4d;        /* Tokyo Night blue with 30% opacity */
  }
  
  #custom-weather.snowy {
    color: ${custom.text_color};
    background-color: ${custom.text_color}1a; /* Tokyo Night text with 10% opacity */
    border-color: ${custom.text_color}4d;     /* Tokyo Night text with 30% opacity */
  }
  
  #custom-weather:hover {
    background-color: ${custom.blue}26;     /* Tokyo Night blue with 15% opacity */
    border-color: ${custom.blue};
  }

  #custom-todo {
    color: ${custom.yellow};
    font-style: italic;
    font-weight: 500;
  }

  /* Subtle hover effects */
  #bluetooth:hover,
  #custom-vpn:hover,
  #custom-todo:hover,
  #custom-waybar-mpris:hover,
  #pulseaudio:hover,
  #pulseaudio#source:hover,
  #pulseaudio#sink:hover,
  #network:hover,
  #cpu:hover,
  #temperature:hover,
  #memory:hover,
  #disk:hover,
  #battery:hover,
  #clock:hover,
  #language:hover,
  #mpris:hover {
    background-color: ${custom.blue}26;     /* Tokyo Night blue with 15% opacity */
    border-color: ${custom.blue};
    box-shadow: 0 2px 6px ${custom.blue}26; /* Tokyo Night blue with 15% opacity */
  }

  tooltip {
    background: ${custom.background_1};
    border: 1px solid ${custom.border_color};
    border-radius: 6px;
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
  }

  tooltip label {
    color: ${custom.text_color};
    padding: 6px 8px;
    font-weight: 500;
  }
''

