# modules/core/vpn/default.nix
# ==============================================================================
# VPN Services Configuration
# ==============================================================================
# Configures VPN services (Mullvad) for physical hosts.
# - Enables Mullvad VPN service
# - Sets up autoconnect service on boot
#
# ==============================================================================

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
