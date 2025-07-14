# modules/home/waybar/settings.nix
# ═══════════════════════════════════════════════════════════════════════════════════════════════
# Waybar Configuration - Modern Unified Layout
# ═══════════════════════════════════════════════════════════════════════════════════════════════
# A comprehensive, single-bar configuration featuring system monitoring, media controls,
# connectivity status, and productivity tools optimized for Hyprland window manager.
#
# Layout Philosophy:
# • Left   → Navigation & Window Management
# • Center → Time, Weather & Personal Productivity  
# • Right  → System Status & Controls
# ═══════════════════════════════════════════════════════════════════════════════════════════════

{ custom }:
{
  # ╭─────────────────────────────────────────────────────────────────────────────────────────────╮
  # │                              🎯 Main Bar Configuration                                      │
  # ╰─────────────────────────────────────────────────────────────────────────────────────────────╯
  mainBar = with custom; {
    # ┌─ Bar Positioning & Dimensions ──────────────────────────────────────────────────────────┐
    position = "top";
    layer = "top";
    height = 36;
    margin-top = 0;
    margin-bottom = 0;
    margin-left = 0;
    margin-right = 0;
    
    # ┌─ Module Layout Structure ────────────────────────────────────────────────────────────────┐
    # Left: System Navigation & Active Window Context
    modules-left = [
      "custom/launcher"    # 🚀 Application launcher & wallpaper manager
      "hyprland/workspaces" # 🏢 Workspace indicators with semantic icons
      "custom/blank"       # ⎵  Visual spacing
      "mpris"              # 🎵 Media player controls (Spotify, MPV, etc.)
      "custom/blank"       # ⎵  Visual spacing
      "hyprland/window"    # 🪟 Current window title
    ];
    
    # Center: Time, Weather & Personal Productivity
    modules-center = [
      "custom/blank"       # ⎵  Visual spacing
      "custom/todo"        # 📋 Personal todo list integration
      "custom/blank"       # ⎵  Visual spacing  
      "clock"              # 🕐 Time display with calendar
      "custom/blank"       # ⎵  Visual spacing
      "custom/weather"     # 🌤️ Weather information for Istanbul
      "custom/blank"       # ⎵  Visual spacing
    ];
    
    # Right: System Monitoring & Controls
    modules-right = [
      "cpu"                # 💻 CPU usage monitoring
      "temperature"        # 🌡️ CPU temperature monitoring
      "memory"             # 🧠 RAM usage monitoring
      "disk"               # 💾 Disk usage monitoring
      "bluetooth"          # 📶 Bluetooth connectivity status
      "pulseaudio#sink"    # 🔊 Audio output controls
      "pulseaudio#source"  # 🎤 Microphone input controls
      "network"            # 🌐 Network connectivity status
      "custom/vpn"         # 🔒 VPN status (unified Mullvad + others)
      "battery"            # 🔋 Battery status & power management
      "custom/notification" # 🔔 System notifications center
      "custom/blank"       # ⎵  Visual spacing
      "tray"               # 📌 System tray applications
    ];

    # ╭─────────────────────────────────────────────────────────────────────────────────────────────╮
    # │                                🎨 Module Definitions                                        │
    # ╰─────────────────────────────────────────────────────────────────────────────────────────────╯

    # ┌─ Visual Spacing Element ─────────────────────────────────────────────────────────────────┐
    "custom/blank" = {
      format = " ";          # Single space for visual separation
      tooltip = false;       # No tooltip needed for spacing
    };

    # ┌─ Left Section: Navigation & Window Management ───────────────────────────────────────────┐
    
    # 🚀 Application Launcher & System Controls
    "custom/launcher" = {
      format = "󱄅";
      on-click = "rofi -show drun";                    # Primary: Application launcher
      on-click-right = "wallpaper-manager";           # Secondary: Random wallpaper
      on-click-middle = "rofi -show window";          # Tertiary: Window switcher
      tooltip = true;
      tooltip-format = "󱎫 Sol: App Launcher\n󰑐 Sağ: Random Wallpaper\n󰦝 Orta: Window Switcher";
    };

    # 🏢 Hyprland Workspace Management
    "hyprland/workspaces" = {
      active-only = false;   # Show all workspaces, not just active ones
      disable-scroll = true; # Prevent accidental workspace switching
      format = "{icon}";     # Display semantic icons instead of numbers
      on-click = "activate"; # Switch to workspace on click
      
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
        
        # State-specific icons
        sort-by-number = true;
        urgent = "󰀨";      # ⚠️ Alert icon for urgent workspaces
        focused = "󰮯";     # ⚫ Filled circle for active workspace
        default = "󰧞";     # ⚪ Default dot for normal workspaces
        special = "󰠱";     # ⭐ Special workspace icon (scratchpad)
        empty = "󰑊";       # ○ Empty circle for unused workspaces
      };
      
      # Mouse wheel navigation
      on-scroll-up = "hyprctl dispatch workspace e+1";    # Next workspace
      on-scroll-down = "hyprctl dispatch workspace e-1";  # Previous workspace
    };

    # 🪟 Active Window Information
    "hyprland/window" = {
      format = "󱂬 {}";          # Window icon + title
      max-length = 35;          # Prevent overly long titles
      separate-outputs = true;  # Show different windows per monitor
    };

    # ┌─ Center Section: Time, Weather & Productivity ───────────────────────────────────────────┐
    
    # 📋 Personal Todo List Integration
    "custom/todo" = {
      # Read todos from ~/.todo file, format as pipe-separated list
      exec = "if [ -f ~/.todo ] && [ -s ~/.todo ]; then cat ~/.todo | tr '\n' ' | ' | sed 's/ | $//'; else echo 'No todos'; fi";
      on-click = "kitty --title 'Todo Manager' --hold -e vim ~/.todo";      # Edit todos
      on-click-right = "kitty --title 'Calendar' -e calcurse";             # Open calendar
      format = "󱄅 {}";
      interval = 30;            # Refresh every 30 seconds
      signal = "7";             # Custom signal for manual refresh
      tooltip = true;
      tooltip-format = "󱎫 Sol: Edit Todo\n󰑐 Sağ: Calendar\n\nCurrent todos from ~/.todo";
    };

    # 🕐 Time Display with Calendar Integration
    clock = {
      calendar = {
        format = {
          today = "<span color='${green}'><b>{}</b></span>";  # Highlight today
        };
      };
      format = "󰅐 {:%H:%M}";                                   # Primary: Time display
      tooltip = true;
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";  # Calendar popup
      format-alt = "󰃭 {:%d/%m/%Y}";                            # Alternative: Date display
      on-click-middle = "rofi -show window";                   # Middle click: Window switcher
    };

    # 🌤️ Weather Information for Istanbul
    "custom/weather" = {
      # Fetch weather from wttr.in with custom icon mapping
      exec = ''
        weather=$(curl -s --connect-timeout 5 'wttr.in/Istanbul?format=%c+%t' 2>/dev/null)
        if [ -z "$weather" ]; then
          echo "󰔏 N/A"
        else
          # Map weather emoji to nerd font icons
          if [[ "$weather" == *"☀"* ]]; then
            icon="󰖙"    # Sunny
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
            icon="󰖑"    # Foggy
          else
            icon="󰔏"    # Unknown/Default
          fi
          # Extract temperature and format output
          temp=$(echo "$weather" | sed 's/^[^+]*\(+[^°]*°[CF]\)/\1/')
          echo "$icon $temp"
        fi
      '';
      interval = 1800;          # Update every 30 minutes
      format = "{}";
      on-click = "xdg-open 'https://wttr.in/Istanbul'";  # Detailed forecast
      tooltip = true;
      tooltip-format = "Hava Durumu - Istanbul\nTıkla: Detaylı tahmin";
    };

    # ┌─ Right Section: System Monitoring ───────────────────────────────────────────────────────┐
    
    # 💻 CPU Usage Monitoring
    cpu = {
      format = "󰻠 {usage}%";                     # Primary: Usage percentage
      format-alt = "󰻠 {avg_frequency} GHz";      # Alternative: Frequency display
      interval = 2;                             # Update every 2 seconds
      on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title System_Monitor btop'";
      tooltip = true;
      tooltip-format = "CPU Usage: {usage}%\nLoad: {load}\n󰑐 Sağ tık: System Monitor";
    };

    # 🧠 Memory Usage Monitoring  
    memory = {
      format = "󰍛 {}%";                         # Primary: Usage percentage
      format-alt = "󰍛 {used} GiB";              # Alternative: Absolute usage
      interval = 2;                             # Update every 2 seconds
      on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title System_Monitor btop'";
      tooltip = true;
      tooltip-format = "RAM: {used} GiB / {total} GiB ({percentage}%)\n󰑐 Sağ tık: System Monitor";
    };

    # 💾 Disk Usage Monitoring
    disk = {
      format = "󰋊 {percentage_used}%";           # Disk usage percentage
      interval = 300;                           # Update every 5 minutes
      on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title float_kitty btop'";
    };

    # 🌡️ CPU Temperature Monitoring
    temperature = {
      interval = 2;                             # Update every 2 seconds
      format = "{icon} {temperatureC}°C";       # Temperature with status icon
      format-critical = "{icon} {temperatureC}°C";  # Critical temperature format
      max-length = 12;                          # Prevent layout overflow
      critical-threshold = 85;                  # Critical temperature threshold
      on-click-right = "hyprctl dispatch exec '[float; center; size 950 650] kitty --override font_size=14 --title System_Monitor btop'";
      format-icons = ["󱃃" "󱃃" "󱃂" "󱃅"];       # Temperature status icons
      hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";  # Hardware sensor path
      input-filename = "temp1_input";           # Sensor input file
      tooltip = true;
      tooltip-format = "CPU Temperature: {temperatureC}°C\n󰑐 Sağ tık: System Monitor";
    };

    # 🎵 Media Player Control (MPRIS)
    mpris = {
      format = "{player_icon} {dynamic}";       # Player icon + dynamic content
      format-paused = "{status_icon} <i>{dynamic}</i>";  # Italicize when paused
      format-stopped = "";                      # Hide when stopped
      
      # Player-specific icons
      player-icons = {
        default = "▶";
        mpv = "󰐹";        # MPV video player
        spotify = "󰓇";     # Spotify music streaming
        firefox = "󰈹";     # Firefox browser media
        chrome = "󰊯";      # Chrome browser media
        vlc = "󰕼";         # VLC media player
        rhythmbox = "󰓃";   # Rhythmbox music player
        audacious = "󰓃";   # Audacious music player
        kdeconnect = "󰄡"; # KDE Connect phone media
      };
      
      # Playback status icons
      status-icons = {
        paused = "⏸";      # Pause symbol
        playing = "▶";     # Play symbol
        stopped = "⏹";     # Stop symbol
      };
      
      max-length = 40;                          # Prevent overly long track names
      on-click = "playerctl play-pause";        # Toggle playback
      on-click-right = "playerctl next";        # Next track
      on-click-middle = "playerctl previous";   # Previous track
      tooltip = true;
      tooltip-format = "Now Playing: {title}\nBy: {artist}\nAlbum: {album}\n\n󱎫 Sol: Play/Pause\n󰦝 Orta: Previous\n󰑐 Sağ: Next";
    };

    # ┌─ Right Section: Connectivity & Network ──────────────────────────────────────────────────┐
    
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
      format-wifi = "󰤨 {signalStrength}%";      # WiFi with signal strength
      format-ethernet = "󰤥 Connected";          # Ethernet connection
      format-linked = "󰤥 {ifname} (No IP)";     # Connected but no IP
      format-disconnected = "󰤭 Disconnected";   # No connection
      on-click-right = "rofi-iwmenu";           # Network interface menu
      on-click-middle = "rofi-wifi";            # WiFi selection menu
      tooltip-format = "Connected to {essid}\nIP: {ipaddr}\nGateway: {gwaddr}";
      
      # Detailed WiFi tooltip
      tooltip-format-wifi = ''
        Network: {essid}
        Signal: {signalStrength}%
        Speed: {frequency} MHz
        IP: {ipaddr}
        Gateway: {gwaddr}
        
        󰑐 Sağ tık: Network Menu
        󰦝 Orta tık: WiFi Selection
      '';
      
      # Ethernet connection tooltip
      tooltip-format-ethernet = ''
        Connection: Ethernet
        IP: {ipaddr}
        Gateway: {gwaddr}
        Speed: {bandwidthUpBits} ↑ {bandwidthDownBits} ↓
      '';
    };

    # 📶 Bluetooth Connectivity Management
    bluetooth = {
      format = "{icon}";                        # Show appropriate icon
      format-disabled = "<span foreground='${red}'>󰂲</span>";      # Disabled state
      format-off = "<span foreground='${red}'>󰂲</span>";           # Off state
      format-on = "<span foreground='${cyan}'>󰂯</span>";          # On but not connected
      format-connected = "<span foreground='${blue}'>{icon} {device_alias}</span>";         # Connected device
      format-connected-battery = "<span foreground='${blue}'>{icon} {device_alias} {device_battery_percentage}%</span>";  # With battery
      
      # Device-specific icons
      format-icons = {
        default = "󰂱";      # Generic Bluetooth
        headset = "󰋋";      # Headset
        headphone = "󰋋";    # Headphones
        earbuds = "󰋎";      # Earbuds
        speaker = "󰓃";      # Speaker
        phone = "󰏲";        # Phone
        portable = "󰄋";     # Portable device
        computer = "󰟀";     # Computer
        keyboard = "󰌌";     # Keyboard
        mouse = "󰍽";        # Mouse
        gamepad = "󰊱";      # Game controller
        watch = "󰖉";        # Smart watch
      };
      
      tooltip = true;
      tooltip-format = "Bluetooth: {status}\nController: {controller_alias}\n\nTıkla: Bluetooth Manager";
      tooltip-format-connected = "Connected: {device_alias}\nBattery: {device_battery_percentage}%";
      tooltip-format-enumerate-connected = "Device: {device_alias}\nMAC: {device_address}";
      tooltip-format-enumerate-connected-battery = "Device: {device_alias}\nBattery: {device_battery_percentage}%";
      on-click = "blueman-manager";             # Open Bluetooth manager
    };

    # ┌─ Right Section: Audio Controls ──────────────────────────────────────────────────────────┐
    
    # 🔊 Audio Output (Speakers/Headphones)
    "pulseaudio#sink" = {
      format = "{icon} {volume}%";              # Icon + volume percentage
      format-muted = "󰝟 Muted";                 # Muted state
      format-bluetooth = "󰂱 {volume}%";         # Bluetooth audio output
      format-bluetooth-muted = "󰂲 Muted";       # Bluetooth muted
      format-headphone = "󰋋 {volume}%";         # Headphone output
      format-headphone-muted = "󰋋 Muted";       # Headphone muted
      
      # Audio device icons
      format-icons = {
        headphone = ["󰋋"];   # Headphones
        headset = ["󰋎"];     # Headset
        phone = ["󰏲"];       # Phone audio
        default = ["󰕿" "󰖀" "󰕾"];  # Speaker volume levels
      };
      
      scroll-step = 5;                          # Volume adjustment step
      max-volume = 100;                         # Maximum volume limit
      on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";           # Toggle mute
      on-click-middle = "pactl set-sink-volume @DEFAULT_SINK@ 50%";     # Set to 50%
      on-click-right = "pavucontrol";                                   # Audio control panel
      on-scroll-down = "pactl set-sink-volume @DEFAULT_SINK@ -1%";      # Volume down
      on-scroll-up = "pactl set-sink-volume @DEFAULT_SINK@ +1%";        # Volume up
      tooltip = true;
      tooltip-format = "Volume: {volume}%\nDevice: {desc}\n\n󱎫 Sol: Mute Toggle\n󰦝 Orta: Set 50%\n󰑐 Sağ: Audio Control";
    };

    # 🎤 Audio Input (Microphone)
    "pulseaudio#source" = {
      format = "{format_source}";
      format-source = "󰍬 {volume}%";            # Microphone with volume
      format-source-muted = "<span foreground='${red}'>󰍭</span>";  # Muted microphone
      max-volume = 40;                          # Reasonable microphone limit
      scroll-step = 5;                          # Volume adjustment step
      on-click = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";       # Toggle mute
      on-click-middle = "pactl set-source-volume @DEFAULT_SOURCE@ 40%"; # Set to 40%
      on-click-right = "pavucontrol";                                   # Audio control panel
      on-scroll-down = "pactl set-source-volume @DEFAULT_SOURCE@ -1%";  # Volume down
      on-scroll-up = "pactl set-source-volume @DEFAULT_SOURCE@ +1%";    # Volume up
      tooltip = true;
      tooltip-format = "Microphone: {volume}%\nDevice: {source_desc}\n\n󱎫 Sol: Mute Toggle\n󰦝 Orta: Set 40%\n󰑐 Sağ: Audio Control";
    };

    # ┌─ Right Section: Power & System Status ───────────────────────────────────────────────────┐
    
    # 🔋 Battery Status & Power Management
    battery = {
      interval = 30;                            # Check every 30 seconds
      
      # Battery level thresholds
      states = {
        warning = 30;       # Show warning at 30%
        critical = 15;      # Show critical at 15%
        full = 95;          # Consider full at 95%
      };
      
      format = "{icon} {capacity}%";            # Icon + percentage
      format-charging = "󰂄 {capacity}%";        # Charging state
      format-plugged = "󰂄 {capacity}%";         # Plugged in
      format-full = "󰁹 {capacity}%";            # Full battery
      format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂"];  # Battery level icons
      format-time = "{H}h {M}m";                # Time remaining format
      tooltip = true;
      tooltip-format = "Battery: {capacity}%\nTime remaining: {time}\nPower: {power} W";
    };

    # ┌─ Right Section: System Controls ─────────────────────────────────────────────────────────┐
    
    # 🔔 Notification Center (SwayNC Integration)
    "custom/notification" = {
      tooltip = true;
      format = "{icon}";                        # Show notification state icon
      
      # Notification state icons with color coding
      format-icons = {
        notification = "<span foreground='${red}'>󰂚</span>";              # New notifications
        none = "󰂚";                                                      # No notifications
        dnd-notification = "<span foreground='${red}'>󰂛</span>";         # DND with notifications
        dnd-none = "󰂛";                                                  # DND without notifications
        inhibited-notification = "<span foreground='${red}'>󰂚</span>";   # Inhibited with notifications
        inhibited-none = "󰂚";                                            # Inhibited without notifications
        dnd-inhibited-notification = "<span foreground='${red}'>󰂛</span>"; # DND + Inhibited with notifications
        dnd-inhibited-none = "󰂛";                                        # DND + Inhibited without notifications
      };
      
      return-type = "json";                     # Expect JSON response
      exec-if = "which swaync-client";          # Only run if SwayNC is available
      exec = "swaync-client -swb";              # Get notification status
      on-click = "swaync-client -t -sw";        # Toggle notification panel
      on-click-right = "swaync-client -d -sw";  # Clear all notifications
      escape = true;                            # Escape special characters
      tooltip-format = "Notifications\n\n󱎫 Sol: Toggle Panel\n󰑐 Sağ: Clear All";
    };

    # 📌 System Tray for Background Applications
    tray = {
      icon-size = 18;                           # Tray icon size
      spacing = 6;                              # Space between icons
      show-passive-items = true;                # Show inactive tray items
      reverse-direction = true;                 # Reverse icon order
      smooth-scrolling-threshold = 0;          # Disable smooth scrolling
      format = "{icon}";                        # Show just the icon
      tooltip = true;                           # Enable tooltips
      tooltip-format = "{title}";               # Show application title
      tray-light-mode = "auto";                 # Auto-detect light/dark mode
      require-input = true;                     # Require user input for interaction
      
      # Custom icons for specific applications
      special-icons = {
        firefox = "󰈹";        # Firefox browser
        zen-browser = "󰈹";    # Zen browser
        telegram = "󰔁";       # Telegram messenger
        discord = "󰙯";        # Discord chat
        spotify = "󰓇";        # Spotify music
        steam = "󰓓";          # Steam gaming platform
      };
    };
  };
}

