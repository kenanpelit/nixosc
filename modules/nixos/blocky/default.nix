# modules/nixos/blocky/default.nix
# ==============================================================================
# DNS ad-blocking via Blocky
# ------------------------------------------------------------------------------
# Blocky is a local DNS proxy with blocklists. This replaces the previous hblock
# HOSTALIASES-based approach and works system-wide (not per-app/per-user).
# ==============================================================================

{ lib, config, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;

  cfg = config.my.dns.blocky;
  isPhysicalHost = config.my.host.isPhysicalHost or false;
  hasMullvad = config.services.mullvad-vpn.enable or false;

  resolvconf = "${pkgs.openresolv}/sbin/resolvconf";
  resolvconfAdd = pkgs.writeShellScript "blocky-resolvconf-add" ''
    #!${pkgs.bash}/bin/bash
    set -uo pipefail
    # Best-effort: don't fail Blocky start if resolvconf can't be updated.
    if ! ${resolvconf} -m 0 -x -a blocky <<'EOF'; then
    nameserver 127.0.0.1
    nameserver ::1
    EOF
      exit 0
    fi
    ${resolvconf} -u || true
  '';
  resolvconfDel = pkgs.writeShellScript "blocky-resolvconf-del" ''
    #!${pkgs.bash}/bin/bash
    set -uo pipefail
    # Best-effort: don't fail Blocky stop if resolvconf can't be updated.
    ${resolvconf} -f -d blocky || true
    ${resolvconf} -u || true
  '';
in
{
  options.my.dns.blocky = {
    enable = mkOption {
      type = types.bool;
      default = isPhysicalHost;
      defaultText = "config.my.host.isPhysicalHost";
      description = "Enable Blocky (local DNS proxy + ad/malware blocking).";
    };

    noGoogle = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable aggressive "no-google" blocklists (Google/YouTube/DoubleClick/etc).

          This can break Google services and apps. Keep it off unless you
          explicitly want to block Google domains.
        '';
      };
    };

    autostart = mkOption {
      type = types.bool;
      default = !hasMullvad;
      defaultText = "!config.services.mullvad-vpn.enable";
      description = ''
        Start Blocky automatically at boot.

        If Mullvad VPN is enabled, default is off to avoid DNS-leak-prevention conflicts.
        You can still start/stop Blocky manually (e.g. via `systemctl start/stop blocky`).
      '';
    };

    httpPort = mkOption {
      type = types.port;
      default = 4000;
      description = "Blocky HTTP port (metrics/health).";
    };

    upstream = mkOption {
      type = types.listOf types.str;
      default = [
        "1.1.1.1"
        "9.9.9.9"
      ];
      description = "Upstream DNS servers (IP or DoH/DoT endpoints supported by Blocky).";
    };
  };

  config = mkIf cfg.enable {
    services.blocky = {
      enable = true;
      settings = {
        # New-style configuration (Blocky >= 0.27). Avoid deprecated keys.
        ports = {
          dns = 53;
          http = cfg.httpPort;
        };

        log.level = "info";

        upstreams.groups.default = cfg.upstream;

        # Keep Blocky resilient at boot: if a list fetch fails, don't block start.
        blocking = {
          # Host-format lists work well with Blocky and are widely available.
          denylists = {
            ads = [
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
              # Extra coverage for ad/tracker domains (plain domain list).
              "https://raw.githubusercontent.com/blocklistproject/Lists/master/ads.txt"
            ];

            # Optional: aggressive Google/YouTube blocking.
            nogoogle = [
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/pihole-google.txt"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/youtubeparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/shortlinksparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/proxiesparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/productsparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/mailparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/generalparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/fontsparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/firebaseparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/doubleclickparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/domainsparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/dnsparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/androidparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/analyticsparsed"
              "https://raw.githubusercontent.com/nickspaargaren/no-google/master/categories/fiberparsed"
            ];
          };
          clientGroupsBlock.default =
            [ "ads" ]
            ++ lib.optionals cfg.noGoogle.enable [ "nogoogle" ];

          loading = {
            refreshPeriod = "24h";
            # Old behaviour: "don't fail start if list fetch fails".
            strategy = "fast";
          };
        };
      };
    };

    # Keep the unit available even when not autostarting; `osc-mullvad toggle --with-blocky`
    # can start/stop it at runtime. Also, switch /etc/resolv.conf to 127.0.0.1 only while
    # Blocky is running (ExecStartPost/ExecStopPost).
    systemd.services.blocky = lib.mkMerge [
      {
        serviceConfig = {
          # Blocky itself may run as an unprivileged user; resolvconf needs root.
          ExecStartPost = [ "+${resolvconfAdd}" ];
          ExecStopPost = [ "+${resolvconfDel}" ];
        };
      }
      (lib.mkIf (!cfg.autostart) {
        wantedBy = lib.mkForce [ ];
      })
    ];

    environment.systemPackages = [ pkgs.blocky ];
  };
}
