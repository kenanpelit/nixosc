# modules/core/hblock/default.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.hblock;
in {
  options.services.hblock = {
    enable = mkEnableOption "hBlock service";
    
    updateInterval = mkOption {
      type = types.str;
      default = "*-*-* 00:00:00";
      description = "When to update the hosts file. Uses the systemd calendar format.";
    };

    randomizedDelaySec = mkOption {
      type = types.int;
      default = 3600;
      description = "Add a random delay before each run.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.hblock = {
      description = "hBlock";
      path = [ pkgs.hblock ];
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeScript "hblock-start" ''
          #!${pkgs.bash}/bin/bash
          ${pkgs.hblock}/bin/hblock -O "/var/lib/hblock/hosts"
          cat "/var/lib/hblock/hosts" > /etc/hosts
          rm -f "/var/lib/hblock/hosts"
        ''}";
        CacheDirectory = "hblock";
        UMask = "0077";
        DynamicUser = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallFilter = [
          "~@clock" "~@cpu-emulation" "~@debug" "~@module"
          "~@mount" "~@obsolete" "~@privileged" "~@raw-io"
          "~@reboot" "~@resources" "~@swap"
        ];
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = "";
        DevicePolicy = "closed";
        ProcSubset = "pid";
        NoNewPrivileges = true;
      };
    };

    systemd.timers.hblock = {
      wantedBy = [ "timers.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      
      timerConfig = {
        OnCalendar = cfg.updateInterval;
        RandomizedDelaySec = cfg.randomizedDelaySec;
        Persistent = true;
        Unit = "hblock.service";
      };
    };

    environment.systemPackages = [ pkgs.hblock ];
  };
}

