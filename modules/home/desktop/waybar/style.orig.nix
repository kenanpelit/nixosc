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
      transition: 0.3s;
    }

    window#waybar {
      background: ${custom.background_0};
      color: ${custom.text_color};
      border-top: 1px solid ${custom.border_color};
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
      padding: 1px 6px;
      margin: 2px 2px;
      border: 1px solid ${custom.border_color};
      border-radius: 6px;
      transition: all 0.2s ease;
    }

    /* Workspace specific styles */
    #workspaces {
      margin: 2px 2px;
      padding: 0;
      background: transparent;
    }

    #workspaces button {
      min-height: 20px;
      min-width: 20px;
      padding: 1px 6px;
      margin: 0 2px;
      border-radius: 6px;
      color: ${custom.blue};
      background-color: ${custom.background_1};
      transition: all 0.2s ease;
      border: 1px solid ${custom.border_color};
    }

    #workspaces button.active {
      color: ${custom.magenta};
      background-color: rgba(122, 162, 247, 0.2);
      border-color: ${custom.blue};
    }

    #workspaces button.empty {
      color: ${custom.text_color};
      background-color: ${custom.background_1};
      opacity: 0.8;
    }

    #workspaces button.urgent {
      color: ${custom.red};
      background-color: rgba(247, 118, 142, 0.2);
      border-color: ${custom.red};
      animation: workspace_urgent 1s ease-in-out infinite;
    }

    /* Module specific colors */
    #bluetooth { color: ${custom.cyan}; }
    #bluetooth.connected { color: ${custom.blue}; }
    
    #network { color: ${custom.blue}; }
    #network.disconnected { color: ${custom.red}; }
    #network.ethernet,
    #network.wifi { color: ${custom.blue}; }

    #battery { color: ${custom.magenta}; }
    #battery.charging { color: ${custom.cyan}; }
    #battery.full { color: ${custom.green}; }
    #battery.warning:not(.charging) { color: ${custom.orange}; }
    #battery.critical:not(.charging) { 
      color: ${custom.red};
      animation: blink-critical 1s infinite;
    }

    #pulseaudio { color: ${custom.magenta}; }
    #pulseaudio.muted { color: ${custom.red}; }
    
    #pulseaudio#sink { color: ${custom.magenta}; }
    #pulseaudio#sink.muted { color: ${custom.red}; }
    
    #pulseaudio#source { color: ${custom.cyan}; }
    #pulseaudio#source.muted { color: ${custom.red}; }
    
    #cpu { color: ${custom.green}; }
    #memory { color: ${custom.magenta}; }
    #disk { color: ${custom.orange}; }
    
    #custom-vpnstatus.connected,
    #custom-vpnmullvad.connected,
    #custom-vpnother.connected { color: ${custom.green}; }
    
    #custom-vpnstatus.disconnected,
    #custom-vpnmullvad.disconnected,
    #custom-vpnother.disconnected { color: ${custom.red}; }

    #mpris {
      background-color: ${custom.background_1};
    }

    #mpris.playing { color: ${custom.green}; }
    #mpris.paused { color: ${custom.blue}; }
    #mpris.stopped { color: ${custom.red}; }

    #custom-launcher {
      color: ${custom.cyan};
      font-size: 20px;
      padding: 0 10px;
      margin: 4px 8px 4px 4px;
      background: ${custom.background_1};
      border: 1px solid ${custom.border_color};
      border-radius: 6px;
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
      padding: 0 8px;
      margin: 4px 2px;
      border: 1px solid ${custom.border_color};
      border-radius: 6px;
      min-width: 24px;
      font-size: 16px;
    }

    #custom-notification {
      padding: 0 6px;
      font-size: 15px;
      margin-right: 4px;
      color: ${custom.orange};
    }

    #custom-firewall {
      padding: 0 6px;
      font-size: 15px;
      margin: 4px 2px;
    }

    #custom-power {
      padding: 0 7px;
      font-size: 17px;
      margin: 4px 4px 4px 2px;
      color: ${custom.red};
    }

    #tray {
      margin: 4px 4px;
    }

    #tray menu {
      background: ${custom.background_1};
      border: 1px solid ${custom.border_color};
    }

    #clock {
      color: ${custom.cyan};
    }

    #language {
      color: ${custom.magenta};
    }

    /* Hover effects */
    #bluetooth:hover,
    #custom-vpnstatus:hover,
    #custom-todo:hover,
    #custom-weather:hover,
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
      background-color: rgba(122, 162, 247, 0.1);
      border-color: ${custom.blue};
    }

    #temperature {
      color: ${custom.green};
    }

    #temperature.critical {
      color: ${custom.red};
      animation: blink-critical 1s infinite;
    }

    #temperature:hover {
      background-color: rgba(122, 162, 247, 0.1);
      border-color: ${custom.blue};
    }

    #custom-notification:hover {
      background-color: rgba(224, 175, 104, 0.1);
      border-color: ${custom.orange};
    }

    #custom-firewall:hover {
      background-color: rgba(247, 118, 142, 0.1);
      border-color: ${custom.red};
    }

    #custom-power:hover {
      background-color: rgba(247, 118, 142, 0.1);
      border-color: ${custom.red};
    }

    tooltip {
      background: ${custom.background_1};
      border: 1px solid ${custom.border_color};
      border-radius: 6px;
    }

    tooltip label {
      color: ${custom.text_color};
      padding: 6px;
    }

    /* Weather module specific styling */
    #custom-weather {
      color: ${custom.blue};
      font-size: 16px;
      padding: 0 10px;
      min-width: 60px;
    }
    
    /* Weather condition colors */
    #custom-weather.sunny {
      color: ${custom.yellow};
    }
    
    #custom-weather.cloudy {
      color: ${custom.cyan};
    }
    
    #custom-weather.rainy {
      color: ${custom.blue};
    }
    
    #custom-weather.snowy {
      color: ${custom.text_color};
    }
    
    #custom-weather:hover {
      background-color: rgba(122, 162, 247, 0.1);
      border-color: ${custom.blue};
    }

    @keyframes blink-critical {
      to {
        background-color: ${custom.red};
        color: ${custom.background_1};
      }
    }

    @keyframes workspace_urgent {
      0% {
        box-shadow: 0 0 5px rgba(247, 118, 142, 0.3);
      }
      50% {
        box-shadow: 0 0 10px rgba(247, 118, 142, 0.6);
      }
      100% {
        box-shadow: 0 0 5px rgba(247, 118, 142, 0.3);
      }
    }
  '';
}
