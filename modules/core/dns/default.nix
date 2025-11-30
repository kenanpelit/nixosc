# modules/core/networking/dns/default.nix
# systemd-resolved with DNS-over-TLS.

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
