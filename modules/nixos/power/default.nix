# modules/nixos/power/default.nix
# ==============================================================================
# Power management (PPD-first)
# ------------------------------------------------------------------------------
# This repo prefers `power-profiles-daemon` (+ `powerprofilesctl`) for day-to-day
# power profile switching (power-saver / balanced / performance).
#
# Keep only the conflict-free parts here (e.g., battery charge thresholds) and
# avoid writing low-level CPU knobs that would fight with PPD.
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkOption types;
  cfg = config.my.power;
  mainUser = config.my.user.name or "";
  mainUserEscaped = lib.escapeShellArg mainUser;

  isPhysicalMachine = config.my.host.isPhysicalHost or false;
  usePpd = cfg.stack == "ppd";

  thresholds = cfg.battery.chargeThresholds;
  autoCfg = cfg.autoProfile;

  # UPower can "Hibernate" on critical battery, but hibernation requires a
  # configured resume device. Without it, the action may fail or reboot.
  resumeDevice =
    if config.boot ? resumeDevice then config.boot.resumeDevice else null;
  canHibernate = resumeDevice != null;

  autoProfileScript = pkgs.writeShellScript "ppd-auto-profile.sh" ''
    set -euo pipefail

    ppd="${pkgs.power-profiles-daemon}/bin/powerprofilesctl"
    awk_bin="${pkgs.gawk}/bin/awk"
    nproc_bin="${pkgs.coreutils}/bin/nproc"
    id_bin="${pkgs.coreutils}/bin/id"
    runuser_bin="${pkgs.util-linux}/bin/runuser"
    notify_bin="${pkgs.libnotify}/bin/notify-send"
    main_user=${mainUserEscaped}

    notify_change() {
      profile="$1"
      reason="$2"

      [ "${if autoCfg.notify then "1" else "0"}" = "1" ] || return 0
      [ -n "$main_user" ] || return 0
      [ -x "$notify_bin" ] || return 0

      uid="$($id_bin -u "$main_user" 2>/dev/null || true)"
      [ -n "$uid" ] || return 0

      runtime="/run/user/$uid"
      [ -S "$runtime/bus" ] || return 0

      case "$profile" in
        performance)
          icon="speedometer"
          title="Power Profile: Performance"
          ;;
        balanced)
          icon="battery-good"
          title="Power Profile: Balanced"
          ;;
        *)
          icon="battery-good"
          title="Power Profile: $profile"
          ;;
      esac

      $runuser_bin -u "$main_user" -- env \
        DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime/bus" \
        XDG_RUNTIME_DIR="$runtime" \
        "$notify_bin" -t 3000 -i "$icon" "$title" "$reason" >/dev/null 2>&1 || true
    }

    # Keep balanced when not on AC (optional battery protection mode).
    if [ "${if autoCfg.onlyOnAC then "1" else "0"}" = "1" ]; then
      ac_online=0
      mains_found=0

      # Prefer explicit Mains supplies.
      for t in /sys/class/power_supply/*/type; do
        [ -r "$t" ] || continue
        if [ "$(${pkgs.coreutils}/bin/cat "$t" 2>/dev/null || true)" = "Mains" ]; then
          mains_found=1
          p="''${t%/type}/online"
          if [ -r "$p" ] && [ "$(${pkgs.coreutils}/bin/cat "$p" 2>/dev/null || echo 0)" = "1" ]; then
            ac_online=1
            break
          fi
        fi
      done

      # Fallback: if no Mains device is exposed, use any online==1 source.
      if [ "$mains_found" -eq 0 ]; then
        for p in /sys/class/power_supply/*/online; do
          [ -r "$p" ] || continue
          if [ "$(${pkgs.coreutils}/bin/cat "$p" 2>/dev/null || echo 0)" = "1" ]; then
            ac_online=1
            break
          fi
        done
      fi

      if [ "$ac_online" -eq 0 ]; then
        current="$($ppd get 2>/dev/null || true)"
        if [ "$current" = "performance" ]; then
          $ppd set balanced || true
          notify_change balanced "Battery mode: switched from performance to balanced"
        fi
        exit 0
      fi
    fi

    cpus="$($nproc_bin --all 2>/dev/null || echo 1)"
    load1="$($awk_bin '{print $1}' /proc/loadavg)"
    load_pct="$($awk_bin -v l="$load1" -v c="$cpus" 'BEGIN { if (c < 1) c = 1; printf "%.2f", (l / c) * 100 }')"

    current="$($ppd get 2>/dev/null || true)"
    if [ -z "$current" ]; then
      exit 0
    fi

    if [ "$current" != "balanced" ] && [ "$current" != "performance" ]; then
      exit 0
    fi

    high="${toString autoCfg.highLoadPercent}"
    low="${toString autoCfg.lowLoadPercent}"

    if $awk_bin -v lp="$load_pct" -v high="$high" 'BEGIN { exit !(lp >= high) }'; then
      if [ "$current" != "performance" ]; then
        $ppd set performance || true
        notify_change performance "High load: $load_pct% (threshold: $high%)"
      fi
      exit 0
    fi

    if $awk_bin -v lp="$load_pct" -v low="$low" 'BEGIN { exit !(lp <= low) }'; then
      if [ "$current" = "performance" ]; then
        $ppd set balanced || true
        notify_change balanced "Load normalized: $load_pct% (threshold: $low%)"
      fi
      exit 0
    fi

    # Between thresholds: keep current profile (hysteresis).
    exit 0
  '';
in
{
  options.my.power = {
    # Profile manager for the machine.
    stack = mkOption {
      type = types.enum [ "ppd" "none" ];
      default = "ppd";
      description = "Power profile manager: 'ppd' (power-profiles-daemon / powerprofilesctl) or 'none'.";
    };

    # Battery thresholds are independent of CPU profile switching.
    battery.chargeThresholds = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable battery charge thresholds (BAT*/charge_control_*_threshold).";
      };
      start = mkOption {
        type = types.ints.between 0 100;
        default = 75;
        description = "Charge start threshold percentage (e.g., 75).";
      };
      stop = mkOption {
        type = types.ints.between 0 100;
        default = 80;
        description = "Charge stop threshold percentage (e.g., 80).";
      };
    };

    autoProfile = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Automatically switch between balanced and performance based on system load.";
      };

      interval = mkOption {
        type = types.str;
        default = "30s";
        example = "20s";
        description = "Systemd timer interval for automatic profile checks.";
      };

      highLoadPercent = mkOption {
        type = types.ints.between 1 100;
        default = 70;
        description = "Switch to performance when normalized load reaches this percentage.";
      };

      lowLoadPercent = mkOption {
        type = types.ints.between 1 100;
        default = 35;
        description = "Switch back to balanced when normalized load drops to this percentage.";
      };

      onlyOnAC = mkOption {
        type = types.bool;
        default = true;
        description = "If true, never keep performance mode while on battery.";
      };

      notify = mkOption {
        type = types.bool;
        default = true;
        description = "Show desktop notifications when the auto profile changes.";
      };
    };
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion = thresholds.start < thresholds.stop;
          message = "my.power.battery.chargeThresholds.start must be < stop.";
        }
        {
          assertion = autoCfg.lowLoadPercent < autoCfg.highLoadPercent;
          message = "my.power.autoProfile.lowLoadPercent must be < highLoadPercent.";
        }
      ];

      # Centralize UPower configuration
      services.upower = {
        enable = true;
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
        criticalPowerAction = lib.mkDefault (if canHibernate then "Hibernate" else "PowerOff");
      };

      # PPD for interactive profile switching (`powerprofilesctl set ...`).
      services.power-profiles-daemon.enable =
        if isPhysicalMachine && usePpd then true else lib.mkForce false;

      # Ensure the CLI exists (also provides the service binary).
      environment.systemPackages = lib.optionals (isPhysicalMachine && usePpd) [
        pkgs.power-profiles-daemon
      ];

      # Most systems that want PPD also want polkit; keep it as a default.
      security.polkit.enable = lib.mkDefault true;
    }

    (mkIf (isPhysicalMachine && usePpd && autoCfg.enable) {
      systemd.services.ppd-auto-profile = {
        description = "Auto-switch power profile based on system load";
        after = [ "power-profiles-daemon.service" ];
        wants = [ "power-profiles-daemon.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = autoProfileScript;
        };
      };

      systemd.timers.ppd-auto-profile = {
        description = "Periodic load check for automatic power profile switching";
        wantedBy = [ "timers.target" ];
        partOf = [ "ppd-auto-profile.service" ];
        timerConfig = {
          OnBootSec = "1m";
          OnUnitActiveSec = autoCfg.interval;
          AccuracySec = "5s";
          Unit = "ppd-auto-profile.service";
        };
      };
    })

    # Use Udev rules instead of a systemd service/bash script.
    # Why: Udev is event-based. It reapplies settings instantly on boot,
    # resume from suspend, or device redetection, ensuring thresholds never get reset.
    (mkIf (isPhysicalMachine && thresholds.enable) {
      services.udev.extraRules = ''
        SUBSYSTEM=="power_supply", KERNEL=="BAT*", \
          TEST=="charge_control_start_threshold", TEST=="charge_control_end_threshold", \
          ATTR{charge_control_start_threshold}="${builtins.toString thresholds.start}", \
          ATTR{charge_control_end_threshold}="${builtins.toString thresholds.stop}"
      '';
    })
  ];
}
