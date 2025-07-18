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
    # Emoji desteği için gerekli paketler
    noto-fonts-emoji
    noto-fonts
    fontconfig
  ];

  # =============================================================================
  # Font Configuration - Emoji desteği
  # =============================================================================
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  # Manuel fontconfig emoji desteği
  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <match target="pattern">
        <test qual="any" name="family">
          <string>monospace</string>
        </test>
        <edit name="family" mode="prepend" binding="weak">
          <string>JetBrainsMono Nerd Font</string>
          <string>Noto Color Emoji</string>
        </edit>
      </match>
      
      <match target="font">
        <test name="family" compare="contains">
          <string>Emoji</string>
        </test>
        <edit name="color" mode="assign">
          <bool>true</bool>
        </edit>
      </match>
    </fontconfig>
  '';

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
      font = "JetBrainsMono Nerd Font 12, Noto Color Emoji 12";
      
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
      
      # App-specific enhancements
      
      # Spotify - music themed with icon
      [app-name=Spotify]
      format=<span color="${colors.green}" size="12pt" weight="600">♪ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.green}" size="11pt" style="italic">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.green}99
      border-size=2
      default-timeout=4000
      markup=1
      
      # System notifications
      [app-name="notify-send"]
      format=<span color="${colors.blue}" size="12pt" weight="600">ⓘ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.blue}99
      markup=1
      
      # WhatsApp/Messages - communication
      [app-name=whatsapp-nativefier-d40211]
      format=<span color="${colors.cyan}" size="12pt" weight="600">♪ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.cyan}99
      border-size=2
      default-timeout=12000
      markup=1
      
      # Firefox - web browsing
      [app-name=firefox]
      format=<span color="${colors.orange}" size="12pt" weight="600">● %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.orange}99
      default-timeout=8000
      markup=1
      
      # Chrome notifications
      [app-name=Google-chrome]
      [app-name=google-chrome]
      format=<span color="${colors.yellow}" size="12pt" weight="600">● %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.yellow}99
      default-timeout=8000
      markup=1
      
      # Brave notifications
      [app-name=brave]
      format=<span color="${colors.yellow}" size="12pt" weight="600">● %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.yellow}99
      default-timeout=8000
      markup=1
 
      # MPD/Music notifications
      [category=mpd]
      format=<span color="${colors.purple}" size="12pt" weight="600">♫ Music</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.purple}" size="11pt" style="italic">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.purple}99
      default-timeout=3000
      group-by=category
      markup=1
      
      # Discord/Communication apps
      [app-name=discord]
      [app-name=webcord]
      format=<span color="${colors.cyan}" size="12pt" weight="600">♪ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.cyan}99
      markup=1
      
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
      format=<span color="${colors.blue}" size="12pt" weight="600">● Network</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
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
    # Emoji desteği için
    LC_ALL = "en_US.UTF-8";
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
    "notify-no-markup" = "MAKO_MARKUP=0 notify-send 'No Markup' '★ ♪ ● ⚡ ▲'";
    "font-check" = "fc-list | grep -i emoji";
    "font-reload" = "fc-cache -f -v";
    "mako-full-restart" = "pkill mako; fc-cache -f -v; sleep 2; mako &";
    "emoji-debug" = "echo 'Testing: ⭐ 🎵 📱' | od -c";
    
    # Mako status and control - Updated for waybar integration
    "mako-stat" = "mako-status";
    "mako-click" = "mako-status click";
    "mako-right-click" = "mako-status right-click";
    "mako-middle-click" = "mako-status middle-click";
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
