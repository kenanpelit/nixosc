# modules/nixos/dns/default.nix
# ==============================================================================
# NixOS DNS policy: resolvers, local proxies, and fallback options.
# Configure name services once here to stay consistent across hosts.
# Adjust resolver choices centrally instead of per-interface tweaks.
#
# Includes optional Blocky integration (merged from modules/nixos/blocky).
# ==============================================================================

{ lib, config, pkgs, ... }:

let
  inherit (lib) mkIf mkMerge mkOption mkEnableOption mkDefault mkForce mkAfter optionals types;

  isPhysicalHost = config.my.host.isPhysicalHost or false;
  hasMullvad = config.services.mullvad-vpn.enable or false;

  cfg = config.my.dns.blocky;
  blockyConfigured = cfg.enable;

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

    noGoogle.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable aggressive "no-google" blocklists (Google/YouTube/DoubleClick/etc).

        This can break Google services and apps. Keep it off unless you
        explicitly want to block Google domains.
      '';
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

  config = mkMerge [
    # -------------------------------------------------------------------------
    # systemd-resolved (default path when Blocky is disabled)
    # -------------------------------------------------------------------------
    (mkIf (!blockyConfigured) {
      services.resolved = {
        enable = true;
        dnssec = "allow-downgrade";
        domains = [ "~." ];
        fallbackDns = [ "1.1.1.1" "9.9.9.9" ];
        extraConfig = ''
          DNSOverTLS=yes
          DNSStubListener=yes
        '';
      };
    })

    # -------------------------------------------------------------------------
    # Blocky + resolvconf path (when enabled)
    # -------------------------------------------------------------------------
    (mkIf blockyConfigured {
      # Avoid resolver stacking and port conflicts; let Blocky own :53.
      services.resolved.enable = mkForce false;

      # Let DNS be controlled dynamically (e.g. Blocky service hooks / VPN).
      networking.resolvconf.enable = mkDefault true;

      # Ignore DHCP-provided router DNS from NetworkManager; keep resolver selection
      # controlled via `networking.nameservers` + VPN keys.
      networking.resolvconf.extraConfig = mkAfter ''
        deny_keys='NetworkManager'
      '';

      # Provide a safe, consistent fallback resolver set when Blocky is stopped
      # and prevent LAN/router DNS from sneaking into resolv.conf.
      networking.nameservers = mkDefault [ "1.1.1.1" "9.9.9.9" ];

      # When using resolvconf + local DNS stacks, let DNS be driven by resolvconf
      # sources we control (static + VPN), not by per-connection DHCP DNS.
      environment.etc."NetworkManager/conf.d/90-osc-dns.conf".text = mkDefault ''
        [main]
        dns=none
      '';

      services.blocky = {
        enable = true;
        settings = {
          # New-style configuration (Blocky >= 0.27). Avoid deprecated keys.
          ports = {
            dns = 53;
            http = cfg.httpPort;
          };

          log.level = "info";

          upstreams = {
            # Don't block service start if upstreams aren't reachable yet (e.g. boot/race).
            init.strategy = "fast";
            # Pick the fastest upstreams per query.
            strategy = "parallel_best";
            timeout = "2s";
            groups.default = cfg.upstream;
          };

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
              ++ optionals cfg.noGoogle.enable [ "nogoogle" ];

            loading = {
              refreshPeriod = "24h";
              # Old behaviour: "don't fail start if list fetch fails".
              strategy = "fast";
            };
          };
        };
      };

      # Keep the unit available even when not autostarting; helper scripts can
      # start/stop it at runtime. Switch resolv.conf to 127.0.0.1 only while
      # Blocky is running (ExecStartPost/ExecStopPost).
      systemd.services.blocky = mkMerge [
        {
          serviceConfig = {
            # Blocky itself may run as an unprivileged user; resolvconf needs root.
            ExecStartPost = [ "+${resolvconfAdd}" ];
            ExecStopPost = [ "+${resolvconfDel}" ];
          };
        }
        (mkIf (!cfg.autostart) {
          wantedBy = mkForce [ ];
        })
      ];

      environment.systemPackages = [ pkgs.blocky ];
    })
  ];
}
