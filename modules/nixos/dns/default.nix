# modules/nixos/dns/default.nix
# ==============================================================================
# NixOS DNS policy: resolvers, caching, and fallback options.
# Configure name services once here to stay consistent across hosts.
# Adjust resolver choices centrally instead of per-interface tweaks.
# ==============================================================================

{ lib, config, ... }:

let
  blockyConfigured = config.my.dns.blocky.enable or false;
in
{
  config = lib.mkMerge [
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

    (lib.mkIf blockyConfigured {
      # Avoid resolver stacking and port conflicts; let Blocky (or other local DNS)
      # own :53 when configured.
      services.resolved.enable = lib.mkForce false;
      # Let DNS be controlled dynamically (e.g. by Blocky service hooks / VPN).
      networking.resolvconf.enable = lib.mkDefault true;
    })
  ];
}
