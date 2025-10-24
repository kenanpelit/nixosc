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
    border-color: rgba(187, 154, 247, 0.4);
    box-shadow: 0 1px 3px rgba(187, 154, 247, 0.2);
  }

  #workspaces button.empty {
    color: ${custom.subtext_color};
    background-color: ${custom.background_1};
    opacity: 0.5;
  }

  #workspaces button.urgent {
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.15);
    border-color: rgba(247, 118, 142, 0.4);
  }

  #workspaces button:hover:not(.active) {
    color: ${custom.cyan};
    background-color: rgba(125, 207, 255, 0.1);
    border-color: rgba(125, 207, 255, 0.3);
  }

  /* Module specific colors - Tokyo Night Storm pure */
  #bluetooth { 
    color: ${custom.cyan}; 
  }
  #bluetooth.connected { 
    color: ${custom.blue};
    background-color: rgba(122, 162, 247, 0.1);
    border-color: rgba(122, 162, 247, 0.3);
  }
  
  #network { 
    color: ${custom.blue}; 
  }
  #network.disconnected { 
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.05);
  }
  #network.ethernet,
  #network.wifi { 
    color: ${custom.blue};
    background-color: rgba(122, 162, 247, 0.1);
    border-color: rgba(122, 162, 247, 0.3);
  }

  #battery { 
    color: ${custom.magenta}; 
  }
  #battery.charging { 
    color: ${custom.cyan};
    background-color: rgba(125, 207, 255, 0.1);
    border-color: rgba(125, 207, 255, 0.3);
  }
  #battery.full { 
    color: ${custom.green};
    background-color: rgba(158, 206, 106, 0.1);
    border-color: rgba(158, 206, 106, 0.3);
  }
  #battery.warning:not(.charging) { 
    color: ${custom.orange};
    background-color: rgba(255, 158, 100, 0.08);
  }
  #battery.critical:not(.charging) { 
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.1);
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

  /* VPN module specific styles */
  #custom-vpn { 
    color: ${custom.cyan}; 
  }
  #custom-vpn.connected { 
    color: ${custom.green};
    background-color: rgba(158, 206, 106, 0.1);
    border-color: rgba(158, 206, 106, 0.3);
  }
  #custom-vpn.warning { 
    color: ${custom.orange};
    background-color: rgba(255, 158, 100, 0.1);
    border-color: rgba(255, 158, 100, 0.3);
  }
  #custom-vpn.disconnected { 
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.05);
    border-color: rgba(247, 118, 142, 0.3);
  }

  #mpris {
    background-color: ${custom.background_1};
    padding: 2px 8px;
    min-width: 100px;
    font-weight: 500;
  }

  #mpris.playing { 
    color: ${custom.green};
    background-color: rgba(158, 206, 106, 0.1);
    border-color: rgba(158, 206, 106, 0.3);
  }
  #mpris.paused { 
    color: ${custom.blue};
    background-color: rgba(122, 162, 247, 0.05);
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
    border: 1px solid rgba(125, 207, 255, 0.3);
    border-radius: 8px;
    transition: all 0.25s cubic-bezier(0.25, 0.46, 0.45, 0.94);
    box-shadow: 0 1px 4px rgba(125, 207, 255, 0.05);
  }

  #custom-launcher:hover {
    background-color: rgba(125, 207, 255, 0.1);
    border-color: ${custom.cyan};
    box-shadow: 0 2px 8px rgba(125, 207, 255, 0.15);
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
    background-color: rgba(255, 158, 100, 0.1);
    border-color: ${custom.orange};
  }

  #custom-power {
    color: ${custom.red};
    font-size: 14px;
    margin: 2px 3px 2px 1px;
  }

  #custom-power:hover {
    background-color: rgba(247, 118, 142, 0.1);
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
    background-color: rgba(122, 162, 247, 0.1);
    border-radius: 4px;
  }

  #clock {
    color: ${custom.cyan};
    font-weight: 600;
    padding: 2px 8px;
    background-color: rgba(125, 207, 255, 0.1);
    border-color: rgba(125, 207, 255, 0.3);
    box-shadow: 0 1px 4px rgba(125, 207, 255, 0.05);
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
    background-color: rgba(224, 175, 104, 0.1);
    border-color: rgba(224, 175, 104, 0.3);
  }
  
  #custom-weather.cloudy {
    color: ${custom.cyan};
    background-color: rgba(125, 207, 255, 0.1);
    border-color: rgba(125, 207, 255, 0.3);
  }
  
  #custom-weather.rainy {
    color: ${custom.blue};
    background-color: rgba(122, 162, 247, 0.1);
    border-color: rgba(122, 162, 247, 0.3);
  }
  
  #custom-weather.snowy {
    color: ${custom.text_color};
    background-color: rgba(192, 202, 245, 0.1);
    border-color: rgba(192, 202, 245, 0.3);
  }
  
  #custom-weather:hover {
    background-color: rgba(122, 162, 247, 0.15);
    border-color: ${custom.blue};
  }

  #memory { 
    color: ${custom.magenta}; 
  }
  
  #disk { 
    color: ${custom.orange}; 
  }
  
  /* System Status module - CPU Usage, Temperature & Power (UPDATED) */
  #custom-system-status {
    color: ${custom.cyan};
    font-size: 14px;
    padding: 2px 10px;
    min-width: 90px;
    font-weight: 600;
    background-color: rgba(125, 207, 255, 0.1);
    border-color: rgba(125, 207, 255, 0.3);
  }

  /* Critical state - Yüksek sıcaklık (80°C+) */
  #custom-system-status.critical {
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.2);
    border-color: rgba(247, 118, 142, 0.5);
    animation: critical-pulse 2s ease-in-out infinite;
    box-shadow: 0 2px 12px rgba(247, 118, 142, 0.4);
  }

  /* High state - Yüksek kullanım/sıcaklık (70-79°C veya 80%+ CPU) */
  #custom-system-status.high {
    color: ${custom.magenta};
    background-color: rgba(187, 154, 247, 0.15);
    border-color: rgba(187, 154, 247, 0.4);
    box-shadow: 0 2px 6px rgba(187, 154, 247, 0.2);
  }

  /* Normal state - Orta kullanım (50-79% CPU) */
  #custom-system-status.normal {
    color: ${custom.cyan};
    background-color: rgba(125, 207, 255, 0.1);
    border-color: rgba(125, 207, 255, 0.3);
  }

  /* Low state - Düşük kullanım (<50% CPU) */
  #custom-system-status.low {
    color: ${custom.green};
    background-color: rgba(158, 206, 106, 0.1);
    border-color: rgba(158, 206, 106, 0.3);
  }

  #custom-system-status.error {
    color: ${custom.red};
    opacity: 0.6;
  }

  /* Hover effects */
  #custom-system-status:hover {
    background-color: rgba(125, 207, 255, 0.2);
    border-color: ${custom.cyan};
    box-shadow: 0 2px 8px rgba(125, 207, 255, 0.3);
  }

  #custom-system-status.high:hover {
    background-color: rgba(187, 154, 247, 0.25);
    border-color: ${custom.magenta};
    box-shadow: 0 2px 8px rgba(187, 154, 247, 0.3);
  }

  #custom-system-status.critical:hover {
    background-color: rgba(247, 118, 142, 0.3);
    border-color: ${custom.red};
    box-shadow: 0 2px 12px rgba(247, 118, 142, 0.5);
  }

  #custom-system-status.low:hover {
    background-color: rgba(158, 206, 106, 0.2);
    border-color: ${custom.green};
    box-shadow: 0 2px 8px rgba(158, 206, 106, 0.2);
  }

  /* Critical pulse animation */
  @keyframes critical-pulse {
    0% {
      box-shadow: 0 2px 12px rgba(247, 118, 142, 0.4);
      border-color: rgba(247, 118, 142, 0.5);
    }
    50% {
      box-shadow: 0 2px 16px rgba(247, 118, 142, 0.6);
      border-color: rgba(247, 118, 142, 0.7);
    }
    100% {
      box-shadow: 0 2px 12px rgba(247, 118, 142, 0.4);
      border-color: rgba(247, 118, 142, 0.5);
    }
  }

  /* Mako Notifications module */
  #custom-mako-notifications {
    color: ${custom.cyan};
    font-weight: 600;
    padding: 2px 8px;
    min-width: 30px;
    background-color: rgba(125, 207, 255, 0.05);
    border-color: rgba(125, 207, 255, 0.2);
    transition: all 0.25s cubic-bezier(0.25, 0.46, 0.45, 0.94);
  }

  #custom-mako-notifications.unread {
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.15);
    border-color: rgba(247, 118, 142, 0.4);
    animation: notification-pulse 2s ease-in-out infinite;
    box-shadow: 0 2px 8px rgba(247, 118, 142, 0.3);
  }

  #custom-mako-notifications.read {
    color: ${custom.green};
    background-color: rgba(158, 206, 106, 0.1);
    border-color: rgba(158, 206, 106, 0.3);
  }

  #custom-mako-notifications.none {
    color: ${custom.subtext_color};
    opacity: 0.6;
    background-color: ${custom.background_1};
    border-color: ${custom.border_color};
  }

  #custom-mako-notifications.error {
    color: ${custom.red};
    background-color: rgba(247, 118, 142, 0.1);
    border-color: rgba(247, 118, 142, 0.3);
    opacity: 0.8;
  }

  #custom-mako-notifications:hover {
    background-color: rgba(125, 207, 255, 0.2);
    border-color: ${custom.cyan};
    box-shadow: 0 2px 8px rgba(125, 207, 255, 0.2);
  }

  #custom-mako-notifications.unread:hover {
    background-color: rgba(247, 118, 142, 0.25);
    border-color: ${custom.red};
    box-shadow: 0 2px 12px rgba(247, 118, 142, 0.4);
  }

  /* Pulse animation for unread notifications */
  @keyframes notification-pulse {
    0% {
      box-shadow: 0 2px 8px rgba(247, 118, 142, 0.3);
    }
    50% {
      box-shadow: 0 2px 12px rgba(247, 118, 142, 0.5);
    }
    100% {
      box-shadow: 0 2px 8px rgba(247, 118, 142, 0.3);
    }
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
  #memory:hover,
  #disk:hover,
  #network:hover,
  #battery:hover,
  #clock:hover,
  #language:hover,
  #mpris:hover {
    background-color: rgba(122, 162, 247, 0.15);
    border-color: ${custom.blue};
    box-shadow: 0 2px 6px rgba(122, 162, 247, 0.15);
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
