# modules/nixos/dns/default.nix
# ==============================================================================
# NixOS module for dns (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
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
