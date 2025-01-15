# modules/home/waybar/waybar.nix
{ pkgs, config, ... }:
{
  # Waybar program yapılandırması
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
    });
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
      ExecCondition = ''
        /run/current-system/sw/bin/bash -c '[ -f "${config.xdg.configHome}/waybar/style.css" ]'
      '';
      ExecStart = ''
        ${pkgs.waybar}/bin/waybar \
          --log-level error \
          --config ${config.xdg.configHome}/waybar/config \
          --style ${config.xdg.configHome}/waybar/style.css
      '';
      Restart = "on-failure";
      RestartSec = "1s";
    };

    Install = {
      WantedBy = ["hyprland-session.target"];
    };
  };
}
