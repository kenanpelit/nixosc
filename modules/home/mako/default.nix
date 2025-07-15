# modules/home/mako/default.nix
{ pkgs, ... }:
let
  # Tokyo Night Storm Colors optimized for Mako
  colors = {
    base = "#24283b";
    mantle = "#1f2335";
    surface0 = "#292e42";
    surface1 = "#414868";
    text = "#c0caf5";
    subtext1 = "#a9b1d6";
    green = "#9ece6a";
    blue = "#7aa2f7";
    purple = "#bb9af7";
    red = "#f7768e";
    orange = "#ff9e64";
    yellow = "#e0af68";
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
  # Mako Configuration
  # =============================================================================
  services.mako = {
    enable = true;
    
    # Global options
    anchor = "top-right";
    font = "Noto Sans Regular 14";
    backgroundColor = colors.base + "aa";  # 67% opacity
    textColor = colors.text;
    width = 540;
    height = 320;
    margin = "13,11";
    padding = "8,10";
    borderSize = 1;
    borderColor = colors.purple;
    borderRadius = 10;
    progressColor = "over " + colors.surface1;
    icons = true;
    maxIconSize = 48;
    iconLocation = "right";
    defaultTimeout = 7000;
    ignoreTimeout = false;
    groupBy = "none";
    layer = "overlay";
    maxVisible = 5;
    
    # Custom format with Tokyo Night styling
    format = ''<span color="${colors.green}" size="13pt" line_height="1.3"><b>%a</b></span>\n<span color="${colors.subtext1}"><i>%s</i></span>\n%b'';
    
    # Sound notification (optional)
    # onNotify = "exec paplay ~/.sounds/message.oga";
    
    # Extra configuration for different urgency levels and apps
    extraConfig = ''
      # Grouped notifications
      [grouped]
      format=<span size="13pt" line_height="1.3"><b>(%g) %a</b></span>\n%b
      border-size=3
      
      # Normal urgency
      [urgency=normal]
      background-color=${colors.base}
      text-color=${colors.text}
      border-color=${colors.purple}
      progress-color=over ${colors.surface1}
      
      # Critical notifications
      [urgency=critical]
      background-color=${colors.base}
      text-color=${colors.text}
      border-color=${colors.orange}
      default-timeout=0
      
      # Low urgency
      [urgency=low]
      background-color=${colors.base}
      text-color=${colors.text}
      border-color=${colors.purple}
      
      # Spotify notifications
      [app-name=Spotify]
      format=<span color="${colors.green}" size="13pt" line_height="1.3"><b>%a</b></span>\n<span color="${colors.purple}"><i>%s</i></span>\n%b
      background-color=${colors.base}
      text-color=${colors.text}
      border-color=${colors.green}
      default-timeout=3000
      
      # WhatsApp notifications
      [app-name=whatsapp-nativefier-d40211]
      format=<span color="${colors.green}" size="13pt" line_height="1.3"><b>%a</b></span>\n<span color="${colors.purple}"><i>%s</i></span>\n%b
      background-color=${colors.base}
      text-color=${colors.text}
      border-color=${colors.red}
      default-timeout=10000
      
      # Firefox notifications
      [app-name=firefox]
      format=<span color="${colors.green}" size="13pt" line_height="1.3"><b>%a</b></span>\n<span color="${colors.purple}"><i>%s</i></span>\n%b
      background-color=${colors.base}
      text-color=${colors.text}
      border-color=${colors.red}
      default-timeout=50000
      
      # Chrome notifications
      [app-name=Google-chrome]
      format=<span color="${colors.green}" size="13pt" line_height="1.3"><b>%a</b></span>\n<span color="${colors.purple}"><i>%s</i></span>\n%b
      background-color=${colors.base}
      text-color=${colors.text}
      border-color=${colors.red}
      default-timeout=30000
      
      # MPD notifications
      [category=mpd]
      default-timeout=2000
      group-by=category
      
      # Mode: Away
      [mode=away]
      default-timeout=0
      ignore-timeout=1
      
      # Mode: Do Not Disturb
      [mode=do-not-disturb]
      invisible=1
    '';
  };

  # =============================================================================
  # Optional: Mako control scripts
  # =============================================================================
  home.sessionVariables = {
    # Ensure mako is used as the notification daemon
    NOTIFY_SEND_BIN = "${pkgs.libnotify}/bin/notify-send";
  };

  # Optional: Add some useful aliases for mako control
  home.shellAliases = {
    # Mako control commands
    "mako-reload" = "makoctl reload";
    "mako-dismiss" = "makoctl dismiss";
    "mako-dismiss-all" = "makoctl dismiss --all";
    "mako-history" = "makoctl history";
    "mako-restore" = "makoctl restore";
    
    # Test notification
    "notify-test" = "notify-send 'Test Notification' 'This is a test message from Mako!' --icon=dialog-information";
  };
}

