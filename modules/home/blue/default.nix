# modules/home/blue/default.nix
# ==============================================================================
# Home module for Hypr Blue Manager: unified night-light control
# (Gammastep / Hyprsunset). Provides per-user service and presets.
# ==============================================================================

{ config, lib, pkgs, ... }:

let
  cfg = config.my.user.blue;
  username = config.home.username;
  sunsetrEnabled = lib.attrByPath [ "my" "user" "sunsetr" "enable" ] false config;
in
{
  options.my.user.blue = {
    enable = lib.mkEnableOption "Hypr Blue Manager servisi (Gammastep + HyprSunset)";

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

    # Other settings
    checkInterval = lib.mkOption {
      type = lib.types.int;
      default = 3600;
      description = "Sıcaklık kontrol aralığı (saniye)";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && sunsetrEnabled) {
      warnings = [
        "my.user.blue ve my.user.sunsetr aynı anda aktif: çakışmayı önlemek için blue.service tanımlanmayacak (sunsetr kullanılacak)."
      ];
    })

    (lib.mkIf (cfg.enable && !sunsetrEnabled) {
    # Install required packages based on enabled tools
    home.packages = [
      cfg.package
    ] ++ lib.optionals cfg.enableGammastep [ pkgs.gammastep ]
      ++ lib.optionals cfg.enableHyprsunset [ pkgs.hyprsunset ];

    # Single unified service that manages everything
    systemd.user.services.blue = {
      Unit = {
        Description = "Hypr Blue Manager - Unified Color Temperature Manager";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

 
      Service = {
        Type = "simple";

        # FIX: PATH’i override etme, sistem bin’lerini de ekle
        Environment = [
          "PATH=/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/run/wrappers/bin"
        ];

        ExecStart = lib.concatStringsSep " " ([
          "/etc/profiles/per-user/${username}/bin/hypr-blue-manager"
          "daemon"
          "--enable-gammastep ${lib.boolToString cfg.enableGammastep}"
          "--enable-hyprsunset ${lib.boolToString cfg.enableHyprsunset}"
          "--temp-day ${toString cfg.temperature.day}"
          "--temp-night ${toString cfg.temperature.night}"
          "--gs-temp-day ${toString cfg.gammastep.tempDay}"
          "--gs-temp-night ${toString cfg.gammastep.tempNight}"
          "--bright-day ${toString cfg.gammastep.brightnessDay}"
          "--bright-night ${toString cfg.gammastep.brightnessNight}"
          "--location ${cfg.gammastep.location}"
          "--gamma ${cfg.gammastep.gamma}"
          "--interval ${toString cfg.checkInterval}"
        ]);

        ExecStop = "/etc/profiles/per-user/${username}/bin/hypr-blue-manager stop";
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "mixed";
        KillSignal = "SIGTERM";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };

  })
  ];
}
