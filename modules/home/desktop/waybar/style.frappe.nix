# modules/home/waybar/style.nix
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
      background: #303446;  /* Frappe arka plan */
      color: #c6d0f5;  /* Frappe metin */
      border-top: 1px solid #414559;
    }

    /* Tüm modüller için Frappe ile uyumlu stil */
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
      background-color: #232634;  /* Frappe koyu arka plan */
      padding: 2px 8px;
      margin: 2px 2px;
      border: 1px solid #414559;
      border-radius: 6px;
    }

    /* Çalışma alanları için Frappe renkleriyle stil */
    #workspaces {
      margin: 2px 2px;
      padding: 0;
      background: transparent;
    }

    #workspaces button {
      min-height: 20px;
      min-width: 20px;
      padding: 2px 8px;
      margin: 0 2px;
      border-radius: 4px;
      color: #8caaee;  /* Frappe mavi */
      background-color: #232634;
      border: 1px solid #414559;
      font-weight: bold;
    }

    #workspaces button.active {
      color: #f4b8e4;  /* Frappe pembe */
      background-color: #414559;
      border-color: #8caaee;
    }

    #workspaces button.empty {
      color: #737994;  /* Frappe soluk metin */
      background-color: #232634;
      opacity: 0.8;
    }

    #workspaces button.urgent {
      color: #e78284;  /* Frappe kırmızı */
      background-color: rgba(231, 130, 132, 0.2);
      border-color: #e78284;
      animation: workspace_urgent 1s ease-in-out infinite;
    }

    /* Frappe renk paletiyle modül renkleri */
    #bluetooth { color: #85c1dc; }  /* Frappe siyan */
    #bluetooth.connected { color: #8caaee; }  /* Frappe mavi */
    
    #network { color: #8caaee; }  /* Frappe mavi */
    #network.disconnected { color: #e78284; }  /* Frappe kırmızı */
    
    #battery { color: #f4b8e4; }  /* Frappe pembe */
    #battery.charging { color: #85c1dc; }  /* Frappe siyan */
    #battery.full { color: #a6d189; }  /* Frappe yeşil */
    #battery.warning:not(.charging) { color: #ef9f76; }  /* Frappe turuncu */
    #battery.critical:not(.charging) { 
      color: #e78284;  /* Frappe kırmızı */
      animation: blink-critical 1s infinite;
    }

    #pulseaudio { color: #f4b8e4; }  /* Frappe pembe */
    #pulseaudio.muted { color: #e78284; }  /* Frappe kırmızı */
    
    #pulseaudio#sink { color: #f4b8e4; }  /* Frappe pembe */
    #pulseaudio#sink.muted { color: #e78284; }  /* Frappe kırmızı */
    
    #pulseaudio#source { color: #85c1dc; }  /* Frappe siyan */
    #pulseaudio#source.muted { color: #e78284; }  /* Frappe kırmızı */
    
    #cpu { color: #a6d189; }  /* Frappe yeşil */
    #memory { color: #f4b8e4; }  /* Frappe pembe */
    #disk { color: #ef9f76; }  /* Frappe turuncu */
    
    #custom-vpnstatus.connected,
    #custom-vpnmullvad.connected,
    #custom-vpnother.connected { color: #a6d189; }  /* Frappe yeşil */
    
    #custom-vpnstatus.disconnected,
    #custom-vpnmullvad.disconnected,
    #custom-vpnother.disconnected { color: #e78284; }  /* Frappe kırmızı */

    #mpris {
      background-color: #232634;
    }

    #mpris.playing { color: #a6d189; }  /* Frappe yeşil */
    #mpris.paused { color: #8caaee; }  /* Frappe mavi */
    #mpris.stopped { color: #e78284; }  /* Frappe kırmızı */

    #custom-launcher {
      color: #85c1dc;  /* Frappe siyan */
      font-size: 20px;
      padding: 0 10px;
      margin: 4px 8px 4px 4px;
      background: #232634;
      border: 1px solid #414559;
      border-radius: 6px;
    }

    #custom-launcher:hover {
      background-color: #414559;
      border-color: #85c1dc;
    }

    /* Sistem simgeleri */
    #custom-notification,
    #custom-firewall,
    #custom-power {
      background-color: #232634;
      padding: 0 8px;
      margin: 4px 2px;
      border: 1px solid #414559;
      border-radius: 6px;
      min-width: 24px;
      font-size: 16px;
    }

    #custom-notification {
      padding: 0 6px;
      font-size: 15px;
      margin-right: 4px;
      color: #ef9f76;  /* Frappe turuncu */
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
      color: #e78284;  /* Frappe kırmızı */
    }

    #tray {
      margin: 4px 4px;
    }

    #tray menu {
      background: #232634;
      border: 1px solid #414559;
    }

    #clock {
      color: #85c1dc;  /* Frappe siyan */
      font-weight: bold;
    }

    #language {
      color: #f4b8e4;  /* Frappe pembe */
    }

    /* Hover efektleri - Frappe renkleriyle uyumlu */
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
      background-color: #414559;
      border-color: #ca9ee6;  /* Frappe mor */
    }

    #temperature {
      color: #a6d189;  /* Frappe yeşil */
    }

    #temperature.critical {
      color: #e78284;  /* Frappe kırmızı */
      animation: blink-critical 1s infinite;
    }

    #temperature:hover {
      background-color: #414559;
      border-color: #ca9ee6;
    }

    #custom-notification:hover {
      background-color: rgba(239, 159, 118, 0.2);
      border-color: #ef9f76;
    }

    #custom-firewall:hover {
      background-color: rgba(231, 130, 132, 0.2);
      border-color: #e78284;
    }

    #custom-power:hover {
      background-color: rgba(231, 130, 132, 0.2);
      border-color: #e78284;
    }

    tooltip {
      background: #232634;
      border: 1px solid #414559;
      border-radius: 6px;
    }

    tooltip label {
      color: #c6d0f5;  /* Frappe metin */
      padding: 6px;
    }

    @keyframes blink-critical {
      to {
        background-color: #e78284;
        color: #232634;
      }
    }

    @keyframes workspace_urgent {
      0% {
        box-shadow: 0 0 5px rgba(231, 130, 132, 0.3);
      }
      50% {
        box-shadow: 0 0 10px rgba(231, 130, 132, 0.6);
      }
      100% {
        box-shadow: 0 0 5px rgba(231, 130, 132, 0.3);
      }
    }
  '';
}

