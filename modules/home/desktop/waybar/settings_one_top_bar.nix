# modules/home/desktop/waybar/settings.nix
{ custom, ... }:
{
  programs.waybar.settings = {
    mainBar = with custom; {
      position = "top";
      layer = "top";
      height = 32;
      margin-top = 0;
      margin-bottom = 0;
      margin-left = 0;
      margin-right = 0;
      
      modules-left = [
        "custom/launcher"
        "hyprland/workspaces"
        "custom/separator"
        "hyprland/window"
        "custom/separator"
        "mpris"
      ];
      
      modules-center = [
        "custom/todo"
        "custom/separator"
        "clock"
        "custom/separator"
        "custom/weather"
      ];
      
      modules-right = [
        "custom/vpnstatus"
        "custom/vpnmullvad"
        "custom/vpnother"
        "custom/separator"
        "network"
        "bluetooth"
        "custom/separator"
        "cpu"
        "temperature"
        "memory"
        "disk"
        "custom/separator"
        "pulseaudio#sink"
        "pulseaudio#source"
        "custom/separator"
        "battery"
        "custom/separator"
        "custom/notification"
        "custom/firewall"
        "tray"
        "custom/separator"
        "custom/power"
      ];

      # Utility modules
      "custom/separator" = {
        format = "|";
        tooltip = false;
      };

      "custom/blank" = {
        format = " ";
        tooltip = false;
      };

      # Left side modules
      "custom/launcher" = {
        format = "󱄅";
        on-click = "wallpaper-manager";
        on-click-right = "rofi -show drun";
        on-click-middle = "rofi -show window";
        tooltip = true;
        tooltip-format = "Wallpaper Manager | Right: App Launcher | Middle: Windows";
      };

      "hyprland/workspaces" = {
        active-only = false;
        disable-scroll = true;
        format = "{icon}";
        on-click = "activate";
        format-icons = {
          "1" = "󰖟";  # Browser
          "2" = "󰆍";  # Terminal
          "3" = "󰈙";  # Documents
          "4" = "󰑴";  # Work/Design
          "5" = "󰙯";  # Communication
          "6" = "󰊖";  # Entertainment
          "7" = "󰒓";  # Security
          "8" = "󰎆";  # Music
          "9" = "󰍹";  # Chat
          sort-by-number = true;
          urgent = "";
          focused = "";
          default = "";
          special = "";
          empty = "";
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
          "7" = [];
          "8" = [];
          "9" = [];
        };
      };

      "hyprland/window" = {
        format = "󱂬 {}";
        max-length = 40;
        separate-outputs = true;
      };

      mpris = {
        format = "{player_icon} {dynamic}";
        format-paused = "{status_icon} <i>{dynamic}</i>";
        max-length = 30;
        player-icons = {
          default = "▶";
          mpv = "🎵";
          firefox = "󰈹";
          spotify = "󰓇";
        };
        status-icons = {
          paused = "⏸";
          playing = "▶";
          stopped = "⏹";
        };
        tooltip = true;
        tooltip-format = "Player: {player}\nTitle: {title}\nArtist: {artist}";
      };

      # Center modules
      "custom/todo" = {
        exec = "awk 1 ORS=' | ' ~/.todo | head -c -3";
        on-click = "kitty --title todo --hold -e vim ~/.todo";
        on-click-right = "kitty -e calcurse";
        format = "󱄅 {}";
        interval = "once";
        signal = "7";
        max-length = 25;
        tooltip = true;
        tooltip-format = "TODO List | Left: Edit | Right: Calendar";
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
        on-click-middle = "rofi -show window";
      };

      "custom/weather" = {
        exec = ''
          weather=$(curl -s --connect-timeout 5 'wttr.in/Istanbul?format=%c+%t' 2>/dev/null)
          if [ -z "$weather" ]; then
            echo "󰔏 N/A"
          else
            if [[ "$weather" == *"☀"* ]]; then
              icon="󰖙"
            elif [[ "$weather" == *"⛅"* ]]; then
              icon="󰖕"
            elif [[ "$weather" == *"☁"* ]]; then
              icon="󰖐"
            elif [[ "$weather" == *"🌧"* ]]; then
              icon="󰖖"
            elif [[ "$weather" == *"⛈"* ]]; then
              icon="󰙾"
            elif [[ "$weather" == *"🌨"* ]]; then
              icon="󰖘"
            elif [[ "$weather" == *"🌫"* ]]; then
              icon="󰖑"
            else
              icon="󰔏"
            fi
            temp=$(echo "$weather" | sed 's/^[^+]*\(+[^°]*°[CF]\)/\1/')
            echo "$icon $temp"
          fi
        '';
        interval = 1800;
        format = "{}";
        on-click = "xdg-open 'https://wttr.in/Istanbul'";
        tooltip = true;
        tooltip-format = "Weather - Istanbul | Click for details";
      };

      # Right side modules
      "custom/vpnstatus" = {
        interval = 5;
        format = "{}";
        exec = "vpn-waybar vpn-status";
        return-type = "json";
        tooltip = true;
      };

      "custom/vpnmullvad" = {
        interval = 5;
        format = "{}";
        exec = "vpn-waybar vpn-mullvad";
        return-type = "json";
        tooltip = true;
        on-click-right = "mullvad connect";
        on-click-middle = "mullvad disconnect";
      };

      "custom/vpnother" = {
        interval = 5;
        format = "{}";
        exec = "vpn-waybar vpn-other";
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
        tooltip-format = "Connected to {essid}\nIP: {ipaddr}";
        tooltip-format-wifi = ''
          SSID: {essid}
          Signal: {signalStrength}%
          IP: {ipaddr}
          GW: {gwaddr}
          Frequency: {frequency} MHz
        '';
      };

      bluetooth = {
        format = "{icon}";
        format-disabled = "<span foreground='#ff6b6b'>󰂲</span>";
        format-off = "<span foreground='#ff6b6b'>󰂲</span>";
        format-on = "<span foreground='#ff8787'>󰂯</span>";
        format-connected = "<span foreground='#74c7ec'>{icon}</span>";
        format-connected-battery = "<span foreground='#74c7ec'>{icon} {device_battery_percentage}%</span>";
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
        tooltip-format = "Bluetooth Status: {status}\nController: {controller_alias}";
        tooltip-format-connected = "Connected: {device_alias}";
        tooltip-format-enumerate-connected = "Device: {device_alias}\nMAC: {device_address}";
        tooltip-format-enumerate-connected-battery = "Device: {device_alias}\nBattery: {device_battery_percentage}%";
        on-click = "blueman-manager";
      };

      # System monitoring
      cpu = {
        format = "󰻠 {usage}%";
        format-alt = "󰻠 {avg_frequency} GHz";
        interval = 2;
        on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
        tooltip = true;
        tooltip-format = "CPU Usage: {usage}%\nFrequency: {avg_frequency} GHz";
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
        hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
        input-filename = "temp1_input";
        tooltip = true;
        tooltip-format = "CPU Temperature: {temperatureC}°C";
      };

      memory = {
        format = "󰍛 {}%";
        format-alt = "󰍛 {used} GiB";
        interval = 2;
        on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
        tooltip = true;
        tooltip-format = "Memory Usage: {percentage}%\nUsed: {used} GiB / {total} GiB";
      };

      disk = {
        format = "󰋊 {percentage_used}%";
        interval = 300;
        on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
        tooltip = true;
        tooltip-format = "Disk Usage: {percentage_used}%\nUsed: {used} / {total}";
      };

      # Audio controls
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
        tooltip-format = "Audio: {volume}%\nDevice: {desc}";
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
        tooltip-format = "Microphone: {volume}%\nDevice: {source_desc}";
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
        tooltip-format = "Battery: {capacity}%\nRemaining: {time}\nPower: {power}W";
      };

      # System controls
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
        on-click = "pkexec systemctl start firewall && notify-send 'Firewall' 'Started' -i security-high";
        on-click-right = "pkexec systemctl restart firewall && notify-send 'Firewall' 'Restarted' -i security-high";
        on-click-middle = "pkexec systemctl stop firewall && notify-send 'Firewall' 'Stopped' -i security-low";
        interval = 5;
        tooltip = true;
        tooltip-format = "Firewall Status\n\nLeft: Start | Middle: Stop | Right: Restart";
      };

      tray = {
        icon-size = 16;
        spacing = 4;
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
          discord = "󰙯";
          spotify = "󰓇";
        };
      };

      "custom/power" = {
        format = "⏻";
        on-click = "power-menu";
        tooltip = true;
        tooltip-format = "Power Menu";
      };
    };
  };
}

