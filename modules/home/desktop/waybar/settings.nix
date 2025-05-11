# modules/home/waybar/settings.nix
{ custom, ... }:
{
  programs.waybar.settings = {
    topBar = with custom; {
      position = "top";
      layer = "top";
      height = 34;
      margin-top = 0;
      margin-bottom = 0;
      margin-left = 0;
      margin-right = 0;
      modules-left = [
        "custom/launcher"
        "hyprland/workspaces"
        "custom/blank"
        "hyprland/window"
      ];
      modules-center = [
        "custom/todo"
        "custom/blank"
        "clock"
        "custom/weather"
        "clock"
      ];
      modules-right = [
        "custom/vpnstatus"
        "custom/vpnmullvad"
        "custom/vpnother"
        "network"
        "battery"
        "custom/blank"
        "tray"
      ];

      "custom/blank" = {
        format = " ";
        tooltip = false;
      };

      "custom/todo" = {
        exec = "awk 1 ORS=' | ' ~/.todo | head -c -3";
        on-click = "kitty --title todo --hold -e vim ~/.todo";
        on-click-right = "kitty -e calcurse";
        format = " 󱄅 {} ";
        interval = "once";
        signal = "7";
      };

      clock = {
        calendar = {
          format = {
            today = "<span color='${green}'><b>{}</b></span>";
          };
        };
        format = "󰅐 {:%H:%M}";
        tooltip = true;
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format-alt = "󰃭 {:%d/%m}";
      };

      "custom/weather" = {
        exec = "curl -s 'wttr.in/Istanbul?format=1' | tr -d +";
        interval = 3600;
        format = "{}";
        tooltip = true;
        tooltip-format = "Hava Durumu";
      };

      "hyprland/workspaces" = {
        active-only = false;
        disable-scroll = true;
        format = "{icon}";
        on-click = "activate";
        format-icons = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";
          sort-by-number = true;
          urgent = "";  # Ünlem işareti
          focused = "";  # İçi dolu daire
          default = "";  # Boş daire
          special = "";  # Yıldız simgesi
          empty = "";    # Kare simgesi
        };
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
        persistent-workspaces = {
          "1" = [];
          "2" = [];
          "3" = [];
          "4" = [];
          "5" = [];
          "6" = [];
        };
      };

      "hyprland/window" = {
        format = "󱂬 {}";
        max-length = "10";
      };

      "custom/vpnstatus" = {
        interval = 5;
        format = "{}";
        exec = "osc-waybar vpn-status";
        return-type = "json";
        tooltip = true;
      };

      "custom/vpnmullvad" = {
        interval = 5;
        format = "{}";
        exec = "osc-waybar vpn-mullvad";
        return-type = "json";
        tooltip = true;
        on-click-right = "mullvad connect";
        on-click-middle = "mullvad disconnect";
      };

      "custom/vpnother" = {
        interval = 5;
        format = "{}";
        exec = "osc-waybar vpn-other";
        return-type = "json";
        tooltip = true;
      };

      network = {
        format-wifi = "󰤨 {signalStrength}%";
        format-ethernet = "󰤥";
        format-linked = "{ifname} (No IP)";
        format-disconnected = "󰤭";
        on-click-right = "rofi-iwmenu";
        on-click-middle = "rofi-wifi";
        tooltip-format-wifi = '''
          SSID: {essid}
          Sinyal: {signalStrength}%
          IP: {ipaddr}
          Ağ Geçidi: {gwaddr}
          DNS: {frequency} MHz
        ''';
      };

      battery = {
        interval = 30;
        states = {
          warning = 30;
          critical = 15;
          full = 95;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󰂄 {capacity}%";
        format-full = "󰁹 {capacity}%";
        format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂"];
        format-time = "{H}h {M}m";
        tooltip = true;
        tooltip-format = "Remaining: {time}";
      };

      "custom/launcher" = {
        format = "󱄅";
        on-click = "wallpaper-manager";
        on-click-right = "rofi -show drun";
        on-click-middle = "rofi -show window";
        tooltip = true;
        tooltip-format = "Random Wallpaper";
      };

      tray = {
        icon-size = 20;
        spacing = 8;
        show-passive-items = true;
        reverse-direction = true;
        smooth-scrolling-threshold = 0;
        format = "{icon}";
        tooltip = true;
        tooltip-format = "{title}";
        tray-light-mode = "auto";
        require-input = true;
        special-icons = {
          firefox = "󰈹";
          zen-browser = "󰈹";
          telegram = "󰔁";
        };
      };
    };

    bottomBar = with custom; {
      layer = "top";
      position = "bottom";
      height = 34;
      margin-top = 0;
      margin-bottom = 0;
      margin-left = 0;
      margin-right = 0;
      modules-left = [
        "custom/launcher"
        "hyprland/workspaces"
        "custom/blank"
        "mpris"
      ];
      modules-center = [
      ];
      modules-right = [
        "cpu"
        "temperature"
        "memory"
        "disk"
        "bluetooth"
        "pulseaudio#sink"
        "pulseaudio#source"
        #"hyprland/language"
        "custom/notification"
        "custom/firewall"
        "custom/blank"
        "custom/power"
      ];

      "custom/launcher" = {
        format = "󱄅";
        on-click = "wallpaper-manager";
        on-click-right = "rofi -show drun";
        on-click-middle = "rofi -show window";
        tooltip = true;
        tooltip-format = "Random Wallpaper";
      };

      temperature = {
        interval = 2;
        format = "{icon} {temperatureC}°C";
        format-critical = "{icon} {temperatureC}°C";
        max-length = 10;
        critical-threshold = 85;
        on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
        format-icons = [
          "󱃃"
          "󱃃"
          "󱃂"
          "󱃅"
        ];
        # CoreTemp için doğru path konfigürasyonu
        hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
        input-filename = "temp1_input";
      };

      cpu = {
        format = "󰻠 {usage}%";
        format-alt = "󰻠 {avg_frequency} GHz";
        interval = 2;
        on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
      };

      memory = {
        format = "󰍛 {}%";
        format-alt = "󰍛 {used} GiB";
        interval = 2;
        on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
      };

      disk = {
        format = "󰋊 {percentage_used}%";
        interval = 300;
        on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
      };

      bluetooth = {
        format = "{icon}";
        format-disabled = "<span foreground='#ff6b6b'>󰂲</span>";
        format-off = "<span foreground='#ff6b6b'>󰂲</span>";
        format-on = "<span foreground='#ff8787'>󰂯</span>";
        format-connected = "<span foreground='#74c7ec'>{icon} {device_alias}</span>";
        format-connected-battery = "<span foreground='#74c7ec'>{icon} {device_alias} {device_battery_percentage}%</span>";
        format-icons = {
          default = "󰂱";
          headset = "󰋋";
          headphone = "󰋋";
          earbuds = "󰋎";
          speaker = "󰓃";
          phone = "󰏲";
          portable = "󰄋";
          computer = "󰟀";
          keyboard = "󰌌";
          mouse = "󰍽";
          gamepad = "󰊱";
          watch = "󰖉";
        };
        tooltip = true;
        tooltip-format = "Bluetooth Durumu: {status}\nDenetleyici: {controller_alias}";
        tooltip-format-connected = "Bağlı: {device_alias}";
        tooltip-format-enumerate-connected = "Cihaz: {device_alias}\nMAC: {device_address}";
        tooltip-format-enumerate-connected-battery = "Cihaz: {device_alias}\nPil: {device_battery_percentage}%";
        on-click = "blueman-manager";
      };

      "pulseaudio#sink" = {
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-bluetooth = "<span foreground='#74c7ec'>󰂱</span> {volume}%";
        format-bluetooth-muted = "<span foreground='#ff6b6b'>󰂲</span> {volume}%";
        format-headphone = "<span foreground='#928374'>{icon}</span> {volume}%";
        format-headphone-muted = "{icon} {volume}%";
        format-icons = {
          headphone = ["󰋋"];
          headset = ["󰋎"];
          phone = ["󰏲"];
          default = ["󰕿" "󰖀" "󰕾"];
        };
        scroll-step = 5;
        max-volume = 100;
        on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
        on-click-middle = "pactl set-sink-volume @DEFAULT_SINK@ 50%";
        on-click-right = "pavucontrol";
        on-scroll-down = "pactl set-sink-volume @DEFAULT_SINK@ -1%";
        on-scroll-up = "pactl set-sink-volume @DEFAULT_SINK@ +1%";
        tooltip = true;
        tooltip-format = "Ses: {volume}%\nCihaz: {desc}";
      };

      "pulseaudio#source" = {
        format = "{format_source}";
        format-source = "󰍬 {volume}%";
        format-source-muted = "<span foreground='#ff6b6b'>󰍭</span>";
        max-volume = 40;
        scroll-step = 5;
        on-click = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
        on-click-middle = "pactl set-source-volume @DEFAULT_SOURCE@ 40%";
        on-click-right = "pavucontrol";
        on-scroll-down = "pactl set-source-volume @DEFAULT_SOURCE@ -1%";
        on-scroll-up = "pactl set-source-volume @DEFAULT_SOURCE@ +1%";
        tooltip = true;
        tooltip-format = "Mikrofon: {volume}%\nCihaz: {source_desc}";
      };

      "hyprland/workspaces" = {
        active-only = false;
        disable-scroll = true;
        format = "{icon}";
        on-click = "activate";
        format-icons = {
          "1" = "1";
          "2" = "2";
          "3" = "3";
          "4" = "4";
          "5" = "5";
          "6" = "6";
          "7" = "7";
          "8" = "8";
          "9" = "9";
          sort-by-number = true;
          urgent = "";  # Ünlem işareti
          focused = "";  # İçi dolu daire
          default = "";  # Boş daire
          special = "";  # Yıldız simgesi
          empty = "";    # Kare simgesi
        };
        on-scroll-up = "hyprctl dispatch workspace e+1";
        on-scroll-down = "hyprctl dispatch workspace e-1";
        persistent-workspaces = {
          "7" = "7";
          "8" = "8";
          "9" = "9";
        };
      };

      mpris = {
        format = "{player_icon} {dynamic}";
        format-paused = "{status_icon} <i>{dynamic}</i>";
        player-icons = {
          default = "▶";
          mpv = "🎵";
        };
        status-icons = {
          paused = "⏸";
        };
      };

      "hyprland/language" = {
        format = "󰌌 {}";
        format-tr = "TR";
        format-en = "US";
      };

      "custom/notification" = {
        tooltip = false;
        format = "{icon}";
        format-icons = {
          notification = "<span foreground='${red}'>󰂚</span>";
          none = "󰂚";
          dnd-notification = "<span foreground='${red}'>󰂛</span>";
          dnd-none = "󰂛";
          inhibited-notification = "<span foreground='${red}'>󰂚</span>";
          inhibited-none = "󰂚";
          dnd-inhibited-notification = "<span foreground='${red}'>󰂛</span>";
          dnd-inhibited-none = "󰂛";
        };
        return-type = "json";
        exec-if = "which swaync-client";
        exec = "swaync-client -swb";
        on-click = "swaync-client -t -sw";
        on-click-right = "swaync-client -d -sw";
        escape = true;
      };

      "custom/firewall" = {
        format = "{}";
        exec = "sh -c 'if systemctl is-active firewall >/dev/null 2>&1; then echo \"<span foreground=\\\"#98c379\\\"> 󰕥 </span>\"; else echo \"<span foreground=\\\"#e06c75\\\"> 󰕥 </span>\"; fi'";
        on-click = "pkexec systemctl start firewall && notify-send 'Güvenlik Duvarı' 'Firewall başlatıldı' -i security-high";
        on-click-right = "pkexec systemctl restart firewall && notify-send 'Güvenlik Duvarı' 'Firewall yeniden başlatıldı' -i security-high";
        on-click-middle = "pkexec systemctl stop firewall && notify-send 'Güvenlik Duvarı' 'Firewall durduruldu' -i security-low";
        interval = 5;
        tooltip = true;
        tooltip-format = "Güvenlik Duvarı Durumu\n\n󱎫 Sol tık: Başlat\n󰦝 Orta tık: Durdur\n󰑐 Sağ tık: Yeniden başlat\n\n<span foreground='#98c379'>Aktif olduğunda sisteminiz korunur</span>";
      };

      "custom/power" = {
        format = "⏻";
        on-click = "power-menu";
        tooltip = false;
      };
    };
  };
}
