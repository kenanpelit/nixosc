# modules/home/waybar/style.nix
{ custom, ... }:

{
  programs.waybar.style = ''
    * {
      border: none;
      border-radius: 0;
      font-family: Maple Mono;
      font-weight: bold;
      font-size: 16px;
      min-height: 0;
      transition: 0.3s;
    }

    window#waybar {
      background: #1a1b26;
      color: #c0caf5;
      border-top: 1px solid #414868;
    }

    /* Common style for all modules */
    #workspaces,
    #bluetooth,
    #custom-vpnstatus,
    #custom-todo,
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
      background-color: #24283b;
      padding: 1px 6px;
      margin: 2px 2px;
      border: 1px solid #414868;
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
      color: #7aa2f7;
      background-color: #24283b;
      transition: all 0.2s ease;
      border: 1px solid #414868;
    }

    #workspaces button.active {
      color: #bb9af7;
      background-color: rgba(122, 162, 247, 0.2);
      border-color: #7aa2f7;
    }

    #workspaces button.empty {
      color: #c0caf5;
      background-color: #24283b;
      opacity: 0.8;
    }

    #workspaces button.urgent {
      color: #f7768e;
      background-color: rgba(247, 118, 142, 0.2);
      border-color: #f7768e;
      animation: workspace_urgent 1s ease-in-out infinite;
    }

    /* Module specific colors */
    #bluetooth { color: #7dcfff; }
    #bluetooth.connected { color: #2ac3de; }
    
    #network { color: #7aa2f7; }
    #network.disconnected { color: #f7768e; }
    #network.ethernet,
    #network.wifi { color: #7aa2f7; }

    #battery { color: #bb9af7; }
    #battery.charging { color: #73daca; }
    #battery.full { color: #9ece6a; }
    #battery.warning:not(.charging) { color: #ff9e64; }
    #battery.critical:not(.charging) { 
      color: #f7768e;
      animation: blink-critical 1s infinite;
    }

    #pulseaudio { color: #bb9af7; }
    #pulseaudio.muted { color: #f7768e; }
    
    #pulseaudio#sink { color: #bb9af7; }
    #pulseaudio#sink.muted { color: #f7768e; }
    
    #pulseaudio#source { color: #7dcfff; }
    #pulseaudio#source.muted { color: #f7768e; }
    
    #cpu { color: #9ece6a; }
    #memory { color: #bb9af7; }
    #disk { color: #e0af68; }
    
    #custom-vpnstatus.connected,
    #custom-vpnmullvad.connected,
    #custom-vpnother.connected { color: #9ece6a; }
    
    #custom-vpnstatus.disconnected,
    #custom-vpnmullvad.disconnected,
    #custom-vpnother.disconnected { color: #f7768e; }

    #mpris {
      background-color: #24283b;
    }

    #mpris.playing { color: #9ece6a; }
    #mpris.paused { color: #7aa2f7; }
    #mpris.stopped { color: #f7768e; }

    #custom-launcher {
      color: #7dcfff;
      font-size: 20px;
      padding: 0 10px;
      margin: 4px 8px 4px 4px;
      background: #24283b;
      border: 1px solid #414868;
      border-radius: 6px;
    }

    #custom-launcher:hover {
      background-color: rgba(125, 207, 255, 0.1);
      border-color: #7dcfff;
    }

    /* System icons with adjusted sizes */
    #custom-notification,
    #custom-firewall,
    #custom-power {
      background-color: #24283b;
      padding: 0 8px;
      margin: 4px 2px;
      border: 1px solid #414868;
      border-radius: 6px;
      min-width: 24px;
      font-size: 16px;
    }

    #custom-notification {
      padding: 0 6px;
      font-size: 15px;
      margin-right: 4px;
      color: #e0af68;
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
      color: #f7768e;
    }

    #tray {
      margin: 4px 4px;
    }

    #tray menu {
      background: #24283b;
      border: 1px solid #414868;
    }

    #clock {
      color: #7dcfff;
    }

    #language {
      color: #bb9af7;
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
      background-color: rgba(122, 162, 247, 0.1);
      border-color: #7aa2f7;
    }

    #temperature {
      color: #9ece6a;  /* Normal durum rengi - yeşil */
    }

    #temperature.critical {
      color: #f7768e;  /* Kritik sıcaklık rengi - kırmızı */
      animation: blink-critical 1s infinite;
    }

    #temperature:hover {
      background-color: rgba(122, 162, 247, 0.1);
      border-color: #7aa2f7;
    }

    #custom-notification:hover {
      background-color: rgba(224, 175, 104, 0.1);
      border-color: #e0af68;
    }

    #custom-firewall:hover {
      background-color: rgba(247, 118, 142, 0.1);
      border-color: #f7768e;
    }

    #custom-power:hover {
      background-color: rgba(247, 118, 142, 0.1);
      border-color: #f7768e;
    }

    tooltip {
      background: #24283b;
      border: 1px solid #414868;
      border-radius: 6px;
    }

    tooltip label {
      color: #c0caf5;
      padding: 6px;
    }

    @keyframes blink-critical {
      to {
        background-color: #f7768e;
        color: #24283b;
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

