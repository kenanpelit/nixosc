# modules/nixos/vpn/default.nix
# ==============================================================================
# NixOS VPN tooling: WireGuard/OpenVPN defaults and helpers.
# Centralize tunnel configuration knobs shared across hosts.
# Manage VPN policy here instead of per-host configs.
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

        grace_sec="''${OSC_MULLVAD_BOOT_GRACE_SEC:-35}"
        poll_sec="''${OSC_MULLVAD_BOOT_POLL_SEC:-2}"
        require_internet="''${OSC_MULLVAD_BOOT_REQUIRE_INTERNET:-1}"
        check_url="''${OSC_MULLVAD_BOOT_CHECK_URL:-https://am.i.mullvad.net/connected}"
        check_expect="''${OSC_MULLVAD_BOOT_CHECK_EXPECT:-You are connected}"
        connect_timeout="''${OSC_MULLVAD_BOOT_CONNECT_TIMEOUT:-2}"
        max_time="''${OSC_MULLVAD_BOOT_MAX_TIME:-4}"

        [[ "$grace_sec" =~ ^[0-9]+$ ]] || grace_sec=35
        [[ "$poll_sec" =~ ^[0-9]+$ ]] || poll_sec=2
        (( poll_sec > 0 )) || poll_sec=2

        has_blocky=0
        if ${pkgs.systemd}/bin/systemctl list-unit-files blocky.service >/dev/null 2>&1; then
          has_blocky=1
        fi

        mullvad_soft_disable() {
          ${mullvadPkg}/bin/mullvad disconnect >/dev/null 2>&1 || true
          ${mullvadPkg}/bin/mullvad auto-connect set off >/dev/null 2>&1 || true
          ${mullvadPkg}/bin/mullvad lockdown-mode set off >/dev/null 2>&1 || true
        }

        blocky_start() {
          [[ "$has_blocky" -eq 1 ]] || return 0
          ${pkgs.systemd}/bin/systemctl start blocky.service >/dev/null 2>&1 || true
        }

        blocky_stop() {
          [[ "$has_blocky" -eq 1 ]] || return 0
          ${pkgs.systemd}/bin/systemctl stop blocky.service >/dev/null 2>&1 || true
        }

        vpn_connected() {
          ${mullvadPkg}/bin/mullvad status 2>/dev/null | grep -q "Connected"
        }

        mullvad_blocked_state() {
          local status_text
          status_text="$(${mullvadPkg}/bin/mullvad status 2>/dev/null || true)"
          echo "$status_text" | grep -qi "Blocked:" && return 0
          echo "$status_text" | grep -qi "device has been revoked" && return 0
          return 1
        }

        vpn_healthy() {
          vpn_connected || return 1
          [[ "$require_internet" == "1" ]] || return 0
          ${pkgs.curl}/bin/curl -fsS --connect-timeout "$connect_timeout" --max-time "$max_time" "$check_url" 2>/dev/null | grep -qi "$check_expect"
        }

        if ! ${mullvadPkg}/bin/mullvad account get >/dev/null 2>&1; then
          echo "Mullvad account not logged in; enabling Blocky fallback."
          mullvad_soft_disable
          blocky_start
          exit 0
        fi

        if mullvad_blocked_state; then
          echo "Mullvad blocked/revoked state detected; resetting daemon state before connect."
          mullvad_soft_disable
        fi

        ${mullvadPkg}/bin/mullvad connect || true

        elapsed=0
        while (( elapsed <= grace_sec )); do
          if vpn_healthy; then
            blocky_stop
            exit 0
          fi
          sleep "$poll_sec"
          elapsed=$((elapsed + poll_sec))
        done

        echo "Mullvad not healthy after grace window; falling back to Blocky."
        mullvad_soft_disable
        blocky_start
      '');
    };
    wantedBy = [ "multi-user.target" ];
  };
}
