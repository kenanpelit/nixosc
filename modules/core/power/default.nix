# modules/core/power/default.nix
# Power management hooks (RAPL, power source).

{ pkgs, lib, config, hostRole ? "unknown", isPhysicalHost ? false, isVirtualHost ? false, ... }:

let
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = isPhysicalHost;
  isVirtualMachine  = isVirtualHost;

  enablePowerTuning     = isPhysicalMachine;
  enableRaplThermoGuard = isPhysicalMachine;

  cpuDetectionScript = pkgs.writeTextFile {
    name = "detect-cpu";
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      CPU_MODEL=$(LC_ALL=C ${pkgs.util-linux}/bin/lscpu | ${pkgs.gnugrep}/bin/grep -F "Model name" | ${pkgs.coreutils}/bin/cut -d: -f2-)
      CPU_MODEL=$(echo "''${CPU_MODEL}" | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

      case "''${CPU_MODEL}" in
        *"Ultra 7 155H"*|*"Meteor Lake"*|*"MTL"*) echo "METEORLAKE" ;;
        *"8650U"*|*"Kaby Lake"*)                   echo "KABYLAKE" ;;
        *)                                        echo "GENERIC" ;;
      esac
    '';
  };

  detectPowerSourceFunc = ''
    detect_power_source() {
      local on_ac=0
      for ps in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [[ -f "$ps" ]] && on_ac="$(cat "$ps")" && break
      done
      if [[ "''${on_ac}" == "1" ]]; then echo "AC"; else echo "BATTERY"; fi
    }
  '';

  mkRobustScript = name: content: pkgs.writeTextFile {
    name = name;
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      exec 1> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.info)
      exec 2> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.err)

      ${content}
    '';
  };
in
{
  systemd.services."power-mgmt-rapl" = lib.mkIf enableRaplThermoGuard {
    wantedBy = [ "multi-user.target" ];
    after    = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkRobustScript "rapl" ''
        PROFILE="$(${cpuDetectionScript})"
        echo "Applying RAPL profile: ''${PROFILE}"
      '';
    };
  };

  systemd.services."power-mgmt-source" = lib.mkIf enablePowerTuning {
    wantedBy = [ "multi-user.target" "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = mkRobustScript "power-source" ''
        ${detectPowerSourceFunc}
        SRC="$(detect_power_source)"
        echo "Power source: ''${SRC}"
      '';
    };
  };
}
