# modules/nixos/dns/default.nix
# ==============================================================================
# NixOS DNS policy: resolvers, caching, and fallback options.
# Configure name services once here to stay consistent across hosts.
# Adjust resolver choices centrally instead of per-interface tweaks.
# ==============================================================================

{ ... }:

{
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
}
