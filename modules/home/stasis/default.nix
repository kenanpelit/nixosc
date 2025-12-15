# modules/home/stasis/default.nix
# ==============================================================================
# Home module for Stasis (Wayland idle manager).
#
# Why `home.activation` instead of `xdg.configFile`?
# - Stasis writes/updates its config on first run.
# - `xdg.configFile` would create a Nix store symlink (read-only), breaking
#   commands like `stasis profile ...` and future config updates.
#
# Default config tries to be compositor-agnostic (Niri / Hyprland) via `sh -c`
# fallbacks.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.stasis;

  dag =
    if lib ? hm && lib.hm ? dag
    then lib.hm.dag
    else config.lib.dag;

  defaultPackage =
    if pkgs ? stasis
    then pkgs.stasis
    else null;

  configDir = "${config.xdg.configHome}/stasis";
  configFile = "${configDir}/stasis.rune";

  # A sane default, designed for Niri + Hyprland + DMS.
  #
  # Notes:
  # - `lock_detection_type "logind"` pairs well with DMS/quickshell-style lockers.
  # - `lock_screen.command` triggers logind lock, which lets the actual locker
  #   react (DMS / other), and gives Stasis a reliable lock/unlock signal.
  defaultConfigText = ''
    # This file is managed by nixosc (Home-Manager activation), but is kept
    # writable on disk so you can still tweak it manually.
    #
    # Reference:
    # - `stasis info`
    # - `stasis dump`

    @author "kenanpelit/nixosc"
    @description "Stasis idle config (DMS + Niri/Hyprland friendly)"

    stasis:
      monitor_media true
      ignore_remote_media true
      respect_idle_inhibitors true

      # Use systemd-logind LockedHint for reliable lock state.
      lock_detection_type "logind"

      # Apps that should inhibit idle actions.
      inhibit_apps [
        "mpv"
        "vlc"
        "Spotify"
        r"steam_app_.*"
      ]

      # 1) Lock the session (lets DMS/quickshell react), 2) DPMS off, 3) suspend.
      lock_screen:
        timeout ${toString cfg.timeouts.lockSeconds}  # ${toString (cfg.timeouts.lockSeconds / 60)} minute(s)
        command "loginctl lock-session"
        resume-command "notify-send 'Welcome back, $env.USER!'"
      end

      dpms:
        timeout ${toString cfg.timeouts.dpmsSeconds}  # ${toString (cfg.timeouts.dpmsSeconds / 60)} minute(s)
        command "niri msg action power-off-monitors || hyprctl dispatch dpms off || true"
        resume-command "niri msg action power-on-monitors || hyprctl dispatch dpms on || true"
      end

      suspend:
        timeout ${toString cfg.timeouts.suspendSeconds}  # ${toString (cfg.timeouts.suspendSeconds / 60)} minute(s)
        command "systemctl suspend"
      end
    end

    # Profiles can be switched at runtime:
    # - `stasis profile work`
    # - `stasis profile none`
    profiles:
      work:
        lock_screen:
          timeout 900
          command "loginctl lock-session"
        end

        dpms:
          timeout 600
          command "niri msg action power-off-monitors || hyprctl dispatch dpms off || true"
          resume-command "niri msg action power-on-monitors || hyprctl dispatch dpms on || true"
        end

        suspend:
          timeout 7200
          command "systemctl suspend"
        end
      end

      presentation:
        # No lock/suspend; keep only mild DPMS.
        dpms:
          timeout 1200
          command "niri msg action power-off-monitors || hyprctl dispatch dpms off || true"
          resume-command "niri msg action power-on-monitors || hyprctl dispatch dpms on || true"
        end
      end
    end
  '';

  stasisctl = pkgs.writeShellScriptBin "stasisctl" ''
    set -euo pipefail
    exec "${cfg.package}/bin/stasis" --config ${lib.escapeShellArg cfg.configFile} "$@"
  '';
in
{
  options.my.user.stasis = {
    enable = lib.mkEnableOption "Stasis (Wayland idle manager)";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = defaultPackage;
      description = ''
        Stasis package to run.

        Defaults to `pkgs.stasis` if it exists in your pinned nixpkgs.
        If it doesn't, set this explicitly (or add a flake input for Stasis).
      '';
    };

    enableService = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run Stasis as a user systemd service.";
    };

    manageConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Create/update the config file via home.activation (kept writable).";
    };

    forceConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Overwrite the config file on each activation (careful: overwrites manual edits).";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = configFile;
      description = "Path to `stasis.rune` used by the service and `stasisctl`.";
    };

    configText = lib.mkOption {
      type = lib.types.lines;
      default = defaultConfigText;
      description = "Default config contents written to `configFile` (when manageConfig is enabled).";
    };

    timeouts = {
      lockSeconds = lib.mkOption {
        type = lib.types.int;
        default = 300;
        description = "Idle seconds before lock-session.";
      };

      dpmsSeconds = lib.mkOption {
        type = lib.types.int;
        default = 600;
        description = "Idle seconds before DPMS off.";
      };

      suspendSeconds = lib.mkOption {
        type = lib.types.int;
        default = 1800;
        description = "Idle seconds before suspend.";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = cfg.package != null;
          message = ''
            my.user.stasis.enable = true but no Stasis package is available.

            Either:
            - Use a nixpkgs that provides `pkgs.stasis`, or
            - Set `my.user.stasis.package` explicitly (e.g. from a Stasis flake input).
          '';
        }
      ];

      home.packages = [
        cfg.package
        stasisctl
      ];
    }

    (lib.mkIf cfg.manageConfig {
      home.activation.stasisConfig = dag.entryAfter [ "writeBoundary" ] ''
        set -eu

        CFG_FILE=${lib.escapeShellArg cfg.configFile}
        CFG_DIR="$(dirname "$CFG_FILE")"

        mkdir -p "$CFG_DIR"

        if [ ! -f "$CFG_FILE" ] || [ "${lib.boolToString cfg.forceConfig}" = "true" ]; then
          cat >"$CFG_FILE" <<'EOF'
${cfg.configText}
EOF
        fi
      '';
    })

    (lib.mkIf cfg.enableService {
      systemd.user.services.stasis = {
        Unit = {
          Description = "Stasis (Wayland idle manager)";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${lib.getExe cfg.package} --config ${lib.escapeShellArg cfg.configFile}";
          ExecReload = "${lib.getExe cfg.package} --config ${lib.escapeShellArg cfg.configFile} reload";
          Restart = "on-failure";
          RestartSec = 2;
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    })
  ]);
}
