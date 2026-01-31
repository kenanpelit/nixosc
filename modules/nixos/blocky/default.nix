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
in
{
  options.my.dns.blocky = {
    enable = mkOption {
      type = types.bool;
      default = isPhysicalHost;
      defaultText = "config.my.host.isPhysicalHost";
      description = "Enable Blocky (local DNS proxy + ad/malware blocking).";
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
          };
          clientGroupsBlock.default = [ "ads" ];

          loading = {
            refreshPeriod = "24h";
            # Old behaviour: "don't fail start if list fetch fails".
            strategy = "fast";
          };
        };
      };
    };

    environment.systemPackages = [ pkgs.blocky ];
  };
}
