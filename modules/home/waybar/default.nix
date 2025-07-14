# modules/home/waybar/default.nix
{ pkgs, config, ... }:
let
  # Tokyo Night Storm tema renkleri - daha zengin palet
  colors = {
    base = "#24283b";
    crust = "#1a1b26";
    mantle = "#16161e";
    surface0 = "#363a4f";
    surface1 = "#414868";
    surface2 = "#565f89";
    text = "#c0caf5";
    subtext1 = "#a9b1d6";
    subtext0 = "#9aa5ce";
    overlay2 = "#737aa2";
    overlay1 = "#6f7bb6";
    overlay0 = "#6b73a7";
    red = "#f7768e";
    maroon = "#e06c75";
    peach = "#ff9e64";
    yellow = "#e0af68";
    green = "#9ece6a";
    teal = "#1abc9c";
    sky = "#7dcfff";
    sapphire = "#74c7ec";
    blue = "#7aa2f7";
    lavender = "#b4befe";
    mauve = "#bb9af7";
    pink = "#f5c2e7";
    # Gradient colors
    gradient1 = "#7aa2f7";
    gradient2 = "#bb9af7";
    gradient3 = "#7dcfff";
  };
  
  # Waybar için gelişmiş özel ayarlar
  custom = {
    font = "Maple Mono";
    font_size = "15px";
    font_weight = "600";
    icon_font_size = "15px";
    text_color = colors.text;
    subtext_color = colors.subtext1;
    background_0 = colors.crust;
    background_1 = colors.base;
    background_2 = colors.mantle;
    surface_0 = colors.surface0;
    surface_1 = colors.surface1;
    surface_2 = colors.surface2;
    border_color = "rgba(65, 72, 104, 0.6)";
    border_hover = "rgba(116, 199, 236, 0.8)";
    red = colors.red;
    maroon = colors.maroon;
    green = colors.green;
    yellow = colors.yellow;
    blue = colors.blue;
    magenta = colors.mauve;
    cyan = colors.sky;
    sapphire = colors.sapphire;
    orange = colors.peach;
    pink = colors.pink;
    lavender = colors.lavender;
    teal = colors.teal;
    opacity = "0.95";
    border_radius = "12px";
    inner_radius = "8px";
    indicator_height = "3px";
    shadow = "0 4px 20px rgba(0, 0, 0, 0.25)";
    glow = "0 0 20px";
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

  # Gelişmiş servis yapılandırması
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar - Enhanced Wayland bar";
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

