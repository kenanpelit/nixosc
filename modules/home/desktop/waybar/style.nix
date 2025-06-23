# modules/home/desktop/waybar/style.nix
{ custom, ... }:
{
  programs.waybar.style = ''
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
      box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    }

    window#waybar.bottom {
      border-top: none;
      border-bottom: 1px solid ${custom.border_color};
      box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
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
      padding: 2px 8px;
      margin: 3px 2px;
      border: 1px solid ${custom.border_color};
      border-radius: 8px;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
    }

    /* Workspace specific styles */
    #workspaces {
      margin: 2px 2px;
      padding: 0;
      background: transparent;
      box-shadow: none;
      border: none;
    }

    #workspaces button {
      min-height: 20px;
      min-width: 20px;
      padding: 1px 6px;
      margin: 0 2px;
      border-radius: 6px;
      color: ${custom.blue};
      background-color: ${custom.background_1};
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      border: 1px solid ${custom.border_color};
    }

    #workspaces button.active {
      color: ${custom.magenta};
      background-color: rgba(187, 154, 247, 0.15);
      border-color: ${custom.blue};
      box-shadow: 0 2px 8px rgba(122, 162, 247, 0.2);
    }

    #workspaces button.empty {
      color: ${custom.text_color};
      background-color: ${custom.background_1};
      opacity: 0.6;
    }

    #workspaces button.urgent {
      color: ${custom.red};
      background-color: rgba(247, 118, 142, 0.15);
      border-color: ${custom.red};
      animation: workspace_urgent 1s ease-in-out infinite;
    }

    #workspaces button:hover:not(.active) {
      color: ${custom.cyan};
      background-color: rgba(125, 207, 255, 0.1);
      border-color: ${custom.cyan};
      box-shadow: 0 2px 6px rgba(125, 207, 255, 0.15);
    }

    /* Module specific colors */
    #bluetooth { 
      color: ${custom.cyan}; 
    }
    #bluetooth.connected { 
      color: ${custom.blue};
      background-color: rgba(122, 162, 247, 0.1);
    }
    
    #network { 
      color: ${custom.blue}; 
    }
    #network.disconnected { 
      color: ${custom.red};
    }
    #network.ethernet,
    #network.wifi { 
      color: ${custom.blue};
      background-color: rgba(122, 162, 247, 0.1);
    }

    #battery { 
      color: ${custom.magenta}; 
    }
    #battery.charging { 
      color: ${custom.cyan};
      background-color: rgba(125, 207, 255, 0.1);
    }
    #battery.full { 
      color: ${custom.green};
      background-color: rgba(158, 206, 106, 0.1);
    }
    #battery.warning:not(.charging) { 
      color: ${custom.orange};
    }
    #battery.critical:not(.charging) { 
      color: ${custom.red};
      background-color: rgba(247, 118, 142, 0.15);
      animation: blink-critical 1s infinite;
    }

    #pulseaudio { 
      color: ${custom.magenta}; 
    }
    #pulseaudio.muted { 
      color: ${custom.red};
    }
    
    #pulseaudio#sink { 
      color: ${custom.magenta}; 
    }
    #pulseaudio#sink.muted { 
      color: ${custom.red};
    }
    
    #pulseaudio#source { 
      color: ${custom.cyan}; 
    }
    #pulseaudio#source.muted { 
      color: ${custom.red};
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
      animation: blink-critical 1s infinite;
    }
    
    #custom-vpnstatus.connected,
    #custom-vpnmullvad.connected,
    #custom-vpnother.connected { 
      color: ${custom.green};
      background-color: rgba(158, 206, 106, 0.1);
    }
    
    #custom-vpnstatus.disconnected,
    #custom-vpnmullvad.disconnected,
    #custom-vpnother.disconnected { 
      color: ${custom.red};
    }

    #mpris {
      background-color: ${custom.background_1};
      padding: 2px 12px;
      min-width: 120px;
    }

    #mpris.playing { 
      color: ${custom.green};
      background-color: rgba(158, 206, 106, 0.1);
    }
    #mpris.paused { 
      color: ${custom.blue};
    }
    #mpris.stopped { 
      color: ${custom.red};
    }

    #custom-launcher {
      color: ${custom.cyan};
      font-size: 22px;
      padding: 2px 12px;
      margin: 4px 8px 4px 6px;
      background: ${custom.background_1};
      border: 1px solid rgba(125, 207, 255, 0.3);
      border-radius: 10px;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    #custom-launcher:hover {
      background-color: rgba(125, 207, 255, 0.1);
      border-color: ${custom.cyan};
    }

    /* System icons with adjusted sizes */
    #custom-notification,
    #custom-firewall,
    #custom-power {
      background-color: ${custom.background_1};
      padding: 2px 10px;
      margin: 4px 2px;
      border: 1px solid ${custom.border_color};
      border-radius: 8px;
      min-width: 28px;
      font-size: 16px;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    #custom-notification {
      color: ${custom.orange};
      font-size: 15px;
      margin-right: 6px;
    }

    #custom-notification:hover {
      background-color: rgba(255, 158, 100, 0.1);
      border-color: ${custom.orange};
    }

    #custom-firewall {
      font-size: 15px;
      margin: 4px 2px;
    }

    #custom-firewall:hover {
      background-color: rgba(122, 162, 247, 0.1);
      border-color: ${custom.blue};
    }

    #custom-power {
      color: ${custom.red};
      font-size: 17px;
      margin: 4px 6px 4px 2px;
    }

    #custom-power:hover {
      background-color: rgba(247, 118, 142, 0.1);
      border-color: ${custom.red};
    }

    #tray {
      margin: 4px 6px;
      padding: 2px 8px;
    }

    #tray menu {
      background: ${custom.background_1};
      border: 1px solid ${custom.border_color};
      border-radius: 8px;
    }

    #tray menuitem {
      color: ${custom.text_color};
      transition: all 0.2s ease;
    }

    #tray menuitem:hover {
      background-color: rgba(122, 162, 247, 0.1);
    }

    #clock {
      color: ${custom.cyan};
      font-weight: 600;
      padding: 2px 12px;
      background-color: rgba(125, 207, 255, 0.1);
      border-color: rgba(125, 207, 255, 0.3);
    }

    #language {
      color: ${custom.magenta};
      font-weight: 600;
    }

    /* Weather module specific styling */
    #custom-weather {
      color: ${custom.blue};
      font-size: 16px;
      padding: 2px 12px;
      min-width: 80px;
      font-weight: 500;
    }
    
    /* Weather condition colors */
    #custom-weather.sunny {
      color: ${custom.yellow};
      background-color: rgba(224, 175, 104, 0.1);
    }
    
    #custom-weather.cloudy {
      color: ${custom.cyan};
      background-color: rgba(125, 207, 255, 0.1);
    }
    
    #custom-weather.rainy {
      color: ${custom.blue};
      background-color: rgba(122, 162, 247, 0.1);
    }
    
    #custom-weather.snowy {
      color: ${custom.text_color};
      background-color: rgba(192, 202, 245, 0.1);
    }
    
    #custom-weather:hover {
      background-color: rgba(122, 162, 247, 0.15);
      border-color: ${custom.blue};
    }

    #custom-todo {
      color: ${custom.yellow};
      font-style: italic;
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
      background-color: rgba(122, 162, 247, 0.15);
      border-color: ${custom.blue};
    }

    tooltip {
      background: ${custom.background_1};
      border: 1px solid ${custom.border_color};
      border-radius: 8px;
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.2);
    }

    tooltip label {
      color: ${custom.text_color};
      padding: 8px 12px;
      font-weight: 500;
    }

    @keyframes blink-critical {
      to {
        background-color: ${custom.red};
        color: ${custom.background_1};
      }
    }

    @keyframes workspace_urgent {
      from {
        box-shadow: 0 0 5px rgba(247, 118, 142, 0.3);
      }
      to {
        box-shadow: 0 0 10px rgba(247, 118, 142, 0.6);
      }
    }
  '';
}

