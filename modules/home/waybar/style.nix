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
  #custom-vpnstatus,
  #custom-todo,
  #custom-weather,
  #custom-vpnmullvad,
  #custom-vpnother,
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
    background-color: rgba(187, 154, 247, 0.2);
    border-color: ${custom.magenta};
    box-shadow: 0 2px 8px rgba(187, 154, 247, 0.3);
  }

  #workspaces button.empty {
    color: ${custom.text_color};
    background-color: ${custom.background_1};
    opacity: 0.5;
  }

  #workspaces button.urgent {
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.2);
    border-color: ${custom.red};
  }

  #workspaces button:hover:not(.active) {
    color: ${custom.cyan};
    background-color: rgba(125, 207, 255, 0.15);
    border-color: ${custom.cyan};
    box-shadow: 0 2px 6px rgba(125, 207, 255, 0.2);
  }

  /* Module specific colors */
  #bluetooth { 
    color: ${custom.cyan}; 
  }
  #bluetooth.connected { 
    color: ${custom.blue};
    background-color: rgba(122, 162, 247, 0.15);
    border-color: rgba(122, 162, 247, 0.3);
    box-shadow: 0 0 8px rgba(122, 162, 247, 0.2);
  }
  
  #network { 
    color: ${custom.blue}; 
  }
  #network.disconnected { 
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.1);
  }
  #network.ethernet,
  #network.wifi { 
    color: ${custom.blue};
    background-color: rgba(122, 162, 247, 0.15);
    border-color: rgba(122, 162, 247, 0.3);
  }

  #battery { 
    color: ${custom.magenta}; 
  }
  #battery.charging { 
    color: ${custom.cyan};
    background-color: rgba(125, 207, 255, 0.15);
    border-color: rgba(125, 207, 255, 0.3);
  }
  #battery.full { 
    color: ${custom.green};
    background-color: rgba(158, 206, 106, 0.15);
    border-color: rgba(158, 206, 106, 0.3);
  }
  #battery.warning:not(.charging) { 
    color: ${custom.orange};
    background-color: rgba(255, 158, 100, 0.1);
  }
  #battery.critical:not(.charging) { 
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.2);
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
    background-color: rgba(247, 118, 142, 0.2);
  }
  
  #custom-vpnstatus.connected,
  #custom-vpnmullvad.connected,
  #custom-vpnother.connected { 
    color: ${custom.green};
    background-color: rgba(158, 206, 106, 0.15);
    border-color: rgba(158, 206, 106, 0.3);
    box-shadow: 0 0 8px rgba(158, 206, 106, 0.2);
  }
  
  #custom-vpnstatus.disconnected,
  #custom-vpnmullvad.disconnected,
  #custom-vpnother.disconnected { 
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.1);
  }

  #mpris {
    background-color: ${custom.background_1};
    padding: 2px 8px;
    min-width: 100px;
    font-weight: 500;
  }

  #mpris.playing { 
    color: ${custom.green};
    background-color: rgba(158, 206, 106, 0.15);
    border-color: rgba(158, 206, 106, 0.3);
  }
  #mpris.paused { 
    color: ${custom.blue};
    background-color: rgba(122, 162, 247, 0.1);
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
    border: 1px solid rgba(125, 207, 255, 0.4);
    border-radius: 8px;
    transition: all 0.25s cubic-bezier(0.25, 0.46, 0.45, 0.94);
    box-shadow: 0 1px 4px rgba(125, 207, 255, 0.1);
  }

  #custom-launcher:hover {
    background-color: rgba(125, 207, 255, 0.15);
    border-color: ${custom.cyan};
    box-shadow: 0 2px 8px rgba(125, 207, 255, 0.3);
  }

  /* System icons */
  #custom-notification,
  #custom-firewall,
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
    background-color: rgba(255, 158, 100, 0.15);
    border-color: ${custom.orange};
    box-shadow: 0 2px 6px rgba(255, 158, 100, 0.3);
  }

  #custom-firewall {
    font-size: 14px;
    margin: 2px 1px;
  }

  #custom-firewall:hover {
    background-color: rgba(122, 162, 247, 0.15);
    border-color: ${custom.blue};
    box-shadow: 0 2px 6px rgba(122, 162, 247, 0.3);
  }

  #custom-power {
    color: ${custom.red};
    font-size: 15px;
    margin: 2px 3px 2px 1px;
  }

  #custom-power:hover {
    background-color: rgba(247, 118, 142, 0.15);
    border-color: ${custom.red};
    box-shadow: 0 2px 6px rgba(247, 118, 142, 0.3);
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
    background-color: rgba(122, 162, 247, 0.15);
    border-radius: 4px;
  }

  #clock {
    color: ${custom.cyan};
    font-weight: 600;
    padding: 2px 8px;
    background-color: rgba(125, 207, 255, 0.15);
    border-color: rgba(125, 207, 255, 0.4);
    box-shadow: 0 1px 4px rgba(125, 207, 255, 0.1);
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
    background-color: rgba(224, 175, 104, 0.15);
    border-color: rgba(224, 175, 104, 0.3);
  }
  
  #custom-weather.cloudy {
    color: ${custom.cyan};
    background-color: rgba(125, 207, 255, 0.15);
    border-color: rgba(125, 207, 255, 0.3);
  }
  
  #custom-weather.rainy {
    color: ${custom.blue};
    background-color: rgba(122, 162, 247, 0.15);
    border-color: rgba(122, 162, 247, 0.3);
  }
  
  #custom-weather.snowy {
    color: ${custom.text_color};
    background-color: rgba(192, 202, 245, 0.15);
    border-color: rgba(192, 202, 245, 0.3);
  }
  
  #custom-weather:hover {
    background-color: rgba(122, 162, 247, 0.2);
    border-color: ${custom.blue};
    box-shadow: 0 2px 6px rgba(122, 162, 247, 0.3);
  }

  #custom-todo {
    color: ${custom.yellow};
    font-style: italic;
    font-weight: 500;
  }

  /* Hover effects */
  #bluetooth:hover,
  #custom-vpnstatus:hover,
  #custom-todo:hover,
  #custom-vpnmullvad:hover,
  #custom-vpnother:hover,
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
    background-color: rgba(122, 162, 247, 0.2);
    border-color: ${custom.blue};
    box-shadow: 0 2px 6px rgba(122, 162, 247, 0.3);
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

