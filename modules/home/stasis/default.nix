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
  # - We use `lock_detection_type "process"` and a small wrapper (`stasis-lock`)
  #   that blocks until the lock is actually released. This is important because
  #   DMS locking (IPC call) may return immediately, and Stasis needs a long-lived
  #   process to track "locked" state reliably.
  # - Stasis timeouts are sequential (each timeout is relative to the previous
  #   action firing). To match Hypridle's "absolute" schedule, we convert absolute
  #   targets (t=300/900/1800/1860/3600) into deltas (300/600/900/60/1740).
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

      # Track locks by process lifetime (see `stasis-lock` wrapper).
      lock_detection_type "process"

      # Apps that should inhibit idle actions.
      inhibit_apps [
        "mpv"
        "vlc"
        "Spotify"
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

    # Prefer Hyprland lock when available.
    if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprlock >/dev/null 2>&1; then
      exec hyprlock
    fi

    # Niri (and others): use DMS lock if available and block until unlocked.
    if command -v dms >/dev/null 2>&1; then
      dms ipc call lock lock >/dev/null 2>&1 || true

      # Block until DMS reports unlock (keeps this process alive for Stasis).
      for _ in $(seq 1 2400); do # ~10 min @ 0.25s
        out="$(dms ipc call lock isLocked 2>/dev/null | tr -d '\r' | tail -n 1 || true)"
        if [[ "$out" != "true" ]]; then
          exit 0
        fi
        sleep 0.25
      done
      exit 0
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

          # Older configs may use loginctl directly; on this setup DMS/hyprlock is
          # the actual locker, so migrate lock_screen commands to stasis-lock.
          if grep -q 'command[[:space:]]*"loginctl lock-session"' "$CFG_FILE"; then
            tmp="$(mktemp)"
            sed "s|command[[:space:]]*\\\"loginctl lock-session\\\"|command \\\"$lock_cmd\\\"|g" "$CFG_FILE" >"$tmp"
            mv -f "$tmp" "$CFG_FILE"
          fi

          # For `lock_screen` blocks: if the configured command binary is missing,
          # replace it with stasis-lock.
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

              # If it's not an absolute path and the binary doesn't exist, migrate.
              if [[ "$bin" != /* ]] && ! command -v "$bin" >/dev/null 2>&1; then
                echo "''${indent}command \"''${lock_cmd}\"" >>"$tmp"
                changed="1"
                continue
              fi
            fi

            if [[ "$in_lock" == "1" && "$line" =~ ^[[:space:]]*end[[:space:]]*$ ]]; then
              in_lock="0"
            fi

            echo "$line" >>"$tmp"
          done <"$CFG_FILE"

          if [[ "$changed" == "1" ]]; then
            mv -f "$tmp" "$CFG_FILE"
          else
            rm -f "$tmp"
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

          # Ensure we use process-based lock detection when using stasis-lock.
          if grep -q "$lock_cmd" "$CFG_FILE" && ! grep -Eq 'lock_detection_type|lock-detection-type' "$CFG_FILE"; then
            tmp="$(mktemp)"
            awk '
              { print }
              $0 ~ /^[[:space:]]*respect_idle_inhibitors[[:space:]]+true/ {
                print "  lock_detection_type \"process\""
              }
            ' "$CFG_FILE" >"$tmp"
            mv -f "$tmp" "$CFG_FILE"
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
