# modules/nixos/firewall/default.nix
# ==============================================================================
# NixOS firewall policy: nftables/iptables defaults, open ports, and helpers.
# Central place to manage network exposure across all hosts.
# Keep rules consistent by editing this module instead of per-host hacks.
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  inherit (lib) mkDefault mkOption optional types;
  cfg = config.my.firewall;
  transmissionWebPort  = 9091;
  transmissionPeerPort = 51413;
  customServicePort    = 1401;
in
{
  options.my.firewall = {
    allowTransmissionPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Open Transmission web/peer ports when the service is enabled.";
    };

    allowCustomServicePort = mkOption {
      type = types.bool;
      default = false;
      description = "Open TCP port 1401 for custom service usage.";
    };
  };

  config = {
    networking.firewall = {
      enable = mkDefault true;
      allowPing = false;
      logReversePathDrops = true;
      allowedTCPPorts =
        [ 22 ] # SSH
        ++ (optional cfg.allowTransmissionPorts transmissionWebPort)
        ++ (optional cfg.allowCustomServicePort customServicePort);
      allowedUDPPorts =
        optional cfg.allowTransmissionPorts transmissionPeerPort;
    };

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
  };
}
