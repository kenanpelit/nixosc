# modules/home/sunsetr/default.nix
# =============================================================================
# Home module for sunsetr (Wayland gamma/temperature manager).
# Writes config.toml with provided settings and installs the package.
# =============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.sunsetr;
  sunsetrConfig = ''
    # Backend
    backend = "auto"         # "auto", "hyprland", "hyprsunset" or "wayland"
    transition_mode = "geo"  # "geo", "finish_by", "start_at", "center", "static"

    # Smoothing
    smoothing = true
    startup_duration = 0.5
    shutdown_duration = 0.5
    adaptive_interval = 1

    # Time-based config
    night_temp = 3500
    day_temp = 4000
    night_gamma = 90
    day_gamma = 100
    update_interval = 60

    # Static config
    static_temp = 6500
    static_gamma = 100

    # Manual transitions
    sunset = "19:00:00"
    sunrise = "06:00:00"
    transition_duration = 45

    # Geolocation
    latitude = 41.0082    # Istanbul
    longitude = 28.9784   # Istanbul
  '';
in
{
  options.my.user.sunsetr = {
    enable = lib.mkEnableOption "sunsetr gamma/temperature manager";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.sunsetr ];
    xdg.configFile."sunsetr/config.toml".text = sunsetrConfig;

    systemd.user.services.sunsetr = {
      Unit = {
        Description = "sunsetr gamma/temperature manager";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.sunsetr}/bin/sunsetr --background";
        Restart = "on-failure";
        RestartSec = 5;
        Environment = "XDG_CURRENT_DESKTOP=niri";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
