# modules/nixos/dns/default.nix
# ==============================================================================
# NixOS DNS Configuration
# ------------------------------------------------------------------------------
# Consolidates system-wide DNS policy (resolved) and local DNS proxy (Blocky).
# If Blocky is enabled, it takes over local resolution and disables resolved.
# ==============================================================================

{ lib, config, pkgs, ... }:

let
  inherit (lib) mkIf mkOption types;

  # -- Blocky Configuration Variables --
  cfgBlocky = config.my.dns.blocky;
  isPhysicalHost = config.my.host.isPhysicalHost or false;
  hasMullvad = config.services.mullvad-vpn.enable or false;
  blockyConfigured = cfgBlocky.enable;

  resolvconf = "${pkgs.openresolv}/sbin/resolvconf";
  # Scripts to hook Blocky into openresolv
  resolvconfAdd = pkgs.writeShellScript "blocky-resolvconf-add" ''
    #!${pkgs.bash}/bin/bash
    set -uo pipefail
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
        description = "Enable aggressive 'no-google' blocklists (breaks Google services).";
      };
    };

    autostart = mkOption {
      type = types.bool;
      default = !hasMullvad;
      description = "Start Blocky automatically at boot (disabled if VPN is present).";
    };

    httpPort = mkOption {
      type = types.port;
      default = 4000;
      description = "Blocky HTTP port (metrics/health).";
    };

    upstream = mkOption {
      type = types.listOf types.str;
      default = [
        "https://dns.quad9.net/dns-query"     # Quad9 (Filtered, DNSSEC, Privacy-focused)
        "https://dns.cloudflare.com/dns-query" # Cloudflare (Fast, widely available)
        "1.1.1.1"                             # Fallback / Bootstrap IP to resolve DoH domains
      ];
      description = "Upstream DNS servers (IP, DoH, or DoT endpoints supported by Blocky).";
    };
  };

  config = lib.mkMerge [
    # -- 1. Standard DNS Policy (No Blocky) ------------------------------------
    (lib.mkIf (!blockyConfigured) {
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

    # -- 2. Blocky Enabled Policy ----------------------------------------------
    (lib.mkIf blockyConfigured {
      # Disable systemd-resolved to free up port 53 for Blocky
      services.resolved.enable = lib.mkForce false;
      
      # Enable openresolv for managing /etc/resolv.conf
      networking.resolvconf.enable = lib.mkDefault true;
      networking.resolvconf.extraConfig = lib.mkAfter ''
        deny_keys='NetworkManager'
      '';

      # Fallback resolvers for when Blocky is stopped
      networking.nameservers = lib.mkDefault [ "1.1.1.1" "9.9.9.9" ];

      # Prevent NetworkManager from interfering with resolv.conf
      environment.etc."NetworkManager/conf.d/90-osc-dns.conf".text = lib.mkDefault ''
        [main]
        dns=none
      '';

      # -- Blocky Service Configuration --
      services.blocky = {
        enable = true;
        settings = {
          ports = {
            dns = 53;
            http = cfgBlocky.httpPort;
          };

          log.level = "info";

          upstreams = {
            init.strategy = "fast";
            strategy = "parallel_best";
            timeout = "2s";
            groups.default = cfgBlocky.upstream;
          };

          caching = {
            minTime = "5m";
            maxTime = "30m";
            prefetching = true;
            prefetchExpires = "2h";
            prefetchThreshold = 5;
          };

          blocking = {
            denylists = {
              ads = [
                "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
                "https://big.oisd.nl/"
                "https://raw.githubusercontent.com/blocklistproject/Lists/master/ads.txt"
              ];
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

            allowlists = {
              ads = [
                "https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/optional-list.txt"
              ];
            };

            clientGroupsBlock.default =
              [ "ads" ]
              ++ lib.optionals cfgBlocky.noGoogle.enable [ "nogoogle" ];

            loading = {
              refreshPeriod = "24h";
              strategy = "fast";
            };
          };
        };
      };

      # Systemd hooks for resolvconf integration
      systemd.services.blocky = lib.mkMerge [
        {
          serviceConfig = {
            ExecStartPost = [ "+${resolvconfAdd}" ];
            ExecStopPost = [ "+${resolvconfDel}" ];
          };
        }
        (lib.mkIf (!cfgBlocky.autostart) {
          wantedBy = lib.mkForce [ ];
        })
      ];

      environment.systemPackages = [ pkgs.blocky ];
    })
  ];
}
