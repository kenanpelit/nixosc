# modules/core/networking/vpn/default.nix
# Mullvad VPN service and autoconnect.

{ config, lib, pkgs, isPhysicalHost ? false, ... }:

let
  hasMullvad = config.services.mullvad-vpn.enable or false;
  mullvadPkg = pkgs.mullvad;
in {
  services.mullvad-vpn = lib.mkIf isPhysicalHost {
    enable = true;
    package = mullvadPkg;
  };

  systemd.services."mullvad-autoconnect" = lib.mkIf hasMullvad {
    description = "Mullvad autoconnect on boot";
    wants = [ "network-online.target" "mullvad-daemon.service" ];
    after  = [ "network-online.target" "NetworkManager.service" "mullvad-daemon.service" ];
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = 5;
      ExecStart = lib.getExe (pkgs.writeShellScriptBin "mullvad-autoconnect" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        ${mullvadPkg}/bin/mullvad connect
      '');
    };
    wantedBy = [ "multi-user.target" ];
  };
}
