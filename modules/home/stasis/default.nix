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

{ inputs, config, lib, pkgs, ... }:
let
  cfg = config.my.user.stasis;

  dag =
    if lib ? hm && lib.hm ? dag
    then lib.hm.dag
    else config.lib.dag;

  system = pkgs.stdenv.hostPlatform.system;

  stasisFromInput =
    if inputs ? stasis
    then
      let
        stasisPackages = inputs.stasis.packages or { };
      in
      lib.attrByPath
        [ system "stasis" ]
        (lib.attrByPath [ system "default" ] null stasisPackages)
        stasisPackages
    else null;

  defaultPackage =
    if stasisFromInput != null
    then stasisFromInput
    else if pkgs ? stasis then pkgs.stasis else null;

  configDir = "${config.xdg.configHome}/stasis";
  configFile = "${configDir}/stasis.rune";

  # A sane default, designed for Niri + Hyprland + DMS.
  #
  # Notes:
  # - IMPORTANT: `stasis-lock` must NOT block when used in the idle pipeline.
  #   If it blocks (e.g. waiting until unlock), Stasis will never reach later
  #   stages like DPMS/suspend. For manual use you can still run
  #   `stasis-lock --wait`.
  # - Stasis timeouts are sequential (each timeout is relative to the previous
  #   action firing). To match Hypridle's "absolute" schedule, we convert absolute
  #   targets (t=300/900/1800/1860/3600) into deltas (300/600/900/60/1740).
  defaultConfigText = ''
    # This file is managed by nixosc (Home-Manager activation), but is kept
    # writable on disk so you can still tweak it manually.
    #
    # Reference (Stasis 0.6.x):
    # - `stasis info`
    # - `stasis list-actions`
    # - `stasis trigger <name>`

    @author "kenanpelit/nixosc"
    @description "Stasis idle config (DMS + Niri/Hyprland friendly)"

    stasis:
      monitor_media true
      ignore_remote_media true
      respect_idle_inhibitors true

      # Apps that should inhibit idle actions.
      inhibit_apps [
        "mpv"
        "vlc"
        r"steam_app_.*"
      ]

      # Schedule (matches the Hypridle module defaults in this repo):
      # - 05:00  keyboard backlight off
      # - 15:00  screen dim
      # - 30:00  lock-session
      # - 31:00  DPMS off
      # - 60:00  suspend

      # NOTE (Laptop):
      # Stasis treats laptops specially and reads idle actions from `on_ac` and
      # `on_battery` blocks. If you only define actions directly under `stasis:`,
      # it will error with "no valid idle actions found".
      #
      # However, the CLI (`stasis list-actions` / `stasis trigger`) currently
      # only exposes desktop actions reliably. To avoid surprises (and to make
      # `stasis trigger lock_screen` work consistently), we define desktop
      # placeholders with a very large timeout. They will not auto-fire, but
      # they remain manually triggerable.

      lock_screen:
        timeout 31536000
        command "${config.home.profileDirectory}/bin/stasis-lock"
      end

      dpms:
        timeout 31536000
        command "niri msg action power-off-monitors || hyprctl dispatch dpms off || true"
        resume-command "niri msg action power-on-monitors || hyprctl dispatch dpms on || true"
      end

      suspend:
        timeout 31536000
        command "systemctl suspend -i"
      end

      on_ac:
        kbd_backlight:
          timeout ${toString cfg.timeouts.kbdBacklightDeltaSeconds}
          command "${config.home.profileDirectory}/bin/stasis-kbd-backlight off"
          resume-command "${config.home.profileDirectory}/bin/stasis-kbd-backlight restore"
        end

        brightness:
          timeout ${toString cfg.timeouts.dimDeltaSeconds}
          command "sh -c 'brightnessctl -s set 10 || true'"
          resume-command "sh -c 'brightnessctl -r || true'"
        end

        lock_screen:
          timeout ${toString cfg.timeouts.lockDeltaSeconds}
          command "${config.home.profileDirectory}/bin/stasis-lock"
          resume-command "notify-send 'Welcome back, $env.USER!'"
        end

        dpms:
          timeout ${toString cfg.timeouts.dpmsDeltaSeconds}
          command "niri msg action power-off-monitors || hyprctl dispatch dpms off || true"
          resume-command "niri msg action power-on-monitors || hyprctl dispatch dpms on || true"
        end

        suspend:
          timeout ${toString cfg.timeouts.suspendDeltaSeconds}
          command "systemctl suspend -i"
        end
      end

      # Battery: keep same schedule by default (tune later if you want).
      on_battery:
        kbd_backlight:
          timeout ${toString cfg.timeouts.kbdBacklightDeltaSeconds}
          command "${config.home.profileDirectory}/bin/stasis-kbd-backlight off"
          resume-command "${config.home.profileDirectory}/bin/stasis-kbd-backlight restore"
        end

        brightness:
          timeout ${toString cfg.timeouts.dimDeltaSeconds}
          command "sh -c 'brightnessctl -s set 10 || true'"
          resume-command "sh -c 'brightnessctl -r || true'"
        end

        lock_screen:
          timeout ${toString cfg.timeouts.lockDeltaSeconds}
          command "${config.home.profileDirectory}/bin/stasis-lock"
          resume-command "notify-send 'Welcome back, $env.USER!'"
        end

        dpms:
          timeout ${toString cfg.timeouts.dpmsDeltaSeconds}
          command "niri msg action power-off-monitors || hyprctl dispatch dpms off || true"
          resume-command "niri msg action power-on-monitors || hyprctl dispatch dpms on || true"
        end

        suspend:
          timeout ${toString cfg.timeouts.suspendDeltaSeconds}
          command "systemctl suspend -i"
        end
      end
    end

    # Profiles can be switched at runtime:
    # - `stasis profile work`
    # - `stasis profile none`
    profiles:
      work:
        lock_screen:
          timeout 900
          command "${config.home.profileDirectory}/bin/stasis-lock"
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

  stasisLock = pkgs.writeShellScriptBin "stasis-lock" ''
    set -euo pipefail

    wait="0"
    if [[ "''${1:-}" == "--wait" ]]; then
      wait="1"
    fi

    # Helpful breadcrumb in journal when called by stasis.service.
    if command -v logger >/dev/null 2>&1; then
      logger -t stasis-lock "lock requested (wait=$wait)"
    fi

    # Prefer Hyprland lock when available.
    if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprlock >/dev/null 2>&1; then
      if [[ "$wait" == "1" ]]; then
        exec hyprlock
      fi
      hyprlock >/dev/null 2>&1 &
      disown || true
      exit 0
    fi

    # Niri (and others): use DMS lock if available and block until unlocked.
    if command -v dms >/dev/null 2>&1; then
      # IMPORTANT: DMS lock call may block; never let it block the Stasis action
      # pipeline. Only block when explicitly requested via `--wait`.
      (dms ipc call lock lock >/dev/null 2>&1 || true) &
      disown || true

      if [[ "$wait" != "1" ]]; then exit 0; fi

      # Block until DMS reports unlock.
      while true; do
        out="$(
          dms ipc call lock isLocked 2>/dev/null \
          | tr -d '\r' \
          | tail -n 1 \
          | tr -d '[:space:]' \
          || true
        )"

        case "$out" in
          true) ;;
          false) exit 0 ;;
          *) ;;
        esac

        sleep 0.25
      done
    fi

    # Fallback: logind lock (may use compositor's default locker).
    if command -v loginctl >/dev/null 2>&1; then
      exec loginctl lock-session
    fi
  '';

  stasisKbdBacklight = pkgs.writeShellScriptBin "stasis-kbd-backlight" ''
    set -euo pipefail

    mode="''${1:-}"
    if [[ "$mode" != "off" && "$mode" != "restore" ]]; then
      echo "Usage: stasis-kbd-backlight <off|restore>" >&2
      exit 2
    fi

    # Some machines simply don't expose a keyboard backlight device.
    # Avoid noisy logs by no-op'ing when it's missing.
    if ! command -v brightnessctl >/dev/null 2>&1; then
      exit 0
    fi

    # Prefer an explicit *kbd_backlight* LEDs device (ThinkPads: tpacpi::kbd_backlight).
    dev="$(
      brightnessctl -l 2>/dev/null \
        | awk -F"'" '/Device .*kbd_backlight.* of class .*leds/ {print $2; exit}'
    )"

    if [[ -z "$dev" ]]; then
      exit 0
    fi

    case "$mode" in
      off)
        brightnessctl -sd "$dev" set 0 >/dev/null 2>&1 || true
        ;;
      restore)
        brightnessctl -rd "$dev" >/dev/null 2>&1 || true
        ;;
    esac
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

        Defaults to `inputs.stasis.packages.${system}.stasis` when `inputs.stasis`
        is present, otherwise falls back to `pkgs.stasis` (if your pinned nixpkgs
        provides it). If neither exists, set this explicitly.
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
      # Absolute targets from "idle start" (Hypridle-style).
      # We convert these to sequential deltas internally (Stasis-style).
      kbdBacklightAtSeconds = lib.mkOption {
        type = lib.types.int;
        default = 300;
        description = "After how many idle seconds to turn keyboard backlight off.";
      };

      dimAtSeconds = lib.mkOption {
        type = lib.types.int;
        default = 900;
        description = "After how many idle seconds to dim the screen (brightnessctl).";
      };

      lockAtSeconds = lib.mkOption {
        type = lib.types.int;
        default = 1800;
        description = "After how many idle seconds to `loginctl lock-session`.";
      };

      dpmsAtSeconds = lib.mkOption {
        type = lib.types.int;
        default = 1860;
        description = "After how many idle seconds to turn displays off (DPMS).";
      };

      suspendAtSeconds = lib.mkOption {
        type = lib.types.int;
        default = 3600;
        description = "After how many idle seconds to suspend.";
      };

      # Derived deltas (Stasis executes actions sequentially).
      kbdBacklightDeltaSeconds = lib.mkOption {
        type = lib.types.int;
        internal = true;
        default = cfg.timeouts.kbdBacklightAtSeconds;
      };

      dimDeltaSeconds = lib.mkOption {
        type = lib.types.int;
        internal = true;
        default = cfg.timeouts.dimAtSeconds - cfg.timeouts.kbdBacklightAtSeconds;
      };

      lockDeltaSeconds = lib.mkOption {
        type = lib.types.int;
        internal = true;
        default = cfg.timeouts.lockAtSeconds - cfg.timeouts.dimAtSeconds;
      };

      dpmsDeltaSeconds = lib.mkOption {
        type = lib.types.int;
        internal = true;
        default = cfg.timeouts.dpmsAtSeconds - cfg.timeouts.lockAtSeconds;
      };

      suspendDeltaSeconds = lib.mkOption {
        type = lib.types.int;
        internal = true;
        default = cfg.timeouts.suspendAtSeconds - cfg.timeouts.dpmsAtSeconds;
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
        {
          assertion =
            cfg.timeouts.kbdBacklightAtSeconds >= 0
            && cfg.timeouts.dimAtSeconds >= cfg.timeouts.kbdBacklightAtSeconds
            && cfg.timeouts.lockAtSeconds >= cfg.timeouts.dimAtSeconds
            && cfg.timeouts.dpmsAtSeconds >= cfg.timeouts.lockAtSeconds
            && cfg.timeouts.suspendAtSeconds >= cfg.timeouts.dpmsAtSeconds;
          message = ''
            my.user.stasis.timeouts.*AtSeconds must be monotonic (non-decreasing).
            Expected: kbdBacklightAt <= dimAt <= lockAt <= dpmsAt <= suspendAt
          '';
        }
      ];

      home.packages = [
        cfg.package
        stasisctl
        stasisLock
        stasisKbdBacklight
        pkgs.brightnessctl
        pkgs.libnotify
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
        else
          # If the user already started Stasis once, it may have auto-generated a
          # config with a lock command that doesn't exist on this system.
          # This setup locks via DMS (Niri) or hyprlock (Hyprland), so we
          # auto-migrate `lock_screen.command` in-place when needed.
          #
          # Keep it a minimal patch (do not rewrite the whole file) unless
          # `forceConfig = true`.
          lock_cmd=${lib.escapeShellArg "${config.home.profileDirectory}/bin/stasis-lock"}
          kbd_cmd=${lib.escapeShellArg "${config.home.profileDirectory}/bin/stasis-kbd-backlight"}

          # For `lock_screen` blocks:
          # For `lock_screen` blocks:
          # - Ensure `command` points to our non-blocking locker (`stasis-lock`).
          # - Drop any `lock-command` lines (we avoid logind-managed lockers here
          #   because it previously caused lock loops on this setup).
          tmp="$(mktemp)"
          changed="0"
          in_lock="0"
          while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*lock[_-]screen:[[:space:]]*$ ]]; then
              in_lock="1"
              echo "$line" >>"$tmp"
              continue
            fi

            if [[ "$in_lock" == "1" && "$line" =~ ^([[:space:]]*)command[[:space:]]+\"([^\"]+)\"[[:space:]]*$ ]]; then
              indent="''${BASH_REMATCH[1]}"
              cmd="''${BASH_REMATCH[2]}"
              bin="''${cmd%% *}"

              # If it's not an absolute path and the binary doesn't exist, normalize.
              if [[ "$bin" != /* ]] && ! command -v "$bin" >/dev/null 2>&1; then
                echo "''${indent}command \"''${lock_cmd}\"" >>"$tmp"
                changed="1"
                continue
              fi

              # Normalize any logind-style command to our locker.
              if [[ "$cmd" == "loginctl lock-session" ]]; then
                echo "''${indent}command \"''${lock_cmd}\"" >>"$tmp"
                changed="1"
                continue
              fi

              # If this is some locker-ish command, normalize to our wrapper.
              if [[ "$cmd" == "''${lock_cmd}" || "$bin" == "stasis-lock" || "$bin" == "hyprlock" || "$bin" == "dms" ]]; then
                echo "''${indent}command \"''${lock_cmd}\"" >>"$tmp"
                changed="1"
                continue
              fi
            fi

            if [[ "$in_lock" == "1" && "$line" =~ ^([[:space:]]*)lock-command[[:space:]]+\"([^\"]+)\"[[:space:]]*$ ]]; then
              changed="1"
              # Drop lock-command lines entirely.
              continue
            fi

            if [[ "$in_lock" == "1" && "$line" =~ ^([[:space:]]*)end[[:space:]]*$ ]]; then
              in_lock="0"
            fi

            echo "$line" >>"$tmp"
          done <"$CFG_FILE"

          if [[ "$changed" == "1" ]]; then
            mv -f "$tmp" "$CFG_FILE"
          else
            rm -f "$tmp"
          fi

          # Stasis 0.6.x CLI triggers are step-based (`stasis trigger lock_screen`)
          # but laptop configs often only define `on_ac`/`on_battery` actions.
          # Ensure desktop placeholder actions exist so `list-actions`/`trigger`
          # behave predictably without affecting the real idle schedule.
          if ! grep -qE '^[[:space:]]{2}lock[_-]screen:[[:space:]]*$' "$CFG_FILE"; then
            lock_cmd=${lib.escapeShellArg "${config.home.profileDirectory}/bin/stasis-lock"}
            tmp="$(mktemp)"
            inserted="0"
            while IFS= read -r line; do
              echo "$line" >>"$tmp"
              if [[ "$inserted" == "0" && "$line" =~ ^[[:space:]]*stasis:[[:space:]]*$ ]]; then
                cat >>"$tmp" <<EOF
  lock_screen:
    timeout 31536000
    command "$lock_cmd"
  end

  dpms:
    timeout 31536000
    command "niri msg action power-off-monitors || hyprctl dispatch dpms off || true"
    resume-command "niri msg action power-on-monitors || hyprctl dispatch dpms on || true"
  end

  suspend:
    timeout 31536000
    command "systemctl suspend -i"
  end

EOF
                inserted="1"
              fi
            done <"$CFG_FILE"
            mv -f "$tmp" "$CFG_FILE"
          fi

          # Keep kbd_backlight actions quiet and safe across machines without a
          # kbd backlight device (avoid "Device not found" spam).
          if grep -qE 'kbd_backlight' "$CFG_FILE"; then
            tmp="$(mktemp)"
            sed -E \
              -e "s|^([[:space:]]*)command[[:space:]]+\\\".*kbd_backlight.*\\\"$|\\1command \\\"$kbd_cmd off\\\"|" \
              -e "s|^([[:space:]]*)resume-command[[:space:]]+\\\".*kbd_backlight.*\\\"$|\\1resume-command \\\"$kbd_cmd restore\\\"|" \
              "$CFG_FILE" >"$tmp"
            mv -f "$tmp" "$CFG_FILE"
          fi

          # If this machine is a laptop and the config doesn't define `on_ac` /
          # `on_battery`, Stasis will not load any actions. In that case we
          # migrate by backing up the old file and writing our laptop-safe base.
          if ! grep -qE '^[[:space:]]*on_ac:[[:space:]]*$' "$CFG_FILE" && ! grep -qE '^[[:space:]]*on_battery:[[:space:]]*$' "$CFG_FILE"; then
            if grep -qE '^[[:space:]]{2}lock[_-]screen:[[:space:]]*$' "$CFG_FILE"; then
              chassis="/sys/class/dmi/id/chassis_type"
              if [ -r "$chassis" ]; then
                ct="$(cat "$chassis" 2>/dev/null || true)"
                # DMI chassis types: 8/9/10/14 commonly indicate a laptop-like device.
                if [[ "$ct" =~ ^(8|9|10|14)$ ]]; then
                  ts="$(date +%Y%m%d-%H%M%S)"
                  cp -f "$CFG_FILE" "$CFG_FILE.bak-$ts"
                  cat >"$CFG_FILE" <<'EOF'
${cfg.configText}
EOF
                fi
              fi
            fi
          fi
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
          Environment = [
            "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/run/wrappers/bin"
          ];
          ExecStart = "${lib.getExe' cfg.package "stasis"} --verbose --config ${lib.escapeShellArg cfg.configFile}";
          ExecReload = "${lib.getExe' cfg.package "stasis"} --verbose --config ${lib.escapeShellArg cfg.configFile} reload";
          Restart = "on-failure";
          RestartSec = 2;
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    })
  ]);
}
