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
      background: rgba(18, 20, 29, 0.95);  /* Daha koyu ve yarı saydam arkaplan */
      color: #f8f8f2;  /* Yüksek kontrastlı metin rengi */
      border-top: 1px solid rgba(100, 114, 125, 0.5);
    }

    /* Terminal/Bash uyumlu stil için tüm modüller */
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
      background-color: rgba(40, 42, 54, 0.85);  /* Koyu ama terminal ile uyumlu arka plan */
      padding: 2px 8px;
      margin: 2px 2px;
      border: 1px solid rgba(100, 114, 125, 0.4);
      border-radius: 6px;
    }

    /* Çalışma alanları için geliştirilmiş stil */
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
      color: #8be9fd;  /* Terminal mavi */
      background-color: rgba(40, 42, 54, 0.85);
      border: 1px solid rgba(100, 114, 125, 0.4);
      font-weight: bold;
    }

    #workspaces button.active {
      color: #ff79c6;  /* Terminal pembe */
      background-color: rgba(80, 85, 98, 0.6);
      border-color: #8be9fd;
    }

    #workspaces button.empty {
      color: #6272a4;  /* Soluk metin rengi */
      background-color: rgba(40, 42, 54, 0.6);
      opacity: 0.8;
    }

    #workspaces button.urgent {
      color: #ff5555;  /* Terminal kırmızı */
      background-color: rgba(255, 85, 85, 0.2);
      border-color: #ff5555;
      animation: workspace_urgent 1s ease-in-out infinite;
    }

    /* Terminal renk paletine uyumlu modül renkleri */
    #bluetooth { color: #8be9fd; }  /* Siyan */
    #bluetooth.connected { color: #8be9fd; }
    
    #network { color: #8be9fd; }  /* Siyan */
    #network.disconnected { color: #ff5555; }  /* Kırmızı */
    
    #battery { color: #ff79c6; }  /* Pembe */
    #battery.charging { color: #8be9fd; }  /* Siyan */
    #battery.full { color: #50fa7b; }  /* Yeşil */
    #battery.warning:not(.charging) { color: #ffb86c; }  /* Turuncu */
    #battery.critical:not(.charging) { 
      color: #ff5555;  /* Kırmızı */
      animation: blink-critical 1s infinite;
    }

    #pulseaudio { color: #ff79c6; }  /* Pembe */
    #pulseaudio.muted { color: #ff5555; }  /* Kırmızı */
    
    #pulseaudio#sink { color: #ff79c6; }  /* Pembe */
    #pulseaudio#sink.muted { color: #ff5555; }  /* Kırmızı */
    
    #pulseaudio#source { color: #8be9fd; }  /* Siyan */
    #pulseaudio#source.muted { color: #ff5555; }  /* Kırmızı */
    
    #cpu { color: #50fa7b; }  /* Yeşil */
    #memory { color: #ff79c6; }  /* Pembe */
    #disk { color: #ffb86c; }  /* Turuncu */
    
    #custom-vpnstatus.connected,
    #custom-vpnmullvad.connected,
    #custom-vpnother.connected { color: #50fa7b; }  /* Yeşil */
    
    #custom-vpnstatus.disconnected,
    #custom-vpnmullvad.disconnected,
    #custom-vpnother.disconnected { color: #ff5555; }  /* Kırmızı */

    #mpris {
      background-color: rgba(40, 42, 54, 0.85);
    }

    #mpris.playing { color: #50fa7b; }  /* Yeşil */
    #mpris.paused { color: #8be9fd; }  /* Siyan */
    #mpris.stopped { color: #ff5555; }  /* Kırmızı */

    #custom-launcher {
      color: #8be9fd;  /* Siyan */
      font-size: 20px;
      padding: 0 10px;
      margin: 4px 8px 4px 4px;
      background: rgba(40, 42, 54, 0.85);
      border: 1px solid rgba(100, 114, 125, 0.4);
      border-radius: 6px;
    }

    #custom-launcher:hover {
      background-color: rgba(98, 114, 164, 0.4);
      border-color: #8be9fd;
    }

    /* Sistem simgeleri */
    #custom-notification,
    #custom-firewall,
    #custom-power {
      background-color: rgba(40, 42, 54, 0.85);
      padding: 0 8px;
      margin: 4px 2px;
      border: 1px solid rgba(100, 114, 125, 0.4);
      border-radius: 6px;
      min-width: 24px;
      font-size: 16px;
    }

    #custom-notification {
      padding: 0 6px;
      font-size: 15px;
      margin-right: 4px;
      color: #ffb86c;  /* Turuncu */
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
      color: #ff5555;  /* Kırmızı */
    }

    #tray {
      margin: 4px 4px;
    }

    #tray menu {
      background: rgba(40, 42, 54, 0.95);
      border: 1px solid rgba(100, 114, 125, 0.4);
    }

    #clock {
      color: #8be9fd;  /* Siyan */
      font-weight: bold;
    }

    #language {
      color: #ff79c6;  /* Pembe */
    }

    /* Hover efektleri - Terminal renkleriyle uyumlu */
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
      background-color: rgba(98, 114, 164, 0.4);
      border-color: #bd93f9;  /* Mor */
    }

    #temperature {
      color: #50fa7b;  /* Yeşil */
    }

    #temperature.critical {
      color: #ff5555;  /* Kırmızı */
      animation: blink-critical 1s infinite;
    }

    #temperature:hover {
      background-color: rgba(98, 114, 164, 0.4);
      border-color: #bd93f9;
    }

    #custom-notification:hover {
      background-color: rgba(255, 184, 108, 0.2);
      border-color: #ffb86c;
    }

    #custom-firewall:hover {
      background-color: rgba(255, 85, 85, 0.2);
      border-color: #ff5555;
    }

    #custom-power:hover {
      background-color: rgba(255, 85, 85, 0.2);
      border-color: #ff5555;
    }

    tooltip {
      background: rgba(40, 42, 54, 0.95);
      border: 1px solid rgba(100, 114, 125, 0.4);
      border-radius: 6px;
    }

    tooltip label {
      color: #f8f8f2;  /* Parlak metin rengi */
      padding: 6px;
    }

    @keyframes blink-critical {
      to {
        background-color: #ff5555;
        color: #282a36;
      }
    }

    @keyframes workspace_urgent {
      0% {
        box-shadow: 0 0 5px rgba(255, 85, 85, 0.3);
      }
      50% {
        box-shadow: 0 0 10px rgba(255, 85, 85, 0.6);
      }
      100% {
        box-shadow: 0 0 5px rgba(255, 85, 85, 0.3);
      }
    }
  '';
}

