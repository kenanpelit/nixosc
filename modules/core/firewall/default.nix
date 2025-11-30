# modules/core/security/firewall/default.nix
# Firewall rules (single authority).

{ lib, ... }:

let
  inherit (lib) mkDefault;
  transmissionWebPort  = 9091;
  transmissionPeerPort = 51413;
  customServicePort    = 1401;
in
{
  networking.firewall = {
    enable = mkDefault true;
    allowPing = false;
    logReversePathDrops = true;
    allowedTCPPorts = [ transmissionWebPort customServicePort ];
    allowedUDPPorts = [ transmissionPeerPort ];
  };
}
