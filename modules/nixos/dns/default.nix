# modules/nixos/dns/default.nix
# ==============================================================================
# NixOS DNS policy: resolvers, caching, and fallback options.
# Configure name services once here to stay consistent across hosts.
# Adjust resolver choices centrally instead of per-interface tweaks.
# ==============================================================================

{ lib, config, ... }:

let
  blockyEnabled = config.services.blocky.enable or false;
in
{
  config = lib.mkMerge [
    (lib.mkIf (!blockyEnabled) {
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

    (lib.mkIf blockyEnabled {
      # Avoid resolver stacking and port conflicts; let Blocky own DNS.
      services.resolved.enable = lib.mkForce false;
      networking.resolvconf.useLocalResolver = true;
    })
  ];
}
