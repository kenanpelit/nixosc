# modules/nixos/tcp/default.nix
# ==============================================================================
# NixOS TCP/IP tuning: congestion control and safe network hardening.
# Keep low-level network tunables centralized for all hosts.
# Prefer mkDefault so hosts can override without conflicts.
# ==============================================================================

{ lib, ... }:

let
  inherit (lib) mkDefault;
in
{
  # Ensure BBR and fq qdisc exist so systemd-sysctl doesn't fail during boot.
  boot.kernelModules = [ "tcp_bbr" "sch_fq" ];

  boot.kernel.sysctl = {
    # Throughput + latency baseline.
    "net.core.default_qdisc" = mkDefault "fq";
    "net.ipv4.tcp_congestion_control" = mkDefault "bbr";

    # Better behavior on broken PMTU paths (common on some VPNs/ISPs).
    "net.ipv4.tcp_mtu_probing" = mkDefault 1;

    # Enable TCP Fast Open (client+server). Middleboxes may block it; TCP falls back.
    "net.ipv4.tcp_fastopen" = mkDefault 3;

    # Basic network hardening (safe defaults for most clients/hosts).
    "net.ipv4.conf.all.rp_filter"     = mkDefault 2;
    "net.ipv4.conf.default.rp_filter" = mkDefault 2;
    "net.ipv4.conf.all.accept_redirects"     = mkDefault 0;
    "net.ipv4.conf.default.accept_redirects" = mkDefault 0;
    "net.ipv4.conf.all.secure_redirects"     = mkDefault 0;
    "net.ipv4.conf.default.secure_redirects" = mkDefault 0;
    "net.ipv4.conf.all.send_redirects"       = mkDefault 0;
    "net.ipv4.conf.default.send_redirects"   = mkDefault 0;
    "net.ipv4.conf.all.accept_source_route"     = mkDefault 0;
    "net.ipv4.conf.default.accept_source_route" = mkDefault 0;

    "net.ipv6.conf.all.accept_redirects"     = mkDefault 0;
    "net.ipv6.conf.default.accept_redirects" = mkDefault 0;
    "net.ipv6.conf.all.accept_source_route"  = mkDefault 0;
    "net.ipv6.conf.default.accept_source_route" = mkDefault 0;
  };
}
