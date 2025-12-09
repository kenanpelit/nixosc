# modules/home/walker/default.nix
# ==============================================================================
# Home Manager module for walker.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ==============================================================================

{ config, lib, pkgs, inputs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkMerge
    mkDefault
    types
    literalExpression
    mdDoc;

  cfg = config.programs.walker;
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;

  tomlFormat = pkgs.formats.toml { };

  elephantPkg =
    if inputs ? elephant then
      inputs.elephant.packages.${pkgs.stdenv.hostPlatform.system}.elephant-with-providers
    else
      throw "elephant flake input is required for Walker (inputs.elephant not found)";
in
{
  # Allow enabling via my.user.walker.enable
  options.my.user.walker.enable = mkEnableOption "Walker launcher (my.user.* alias)";

  options.programs.walker = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = mdDoc "Enable the Walker launcher and Elephant backend.";
    };

    runAsService = mkOption {
      type = types.bool;
      default = true;
      description = mdDoc "Run Walker/Elephant as user services.";
    };

    package = mkOption {
      type = types.package;
      default =
        if inputs ? walker then
          inputs.walker.packages.${pkgs.stdenv.hostPlatform.system}.default
        else
          pkgs.walker;
      defaultText = literalExpression "inputs.walker.packages.${pkgs.stdenv.hostPlatform.system}.default";
      description = mdDoc "Walker package to install.";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          force_keyboard_focus = true;
          theme = "catppuccin";
          page_jump_size = 10;
          providers = {
            default = [ "desktopapplications" "calc" "runner" ];
            prefixes = [
              { prefix = ">"; provider = "runner"; }
              { prefix = "/"; provider = "files"; }
            ];
          };
        }
      '';
      description = mdDoc "Walker configuration written to $XDG_CONFIG_HOME/walker/config.toml.";
    };
  };

  config = mkMerge [
    # Bridge my.user.walker.enable -> programs.walker.enable
    { programs.walker.enable = mkDefault config.my.user.walker.enable; }

    (mkIf cfg.enable {
      # Packages
      home.packages = [
        cfg.package
        elephantPkg
      ];

      # Providers shipped with Elephant
      home.file.".config/elephant/providers" = {
        source = "${elephantPkg}/lib/elephant/providers";
        recursive = true;
      };

      # Elephant backend
      systemd.user.services.elephant = mkIf cfg.runAsService {
        Unit = {
          Description = "Elephant - Backend provider for Walker";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
          StartLimitBurst = 10;
          StartLimitIntervalSec = 120;
        };

        Service = {
          Type = "simple";
          ExecStart = "${elephantPkg}/bin/elephant";
          Restart = "always";
          RestartSec = 3;
          MemoryMax = "500M";
          CPUQuota = "50%";
          TimeoutStopSec = 10;
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };

      # Health-check timer/service
      systemd.user.timers.elephant-healthcheck = mkIf cfg.runAsService {
        Unit.Description = "Periodic health check for Elephant service";
        Timer = {
          OnBootSec = "1min";
          OnUnitActiveSec = "3min";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };

      systemd.user.services.elephant-healthcheck = mkIf cfg.runAsService {
        Unit.Description = "Health check and restart Elephant if needed";
        Service = {
          Type = "oneshot";
          Environment = [ "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus" ];
          ExecStart = pkgs.writeShellScript "elephant-healthcheck" ''
            #!${pkgs.bash}/bin/bash
            LOG_FILE="$HOME/.local/share/elephant-health.log"
            TS=$(${pkgs.coreutils}/bin/date '+%Y-%m-%d %H:%M:%S')
            ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$LOG_FILE")"

            if ! ${pkgs.procps}/bin/pgrep -u "$USER" -x elephant >/dev/null 2>&1; then
              echo "$TS: Elephant not running, restarting..." | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
              SYSTEMD_SOCKET="/run/user/$(${pkgs.coreutils}/bin/id -u)/systemd/private"
              if [ -S "$SYSTEMD_SOCKET" ]; then
                ${pkgs.systemd}/bin/busctl --user call \
                  org.freedesktop.systemd1 \
                  /org/freedesktop/systemd1 \
                  org.freedesktop.systemd1.Manager \
                  StartUnit ss elephant.service replace \
                  2>&1 | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
              else
                ${elephantPkg}/bin/elephant &
                echo "$TS: Started Elephant directly" | ${pkgs.coreutils}/bin/tee -a "$LOG_FILE"
              fi
            fi
          '';
        };
      };

      # Walker frontend
      systemd.user.services.walker = mkIf cfg.runAsService {
        Unit = {
          Description = "Walker - Application launcher";
          Documentation = "https://github.com/abenz1267/walker";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" "elephant.service" ];
          Requires = [ "elephant.service" ];
        };

        Service = {
          Type = "simple";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
          ExecStart = "${cfg.package}/bin/walker --gapplication-service";
          Restart = "on-failure";
          RestartSec = 3;
          TimeoutStartSec = 120;
          TimeoutStopSec = 10;
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };

      # Walker config
      xdg.configFile."walker/config.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "walker-config.toml" cfg.settings;
      };

      # D-Bus activation file
      xdg.dataFile."dbus-1/services/io.github.abenz1267.walker.service".text = ''
        [D-BUS Service]
        Name=io.github.abenz1267.walker
        Exec=${cfg.package}/bin/walker --gapplication-service
        SystemdService=walker.service
      '';

      # Activation notice
      home.activation.walkerInfo = dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.coreutils}/bin/cat << 'EOF'
        Walker + Elephant configured.
        Services: elephant, walker${if cfg.runAsService then " (enabled)" else " (disabled)"}.
        EOF
      '';
    })
  ];
}
