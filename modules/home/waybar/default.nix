# modules/home/waybar/default.nix
{ pkgs, config, ... }:
let
  # Tokyo Night Storm - Premium dark theme
  tokyo_night_storm = {
    # Background layers
    bg = "#24283b";
    bg_dark = "#1f2335";
    bg_float = "#1d202f";
    bg_highlight = "#292e42";
    bg_popup = "#1d202f";
    bg_statusline = "#1d202f";
    bg_visual = "#283457";
    border = "#1d202f";
    border_highlight = "#27a1b9";
    
    # Text colors
    fg = "#c0caf5";
    fg_dark = "#a9b1d6";
    fg_gutter = "#3b4261";
    comment = "#565f89";
    dark3 = "#545c7e";
    dark5 = "#737aa2";
    
    # Semantic colors
    blue = "#7aa2f7";
    cyan = "#7dcfff";
    green = "#9ece6a";
    magenta = "#bb9af7";
    purple = "#9d7cd8";
    red = "#f7768e";
    orange = "#ff9e64";
    yellow = "#e0af68";
    teal = "#1abc9c";
    
    # Surface layers
    surface0 = "#363a4f";
    surface1 = "#414868";
    surface2 = "#565f89";
    
    # Compatibility aliases
    crust = "#1a1b26";
    base = "#24283b";
    mantle = "#16161e";
    text = "#c0caf5";
    subtext1 = "#a9b1d6";
    subtext0 = "#9aa5ce";
  };
  
  # Waybar için optimize edilmiş ayarlar
  custom = {
    # Font configuration
    font = "JetBrainsMono Nerd Font";
    font_size = "15px";
    font_weight = "600";
    
    # Text colors
    text_color = tokyo_night_storm.fg;
    subtext_color = tokyo_night_storm.fg_dark;
    
    # Background layers
    background_0 = tokyo_night_storm.crust;
    background_1 = tokyo_night_storm.base;
    background_2 = tokyo_night_storm.mantle;
    
    # Surface layers
    surface_0 = tokyo_night_storm.surface0;
    surface_1 = tokyo_night_storm.surface1;
    surface_2 = tokyo_night_storm.surface2;
    
    # Border and UI
    border_color = "rgba(69, 71, 90, 0.8)";
    opacity = "0.95";
    border_radius = "8px";
    inner_radius = "6px";
    
    # Semantic colors
    red = tokyo_night_storm.red;
    green = tokyo_night_storm.green;
    yellow = tokyo_night_storm.yellow;
    blue = tokyo_night_storm.blue;
    magenta = tokyo_night_storm.magenta;
    cyan = tokyo_night_storm.cyan;
    orange = tokyo_night_storm.orange;
    purple = tokyo_night_storm.purple;
    teal = tokyo_night_storm.teal;
    
    # Accent colors for different states
    accent_primary = tokyo_night_storm.blue;
    accent_secondary = tokyo_night_storm.magenta;
    accent_success = tokyo_night_storm.green;
    accent_warning = tokyo_night_storm.yellow;
    accent_error = tokyo_night_storm.red;
    accent_info = tokyo_night_storm.cyan;
  };

in
{
  # Waybar program yapılandırması
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or [ ]) ++ [ 
        "-Dexperimental=true" 
        "-Dcava=enabled"
        "-Dmpris=enabled" 
      ];
    });
    
    # Ayarları dahil et
    settings = import ./settings.nix { inherit custom; };
    
    # Stilleri dahil et
    style = import ./style.nix { inherit custom; };
  };

  # Systemd servis
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar - Modern Wayland bar";
      Documentation = "https://github.com/Alexays/Waybar/wiki";
      After = ["hyprland-session.target" "graphical-session.target"];
      PartOf = ["hyprland-session.target"];
      Wants = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.waybar}/bin/waybar --log-level error";
      ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
      Restart = "on-failure";
      RestartSec = "2s";
      KillMode = "mixed";
      Environment = [
        "XDG_CURRENT_DESKTOP=Hyprland"
        "XDG_SESSION_TYPE=wayland"
      ];
    };
    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
}

