# modules/home/mako/default.nix
# ==============================================================================
# Mako Notification Daemon Configuration - Catppuccin Mocha Themed
# ==============================================================================
# Basic colors managed by Catppuccin module, but custom formatting preserved
# This module handles advanced app-specific formatting and behaviors
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, lib, ... }:
let
  # Catppuccin Mocha Colors - for custom formatting only
  colors = {
    base = "#1e1e2e";        # Ana arka plan
    mantle = "#181825";      # Koyu arka plan
    surface0 = "#313244";     # Yüzey 0
    surface1 = "#45475a";     # Yüzey 1
    surface2 = "#585b70";     # Yüzey 2
    text = "#cdd6f4";        # Ana metin
    subtext0 = "#a6adc8";    # Alt metin 0
    subtext1 = "#bac2de";    # Alt metin 1
    overlay0 = "#6c7086";    # Overlay 0
    overlay1 = "#7f849c";    # Overlay 1
    
    # Accent colors for app-specific formatting
    rosewater = "#f5e0dc";
    flamingo = "#f2cdcd";
    pink = "#f5c2e7";
    mauve = "#cba6f7";       # Ana accent (tema ile uyumlu)
    red = "#f38ba8";
    maroon = "#eba0ac";
    peach = "#fab387";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    teal = "#94e2d5";
    sky = "#89dceb";
    sapphire = "#74c7ec";
    blue = "#89b4fa";
    lavender = "#b4befe";
  };
in
{
  options.my.user.mako = {
    enable = lib.mkEnableOption "Mako notification daemon";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Mako Configuration - Advanced Configuration
    # =============================================================================
    services.mako = {
      enable = true;
    
    settings = {
      # Positioning - optimal for Hyprland
      anchor = "top-right";
      margin = "15,20,0,0";
      
      # Typography - consistent with system theme
      font = "Maple Mono NF 12";
      
      # NOTE: Basic colors (background-color, text-color, border-color, progress-color) 
      # are managed by Catppuccin module for consistency
      
      # Dimensions - optimized
      width = 540;
      height = 320;
      padding = "18,20";
      border-size = 2;
      border-radius = 12;  # Modern rounded corners

      # History settings
      max-history = 50;
  
      # Visual enhancements (non-conflicting)
      icons = 1;
      max-icon-size = 64;
      icon-location = "left";
      
      # Timing - user-friendly
      default-timeout = 8000;
      ignore-timeout = 0;
      
      # Organization
      group-by = "app-name";
      layer = "overlay";
      max-visible = 4;
     
      # Enhanced format with custom icons and colors
      markup = 1;
      format = ''<span color="${colors.blue}" size="12pt" weight="600">%a</span>\n<span color="${colors.text}" size="13pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="12pt">%b</span>'';
    };
    
    # =============================================================================
    # App-specific Custom Formatting - The Magic! ✨
    # =============================================================================
    extraConfig = ''
      # Grouped notifications with custom styling
      [grouped]
      format=<span color="${colors.mauve}" size="11pt" weight="600">(%g) %a</span>\n<span color="${colors.text}" size="13pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="10pt">%b</span>
      border-size=3
      border-color=${colors.mauve}
      markup=1
      
      # Enhanced urgency levels with custom formatting
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
      
      # 🎨 Beautiful App-specific Formatting with Icons
      
      # 💬 Messaging Apps
      [app-name=ferdium]
      format=<span color="${colors.teal}" size="12pt" weight="600">💬 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.teal}99
      border-size=2
      default-timeout=12000
      markup=1
      on-button-left=exec ferdium
      on-button-middle=dismiss
      on-button-right=dismiss
      
      [app-name=discord]
      format=<span color="${colors.teal}" size="12pt" weight="600">💬 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.teal}99
      markup=1
      on-button-left=exec discord
      on-button-middle=dismiss
      on-button-right=dismiss
      
      [app-name=WebCord]
      [app-name=webcord]
      format=<span color="${colors.teal}" size="12pt" weight="600">💬 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.teal}99
      markup=1
      on-button-left=exec webcord
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # 🎵 Music Apps
      [app-name=Spotify]
      [app-name=spotify]
      format=<span color="${colors.green}" size="12pt" weight="600">🎵 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.green}" size="11pt" style="italic">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.green}99
      border-size=2
      default-timeout=4000
      markup=1
      on-button-left=exec spotify
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # 🌐 Browsers
      [app-name=firefox]
      format=<span color="${colors.peach}" size="12pt" weight="600">🌐 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.peach}99
      default-timeout=8000
      markup=1
      on-button-left=exec firefox
      on-button-middle=dismiss
      on-button-right=dismiss
      
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
      
      # ♫ Music/MPD
      [category=mpd]
      format=<span color="${colors.mauve}" size="12pt" weight="600">♫ Music</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.mauve}" size="11pt" style="italic">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.mauve}99
      default-timeout=3000
      group-by=category
      markup=1
      
      # ✈️ Communication
      [app-name=telegram]
      [app-name=telegram-desktop]
      format=<span color="${colors.sky}" size="12pt" weight="600">✈️ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.sky}99
      markup=1
      on-button-left=exec telegram-desktop
      on-button-middle=dismiss
      on-button-right=dismiss
      
      [app-name=whatsapp-nativefier-d40211]
      [app-name=whatsapp]
      format=<span color="${colors.teal}" size="12pt" weight="600">💬 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.teal}99
      border-size=2
      default-timeout=12000
      markup=1
      on-button-left=exec whatsapp-nativefier-d40211
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # 💼 Work Apps
      [app-name=slack]
      format=<span color="${colors.mauve}" size="12pt" weight="600">💼 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.mauve}99
      markup=1
      on-button-left=exec slack
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # 🔒 Security
      [app-name=signal]
      [app-name=signal-desktop]
      format=<span color="${colors.blue}" size="12pt" weight="600">🔒 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.blue}99
      markup=1
      on-button-left=exec signal-desktop
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # 📧 Email
      [app-name=thunderbird]
      format=<span color="${colors.blue}" size="12pt" weight="600">📧 %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.blue}99
      markup=1
      on-button-left=exec thunderbird
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # ⚡ System Notifications
      [summary~="Battery"]
      [summary~="Power"]
      format=<span color="${colors.yellow}" size="12pt" weight="600">⚡ Power</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.yellow}99
      markup=1
      
      [summary~="Network"]
      [summary~="WiFi"]
      [summary~="Connection"]
      format=<span color="${colors.sapphire}" size="12pt" weight="600">🌐 Network</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.sapphire}99
      markup=1
      
      [summary~="Update"]
      [summary~="Upgrade"]
      format=<span color="${colors.green}" size="12pt" weight="600">⬆ System</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.green}99
      default-timeout=12000
      markup=1
      
      # ⌨ Development
      [app-name=kitty]
      format=<span color="${colors.overlay1}" size="12pt" weight="600">⌨ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.overlay1}99
      markup=1
      on-button-left=exec kitty
      on-button-middle=dismiss
      on-button-right=dismiss
      
      [app-name=code]
      [app-name=codium]
      [app-name=vscode]
      format=<span color="${colors.lavender}" size="12pt" weight="600">⚛ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.lavender}99
      markup=1
      on-button-left=exec code
      on-button-middle=dismiss
      on-button-right=dismiss
      
      # ℹ System
      [app-name="notify-send"]
      format=<span color="${colors.blue}" size="12pt" weight="600">ℹ %a</span>\n<span color="${colors.text}" size="14pt" weight="700">%s</span>\n<span color="${colors.subtext1}" size="11pt">%b</span>
      background-color=${colors.base}f0
      border-color=${colors.blue}99
      markup=1
      
      # Special modes
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
    NOTIFY_SEND_BIN = "${pkgs.libnotify}/bin/notify-send";
  };

  # Enhanced aliases with theme-appropriate tests
  home.shellAliases = {
    # Basic mako control
    "mako-reload" = "makoctl reload";
    "mako-dismiss" = "makoctl dismiss";
    "mako-dismiss-all" = "makoctl dismiss --all";
    "mako-history" = "makoctl history";
    "mako-restore" = "makoctl restore";
    
    # Test notifications - Catppuccin themed
    "notify-test" = "notify-send 'Catppuccin Test' 'Mako notification with Catppuccin Mocha theme'";
    "notify-critical" = "notify-send -u critical 'Critical Alert' 'This is a critical notification'";
    "notify-music" = "notify-send -a spotify 'Now Playing' 'Test song by Test Artist'";
    "notify-system" = "notify-send 'System Update' 'Updates are available'";
    "notify-emoji" = "notify-send 'Emoji Test' '🎵 ⚡ 🌐 💬 📧'";
    
    # App-specific tests
    "notify-ferdium" = "notify-send -a ferdium 'Ferdium Test' 'Click to open messaging apps'";
    "notify-discord" = "notify-send -a discord 'Discord Test' 'New message received'";
    "notify-webcord" = "notify-send -a webcord 'WebCord Test' 'Discord alternative notification'";
    "notify-brave" = "notify-send -a brave 'Brave Test' 'Browser notification test'";
    "notify-kitty" = "notify-send -a kitty 'Terminal' 'Terminal notification'";
    
    # Mako management
    "mako-restart" = "pkill mako; sleep 1; mako &";
    "mako-start" = "mako &";
    "mako-stop" = "pkill mako";
    "mako-logs" = "journalctl --user -u mako -f";
    "mako-status" = "makoctl mode";
  };
}
