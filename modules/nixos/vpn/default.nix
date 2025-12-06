# modules/core/vpn/default.nix
# ==============================================================================
# VPN Services Configuration
# ==============================================================================
# Configures VPN services (Mullvad) for physical hosts.
# - Enables Mullvad VPN service
# - Sets up autoconnect service on boot
#
# ==============================================================================

{ config, lib, pkgs, ... }:

let
  isPhysicalHost = config.my.host.isPhysicalHost;
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
    unitConfig.ConditionPathExists = "/var/lib/mullvad-vpn/account-history.json";
    serviceConfig = {
      Type = "oneshot";
      Restart = "no";
      ExecStart = lib.getExe (pkgs.writeShellScriptBin "mullvad-autoconnect" ''
        #!${pkgs.bash}/bin/bash
        set -euo pipefail
        if ! ${mullvadPkg}/bin/mullvad account get >/dev/null 2>&1; then
          echo "Mullvad account not logged in; skipping autoconnect."
          exit 0
        fi
        ${mullvadPkg}/bin/mullvad connect || exit 0
      '');
    };
    wantedBy = [ "multi-user.target" ];
  };
}
