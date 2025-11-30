# modules/core/firewall/default.nix
# ==============================================================================
# Firewall Configuration
# ==============================================================================
# Configures the system firewall and related tools.
# - Enables firewall
# - Configures allowed TCP/UDP ports
# - Installs conntrack-tools
# - Provides shell aliases for firewall management
#
# ==============================================================================

{ lib, pkgs, ... }:

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

  environment.systemPackages = with pkgs; [ conntrack-tools ];

  environment.shellAliases = {
    fw-list         = "sudo nft list ruleset";
    fw-list-filter  = "sudo nft list table inet filter";
    fw-list-nat     = "sudo nft list table inet nat";
    fw-list-input   = "sudo nft list chain inet filter input";
    fw-list-forward = "sudo nft list chain inet filter forward";

    fw-stats         = "sudo nft list ruleset -a -s";
    fw-counters      = "sudo nft list ruleset | grep -E 'counter|packets'";
    fw-reset-counters = "sudo nft reset counters table inet filter";

    fw-monitor       = "sudo nft monitor";
    fw-dropped       = "sudo journalctl -k | grep 'nft-drop'";
    fw-dropped-live  = "sudo journalctl -kf | grep 'nft-drop'";

    fw-connections      = "sudo conntrack -L";
    fw-connections-ssh  = "sudo conntrack -L | grep -E 'tcp.*22'";
    fw-flush-conntrack  = "sudo conntrack -F";
  };
}
