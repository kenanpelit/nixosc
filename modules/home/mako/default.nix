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
      
      # Typography - emoji desteği için font fallback
      font = "Hack Nerd Font Mono 12";
      
      # Colors - enhanced Tokyo Night
      background-color = colors.base + "f0";  # 94% opacity for better depth
      text-color = colors.text;
      border-color = colors.purple + "cc";    # Semi-transparent border
      
      # Dimensions - adjusted for larger fonts
      width = 540;
      height = 320;
      padding = "18,20";
      border-size = 2;
      border-radius = 14;  # Slightly more rounded

      # History settings
      max-history = 50;        # Maksimum 50 bildirim history'de tut
  
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
      markup = 1;
      format = ''<span color="${colors.cyan}" size="12pt" weight="600">%a</span>\n<span color="${colors.text}" size="13pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="12pt">%b</span>'';
    };
    
    # Enhanced styling - app-specific improvements
    extraConfig = ''
      # Grouped notifications - better styling
      [grouped]
      format=<span color="${colors.purple}" size="11pt" weight="600">(%g) %a</span>\n<span color="${colors.text}" size="13pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="10pt">%b</span>
      border-size=3
      border-color=${colors.purple}
      markup=1
      
      # Urgency levels with better visual distinction
      [urgency=normal]
      background-color=${colors.base}f0
      text-color=${colors.text}
      border-color=${colors.blue}aa
      border-size=2
      markup=1
      
      [urgency=critical]
      background-color=${colors.base}f5
      text-color=${colors.text}
      border-color=${colors.red}
      border-size=3
      default-timeout=0
      format=<span color="${colors.red}" size="12pt" weight="700">⚠ %a</span>\n<span color="${colors.text}" size="14pt" weight="800">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      markup=1
      
      [urgency=low]
      background-color=${colors.base}dd
      text-color=${colors.subtext1}
      border-color=${colors.surface2}80
      border-size=1
      default-timeout=5000
      markup=1
      
      # App-specific enhancements with click actions
      
      # Ferdium - WhatsApp, Discord, Telegram etc.
      [app-name=ferdium]
      format=<span color="${colors.cyan}" size="12pt" weight="600">💬 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.cyan}99
      border-size=2
      default-timeout=12000
      markup=1
      on-button-left=exec ferdium
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # Discord - native Discord app
      [app-name=discord]
      format=<span color="${colors.cyan}" size="12pt" weight="600">💬 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.cyan}99
      markup=1
      on-button-left=exec discord
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # WebCord - alternative Discord client
      [app-name=WebCord]
      format=<span color="${colors.cyan}" size="12pt" weight="600">💬 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.cyan}99
      markup=1
      on-button-left=exec webcord
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # Spotify - music themed with icon
      [app-name=Spotify]
      format=<span color="${colors.green}" size="12pt" weight="600">♪ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.green}" size="11pt" style="italic">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.green}99
      border-size=2
      default-timeout=4000
      markup=1
      on-button-left=exec spotify
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # System notifications
      [app-name="notify-send"]
      format=<span color="${colors.blue}" size="12pt" weight="600">ⓘ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.blue}99
      markup=1
      
      # WhatsApp/Messages - native WhatsApp
      [app-name=whatsapp-nativefier-d40211]
      [app-name=whatsapp]
      format=<span color="${colors.cyan}" size="12pt" weight="600">💬 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.cyan}99
      border-size=2
      default-timeout=12000
      markup=1
      on-button-left=exec whatsapp-nativefier-d40211
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # Firefox - web browsing
      [app-name=firefox]
      format=<span color="${colors.orange}" size="12pt" weight="600">🌐 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.orange}99
      default-timeout=8000
      markup=1
      on-button-left=exec firefox
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # Chrome notifications
      [app-name=Google-chrome]
      [app-name=google-chrome]
      format=<span color="${colors.yellow}" size="12pt" weight="600">🌐 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.yellow}99
      default-timeout=8000
      markup=1
      on-button-left=exec google-chrome-stable
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # Brave notifications
      [app-name=brave]
      [app-name=brave-browser]
      format=<span color="${colors.yellow}" size="12pt" weight="600">🌐 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.yellow}99
      default-timeout=8000
      markup=1
      on-button-left=exec brave
      on-button-middle=dismiss
      on-button-right=dismiss
 
      # MPD/Music notifications
      [category=mpd]
      format=<span color="${colors.purple}" size="12pt" weight="600">♫ Music</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.purple}" size="11pt" style="italic">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.purple}99
      default-timeout=3000
      group-by=category
      markup=1
      
      # Telegram
      [app-name=telegram]
      [app-name=telegram-desktop]
      format=<span color="${colors.cyan}" size="12pt" weight="600">✈️ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.cyan}99
      markup=1
      on-button-left=exec telegram-desktop
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # Slack
      [app-name=slack]
      format=<span color="${colors.purple}" size="12pt" weight="600">💼 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.purple}99
      markup=1
      on-button-left=exec slack
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # Signal
      [app-name=signal]
      [app-name=signal-desktop]
      format=<span color="${colors.blue}" size="12pt" weight="600">🔒 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.blue}99
      markup=1
      on-button-left=exec signal-desktop
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # Email clients
      [app-name=thunderbird]
      format=<span color="${colors.blue}" size="12pt" weight="600">📧 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.blue}99
      markup=1
      on-button-left=exec thunderbird
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # Battery/Power notifications
      [summary~="Battery"]
      [summary~="Power"]
      format=<span color="${colors.yellow}" size="12pt" weight="600">⚡ Power</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.yellow}99
      markup=1
      
      # Network notifications
      [summary~="Network"]
      [summary~="WiFi"]
      [summary~="Connection"]
      format=<span color="${colors.blue}" size="12pt" weight="600">🌐 Network</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.blue}99
      markup=1
      
      # System update notifications
      [summary~="Update"]
      [summary~="Upgrade"]
      format=<span color="${colors.green}" size="12pt" weight="600">▲ System</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.green}99
      default-timeout=12000
      markup=1
      
      # Modes
      [mode=away]
      default-timeout=0
      ignore-timeout=1
      background-color=${colors.surface0}cc
      text-color=${colors.subtext0}
      markup=1
      
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
    "notify-test" = "notify-send Test Message";
    "notify-critical" = "notify-send -u critical Critical Alert";
    "notify-music" = "notify-send -a Spotify Now Playing";
    "notify-system" = "notify-send System Update";
    "notify-emoji" = "notify-send 'Symbol Test' '★ ♪ ● ⚡ ▲'";
    "notify-simple" = "notify-send Star Check";
    
    # Test notifications for apps
    "notify-ferdium" = "notify-send -a ferdium 'Ferdium Test' 'Click to open Ferdium'";
    "notify-discord" = "notify-send -a discord 'Discord Test' 'Click to open Discord'";
    "notify-webcord" = "notify-send -a WebCord 'WebCord Test' 'Click to open WebCord'";
    "notify-brave" = "notify-send -a brave 'Brave Test' 'Click to open Brave'";
    
    # Mako status and control - Updated for waybar integration
    "mako-stat" = "mako-status";
    "mako-click" = "mako-status click";
    "mako-right-click" = "mako-status right-click";
    "mako-middle-click" = "mako-status middle-click";
    "mako-restart" = "pkill mako; sleep 1; mako &";
    "mako-start" = "mako &";
    "mako-stop" = "pkill mako";
    "mako-logs" = "journalctl --user -t mako -f";

  };
}

