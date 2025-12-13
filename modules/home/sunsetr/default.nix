# modules/home/sunsetr/default.nix
# ==============================================================================
# Home module for sunsetr (Wayland night light / gamma-temperature manager).
# Writes `~/.config/sunsetr/sunsetr.toml` and optionally runs a user service.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.sunsetr;
  dag =
    if lib ? hm && lib.hm ? dag
    then lib.hm.dag
    else config.lib.dag;

  configDir = "${config.xdg.configHome}/sunsetr";

  toml = ''
    [Backend]
    backend = "${cfg.settings.backend}"
    transition_mode = "${cfg.settings.transitionMode}"

    [Smoothing]
    smoothing = ${lib.boolToString cfg.settings.smoothing.enable}
    startup_duration = ${toString cfg.settings.smoothing.startupDuration}
    shutdown_duration = ${toString cfg.settings.smoothing.shutdownDuration}
    adaptive_interval = ${toString cfg.settings.smoothing.adaptiveInterval}

    ["Time-based config"]
    night_temp = ${toString cfg.settings.time.nightTemp}
    day_temp = ${toString cfg.settings.time.dayTemp}
    night_gamma = ${toString cfg.settings.time.nightGamma}
    day_gamma = ${toString cfg.settings.time.dayGamma}
    update_interval = ${toString cfg.settings.time.updateInterval}

    ["Static config"]
    static_temp = ${toString cfg.settings.static.temp}
    static_gamma = ${toString cfg.settings.static.gamma}

    ["Manual transitions"]
    sunset = "${cfg.settings.manual.sunset}"
    sunrise = "${cfg.settings.manual.sunrise}"
    transition_duration = ${toString cfg.settings.manual.transitionDuration}

    [Geolocation]
    latitude = ${toString cfg.settings.geo.latitude}
    longitude = ${toString cfg.settings.geo.longitude}
  '';

  sunsetrRun = pkgs.writeShellScript "sunsetr-run.sh" ''
    set -euo pipefail

    : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
    : "''${WAYLAND_DISPLAY:=wayland-0}"

    socket="''${XDG_RUNTIME_DIR}/''${WAYLAND_DISPLAY}"
    for _ in $(seq 1 40); do
      if [ -S "$socket" ]; then
        break
      fi
      sleep 0.25
    done

    exec ${pkgs.sunsetr}/bin/sunsetr --config ${lib.escapeShellArg configDir}
  '';
in
{
  options.my.user.sunsetr = {
    enable = lib.mkEnableOption "sunsetr night light manager";

    enableService = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run sunsetr as a user systemd service.";
    };

    settings = {
      backend = lib.mkOption {
        type = lib.types.enum [ "auto" "hyprland" "hyprsunset" "wayland" ];
        default = "auto";
        description = "sunsetr backend selection.";
      };

      transitionMode = lib.mkOption {
        type = lib.types.enum [ "geo" "finish_by" "start_at" "center" "static" ];
        default = "geo";
        description = "Transition mode.";
      };

      smoothing = {
        enable = lib.mkOption { type = lib.types.bool; default = true; };
        startupDuration = lib.mkOption { type = lib.types.float; default = 0.5; };
        shutdownDuration = lib.mkOption { type = lib.types.float; default = 0.5; };
        adaptiveInterval = lib.mkOption { type = lib.types.int; default = 1; };
      };

      time = {
        nightTemp = lib.mkOption { type = lib.types.int; default = 3500; };
        dayTemp = lib.mkOption { type = lib.types.int; default = 4000; };
        nightGamma = lib.mkOption { type = lib.types.int; default = 90; };
        dayGamma = lib.mkOption { type = lib.types.int; default = 100; };
        updateInterval = lib.mkOption { type = lib.types.int; default = 60; };
      };

      static = {
        temp = lib.mkOption { type = lib.types.int; default = 6500; };
        gamma = lib.mkOption { type = lib.types.int; default = 100; };
      };

      manual = {
        sunset = lib.mkOption { type = lib.types.str; default = "19:00:00"; };
        sunrise = lib.mkOption { type = lib.types.str; default = "06:00:00"; };
        transitionDuration = lib.mkOption { type = lib.types.int; default = 45; };
      };

      geo = {
        latitude = lib.mkOption { type = lib.types.float; default = 41.0082; };
        longitude = lib.mkOption { type = lib.types.float; default = 28.9784; };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.sunsetr ];

    # NOTE: Do NOT manage this file via `xdg.configFile` (it becomes read-only / a Nix store symlink).
    # sunsetr needs to be able to edit it (e.g. `sunsetr geo`).
    home.activation.sunsetrConfig = dag.entryAfter [ "writeBoundary" ] ''
      CFG_DIR="${configDir}"
      CFG_FILE="$CFG_DIR/sunsetr.toml"

      # Ensure directory exists
      if [ ! -d "$CFG_DIR" ]; then
        $DRY_RUN_CMD mkdir -p "$CFG_DIR"
      fi

      # If previously managed by Nix (symlink), replace with a writable file.
      if [ -L "$CFG_FILE" ]; then
        $DRY_RUN_CMD rm -f "$CFG_FILE"
      fi

      # Only create a default config once; keep user's edits afterwards.
      if [ ! -f "$CFG_FILE" ]; then
        $DRY_RUN_CMD cat > "$CFG_FILE" << 'EOFSUNSETR'
${toml}
EOFSUNSETR
      fi
    '';

    systemd.user.services.sunsetr = lib.mkIf cfg.enableService {
      Unit = {
        Description = "sunsetr gamma/temperature manager";
        Conflicts = [ "blue.service" ];
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = sunsetrRun;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
