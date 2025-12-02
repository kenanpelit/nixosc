# modules/core/dns/default.nix
# ==============================================================================
# DNS Configuration
# ==============================================================================
# Configures systemd-resolved with privacy features.
# - Enables DNS-over-TLS (DoT)
# - Configures DNSSEC (allow-downgrade)
# - Sets fallback DNS servers (Cloudflare/Quad9)
#
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
