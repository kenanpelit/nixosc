# modules/home/blue/default.nix
# ==============================================================================
# Hypr Blue Manager Service Configuration
# ==============================================================================
# Unified Gammastep + HyprSunset + wl-gammarelay service for automatic
# color temperature adjustment in Hyprland.
#
# Features:
#   - Single service manages all three tools
#   - Each tool can be enabled/disabled independently
#   - Configurable temperature profiles (4000K, 3500K, 3000K)
#   - Time-based automatic adjustments
#
# Author: Kenan Pelit
# Version: 3.0.0
# ==============================================================================
{ config, lib, pkgs, username, ... }:

let
  cfg = config.services.blue;
in
{
  options.services.blue = {
    enable = lib.mkEnableOption "Hypr Blue Manager servisi (Gammastep + HyprSunset + wl-gammarelay)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.writeShellScriptBin "hypr-blue-manager" (builtins.readFile ./hypr-blue-manager.sh);
      description = "Hypr Blue Manager paketi";
    };

    # Tool enable/disable options
    enableGammastep = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Gammastep'i aktif et";
    };

    enableHyprsunset = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "HyprSunset'i aktif et";
    };

    enableWlGammarelay = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "wl-gammarelay'i aktif et";
    };

    # Temperature settings
    temperature = {
      day = lib.mkOption {
        type = lib.types.int;
        default = 4000;
        description = "Gündüz sıcaklığı (Kelvin). Önerilen: 4000K (hafif), 3500K (orta), 3000K (güçlü)";
      };

      night = lib.mkOption {
        type = lib.types.int;
        default = 3000;
        description = "Gece sıcaklığı (Kelvin). Önerilen: 4000K (hafif), 3500K (orta), 3000K (güçlü)";
      };
    };

    # Gammastep specific settings
    gammastep = {
      tempDay = lib.mkOption {
        type = lib.types.int;
        default = cfg.temperature.day;
        description = "Gammastep gündüz sıcaklığı";
      };

      tempNight = lib.mkOption {
        type = lib.types.int;
        default = cfg.temperature.night;
        description = "Gammastep gece sıcaklığı";
      };

      brightnessDay = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        description = "Gündüz parlaklığı (0.1-1.0)";
      };

      brightnessNight = lib.mkOption {
        type = lib.types.float;
        default = 0.8;
        description = "Gece parlaklığı (0.1-1.0)";
      };

      location = lib.mkOption {
        type = lib.types.str;
        default = "41.0108:29.0219";
        description = "Konum (format: enlem:boylam)";
      };

      gamma = lib.mkOption {
        type = lib.types.str;
        default = "1,0.2,0.1";
        description = "Gamma değerleri (format: r,g,b)";
      };
    };

    # wl-gammarelay specific settings
    wlGammarelay = {
      tempDay = lib.mkOption {
        type = lib.types.int;
        default = cfg.temperature.day;
        description = "wl-gammarelay gündüz sıcaklığı";
      };

      tempNight = lib.mkOption {
        type = lib.types.int;
        default = cfg.temperature.night;
        description = "wl-gammarelay gece sıcaklığı";
      };

      brightness = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        description = "wl-gammarelay parlaklık (0.1-1.0)";
      };

      gamma = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        description = "wl-gammarelay gamma (0.1-2.0)";
      };
    };

    # Other settings
    checkInterval = lib.mkOption {
      type = lib.types.int;
      default = 3600;
      description = "Sıcaklık kontrol aralığı (saniye)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install required packages based on enabled tools
    home.packages = [
      cfg.package
    ] ++ lib.optionals cfg.enableGammastep [ pkgs.gammastep ]
      ++ lib.optionals cfg.enableHyprsunset [ pkgs.hyprsunset ]
      ++ lib.optionals cfg.enableWlGammarelay [ pkgs.wl-gammarelay-rs ];

    # Single unified service that manages everything
    systemd.user.services.blue = {
      Unit = {
        Description = "Hypr Blue Manager - Unified Color Temperature Manager";
        After = [ "hyprland-session.target" ] ++ lib.optional cfg.enableWlGammarelay "wl-gammarelay.service";
        PartOf = [ "hyprland-session.target" ];
        Wants = lib.optional cfg.enableWlGammarelay "wl-gammarelay.service";
      };

      Service = {
        Type = "simple";
        Environment = "PATH=/etc/profiles/per-user/${username}/bin:$PATH";
        
        ExecStart = lib.concatStringsSep " " ([
          "/etc/profiles/per-user/${username}/bin/hypr-blue-manager"
          "daemon"
          "--enable-gammastep ${lib.boolToString cfg.enableGammastep}"
          "--enable-hyprsunset ${lib.boolToString cfg.enableHyprsunset}"
          "--enable-wlgamma ${lib.boolToString cfg.enableWlGammarelay}"
          "--temp-day ${toString cfg.temperature.day}"
          "--temp-night ${toString cfg.temperature.night}"
          "--gs-temp-day ${toString cfg.gammastep.tempDay}"
          "--gs-temp-night ${toString cfg.gammastep.tempNight}"
          "--bright-day ${toString cfg.gammastep.brightnessDay}"
          "--bright-night ${toString cfg.gammastep.brightnessNight}"
          "--location ${cfg.gammastep.location}"
          "--gamma ${cfg.gammastep.gamma}"
          "--wl-temp-day ${toString cfg.wlGammarelay.tempDay}"
          "--wl-temp-night ${toString cfg.wlGammarelay.tempNight}"
          "--wl-brightness ${toString cfg.wlGammarelay.brightness}"
          "--wl-gamma ${toString cfg.wlGammarelay.gamma}"
          "--interval ${toString cfg.checkInterval}"
        ]);

        ExecStop = "/etc/profiles/per-user/${username}/bin/hypr-blue-manager stop";
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "mixed";
        KillSignal = "SIGTERM";
      };

      Install.WantedBy = [ "hyprland-session.target" ];
    };

    # Separate wl-gammarelay daemon service
    # This ensures wl-gammarelay is always running and initialized with correct temperature
    systemd.user.services.wl-gammarelay = lib.mkIf cfg.enableWlGammarelay {
      Unit = {
        Description = "wl-gammarelay - Wayland Color Temperature Daemon";
        After = [ "hyprland-session.target" ];
        PartOf = [ "hyprland-session.target" ];
        Before = [ "blue.service" ];
      };

      Service = {
        Type = "dbus";
        BusName = "rs.wl-gammarelay";
        ExecStart = "${pkgs.wl-gammarelay-rs}/bin/wl-gammarelay-rs";
        
        # Initialize with configured day temperature
        ExecStartPost = [
          "${pkgs.coreutils}/bin/sleep 1"
          "${pkgs.systemd}/bin/busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q ${toString cfg.wlGammarelay.tempDay}"
          "${pkgs.systemd}/bin/busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Brightness d ${toString cfg.wlGammarelay.brightness}"
          "${pkgs.systemd}/bin/busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Gamma d ${toString cfg.wlGammarelay.gamma}"
        ];

        SuccessExitStatus = [ 0 2 ];
        Restart = "on-failure";
        RestartSec = 3;
      };

      Install.WantedBy = [ "hyprland-session.target" ];
    };
  };
}

