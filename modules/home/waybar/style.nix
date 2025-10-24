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
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  }

  window#waybar {
    background: ${custom.background_0};
    color: ${custom.text_color};
    border-top: 1px solid ${custom.border_color};
    box-shadow: 0 3px 15px rgba(0, 0, 0, 0.15);
  }

  window#waybar.bottom {
    border-top: none;
    border-bottom: 1px solid ${custom.border_color};
    box-shadow: 0 -3px 15px rgba(0, 0, 0, 0.15);
  }

  /* Common style for all modules - kompakt ve zarif */
  #workspaces,
  #bluetooth,
  #custom-vpn,
  #custom-mako-notifications,
  #custom-todo,
  #custom-weather,
  #custom-system-status,
  #custom-waybar-mpris,
  #pulseaudio,
  #pulseaudio#source,
  #pulseaudio#sink,
  #memory,
  #disk,
  #network,
  #battery,
  #clock,
  #language,
  #tray,
  #mpris,
  #window {
    background-color: ${custom.background_1};
    padding: 3px 8px;
    margin: 3px 2px;
    border: 1px solid ${custom.border_color};
    border-radius: 8px;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
  }

  /* Workspace specific styles - modern pill şekli */
  #workspaces {
    margin: 3px 2px;
    padding: 2px;
    background: transparent;
    box-shadow: none;
    border: none;
  }

  #workspaces button {
    min-height: 20px;
    min-width: 20px;
    padding: 2px 7px;
    margin: 0 2px;
    border-radius: 7px;
    color: ${custom.blue};
    background-color: ${custom.background_1};
    border: 1px solid ${custom.border_color};
    font-weight: 600;
    font-size: 13px;
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  }

  #workspaces button.active {
    color: ${custom.magenta};
    background-color: alpha(${custom.magenta}, 0.2);
    border: 2px solid alpha(${custom.magenta}, 0.45);
    box-shadow: 0 2px 6px alpha(${custom.magenta}, 0.25);
    font-weight: 700;
  }

  #workspaces button.empty {
    color: ${custom.subtext_color};
    background-color: ${custom.background_1};
    opacity: 0.5;
  }

  #workspaces button.urgent {
    color: ${custom.red};
    background-color: alpha(${custom.red}, 0.18);
    border: 2px solid alpha(${custom.red}, 0.5);
    box-shadow: 0 2px 8px alpha(${custom.red}, 0.3);
  }

  #workspaces button:hover:not(.active) {
    color: ${custom.cyan};
    background-color: alpha(${custom.cyan}, 0.12);
    border: 2px solid alpha(${custom.cyan}, 0.35);
    box-shadow: 0 2px 6px alpha(${custom.cyan}, 0.2);
  }

  /* Window title - zarif ve minimal */
  #window {
    color: ${custom.text_secondary};
    font-weight: 500;
    padding: 3px 10px;
    background-color: ${custom.background_1};
    border: 1px solid alpha(${custom.border_color}, 0.5);
    min-width: 120px;
  }

  /* Launcher - öne çıkan ama abartısız */
  #custom-launcher {
    color: ${custom.cyan};
    font-size: 18px;
    padding: 3px 10px;
    margin: 3px 4px 3px 3px;
    background: ${custom.background_1};
    border: 1px solid alpha(${custom.cyan}, 0.35);
    border-radius: 9px;
    box-shadow: 0 2px 6px alpha(${custom.cyan}, 0.08);
    font-weight: 700;
  }

  #custom-launcher:hover {
    background-color: alpha(${custom.cyan}, 0.12);
    border: 2px solid alpha(${custom.cyan}, 0.5);
    box-shadow: 0 3px 10px alpha(${custom.cyan}, 0.2);
  }

  /* Clock - vurgulu ama dengeli */
  #clock {
    color: ${custom.cyan};
    font-weight: 700;
    font-size: 14px;
    padding: 3px 10px;
    background-color: alpha(${custom.cyan}, 0.12);
    border-color: alpha(${custom.cyan}, 0.35);
    box-shadow: 0 2px 6px alpha(${custom.cyan}, 0.1);
  }

  #clock:hover {
    background-color: alpha(${custom.cyan}, 0.2);
    border: 2px solid alpha(${custom.cyan}, 0.5);
    box-shadow: 0 3px 8px alpha(${custom.cyan}, 0.2);
  }

  /* Module specific colors - consistent with original */
  #bluetooth { 
    color: ${custom.cyan}; 
  }
  
  #bluetooth.connected { 
    color: ${custom.blue};
    background-color: alpha(${custom.blue}, 0.12);
    border: 2px solid alpha(${custom.blue}, 0.35);
    box-shadow: 0 2px 6px alpha(${custom.blue}, 0.15);
  }
  
  #network { 
    color: ${custom.blue}; 
  }
  
  #network.disconnected { 
    color: ${custom.red};
    background-color: alpha(${custom.red}, 0.08);
    opacity: 0.7;
  }
  
  #network.ethernet,
  #network.wifi { 
    color: ${custom.blue};
    background-color: alpha(${custom.blue}, 0.12);
    border: 2px solid alpha(${custom.blue}, 0.35);
  }

  /* Battery with clear states */
  #battery { 
    color: ${custom.magenta}; 
    font-weight: 600;
  }
  
  #battery.charging { 
    color: ${custom.cyan};
    background-color: alpha(${custom.cyan}, 0.12);
    border: 2px solid alpha(${custom.cyan}, 0.35);
  }
  
  #battery.full { 
    color: ${custom.green};
    background-color: alpha(${custom.green}, 0.12);
    border: 2px solid alpha(${custom.green}, 0.35);
  }
  
  #battery.warning:not(.charging) { 
    color: ${custom.orange};
    background-color: alpha(${custom.orange}, 0.1);
    border: 2px solid alpha(${custom.orange}, 0.35);
  }
  
  #battery.critical:not(.charging) { 
    color: ${custom.red};
    background-color: alpha(${custom.red}, 0.15);
    border: 2px solid alpha(${custom.red}, 0.5);
    box-shadow: 0 3px 10px alpha(${custom.red}, 0.3);
  }

  /* Audio modules */
  #pulseaudio { 
    color: ${custom.magenta}; 
  }
  
  #pulseaudio.muted { 
    color: ${custom.red};
    opacity: 0.7;
  }
  
  #pulseaudio#sink { 
    color: ${custom.magenta}; 
  }
  
  #pulseaudio#sink.muted { 
    color: ${custom.red};
    background-color: alpha(${custom.red}, 0.08);
    opacity: 0.7;
  }
  
  #pulseaudio#source { 
    color: ${custom.cyan}; 
  }
  
  #pulseaudio#source.muted { 
    color: ${custom.red};
    background-color: alpha(${custom.red}, 0.08);
    opacity: 0.7;
  }

  /* VPN module - clear status indicators */
  #custom-vpn { 
    color: ${custom.cyan}; 
  }
  
  #custom-vpn.connected { 
    color: ${custom.green};
    background-color: alpha(${custom.green}, 0.12);
    border: 2px solid alpha(${custom.green}, 0.35);
  }
  
  #custom-vpn.warning { 
    color: ${custom.orange};
    background-color: alpha(${custom.orange}, 0.1);
    border: 2px solid alpha(${custom.orange}, 0.35);
  }
  
  #custom-vpn.disconnected { 
    color: ${custom.red};
    background-color: alpha(${custom.red}, 0.08);
    border-color: alpha(${custom.red}, 0.35);
  }

  /* Media player */
  #mpris {
    background-color: ${custom.background_1};
    padding: 3px 10px;
    min-width: 100px;
    font-weight: 600;
  }

  #mpris.playing { 
    color: ${custom.green};
    background-color: alpha(${custom.green}, 0.12);
    border: 2px solid alpha(${custom.green}, 0.35);
  }
  
  #mpris.paused { 
    color: ${custom.blue};
    background-color: alpha(${custom.blue}, 0.08);
    opacity: 0.8;
  }
  
  #mpris.stopped { 
    color: ${custom.red};
    opacity: 0.7;
  }

  /* System status module - improved hierarchy */
  #custom-system-status {
    color: ${custom.cyan};
    font-size: 14px;
    padding: 3px 12px;
    min-width: 90px;
    font-weight: 700;
    background-color: alpha(${custom.cyan}, 0.12);
    border-color: alpha(${custom.cyan}, 0.35);
  }

  #custom-system-status.critical {
    color: ${custom.red};
    background-color: alpha(${custom.red}, 0.2);
    border: 2px solid alpha(${custom.red}, 0.55);
    box-shadow: 0 3px 12px alpha(${custom.red}, 0.35);
  }

  #custom-system-status.high {
    color: ${custom.magenta};
    background-color: alpha(${custom.magenta}, 0.15);
    border: 2px solid alpha(${custom.magenta}, 0.45);
    box-shadow: 0 2px 8px alpha(${custom.magenta}, 0.2);
  }

  #custom-system-status.normal {
    color: ${custom.cyan};
    background-color: alpha(${custom.cyan}, 0.12);
    border-color: alpha(${custom.cyan}, 0.35);
  }

  #custom-system-status.low {
    color: ${custom.green};
    background-color: alpha(${custom.green}, 0.12);
    border-color: alpha(${custom.green}, 0.35);
  }

  #custom-system-status.error {
    color: ${custom.red};
    opacity: 0.6;
  }

  #custom-system-status:hover {
    background-color: alpha(${custom.cyan}, 0.2);
    border: 2px solid ${custom.cyan};
    box-shadow: 0 3px 10px alpha(${custom.cyan}, 0.25);
  }

  #custom-system-status.high:hover {
    background-color: alpha(${custom.magenta}, 0.25);
    border: 2px solid ${custom.magenta};
    box-shadow: 0 3px 10px alpha(${custom.magenta}, 0.3);
  }

  #custom-system-status.critical:hover {
    background-color: alpha(${custom.red}, 0.3);
    border: 2px solid ${custom.red};
    box-shadow: 0 4px 14px alpha(${custom.red}, 0.45);
  }

  #custom-system-status.low:hover {
    background-color: alpha(${custom.green}, 0.2);
    border: 2px solid ${custom.green};
    box-shadow: 0 3px 10px alpha(${custom.green}, 0.2);
  }

  /* Weather module - refined */
  #custom-weather {
    color: ${custom.blue};
    font-size: 14px;
    padding: 3px 10px;
    min-width: 65px;
    font-weight: 600;
  }
  
  #custom-weather.sunny {
    color: ${custom.yellow};
    background-color: alpha(${custom.yellow}, 0.12);
    border: 2px solid alpha(${custom.yellow}, 0.35);
  }
  
  #custom-weather.cloudy {
    color: ${custom.cyan};
    background-color: alpha(${custom.cyan}, 0.12);
    border-color: alpha(${custom.cyan}, 0.35);
  }
  
  #custom-weather.rainy {
    color: ${custom.blue};
    background-color: alpha(${custom.blue}, 0.12);
    border: 2px solid alpha(${custom.blue}, 0.35);
  }
  
  #custom-weather.snowy {
    color: ${custom.text_color};
    background-color: alpha(${custom.surface_1}, 0.2);
    border-color: alpha(${custom.surface_1}, 0.4);
  }
  
  #custom-weather:hover {
    background-color: alpha(${custom.blue}, 0.18);
    border: 2px solid ${custom.blue};
  }

  /* Mako Notifications - clear status */
  #custom-mako-notifications {
    color: ${custom.cyan};
    font-weight: 700;
    padding: 3px 10px;
    min-width: 32px;
    background-color: alpha(${custom.cyan}, 0.08);
    border-color: alpha(${custom.cyan}, 0.25);
  }

  #custom-mako-notifications.unread {
    color: ${custom.red};
    background-color: alpha(${custom.red}, 0.18);
    border: 2px solid alpha(${custom.red}, 0.45);
    box-shadow: 0 2px 10px alpha(${custom.red}, 0.3);
  }

  #custom-mako-notifications.read {
    color: ${custom.green};
    background-color: alpha(${custom.green}, 0.12);
    border-color: alpha(${custom.green}, 0.35);
  }

  #custom-mako-notifications.none {
    color: ${custom.subtext_color};
    opacity: 0.6;
    background-color: ${custom.background_1};
    border-color: ${custom.border_color};
  }

  #custom-mako-notifications.error {
    color: ${custom.red};
    background-color: alpha(${custom.red}, 0.12);
    border-color: alpha(${custom.red}, 0.35);
    opacity: 0.8;
  }

  #custom-mako-notifications:hover {
    background-color: alpha(${custom.cyan}, 0.15);
    border: 2px solid ${custom.cyan};
    box-shadow: 0 2px 8px alpha(${custom.cyan}, 0.2);
  }

  #custom-mako-notifications.unread:hover {
    background-color: alpha(${custom.red}, 0.28);
    border: 2px solid ${custom.red};
    box-shadow: 0 3px 12px alpha(${custom.red}, 0.4);
  }

  /* Todo list - subtle emphasis */
  #custom-todo {
    color: ${custom.yellow};
    font-style: italic;
    font-weight: 500;
  }

  /* System resources */
  #memory { 
    color: ${custom.magenta}; 
    font-weight: 600;
  }
  
  #disk { 
    color: ${custom.orange}; 
    font-weight: 600;
  }

  /* System icons - minimal and functional */
  #custom-notification,
  #custom-power {
    background-color: ${custom.background_1};
    padding: 3px 8px;
    margin: 3px 2px;
    border: 1px solid ${custom.border_color};
    border-radius: 8px;
    min-width: 22px;
    font-size: 14px;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
  }

  #custom-notification {
    color: ${custom.orange};
    margin-right: 3px;
  }

  #custom-notification:hover {
    background-color: alpha(${custom.orange}, 0.12);
    border: 2px solid ${custom.orange};
  }

  #custom-power {
    color: ${custom.red};
    margin: 3px 3px 3px 2px;
  }

  #custom-power:hover {
    background-color: alpha(${custom.red}, 0.12);
    border: 2px solid ${custom.red};
  }

  /* System tray - clean integration */
  #tray {
    margin: 3px 3px;
    padding: 3px 8px;
  }

  #tray menu {
    background: ${custom.background_1};
    border: 1px solid ${custom.border_color};
    border-radius: 8px;
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.25);
  }

  #tray menuitem {
    color: ${custom.text_color};
    padding: 6px 10px;
    border-radius: 6px;
  }

  #tray menuitem:hover {
    background-color: alpha(${custom.blue}, 0.15);
  }

  /* Language indicator */
  #language {
    color: ${custom.magenta};
    font-weight: 600;
    padding: 3px 8px;
  }

  /* Unified hover effects - subtle but noticeable */
  #bluetooth:hover,
  #custom-vpn:hover,
  #custom-todo:hover,
  #custom-waybar-mpris:hover,
  #pulseaudio:hover,
  #pulseaudio#source:hover,
  #pulseaudio#sink:hover,
  #memory:hover,
  #disk:hover,
  #network:hover,
  #battery:hover,
  #language:hover,
  #mpris:hover,
  #window:hover {
    background-color: alpha(${custom.blue}, 0.15);
    border: 2px solid alpha(${custom.blue}, 0.4);
    box-shadow: 0 3px 8px alpha(${custom.blue}, 0.15);
  }

  /* Tooltip - clean and readable */
  tooltip {
    background: ${custom.background_1};
    border: 1px solid ${custom.border_color};
    border-radius: 8px;
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.25);
  }

  tooltip label {
    color: ${custom.text_color};
    padding: 7px 10px;
    font-weight: 500;
  }
''
