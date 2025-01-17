# modules/home/waybar/style.nix
{ custom, ... }:
{
  programs.waybar.style = with custom; ''
    * {
      border: none;
      border-radius: 0;
      font-family: ${font};
      font-weight: ${font_weight};
      font-size: ${font_size};
      min-height: 0;
      transition: 0.3s;
    }

    window#waybar {
      background: ${background_0};
      color: ${text_color};
      border-top: 1px solid ${border_color};
    }

    #workspaces {
      background: ${background_1};
      margin: 4px 4px;
      padding: 0 6px;
      border-radius: 8px;
    }

    #workspaces button {
      color: ${text_color};
      padding: 0 4px;
      transition: all 0.3s;
    }

    #workspaces button:hover {
      color: ${text_color};
      background: ${background_0};
      border-radius: 4px;
    }

    #workspaces button:not(.empty) {
      color: #7aa2f7;
    }

    #workspaces button.active:not(.empty) {
      color: #bb9af7;
    }

    #workspaces button.active.empty {
      color: #bb9af7;
    }

    #workspaces button.urgent {
      color: #f7768e;
    }

    /* Common module styles */
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
    #memory,
    #disk,
    #battery,
    #clock,
    #language,
    #tray,
    #custom-notification {
      background: ${background_1};
      padding: 0 10px;
      margin: 4px 2px;
      border-radius: 8px;
      color: ${text_color};
      transition: background 0.3s;
    }

    /* Module-specific colors */
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
      background: ${background_1};
      padding: 0 10px;
      margin: 4px 2px;
      border-radius: 8px;
    }

    #mpris.playing { color: #9ece6a; }
    #mpris.paused { color: #7aa2f7; }
    #mpris.stopped { color: #f7768e; }

    #custom-launcher {
      color: #7dcfff;
      font-size: 20px;
      padding: 0 10px;
      margin: 4px 8px 4px 4px;
      background: ${background_1};
      border-radius: 8px;
    }

    #custom-launcher:hover {
      background: ${background_0};
    }

    #custom-firewall {
      color: #f7768e;
      margin: 4px 8px 4px 4px;
      padding: 0 8px;
      background: ${background_1};
      border-radius: 8px;
    }

    #custom-power {
      color: #f7768e;
      margin: 4px 8px 4px 4px;
      padding: 0 8px;
      background: ${background_1};
      border-radius: 8px;
    }

    #custom-power:hover {
      background: ${background_0};
      color: #ff9e64;
    }

    #tray {
      background: ${background_1};
      margin: 4px 4px;
      padding: 0 8px;
      border-radius: 8px;
    }

    #tray menu {
      background: ${background_1};
      border: 1px solid ${border_color};
    }

    #custom-notification {
      background: ${background_1};
      margin: 4px 8px 4px 0;
      padding: 0 10px;
      border-radius: 8px;
      color: #e0af68;
    }

    #clock {
      color: #7dcfff;
    }

    #language {
      color: #bb9af7;
    }

    tooltip {
      background: ${background_1};
      border: 1px solid ${border_color};
      border-radius: 8px;
    }

    tooltip label {
      color: ${text_color};
      padding: 6px;
    }

    @keyframes blink-critical {
      to {
        color: ${text_color};
        background-color: #f7768e;
      }
    }
  '';
}
