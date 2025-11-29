# modules/core/security/default.nix
# ==============================================================================
# Security & Hardening Configuration — Defense in Depth
# ==============================================================================
#
# Module:      modules/core/security
# Purpose:     Centralized security configuration and hardening
# Author:      Kenan Pelit
# Created:     2025-10-09
# Modified:    2025-11-15
#
# Architecture:
#   Firewall → Authentication → Access Control → Audit → SSH → Ad Blocking
#
# Security Layers:
#   1. Network Firewall     - nftables packet filtering, DoS mitigation
#   2. PAM/Polkit          - Authentication and authorization
#   3. AppArmor            - Mandatory access control (MAC)
#   4. Audit Logging       - System activity monitoring
#   5. SSH Hardening       - Secure remote access
#   6. DNS Blocking        - Ad/tracker filtering (hBlock)
#
# Design Principles:
#   • Single Authority  – All firewall ports defined HERE
#   • Modern nftables   – Atomic updates, deterministic rule order, IPv4+IPv6
#   • Defense in Depth  – Multiple independent security layers
#   • Fail Secure       – Default deny, explicit allow
#   • SSH Friendly      – No firewall rate limit on SSH (fail2ban handles brute)
#   • Production Ready  – Documented and diagnosable
#
# Module Boundaries:
#   ✓ Firewall configuration          (THIS MODULE)
#   ✓ PAM/Polkit authentication       (THIS MODULE)
#   ✓ AppArmor MAC                    (THIS MODULE)
#   ✓ Audit logging                   (THIS MODULE)
#   ✓ SSH client config               (THIS MODULE)
#   ✓ fail2ban SSH protection         (THIS MODULE)
#   ✗ SSH daemon config               (networking module)
#   ✗ User authentication             (account module)
#   ✗ GNOME Keyring daemon            (display/services module)
#
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  inherit (lib) mkEnableOption mkIf mkAfter mkForce;

  # ----------------------------------------------------------------------------
  # Port Configuration (Single Source of Truth)
  # ----------------------------------------------------------------------------
  # All open ports declared here - no duplication in other modules.
  transmissionWebPort  = 9091;    # Transmission Web UI (HTTP)
  transmissionPeerPort = 51413;   # BitTorrent peer connections (TCP/UDP)
  customServicePort    = 1401;    # TODO: Document which service uses this

  # ----------------------------------------------------------------------------
  # hBlock Update Script — Per-User DNS Blocking
  # ----------------------------------------------------------------------------
  # Updates per-user HOSTALIASES file using hBlock blocklists.
  #
  # Characteristics:
  #   • Iterates /home/* and skips UID < 1000
  #   • Writes to $HOME/.config/hblock/hosts atomically
  #   • Uses HOSTALIASES format: "domain domain"

  hblockUpdateScript = pkgs.writeShellScript "hblock-update" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    for USER_HOME in /home/*; do
      [[ -e "$USER_HOME" ]] || continue
      [[ -d "$USER_HOME" ]] || continue

      USER="$(basename "$USER_HOME")"
      USER_UID=$(id -u "$USER" 2>/dev/null || echo 0)

      # Skip system users
      if [[ "$USER_UID" -lt 1000 ]]; then
        continue
      fi

      CONFIG_DIR="$USER_HOME/.config/hblock"
      HOSTS_FILE="$CONFIG_DIR/hosts"
      TEMP_FILE="$CONFIG_DIR/hosts.tmp"

      mkdir -p "$CONFIG_DIR"

      {
        echo "# Base entries"
        echo "localhost 127.0.0.1"
        echo "hay 127.0.0.2"  # Custom hostname entry
        echo "# hBlock entries (Updated: $(date))"

        # hBlock output: "0.0.0.0 domain.com"
        # We convert to HOSTALIASES: "domain.com domain.com"
        if ${pkgs.hblock}/bin/hblock -O - 2>/dev/null | while read -r LINE; do
          if [[ $LINE =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+(.+)$ ]]; then
            dom="''${BASH_REMATCH[2]}"
            echo "''${dom} ''${dom}"
          fi
        done; then
          :
        else
          echo "# Failed to fetch hBlock list at $(date)" >&2
        fi
      } > "$TEMP_FILE"

      if mv "$TEMP_FILE" "$HOSTS_FILE" 2>/dev/null; then
        chown "$USER:users" "$HOSTS_FILE" 2>/dev/null || {
          echo "Warning: Failed to set ownership for $HOSTS_FILE" >&2
        }
        chmod 0644 "$HOSTS_FILE"
      else
        echo "Error: Failed to write $HOSTS_FILE" >&2
        rm -f "$TEMP_FILE"
      fi
    done
  '';
in
{
  # ============================================================================
  # Module Options
  # ============================================================================
  options.services.hblock.enable =
    mkEnableOption "hBlock per-user HOSTALIASES with daily auto-update";

  # ============================================================================
  # Security Configuration
  # ============================================================================
  config = {
    # ==========================================================================
    # 1) Network Firewall — nftables
    # ==========================================================================
    # nftables replaces the legacy iptables firewall.

    networking.firewall.enable = mkForce false;

    networking.nftables = {
      enable = true;

      # Full ruleset; NixOS loads atomically (no transient flush).
      ruleset = ''
        # ======================================================================
        # MAIN TABLE: inet filter (IPv4 + IPv6)
        # ======================================================================
        table inet filter {
          # --------------------------------------------------------------------
          # INPUT CHAIN — Incoming packets
          # --------------------------------------------------------------------
          chain input {
            type filter hook input priority filter; policy drop;

            # 1. Connection state
            ct state invalid          counter drop   comment "Drop invalid"
            ct state established,related counter accept comment "Allow established/related"

            # 2. Loopback
            iif lo                    counter accept comment "Allow loopback"

            # 3. ICMP (v4 + v6) — REQUIRED
            ip protocol icmp icmp type {
              echo-request,
              echo-reply,
              destination-unreachable,
              time-exceeded
            } limit rate 10/second burst 20 packets
              counter accept comment "Allow essential ICMPv4"

            ip6 nexthdr icmpv6 icmpv6 type {
              echo-request,
              echo-reply,
              destination-unreachable,
              packet-too-big,
              time-exceeded,
              nd-neighbor-solicit,
              nd-neighbor-advert,
              nd-router-solicit,
              nd-router-advert
            } limit rate 10/second burst 20 packets
              counter accept comment "Allow essential ICMPv6"

            # 4. SSH — fail2ban handles brute-force
            tcp dport 22 ct state new,established
              counter accept comment "SSH (fail2ban protected)"

            # Optional custom port example:
            # tcp dport 36499 ct state new,established counter accept comment "SSH custom port"

            # 5. SYN flood protection (non-SSH)
            tcp flags syn tcp dport != 22
              limit rate 5/second burst 10 packets
              counter accept comment "SYN flood rate limit (non-SSH)"

            tcp flags syn tcp dport != 22
              counter drop comment "Drop excessive SYN (non-SSH)"

            # 6. Explicitly allowed services
            # ---- Transmission ----
            tcp dport ${toString transmissionWebPort}  ct state new
              counter accept comment "Transmission Web UI"

            tcp dport ${toString transmissionPeerPort} ct state new
              counter accept comment "Transmission peer TCP"
            udp dport ${toString transmissionPeerPort}
              counter accept comment "Transmission peer UDP"

            # ---- Custom service ----
            tcp dport ${toString customServicePort} ct state new
              counter accept comment "Custom service TCP"
            udp dport ${toString customServicePort}
              counter accept comment "Custom service UDP"

            # ---- VPN ports ----
            udp dport { 1194, 1195, 1196 }
              counter accept comment "OpenVPN"
            udp dport 51820
              counter accept comment "WireGuard"

            # 7. Logging (rate limited)
            limit rate 5/minute
              counter log prefix "nft-drop: " level info

            # 8. Default drop
            counter drop comment "Default drop policy"
          }

          # --------------------------------------------------------------------
          # FORWARD CHAIN — Routing / VPN forwarding
          # --------------------------------------------------------------------
          chain forward {
            type filter hook forward priority filter; policy drop;

            ct state established,related
              counter accept comment "Allow established forwarding"

            iifname "wg*" counter accept comment "Allow VPN forwarding (wg* in)"
            oifname "wg*" counter accept comment "Allow VPN forwarding (wg* out)"
            iifname "tun*" counter accept comment "Allow VPN forwarding (tun* in)"
            oifname "tun*" counter accept comment "Allow VPN forwarding (tun* out)"

            limit rate 2/minute
              counter log prefix "nft-forward-drop: " level info

            counter drop comment "Default forward drop"
          }

          # --------------------------------------------------------------------
          # OUTPUT CHAIN — Outgoing packets
          # --------------------------------------------------------------------
          chain output {
            type filter hook output priority filter; policy accept;
          }
        }

        # ======================================================================
        # NAT TABLE: inet nat
        # ======================================================================
        table inet nat {
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;

            oifname "wg*"  counter masquerade comment "Masquerade WireGuard"
            oifname "tun*" counter masquerade comment "Masquerade OpenVPN"
          }
        }
      '';
    };

    # ==========================================================================
    # 2) fail2ban — SSH Brute-Force Protection
    # ==========================================================================
    services.fail2ban = {
      enable   = true;
      maxretry = 5;
      bantime  = "1h";

      bantime-increment = {
        enable      = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime     = "48h";
      };

      jails.sshd = {
        settings = {
          enabled           = true;
          filter            = "sshd";
          port              = "ssh";
          logpath           = "/var/log/auth.log";
          backend           = "systemd";
          maxretry          = 5;
          findtime          = "10m";
          banaction         = "nftables-multiport";
          banaction_allports = "nftables-allports";
        };
      };
    };

    # ==========================================================================
    # 3) PAM / Polkit
    # ==========================================================================
    # Polkit GNOME authentication agent
    # NOT: Bu agent Hyprland için de çalışıyor, GNOME'da da
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "PolicyKit GNOME Authentication Agent";
      wantedBy    = [ "graphical-session.target" ];
      wants       = [ "graphical-session.target" ];
      after       = [ "graphical-session.target" ];
      serviceConfig = {
        Type           = "simple";
        ExecStart      = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart        = "on-failure";
        RestartSec     = 1;
        TimeoutStopSec = 10;
      };
    };

    # ==========================================================================
    # 4) AppArmor — Mandatory Access Control
    # ==========================================================================
    security.apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
      # packages = [ pkgs.apparmor-profiles ];
    };

    # ==========================================================================
    # 5) Audit System — Activity Monitoring
    # ==========================================================================
    # Not: Burada audit'i *kapalı* tutuyorsun, ama rule set hazır.
    #      Daha önemlisi: auditd.service override sadece enable=true iken
    #      devreye giriyor; böylece "Service has no ExecStart" hatası ortadan kalkıyor.

    security.audit = {
      enable = lib.mkDefault false;

      rules = [
        # /etc/passwd / /etc/shadow değişiklikleri
        "-w /etc/passwd -p wa -k passwd_changes"
        "-w /etc/shadow -p wa -k shadow_changes"

        # sudoers değişiklikleri
        "-w /etc/sudoers -p wa -k sudoers_changes"

        # dosya silme syscalls
        "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F success=1 -k delete"
      ];
    };

    # auditd unit override — sadece audit etkinse
    systemd.services.auditd = mkIf config.security.audit.enable {
      serviceConfig = {
        # Küçük bir gecikme, log rotasyonu vs. için hook noktası
        ExecStartPost = "${pkgs.coreutils}/bin/sleep 1";
      };
    };

    # ==========================================================================
    # 6) hBlock DNS Blocking — Per-User
    # ==========================================================================
    systemd.services.hblock-update = mkIf config.services.hblock.enable {
      description = "Update hBlock hosts file for all users";
      serviceConfig = {
        Type            = "oneshot";
        ExecStart       = "${hblockUpdateScript}";
        PrivateTmp      = true;
        NoNewPrivileges = false;   # chown için root ayrıcalığı gerekli
        ProtectSystem   = "strict";
        ProtectHome     = false;   # /home erişimi gerekli
        ReadWritePaths  = [ "/home" ];
      };
    };

    systemd.timers.hblock-update = mkIf config.services.hblock.enable {
      description = "Daily hBlock update timer";
      wantedBy    = [ "timers.target" ];
      timerConfig = {
        OnCalendar        = "03:00";
        RandomizedDelaySec = "1h";
        Persistent        = true;
        AccuracySec       = "1h";
      };
    };

    # ==========================================================================
    # 7) SSH Client Configuration
    # ==========================================================================
    programs.ssh = {
      startAgent       = false;
      enableAskPassword = false;

      extraConfig = ''
        Host *
          # Connection keep-alive
          ServerAliveInterval 60
          ServerAliveCountMax 3
          TCPKeepAlive yes

          # Fail fast
          ConnectTimeout 30

          # ASSH proxy
          ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
      '';
    };

    # ==========================================================================
    # 8) Environment — Packages, Aliases, Variables
    # ==========================================================================
    environment = {
      # Yeni kullanıcılar için .bashrc içine hBlock entegrasyonu
      etc."skel/.bashrc".text = mkAfter ''
        # hBlock DNS blocking via HOSTALIASES
        export HOSTALIASES="$HOME/.config/hblock/hosts"
      '';

      systemPackages = with pkgs; [
        # Polkit / GUI auth
        polkit_gnome

        # SSH tooling
        assh

        # Network security
        hblock
        fail2ban

        # Audit tools
        audit

        # Firewall / conntrack
        nftables
        conntrack-tools
      ];

      shellAliases = {
        # SSH / ASSH
        assh       = "${pkgs.assh}/bin/assh";
        sshconfig  = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
        sshtest    = "ssh -o ConnectTimeout=5 -o BatchMode=yes";

        # hBlock
        hblock-update-now = "sudo ${hblockUpdateScript}";
        hblock-status     = "wc -l ~/.config/hblock/hosts";
        hblock-check      = "head -20 ~/.config/hblock/hosts";

        # Audit
        audit-summary = "sudo aureport --summary";
        audit-failed  = "sudo aureport --failed";
        audit-search  = "sudo ausearch -i";
        audit-auth    = "sudo ausearch -m USER_LOGIN";

        # nftables
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

        # fail2ban
        f2b-status      = "sudo fail2ban-client status";
        f2b-status-ssh  = "sudo fail2ban-client status sshd";
        f2b-banned      = "sudo fail2ban-client get sshd banned";
        f2b-unban       = "sudo fail2ban-client set sshd unbanip";

        # AppArmor
        aa-status   = "sudo aa-status";
        aa-enforce  = "sudo aa-enforce";
        aa-complain = "sudo aa-complain";
      };

      variables = {
        ASSH_CONFIG = "$HOME/.ssh/assh.yml";
      };
    };
  };
}

# ==============================================================================
# Notlar (Özet)
# ==============================================================================
#
# • auditd hatası:
#   Önceki sürümde security.audit.enable = false iken auditd.serviceConfig
#   tanımladığın için systemd "no ExecStart" diye bağırıyordu.
#   Şimdi auditd override sadece config.security.audit.enable = true iken
#   devreye giriyor → journalctl’daki hata kaybolmalı.
#
# • nftables / fail2ban / hBlock / ASSH / AppArmor davranışları korunuyor.
# • customServicePort için (1401) ileride hangi servis olduğunu açıkça
#   dokümante et; şu an sadece “Custom service” diye duruyor.
#
# ==============================================================================
