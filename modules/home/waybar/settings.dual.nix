# modules/home/waybar/settings.nix
# ═══════════════════════════════════════════════════════════════════════════════════════════════
# Waybar Configuration - Dual Bar Layout (Top + Bottom)
# ═══════════════════════════════════════════════════════════════════════════════════════════════
# A sophisticated dual-bar configuration featuring dedicated areas for different system aspects:
#
# 🔝 Top Bar    → Essential Information & Quick Access
# 🔻 Bottom Bar → System Monitoring & Advanced Controls
#
# Design Philosophy:
# • Top Bar focuses on immediate needs: navigation, time, weather, connectivity
# • Bottom Bar provides detailed system monitoring and power user features
# • Clean separation of concerns for optimal workflow efficiency
# ═══════════════════════════════════════════════════════════════════════════════════════════════

{ custom }:
{
  # ╭─────────────────────────────────────────────────────────────────────────────────────────────╮
  # │                            🔝 Top Bar - Essential Information                               │
  # ╰─────────────────────────────────────────────────────────────────────────────────────────────╯
  topBar = with custom; {
    # ┌─ Bar Positioning & Dimensions ──────────────────────────────────────────────────────────┐
    position = "top";
    layer = "top";
    height = 34;
    margin-top = 0;
    margin-bottom = 0;
    margin-left = 0;
    margin-right = 0;
    
    # ┌─ Module Layout Structure ────────────────────────────────────────────────────────────────┐
    # Left: Navigation & Window Management
    modules-left = [
      "custom/launcher"    # 🚀 Application launcher & system tools
      "hyprland/workspaces" # 🏢 Workspace navigation with semantic icons
      "custom/blank"       # ⎵  Visual spacing
      "hyprland/window"    # 🪟 Active window title display
    ];
    
    # Center: Time, Productivity & Weather
    modules-center = [
      "custom/todo"        # 📋 Personal todo list from ~/.todo
      "custom/blank"       # ⎵  Visual spacing
      "clock"              # 🕐 Time display with calendar integration
      "custom/blank"       # ⎵  Visual spacing
      "custom/weather"     # 🌤️ Istanbul weather information
    ];
    
    # Right: Core Connectivity & Power
    modules-right = [
      "custom/vpn"         # 🔒 VPN status (unified Mullvad + others)
      "network"            # 🌐 Network connectivity (WiFi/Ethernet)
      "battery"            # 🔋 Battery status & power management
      "custom/blank"       # ⎵  Visual spacing
      "tray"               # 📌 System tray applications
    ];

    # ╭─────────────────────────────────────────────────────────────────────────────────────────────╮
    # │                           🎨 Top Bar Module Definitions                                     │
    # ╰─────────────────────────────────────────────────────────────────────────────────────────────╯

    # ┌─ Visual Spacing Element ─────────────────────────────────────────────────────────────────┐
    "custom/blank" = {
      format = " ";          # Single space for visual separation
      tooltip = false;       # No tooltip needed for spacing
    };

    # ┌─ Left Section: Navigation & Window Management ───────────────────────────────────────────┐
    
    # 🚀 Application Launcher & Wallpaper Manager
    "custom/launcher" = {
      format = "󱄅";          # App grid icon
      on-click = "wallpaper-manager";           # Primary: Random wallpaper
      on-click-right = "rofi -show drun";       # Secondary: Application launcher
      on-click-middle = "rofi -show window";    # Tertiary: Window switcher
      tooltip = true;
      tooltip-format = "Random Wallpaper";     # Primary action description
    };

    # 📋 Personal Todo List Integration
    "custom/todo" = {
      # Read todo items from ~/.todo file, format as pipe-separated list
      exec = "awk 1 ORS=' | ' ~/.todo | head -c -3";
      on-click = "kitty --title todo --hold -e vim ~/.todo";    # Edit todos in vim
      on-click-right = "kitty -e calcurse";                    # Open calendar app
      format = " 󱄅 {} ";     # Todo icon with content
      interval = "once";      # Execute once, refresh via signal
      signal = "7";           # Custom signal for manual refresh (pkill -SIGUSR1)
    };

    # 🕐 Time Display with Calendar Integration
    clock = {
      calendar = {
        format = {
          today = "<span color='${green}'><b>{}</b></span>";  # Highlight current day
        };
      };
      format = "󰅐 {:%H:%M}";                                   # Primary: 24-hour time
      tooltip = true;
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";  # Month view calendar
      format-alt = "󰃭 {:%d/%m}";                              # Alternative: Date display
      on-click-middle = "rofi -show window";                   # Middle click: Window switcher
    };

    # 🌤️ Weather Information for Istanbul
    "custom/weather" = {
      # Fetch weather from wttr.in API with emoji to nerd font icon mapping
      exec = ''
        weather=$(curl -s --connect-timeout 5 'wttr.in/Istanbul?format=%c+%t' 2>/dev/null)
        if [ -z "$weather" ]; then
          echo "󰔏 N/A"
        else
          # Map weather emoji to appropriate nerd font icons
          if [[ "$weather" == *"☀"* ]]; then
            icon="󰖙"    # Clear/Sunny
          elif [[ "$weather" == *"⛅"* ]]; then
            icon="󰖕"    # Partly cloudy
          elif [[ "$weather" == *"☁"* ]]; then
            icon="󰖐"    # Cloudy
          elif [[ "$weather" == *"🌧"* ]]; then
            icon="󰖖"    # Rainy
          elif [[ "$weather" == *"⛈"* ]]; then
            icon="󰙾"    # Thunderstorm
          elif [[ "$weather" == *"🌨"* ]]; then
            icon="󰖘"    # Snowy
          elif [[ "$weather" == *"🌫"* ]]; then
            icon="󰖑"    # Foggy/Misty
          else
            icon="󰔏"    # Unknown/Default
          fi
          # Extract temperature and combine with icon
          temp=$(echo "$weather" | sed 's/^[^+]*\(+[^°]*°[CF]\)/\1/')
          echo "$icon $temp"
        fi
      '';
      interval = 1800;        # Update every 30 minutes
      format = "{}";          # Display raw output from exec
      on-click = "xdg-open 'https://wttr.in/Istanbul'";  # Detailed forecast in browser
      tooltip = true;
      tooltip-format = "Hava Durumu - Istanbul";
    };
   
    # 🏢 Hyprland Workspace Management
    "hyprland/workspaces" = {
      active-only = false;    # Show all workspaces, not just active ones
      disable-scroll = true;  # Prevent accidental workspace switching
      format = "{icon}";      # Display semantic icons instead of numbers
      on-click = "activate";  # Switch to workspace on click
      
      # Semantic workspace icons for different use cases
      format-icons = {
        "1" = "󰖟";  # 🌐 Web/Browser workspace
        "2" = "󰆍";  # 💻 Code/Development workspace
        "3" = "󰈙";  # 🖥️ Terminal/CLI workspace
        "4" = "󰑴";  # 📁 Files/File management workspace
        "5" = "󰙯";  # 🎵 Media/Entertainment workspace
        "6" = "󰊖";  # 💬 Chat/Social workspace
        "7" = "󰒓";  # 🎮 Games/Gaming workspace
        "8" = "󰎆";  # 📊 System/Monitoring workspace
        "9" = "󰍹";  # 🔧 Misc/Other workspace
        
        # State-specific icons (currently empty - can be customized)
        sort-by-number = true;
        urgent = "";        # Urgent workspace indicator
        focused = "";       # Currently focused workspace
        default = "";       # Default workspace state
        special = "";       # Special workspace (scratchpad)
        empty = "";         # Empty/unused workspace
      };
      
      # Mouse wheel navigation
      on-scroll-up = "hyprctl dispatch workspace e+1";    # Next workspace
      on-scroll-down = "hyprctl dispatch workspace e-1";  # Previous workspace
      
      # Persistent workspaces (always show these even if empty)
      persistent-workspaces = {
        "1" = [];  # Web/Browser
        "2" = [];  # Code/Dev
        "3" = [];  # Terminal
        "4" = [];  # Files
        "5" = [];  # Media
        "6" = [];  # Chat/Social
      };
    };

    # 🪟 Active Window Information
    "hyprland/window" = {
      format = "󱂬 {}";    # Window icon + title
      max-length = "10";   # Limit title length to prevent overflow
    };

    # ┌─ Right Section: VPN & Connectivity ──────────────────────────────────────────────────────┐
   
    # 🔒 Unified VPN Status (Mullvad + Others)
    "custom/vpn" = {
      interval = 5;                             # Check every 5 seconds
      format = "{}";                            # Use JSON output formatting
      exec = "vpn-waybar";                      # Custom unified VPN script
      return-type = "json";                     # Expect JSON response
      tooltip = true;
      on-click = "mullvad-gui";                 # Open Mullvad GUI
      on-click-right = "mullvad connect";       # Quick connect to Mullvad
      on-click-middle = "mullvad disconnect";   # Quick disconnect from Mullvad
    };

    # 🌐 Network Connectivity Status
    network = {
      format-wifi = "󰤨 {signalStrength}%";    # WiFi with signal strength
      format-ethernet = "󰤥";                  # Ethernet connection indicator
      format-linked = "{ifname} (No IP)";     # Connected but no IP assigned
      format-disconnected = "󰤭";             # No network connection
      on-click-right = "rofi-iwmenu";         # Network interface selection menu
      on-click-middle = "rofi-wifi";          # WiFi network selection menu
      tooltip-format = "Connected to {essid}\nIP: {ipaddr}";  # Basic connection info
      
      # Detailed WiFi connection information
      tooltip-format-wifi = ''
        SSID: {essid}
        Signal: {signalStrength}%
        IP: {ipaddr}
        GW: {gwaddr}
        Frequency: {frequency} MHz
      '';
    };
   
    # 🔋 Battery Status & Power Management
    battery = {
      interval = 30;          # Check every 30 seconds
      
      # Battery level thresholds for different states
      states = {
        warning = 30;         # Show warning state at 30%
        critical = 15;        # Show critical state at 15%
        full = 95;            # Consider battery full at 95%
      };
      
      format = "{icon} {capacity}%";            # Battery icon + percentage
      format-charging = "󰂄 {capacity}%";        # Charging state indicator
      format-plugged = "󰂄 {capacity}%";         # Plugged in (not charging)
      format-full = "󰁹 {capacity}%";            # Battery full indicator
      format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂"];  # Battery level icons (0-100%)
      format-time = "{H}h {M}m";                # Time remaining format
      tooltip = true;
      tooltip-format = "Remaining: {time}";     # Show time remaining in tooltip
    };

    # 📌 System Tray for Background Applications
    tray = {
      icon-size = 20;                    # Tray icon size in pixels
      spacing = 8;                       # Space between tray icons
      show-passive-items = true;         # Show inactive/passive tray items
      reverse-direction = true;          # Reverse icon order (newest first)
      smooth-scrolling-threshold = 0;    # Disable smooth scrolling
      format = "{icon}";                 # Display just the icon
      tooltip = true;                    # Enable tooltips for tray items
      tooltip-format = "{title}";        # Show application title in tooltip
      tray-light-mode = "auto";          # Auto-detect light/dark theme
      require-input = true;              # Require user input for interaction
      
      # Custom icons for specific applications
      special-icons = {
        firefox = "󰈹";       # Firefox browser
        zen-browser = "󰈹";   # Zen browser (alternative Firefox)
        telegram = "󰔁";      # Telegram messenger
      };
    };
  };

  # ╭─────────────────────────────────────────────────────────────────────────────────────────────╮
  # │                      🔻 Bottom Bar - System Monitoring & Controls                          │
  # ╰─────────────────────────────────────────────────────────────────────────────────────────────╯
  bottomBar = with custom; {
    # ┌─ Bar Positioning & Dimensions ──────────────────────────────────────────────────────────┐
    layer = "top";
    position = "bottom";
    height = 34;
    margin-top = 0;
    margin-bottom = 0;
    margin-left = 0;
    margin-right = 0;
    
    # ┌─ Module Layout Structure ────────────────────────────────────────────────────────────────┐
    # Left: Secondary Navigation & Media
    modules-left = [
      "custom/launcher"    # 🚀 Secondary launcher (same as top)
      "hyprland/workspaces" # 🏢 Workspace indicators (bottom perspective)
      "custom/blank"       # ⎵  Visual spacing
      "mpris"              # 🎵 Media player controls (Spotify, MPV, etc.)
    ];
    
    # Center: Intentionally Empty (clean aesthetic)
    modules-center = [];
    
    # Right: System Monitoring & Advanced Controls
    modules-right = [
      "cpu"                # 💻 CPU usage monitoring
      "temperature"        # 🌡️ CPU temperature monitoring
      "memory"             # 🧠 RAM usage monitoring
      "disk"               # 💾 Disk usage monitoring
      "bluetooth"          # 📶 Bluetooth device management
      "pulseaudio#sink"    # 🔊 Audio output controls
      "pulseaudio#source"  # 🎤 Microphone input controls
      "custom/notification" # 🔔 System notifications center
      "custom/firewall"    # 🛡️ Firewall status & controls
      "custom/blank"       # ⎵  Visual spacing
      "custom/power"       # ⚡ Power menu (shutdown/restart/logout)
    ];

    # ╭─────────────────────────────────────────────────────────────────────────────────────────────╮
    # │                         🎨 Bottom Bar Module Definitions                                    │
    # ╰─────────────────────────────────────────────────────────────────────────────────────────────╯

    # ┌─ Visual Spacing Element ─────────────────────────────────────────────────────────────────┐
    "custom/blank" = {
      format = " ";          # Single space for visual separation
      tooltip = false;       # No tooltip needed for spacing
    };

    # ┌─ Left Section: Secondary Navigation & Media ─────────────────────────────────────────────┐
    
    # 🚀 Secondary Application Launcher (mirrors top bar)
    "custom/launcher" = {
      format = "󱄅";          # App grid icon
      on-click = "wallpaper-manager";           # Primary: Random wallpaper
      on-click-right = "rofi -show drun";       # Secondary: Application launcher
      on-click-middle = "rofi -show window";    # Tertiary: Window switcher
      tooltip = true;
      tooltip-format = "Random Wallpaper";     # Primary action description
    };

    # 🏢 Secondary Workspace Indicators (Different Persistent Set)
    "hyprland/workspaces" = {
      active-only = false;    # Show all workspaces
      disable-scroll = true;  # Prevent accidental switching
      format = "{icon}";      # Display semantic icons
      on-click = "activate";  # Switch to workspace on click
      
      # Same semantic icons as top bar
      format-icons = {
        "1" = "󰖟";  # Web/Browser
        "2" = "󰆍";  # Code/Dev
        "3" = "󰈙";  # Terminal
        "4" = "󰑴";  # Files
        "5" = "󰙯";  # Media
        "6" = "󰊖";  # Chat/Social
        "7" = "󰒓";  # Games
        "8" = "󰎆";  # System/Monitoring
        "9" = "󰍹";  # Misc/Other
        
        # State indicators
        sort-by-number = true;
        urgent = "";
        focused = "";
        default = "";
        special = "";
        empty = "";
      };
      
      # Mouse wheel navigation
      on-scroll-up = "hyprctl dispatch workspace e+1";
      on-scroll-down = "hyprctl dispatch workspace e-1";
      
      # Different persistent workspaces (focus on power user spaces)
      persistent-workspaces = {
        "7" = "7";  # Games
        "8" = "8";  # System/Monitoring
        "9" = "9";  # Misc/Other
      };
    };

    # 🎵 Media Player Control (MPRIS Integration)
    mpris = {
      format = "{player_icon} {dynamic}";       # Player icon + dynamic content
      format-paused = "{status_icon} <i>{dynamic}</i>";  # Italicized when paused
      
      # Player-specific icons
      player-icons = {
        default = "▶";        # Generic play button
        mpv = "🎵";           # MPV video player (music note emoji)
      };
      
      # Playback status icons
      status-icons = {
        paused = "⏸";         # Pause symbol
      };
    };

    # ┌─ Right Section: System Performance Monitoring ───────────────────────────────────────────┐
    
    # 🌡️ CPU Temperature Monitoring
    temperature = {
      interval = 2;                      # Update every 2 seconds
      format = "{icon} {temperatureC}°C"; # Temperature with status icon
      format-critical = "{icon} {temperatureC}°C";  # Critical temperature display
      max-length = 10;                   # Prevent layout overflow
      critical-threshold = 85;           # Critical temperature threshold (°C)
      on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
      format-icons = ["󱃃" "󱃃" "󱃂" "󱃅"];  # Temperature status icons (low to high)
      hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";  # Hardware monitor path
      input-filename = "temp1_input";    # Temperature sensor input file
    };

    # 💻 CPU Usage Monitoring
    cpu = {
      format = "󰻠 {usage}%";             # CPU icon + usage percentage
      format-alt = "󰻠 {avg_frequency} GHz"; # Alternative: frequency display
      interval = 2;                      # Update every 2 seconds
      on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
    };

    # 🧠 Memory Usage Monitoring
    memory = {
      format = "󰍛 {}%";                 # Memory icon + usage percentage
      format-alt = "󰍛 {used} GiB";      # Alternative: absolute usage in GiB
      interval = 2;                      # Update every 2 seconds
      on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
    };

    # 💾 Disk Usage Monitoring
    disk = {
      format = "󰋊 {percentage_used}%";   # Disk icon + usage percentage
      interval = 300;                    # Update every 5 minutes (less frequent)
      on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
    };

    # ┌─ Right Section: Device & Connectivity Management ────────────────────────────────────────┐
    
    # 📶 Bluetooth Device Management
    bluetooth = {
      format = "{icon}";                 # Show appropriate device icon
      format-disabled = "<span foreground='#ff6b6b'>󰂲</span>";     # Disabled (red)
      format-off = "<span foreground='#ff6b6b'>󰂲</span>";          # Turned off (red)
      format-on = "<span foreground='#ff8787'>󰂯</span>";           # On but disconnected (light red)
      format-connected = "<span foreground='#74c7ec'>{icon} {device_alias}</span>";        # Connected (blue)
      format-connected-battery = "<span foreground='#74c7ec'>{icon} {device_alias} {device_battery_percentage}%</span>";  # With battery (blue)
      
      # Device-specific icons for different Bluetooth device types
      format-icons = {
        default = "󰂱";       # Generic Bluetooth icon
        headset = "󰋋";       # Headset with microphone
        headphone = "󰋋";     # Headphones (audio only)
        earbuds = "󰋎";       # Wireless earbuds
        speaker = "󰓃";       # Bluetooth speaker
        phone = "󰏲";         # Mobile phone
        portable = "󰄋";      # Portable device
        computer = "󰟀";      # Computer/laptop
        keyboard = "󰌌";      # Bluetooth keyboard
        mouse = "󰍽";         # Bluetooth mouse
        gamepad = "󰊱";       # Game controller
        watch = "󰖉";         # Smart watch
      };
      
      tooltip = true;
      tooltip-format = "Bluetooth Durumu: {status}\nDenetleyici: {controller_alias}";
      tooltip-format-connected = "Bağlı: {device_alias}";
      tooltip-format-enumerate-connected = "Cihaz: {device_alias}\nMAC: {device_address}";
      tooltip-format-enumerate-connected-battery = "Cihaz: {device_alias}\nPil: {device_battery_percentage}%";
      on-click = "blueman-manager";      # Open Bluetooth device manager
    };

    # ┌─ Right Section: Audio Control System ────────────────────────────────────────────────────┐
    
    # 🔊 Audio Output Control (Speakers/Headphones)
    "pulseaudio#sink" = {
      format = "{icon} {volume}%";       # Audio icon + volume percentage
      format-muted = "󰝟";                # Muted speaker icon
      format-bluetooth = "<span foreground='#74c7ec'>󰂱</span> {volume}%";      # Bluetooth audio (blue)
      format-bluetooth-muted = "<span foreground='#ff6b6b'>󰂲</span> {volume}%"; # Bluetooth muted (red)
      format-headphone = "<span foreground='#928374'>{icon}</span> {volume}%";  # Headphone output (gray)
      format-headphone-muted = "{icon} {volume}%";                            # Headphone muted
      
      # Audio output device icons
      format-icons = {
        headphone = ["󰋋"];   # Headphones
        headset = ["󰋎"];     # Headset with mic
        phone = ["󰏲"];       # Phone audio
        default = ["󰕿" "󰖀" "󰕾"];  # Speaker volume levels (low, medium, high)
      };
      
      scroll-step = 5;                   # Volume adjustment step (5%)
      max-volume = 100;                  # Maximum volume limit
      on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";           # Toggle mute
      on-click-middle = "pactl set-sink-volume @DEFAULT_SINK@ 50%";     # Set volume to 50%
      on-click-right = "pavucontrol";                                   # Open audio control panel
      on-scroll-down = "pactl set-sink-volume @DEFAULT_SINK@ -1%";      # Decrease volume
      on-scroll-up = "pactl set-sink-volume @DEFAULT_SINK@ +1%";        # Increase volume
      tooltip = true;
      tooltip-format = "Ses: {volume}%\nCihaz: {desc}";
    };

    # 🎤 Audio Input Control (Microphone)
    "pulseaudio#source" = {
      format = "{format_source}";
      format-source = "󰍬 {volume}%";     # Microphone icon + volume percentage
      format-source-muted = "<span foreground='#ff6b6b'>󰍭</span>";  # Muted microphone (red)
      max-volume = 40;                   # Reasonable microphone volume limit
      scroll-step = 5;                   # Volume adjustment step (5%)
      on-click = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";       # Toggle microphone mute
      on-click-middle = "pactl set-source-volume @DEFAULT_SOURCE@ 40%"; # Set mic volume to 40%
      on-click-right = "pavucontrol";                                   # Open audio control panel
      on-scroll-down = "pactl set-source-volume @DEFAULT_SOURCE@ -1%";  # Decrease mic volume
      on-scroll-up = "pactl set-source-volume @DEFAULT_SOURCE@ +1%";    # Increase mic volume
      tooltip = true;
      tooltip-format = "Mikrofon: {volume}%\nCihaz: {source_desc}";
    };

    # ┌─ Right Section: System Control & Management ─────────────────────────────────────────────┐
    
    # 🔔 System Notification Center (SwayNC Integration)
    "custom/notification" = {
      tooltip = false;                   # Disable tooltip (status is visual)
      format = "{icon}";                 # Show notification state icon
      
      # Notification state icons with color coding
      format-icons = {
        notification = "<span foreground='${red}'>󰂚</span>";              # New notifications (red)
        none = "󰂚";                                                      # No notifications (default)
        dnd-notification = "<span foreground='${red}'>󰂛</span>";         # Do Not Disturb + notifications (red)
        dnd-none = "󰂛";                                                  # Do Not Disturb, no notifications
        inhibited-notification = "<span foreground='${red}'>󰂚</span>";   # Inhibited + notifications (red)
        inhibited-none = "󰂚";                                            # Inhibited, no notifications
        dnd-inhibited-notification = "<span foreground='${red}'>󰂛</span>"; # DND + Inhibited + notifications (red)
        dnd-inhibited-none = "󰂛";                                        # DND + Inhibited, no notifications
      };
      
      return-type = "json";              # Expect JSON response from script
      exec-if = "which swaync-client";   # Only execute if SwayNC is installed
      exec = "swaync-client -swb";       # Get notification status
      on-click = "swaync-client -t -sw";        # Toggle notification panel
      on-click-right = "swaync-client -d -sw";  # Clear all notifications
      escape = true;                     # Escape special characters in output
    };

    # 🛡️ Firewall Status & Control System
    "custom/firewall" = {
      format = "{}";                     # Display formatted output from script
      # Check systemd firewall service status and return colored icon
      exec = "sh -c 'if systemctl is-active firewall >/dev/null 2>&1; then echo \"<span foreground=\\\"#98c379\\\"> 󰕥 </span>\"; else echo \"<span foreground=\\\"#e06c75\\\"> 󰕥 </span>\"; fi'";
      on-click = "pkexec systemctl start firewall && notify-send 'Güvenlik Duvarı' 'Firewall başlatıldı' -i security-high";
      on-click-right = "pkexec systemctl restart firewall && notify-send 'Güvenlik Duvarı' 'Firewall yeniden başlatıldı' -i security-high";
      on-click-middle = "pkexec systemctl stop firewall && notify-send 'Güvenlik Duvarı' 'Firewall durduruldu' -i security-low";
      interval = 5;                      # Check firewall status every 5 seconds
      tooltip = true;
      tooltip-format = "Güvenlik Duvarı Durumu\n\n󱎫 Sol tık: Başlat\n󰦝 Orta tık: Durdur\n󰑐 Sağ tık: Yeniden başlat\n\n<span foreground='#98c379'>Aktif olduğunda sisteminiz korunur</span>";
    };

    # ⚡ Power Management System
    "custom/power" = {
      format = "⏻";                      # Universal power symbol
      on-click = "power-menu";            # Launch power management menu script
      tooltip = false;                   # No tooltip needed (icon is self-explanatory)
    };
  };
}

