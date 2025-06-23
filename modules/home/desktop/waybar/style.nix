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
      background: rgba(30, 30, 46, 0.95);
      backdrop-filter: blur(12px);
      color: ${custom.text_color};
      border-top: 1px solid rgba(122, 162, 247, 0.2);
      box-shadow: 0 2px 20px rgba(0, 0, 0, 0.15);
    }

    window#waybar.bottom {
      border-top: none;
      border-bottom: 1px solid rgba(122, 162, 247, 0.2);
      box-shadow: 0 -2px 20px rgba(0, 0, 0, 0.15);
    }

    /* ===== COMMON MODULE STYLES ===== */
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
      background: linear-gradient(135deg, 
        rgba(49, 50, 68, 0.8), 
        rgba(49, 50, 68, 0.6));
      backdrop-filter: blur(8px);
      padding: 2px 8px;
      margin: 3px 2px;
      border: 1px solid rgba(122, 162, 247, 0.2);
      border-radius: 8px;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    }

    /* ===== WORKSPACE STYLES ===== */
    #workspaces {
      margin: 3px 4px;
      padding: 0;
      background: transparent;
      box-shadow: none;
      border: none;
    }

    #workspaces button {
      min-height: 24px;
      min-width: 32px;
      padding: 2px 8px;
      margin: 0 2px;
      border-radius: 8px;
      color: ${custom.blue};
      background: linear-gradient(135deg, 
        rgba(49, 50, 68, 0.8), 
        rgba(49, 50, 68, 0.6));
      backdrop-filter: blur(8px);
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      border: 1px solid rgba(122, 162, 247, 0.2);
      font-size: 14px;
      font-weight: 600;
      animation: slideInWorkspace 0.4s ease-out;
    }

    #workspaces button.active {
      color: ${custom.magenta};
      background: linear-gradient(135deg, 
        rgba(122, 162, 247, 0.3), 
        rgba(122, 162, 247, 0.2));
      border-color: ${custom.blue};
      transform: scale(1.05);
      box-shadow: 0 4px 12px rgba(122, 162, 247, 0.3);
    }

    #workspaces button.empty {
      color: rgba(186, 194, 222, 0.6);
      background: linear-gradient(135deg, 
        rgba(49, 50, 68, 0.4), 
        rgba(49, 50, 68, 0.3));
      opacity: 0.7;
      transform: scale(0.95);
    }

    #workspaces button.urgent {
      color: ${custom.red};
      background: linear-gradient(135deg, 
        rgba(247, 118, 142, 0.3), 
        rgba(247, 118, 142, 0.2));
      border-color: ${custom.red};
      animation: workspace_urgent 1.5s ease-in-out infinite;
    }

    #workspaces button:hover:not(.active) {
      color: ${custom.cyan};
      background: linear-gradient(135deg, 
        rgba(125, 207, 255, 0.2), 
        rgba(125, 207, 255, 0.1));
      border-color: ${custom.cyan};
      transform: scale(1.02);
      box-shadow: 0 3px 10px rgba(125, 207, 255, 0.2);
    }

    /* ===== LAUNCHER STYLES ===== */
    #custom-launcher {
      color: ${custom.cyan};
      font-size: 22px;
      padding: 2px 12px;
      margin: 4px 8px 4px 6px;
      background: linear-gradient(135deg, 
        rgba(125, 207, 255, 0.15), 
        rgba(125, 207, 255, 0.1));
      border: 1px solid rgba(125, 207, 255, 0.3);
      border-radius: 10px;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      backdrop-filter: blur(8px);
    }

    #custom-launcher:hover {
      background: linear-gradient(135deg, 
        rgba(125, 207, 255, 0.25), 
        rgba(125, 207, 255, 0.15));
      border-color: ${custom.cyan};
      transform: scale(1.05);
      box-shadow: 0 4px 15px rgba(125, 207, 255, 0.3);
    }

    /* ===== SYSTEM CONTROL ICONS ===== */
    #custom-notification,
    #custom-firewall,
    #custom-power {
      background: linear-gradient(135deg, 
        rgba(49, 50, 68, 0.8), 
        rgba(49, 50, 68, 0.6));
      backdrop-filter: blur(8px);
      padding: 2px 10px;
      margin: 4px 2px;
      border: 1px solid rgba(122, 162, 247, 0.2);
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
      background: linear-gradient(135deg, 
        rgba(250, 179, 135, 0.2), 
        rgba(250, 179, 135, 0.1));
      border-color: ${custom.orange};
      box-shadow: 0 3px 10px rgba(250, 179, 135, 0.2);
    }

    #custom-firewall {
      font-size: 15px;
      margin: 4px 2px;
    }

    #custom-firewall:hover {
      background: linear-gradient(135deg, 
        rgba(122, 162, 247, 0.2), 
        rgba(122, 162, 247, 0.1));
      border-color: ${custom.blue};
      box-shadow: 0 3px 10px rgba(122, 162, 247, 0.2);
    }

    #custom-power {
      color: ${custom.red};
      font-size: 17px;
      margin: 4px 6px 4px 2px;
    }

    #custom-power:hover {
      background: linear-gradient(135deg, 
        rgba(247, 118, 142, 0.25), 
        rgba(247, 118, 142, 0.15));
      border-color: ${custom.red};
      transform: scale(1.05);
      box-shadow: 0 4px 15px rgba(247, 118, 142, 0.3);
    }

    /* ===== MODULE SPECIFIC COLORS & STATES ===== */
    #bluetooth { 
      color: ${custom.cyan}; 
    }
    #bluetooth.connected { 
      color: ${custom.blue};
      background: linear-gradient(135deg, 
        rgba(122, 162, 247, 0.15), 
        rgba(122, 162, 247, 0.1));
    }
    #bluetooth.disconnected { 
      color: ${custom.red}; 
      opacity: 0.7;
    }
    
    #network { 
      color: ${custom.blue}; 
    }
    #network.disconnected { 
      color: ${custom.red};
      animation: blink-warning 2s ease-in-out infinite;
    }
    #network.ethernet,
    #network.wifi { 
      color: ${custom.blue};
      background: linear-gradient(135deg, 
        rgba(122, 162, 247, 0.15), 
        rgba(122, 162, 247, 0.1));
    }

    #battery { 
      color: ${custom.magenta}; 
    }
    #battery.charging { 
      color: ${custom.cyan};
      background: linear-gradient(135deg, 
        rgba(125, 207, 255, 0.15), 
        rgba(125, 207, 255, 0.1));
    }
    #battery.full { 
      color: ${custom.green};
      background: linear-gradient(135deg, 
        rgba(166, 227, 161, 0.15), 
        rgba(166, 227, 161, 0.1));
    }
    #battery.warning:not(.charging) { 
      color: ${custom.orange};
      animation: pulse-warning 1.5s ease-in-out infinite;
    }
    #battery.critical:not(.charging) { 
      color: ${custom.red};
      background: linear-gradient(135deg, 
        rgba(247, 118, 142, 0.25), 
        rgba(247, 118, 142, 0.15));
      animation: blink-critical 1s infinite;
    }

    #pulseaudio { 
      color: ${custom.magenta}; 
    }
    #pulseaudio.muted { 
      color: ${custom.red};
      opacity: 0.8;
    }
    
    #pulseaudio#sink { 
      color: ${custom.magenta}; 
    }
    #pulseaudio#sink.muted { 
      color: ${custom.red};
      opacity: 0.8;
    }
    
    #pulseaudio#source { 
      color: ${custom.cyan}; 
    }
    #pulseaudio#source.muted { 
      color: ${custom.red};
      opacity: 0.8;
    }
    
    #cpu { 
      color: ${custom.green}; 
    }
    #cpu.high { 
      color: ${custom.orange};
      animation: pulse-warning 2s ease-in-out infinite;
    }
    
    #memory { 
      color: ${custom.magenta}; 
    }
    #memory.high { 
      color: ${custom.orange};
      animation: pulse-warning 2s ease-in-out infinite;
    }
    
    #disk { 
      color: ${custom.orange}; 
    }
    #disk.full { 
      color: ${custom.red};
      animation: blink-warning 2s ease-in-out infinite;
    }
    
    #temperature {
      color: ${custom.green};
    }
    #temperature.critical {
      color: ${custom.red};
      background: linear-gradient(135deg, 
        rgba(247, 118, 142, 0.25), 
        rgba(247, 118, 142, 0.15));
      animation: blink-critical 1s infinite;
    }

    /* ===== VPN STATUS STYLES ===== */
    #custom-vpnstatus.connected,
    #custom-vpnmullvad.connected,
    #custom-vpnother.connected { 
      color: ${custom.green};
      background: linear-gradient(135deg, 
        rgba(166, 227, 161, 0.15), 
        rgba(166, 227, 161, 0.1));
    }
    
    #custom-vpnstatus.disconnected,
    #custom-vpnmullvad.disconnected,
    #custom-vpnother.disconnected { 
      color: ${custom.red};
      opacity: 0.7;
    }

    /* ===== MEDIA PLAYER STYLES ===== */
    #mpris {
      padding: 2px 12px;
      min-width: 120px;
      max-width: 300px;
    }

    #mpris.playing { 
      color: ${custom.green};
      background: linear-gradient(135deg, 
        rgba(166, 227, 161, 0.15), 
        rgba(166, 227, 161, 0.1));
      border-color: rgba(166, 227, 161, 0.3);
    }
    #mpris.paused { 
      color: ${custom.blue};
      opacity: 0.8;
    }
    #mpris.stopped { 
      color: ${custom.red};
      opacity: 0.6;
    }

    /* ===== SPECIAL MODULE STYLES ===== */
    #clock {
      color: ${custom.cyan};
      font-weight: 600;
      padding: 2px 12px;
      background: linear-gradient(135deg, 
        rgba(125, 207, 255, 0.15), 
        rgba(125, 207, 255, 0.1));
      border-color: rgba(125, 207, 255, 0.3);
    }

    #language {
      color: ${custom.magenta};
      font-weight: 600;
    }

    #custom-weather {
      color: ${custom.blue};
      font-size: 16px;
      padding: 2px 12px;
      min-width: 80px;
      font-weight: 500;
    }
    
    #custom-weather.sunny {
      color: ${custom.yellow};
      background: linear-gradient(135deg, 
        rgba(249, 226, 175, 0.15), 
        rgba(249, 226, 175, 0.1));
    }
    
    #custom-weather.cloudy {
      color: ${custom.cyan};
      background: linear-gradient(135deg, 
        rgba(125, 207, 255, 0.15), 
        rgba(125, 207, 255, 0.1));
    }
    
    #custom-weather.rainy {
      color: ${custom.blue};
      background: linear-gradient(135deg, 
        rgba(122, 162, 247, 0.15), 
        rgba(122, 162, 247, 0.1));
    }
    
    #custom-weather.snowy {
      color: ${custom.text_color};
      background: linear-gradient(135deg, 
        rgba(186, 194, 222, 0.15), 
        rgba(186, 194, 222, 0.1));
    }

    #custom-todo {
      color: ${custom.yellow};
      font-style: italic;
      max-width: 200px;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    /* ===== TRAY STYLES ===== */
    #tray {
      margin: 4px 6px;
      padding: 2px 8px;
    }

    #tray menu {
      background: rgba(30, 30, 46, 0.95);
      backdrop-filter: blur(12px);
      border: 1px solid rgba(122, 162, 247, 0.3);
      border-radius: 8px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    }

    #tray menuitem {
      color: ${custom.text_color};
      transition: all 0.2s ease;
    }

    #tray menuitem:hover {
      background: rgba(122, 162, 247, 0.2);
    }

    /* ===== HOVER EFFECTS ===== */
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
      background: linear-gradient(135deg, 
        rgba(122, 162, 247, 0.25), 
        rgba(122, 162, 247, 0.15));
      border-color: ${custom.blue};
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(122, 162, 247, 0.2);
    }

    /* ===== TOOLTIP STYLES ===== */
    tooltip {
      background: rgba(30, 30, 46, 0.95);
      backdrop-filter: blur(12px);
      border: 1px solid rgba(122, 162, 247, 0.3);
      border-radius: 8px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    }

    tooltip label {
      color: ${custom.text_color};
      padding: 8px 12px;
      font-weight: 500;
    }

    /* ===== ANIMATIONS ===== */
    @keyframes slideInWorkspace {
      from {
        opacity: 0;
        transform: translateY(-10px) scale(0.9);
      }
      to {
        opacity: 1;
        transform: translateY(0) scale(1);
      }
    }

    @keyframes workspace_urgent {
      0%, 100% {
        box-shadow: 0 0 8px rgba(247, 118, 142, 0.3);
        transform: scale(1);
      }
      50% {
        box-shadow: 0 0 16px rgba(247, 118, 142, 0.6), 
                    0 0 24px rgba(247, 118, 142, 0.4);
        transform: scale(1.02);
      }
    }

    @keyframes blink-critical {
      0%, 100% {
        background: linear-gradient(135deg, 
          rgba(247, 118, 142, 0.25), 
          rgba(247, 118, 142, 0.15));
      }
      50% {
        background: linear-gradient(135deg, 
          rgba(247, 118, 142, 0.4), 
          rgba(247, 118, 142, 0.3));
        transform: scale(1.02);
      }
    }

    @keyframes blink-warning {
      0%, 100% {
        opacity: 1;
      }
      50% {
        opacity: 0.6;
      }
    }

    @keyframes pulse-warning {
      0%, 100% {
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      }
      50% {
        box-shadow: 0 2px 8px rgba(250, 179, 135, 0.3);
      }
    }

    /* ===== DARK/LIGHT MODE SUPPORT ===== */
    @media (prefers-color-scheme: light) {
      window#waybar {
        background: rgba(239, 241, 245, 0.95);
        color: #4c4f69;
        border-top-color: rgba(76, 79, 105, 0.2);
      }
      
      tooltip {
        background: rgba(239, 241, 245, 0.95);
        border-color: rgba(76, 79, 105, 0.3);
      }
      
      tooltip label {
        color: #4c4f69;
      }
    }

    /* ===== RESPONSIVE DESIGN ===== */
    @media (max-width: 1366px) {
      #custom-weather {
        min-width: 60px;
        font-size: 14px;
      }
      
      #mpris {
        max-width: 200px;
      }
      
      #custom-todo {
        max-width: 150px;
      }
    }

    @media (max-width: 1024px) {
      * {
        font-size: 12px;
      }
      
      #workspaces button {
        min-width: 28px;
        padding: 1px 6px;
      }
      
      #custom-launcher {
        font-size: 18px;
        padding: 1px 8px;
      }
    }
  '';
}

