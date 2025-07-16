# modules/home/mako/default.nix
{ pkgs, ... }:
let
  # Tokyo Night Storm Colors optimized for Mako
  colors = {
    base = "#24283b";
    mantle = "#1f2335";
    surface0 = "#292e42";
    surface1 = "#414868";
    surface2 = "#565f89";
    text = "#c0caf5";
    subtext0 = "#9aa5ce";
    subtext1 = "#a9b1d6";
    green = "#9ece6a";
    blue = "#7aa2f7";
    purple = "#bb9af7";
    red = "#f7768e";
    orange = "#ff9e64";
    yellow = "#e0af68";
    cyan = "#7dcfff";
  };
in
{
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [ 
    mako
    libnotify  # For notify-send command
  ];

  # =============================================================================
  # Mako Configuration - Enhanced but Stable
  # =============================================================================
  services.mako = {
    enable = true;
    
    # All configuration now goes under settings
    settings = {
      # Positioning - slightly better spacing
      anchor = "top-right";
      margin = "15,20,0,0";
      
      # Typography - modern but safe with larger fonts
      font = "JetBrainsMono Nerd Font 12";
      
      # Colors - enhanced Tokyo Night
      background-color = colors.base + "f0";  # 94% opacity for better depth
      text-color = colors.text;
      border-color = colors.purple + "cc";    # Semi-transparent border
      
      # Dimensions - adjusted for larger fonts
      #width = 450;
      #height = 160;
      width = 540;
      height = 320;
      padding = "18,20";
      border-size = 2;
      border-radius = 14;  # Slightly more rounded

      # History settings
      max-history = 50;        # Maksimum 50 bildirim history'de tut
      # max-history = 0;       # History'yi tamamen kapat
  
      # Visual enhancements
      progress-color = "over " + colors.cyan;
      icons = 1;
      max-icon-size = 64;  # Larger icons to match bigger fonts
      icon-location = "left";  # Modern placement
      
      # Timing - optimized
      default-timeout = 8000;
      ignore-timeout = 0;
      
      # Organization
      group-by = "app-name";  # Cleaner grouping
      layer = "overlay";
      max-visible = 4;  # One more for convenience
      
      # Enhanced format with larger fonts and better hierarchy
      format = ''<span color="${colors.cyan}" size="11pt" weight="600">%a</span>\n<span color="${colors.text}" size="12pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>'';
    };
    
    # Enhanced styling - app-specific improvements
    extraConfig = ''
      # Grouped notifications - better styling
      [grouped]
      format=<span color="${colors.purple}" size="11pt" weight="600">(%g) %a</span>\n<span color="${colors.text}" size="13pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="10pt">%b</span>
      border-size=3
      border-color=${colors.purple}
      
      # Urgency levels with better visual distinction
      [urgency=normal]
      background-color=${colors.base}f0
      text-color=${colors.text}
      border-color=${colors.blue}aa
      border-size=2
      
      [urgency=critical]
      background-color=${colors.base}f5
      text-color=${colors.text}
      border-color=${colors.red}
      border-size=3
      default-timeout=0
      format=<span color="${colors.red}" size="12pt" weight="700">⚠ %a</span>\n<span color="${colors.text}" size="14pt" weight="800">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      
      [urgency=low]
      background-color=${colors.base}dd
      text-color=${colors.subtext1}
      border-color=${colors.surface2}80
      border-size=1
      default-timeout=5000
      
      # App-specific enhancements
      
      # Spotify - music themed with icon
      [app-name=Spotify]
      format=<span color="${colors.green}" size="12pt" weight="600">♪ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.green}" size="11pt" style="italic">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.green}99
      border-size=2
      default-timeout=4000
      
      # System notifications
      [app-name="notify-send"]
      format=<span color="${colors.blue}" size="12pt" weight="600">ⓘ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.blue}99
      
      # WhatsApp/Messages - communication
      [app-name=whatsapp-nativefier-d40211]
      format=<span color="${colors.cyan}" size="12pt" weight="600">💬 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.cyan}99
      border-size=2
      default-timeout=12000
      
      # Firefox - web browsing
      [app-name=firefox]
      format=<span color="${colors.orange}" size="12pt" weight="600">🦊 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.orange}99
      default-timeout=8000
      
      # Chrome notifications
      [app-name=Google-chrome]
      [app-name=google-chrome]
      format=<span color="${colors.yellow}" size="12pt" weight="600">🌐 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.yellow}99
      default-timeout=8000
      
      # Chrome notifications
      [app-name=brave]
      [app-name=brave]
      format=<span color="${colors.yellow}" size="12pt" weight="600">🌐 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.yellow}99
      default-timeout=8000
 
      # MPD/Music notifications
      [category=mpd]
      format=<span color="${colors.purple}" size="12pt" weight="600">♫ Music</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.purple}" size="11pt" style="italic">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.purple}99
      default-timeout=3000
      group-by=category
      
      # Discord/Communication apps
      [app-name=discord]
      [app-name=webcord]
      format=<span color="${colors.cyan}" size="12pt" weight="600">💬 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.cyan}99
      
      # Battery/Power notifications
      [summary~="Battery"]
      [summary~="Power"]
      format=<span color="${colors.yellow}" size="12pt" weight="600">🔋 Power</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.yellow}99
      
      # Network notifications
      [summary~="Network"]
      [summary~="WiFi"]
      [summary~="Connection"]
      format=<span color="${colors.blue}" size="12pt" weight="600">📶 Network</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.blue}99
      
      # System update notifications
      [summary~="Update"]
      [summary~="Upgrade"]
      format=<span color="${colors.green}" size="12pt" weight="600">📦 System</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.green}99
      default-timeout=12000
      
      # Modes
      [mode=away]
      default-timeout=0
      ignore-timeout=1
      background-color=${colors.surface0}cc
      text-color=${colors.subtext0}
      
      [mode=do-not-disturb]
      invisible=1
    '';
  };

  # =============================================================================
  # Environment Variables and Aliases
  # =============================================================================
  home.sessionVariables = {
    # Ensure mako is used as the notification daemon
    NOTIFY_SEND_BIN = "${pkgs.libnotify}/bin/notify-send";
  };

  # Enhanced aliases for better mako control
  home.shellAliases = {
    # Basic mako control
    "mako-reload" = "makoctl reload";
    "mako-dismiss" = "makoctl dismiss";
    "mako-dismiss-all" = "makoctl dismiss --all";
    "mako-history" = "makoctl history";
    "mako-restore" = "makoctl restore";
    
    # Enhanced test notifications
    "notify-test" = "notify-send 'Test Notification' 'This is a test message from Mako!' --icon=dialog-information";
    "notify-critical" = "notify-send -u critical 'Critical Alert' 'This is a critical notification!'";
    "notify-music" = "notify-send -a 'Spotify' 'Now Playing' 'Artist - Song Title'";
    "notify-system" = "notify-send 'System Update' 'Updates are available for installation'";
    
    # Mako status and control - Updated for waybar integration
    "mako-stat" = "mako-status";
    "mako-click" = "mako-status click";
    "mako-right-click" = "mako-status right-click";
    "mako-middle-click" = "mako-status middle-click";
    "mako-running" = "pgrep -f mako && echo 'Mako is running' || echo 'Mako is not running'";
    "mako-restart" = "pkill mako; sleep 1; mako &";
    "mako-start" = "mako &";
    "mako-stop" = "pkill mako";
    "mako-logs" = "journalctl --user -t mako -f";
    
    # Daemon control aliases
    "mako-daemon-start" = "systemctl --user start mako-daemon";
    "mako-daemon-stop" = "systemctl --user stop mako-daemon";
    "mako-daemon-restart" = "systemctl --user restart mako-daemon";
    "mako-daemon-status" = "systemctl --user status mako-daemon";
    "mako-daemon-logs" = "journalctl --user -u mako-daemon -f";
  };
}

