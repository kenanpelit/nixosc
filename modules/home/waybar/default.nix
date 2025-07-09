# modules/home/desktop/waybar/default.nix
{ pkgs, config, ... }:
let
  # Tokyo Night tema renkleri
  colors = {
    base = "#24283b";
    crust = "#1a1b26";
    text = "#c0caf5";
    surface1 = "#414868";
    red = "#f7768e";
    green = "#9ece6a";
    yellow = "#e0af68";
    blue = "#7aa2f7";
    mauve = "#bb9af7";
    sky = "#7dcfff";
    peach = "#ff9e64";
  };
  
  # Waybar için özel ayarlar
  custom = {
    font = "Maple Mono";
    font_size = "16px";
    font_weight = "bold";
    text_color = colors.text;
    background_0 = colors.crust;
    background_1 = colors.base;
    border_color = colors.surface1;
    red = colors.red;
    green = colors.green;
    yellow = colors.yellow;
    blue = colors.blue;
    magenta = colors.mauve;
    cyan = colors.sky;
    orange = colors.peach;
    opacity = "1.0";
    border_radius = "8px";
    indicator_height = "2px";
  };
in
{
  # Waybar program yapılandırması
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
    });
    
    # Ayarları dahil et
    settings = import ./settings.nix { inherit custom; };
    
    # Stilleri dahil et
    style = import ./style.nix { inherit custom; };
  };

  # Özel servis yapılandırması
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar - Wayland bar for Sway and Wlroots based compositors";
      Documentation = "https://github.com/Alexays/Waybar/wiki";
      After = ["hyprland-session.target"];
      PartOf = ["hyprland-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.waybar}/bin/waybar --log-level error";
      Restart = "on-failure";
      RestartSec = "1s";
    };
    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
}

