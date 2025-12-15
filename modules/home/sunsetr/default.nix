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

  mkToml = settings: ''
    [Backend]
    backend = "${settings.backend}"
    transition_mode = "${settings.transitionMode}"

    [Smoothing]
    smoothing = ${lib.boolToString settings.smoothing.enable}
    startup_duration = ${toString settings.smoothing.startupDuration}
    shutdown_duration = ${toString settings.smoothing.shutdownDuration}
    adaptive_interval = ${toString settings.smoothing.adaptiveInterval}

    ["Time-based config"]
    night_temp = ${toString settings.time.nightTemp}
    day_temp = ${toString settings.time.dayTemp}
    night_gamma = ${toString settings.time.nightGamma}
    day_gamma = ${toString settings.time.dayGamma}
    update_interval = ${toString settings.time.updateInterval}

    ["Static config"]
    static_temp = ${toString settings.static.temp}
    static_gamma = ${toString settings.static.gamma}

    ["Manual transitions"]
    sunset = "${settings.manual.sunset}"
    sunrise = "${settings.manual.sunrise}"
    transition_duration = ${toString settings.manual.transitionDuration}

    [Geolocation]
    latitude = ${toString settings.geo.latitude}
    longitude = ${toString settings.geo.longitude}
  '';

  mkSunsetrRun = cfgDir: pkgs.writeShellScript "sunsetr-run-${lib.replaceStrings ["/"] ["-"] cfgDir}.sh" ''
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

    exec ${pkgs.sunsetr}/bin/sunsetr --config ${lib.escapeShellArg cfgDir}
  '';

  mkConfigDirForProfile = name: "${configDir}/profiles/${name}";

  profileNames = builtins.attrNames cfg.profiles;
  profileUnitName = name: "sunsetr-${name}.service";
  allUnitNames = [ "sunsetr.service" ] ++ map profileUnitName profileNames;

  settingsModule = { ... }: {
    options = {
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
in
{
  options.my.user.sunsetr = {
    enable = lib.mkEnableOption "sunsetr night light manager";

    enableService = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run sunsetr as a user systemd service.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule settingsModule;
      default = { };
      description = "Default sunsetr settings (written to ~/.config/sunsetr/sunsetr.toml).";
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          enableService = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Run this profile as a separate user systemd service.";
          };

          settings = lib.mkOption {
            type = lib.types.submodule settingsModule;
            default = { };
            description = "sunsetr settings for this profile.";
          };
        };
      }));
      default = { };
      description = "Additional sunsetr profiles (each uses its own config dir).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages =
      let
        wrapper = pkgs.writeShellScriptBin "sunsetr-profile" ''
          set -euo pipefail
          name="''${1:-}"
          if [[ -z "$name" ]]; then
            echo "Usage: sunsetr-profile <default|PROFILE> [sunsetr args...]" >&2
            echo "Profiles: default ${lib.concatStringsSep " " profileNames}" >&2
            exit 2
          fi
          shift || true

          if [[ "$name" == "default" ]]; then
            cfg_dir=${lib.escapeShellArg configDir}
          else
            cfg_dir=${lib.escapeShellArg configDir}/profiles/"$name"
          fi

          # İsteğe bağlı: profile dizini yoksa oluştur (Nix'te profile tanımlamadan da kullanılabilsin).
          mkdir -p "$cfg_dir"

          # Profil config'i yoksa default'tan kopyala (sonra `sunsetr geo/set` ile özelleştirirsin).
          if [[ ! -f "$cfg_dir/sunsetr.toml" && -f ${lib.escapeShellArg configDir}/sunsetr.toml ]]; then
            cp -f ${lib.escapeShellArg configDir}/sunsetr.toml "$cfg_dir/sunsetr.toml" 2>/dev/null || true
          fi

          subcmd="''${1:-}"
          if [[ "$subcmd" == "status" || "$subcmd" == "S" ]]; then
            shift || true
            exec ${pkgs.sunsetr}/bin/sunsetr status --config "$cfg_dir" "$@"
          fi

          exec ${pkgs.sunsetr}/bin/sunsetr --config "$cfg_dir" "$@"
        '';
      in
      [ pkgs.sunsetr wrapper ];

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
${mkToml cfg.settings}
EOFSUNSETR
      fi
    '';

    home.activation.sunsetrProfiles = dag.entryAfter [ "writeBoundary" ] (lib.concatStringsSep "\n" (
      map (name:
        let
          pCfgDir = mkConfigDirForProfile name;
          pToml = mkToml cfg.profiles.${name}.settings;
        in
        ''
          CFG_DIR="${pCfgDir}"
          CFG_FILE="$CFG_DIR/sunsetr.toml"

          if [ ! -d "$CFG_DIR" ]; then
            $DRY_RUN_CMD mkdir -p "$CFG_DIR"
          fi

          if [ -L "$CFG_FILE" ]; then
            $DRY_RUN_CMD rm -f "$CFG_FILE"
          fi

          if [ ! -f "$CFG_FILE" ]; then
            $DRY_RUN_CMD cat > "$CFG_FILE" << 'EOFSUNSETR'
${pToml}
EOFSUNSETR
          fi
        ''
      ) profileNames
    ));

    systemd.user.services =
      let
        baseSvc = lib.mkIf cfg.enableService {
          sunsetr = {
            Unit = {
              Description = "sunsetr gamma/temperature manager";
              Conflicts = [ "blue.service" ] ++ (lib.remove "sunsetr.service" allUnitNames);
              PartOf = [ "graphical-session.target" ];
              After = [ "graphical-session.target" ];
            };
            Service = {
              Type = "simple";
              ExecStart = mkSunsetrRun configDir;
              Restart = "on-failure";
              RestartSec = 2;
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        };

        profileSvcs = lib.mkMerge (map (name:
          let
            unit = profileUnitName name;
            dir = mkConfigDirForProfile name;
            run = mkSunsetrRun dir;
            p = cfg.profiles.${name};
          in
          lib.mkIf p.enableService {
            ${lib.removeSuffix ".service" unit} = {
              Unit = {
                Description = "sunsetr profile (${name})";
                Conflicts = [ "blue.service" ] ++ (lib.remove unit allUnitNames);
                PartOf = [ "graphical-session.target" ];
                After = [ "graphical-session.target" ];
              };
              Service = {
                Type = "simple";
                ExecStart = run;
                Restart = "on-failure";
                RestartSec = 2;
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };
          }
        ) profileNames);
      in
      lib.mkMerge [ baseSvc profileSvcs ];
  };
}
