# modules/core/security/default.nix
# ==============================================================================
# Security & Hardening Configuration Module
# ==============================================================================
#
# Module: modules/core/security
# Author: Kenan Pelit
# Date:   2025-09-03
#
# Purpose: Centralized security configuration for all aspects of system hardening
#
# Scope:
#   - Firewall rules and port management (single authority)
#   - PAM/Polkit authentication
#   - AppArmor mandatory access control
#   - Audit logging (auditd + rules loader via auditd preStart)
#   - SSH client configuration
#   - Transmission ports
#   - hBlock domain blocking (per-user HOSTALIASES)
#
# Design Principles:
#   1. Single Authority: Firewall ports defined ONLY here
#   2. iptables Preservation: Keep proven stable rules (nftables disabled here)
#   3. Conditional Rules: Tunnel interfaces accepted conditionally via systemd
#   4. hBlock Integration: Per-user ~/.config/hblock/hosts without polluting /etc/hosts
#   5. Audit Rules: No separate loader unit (preStart on auditd to avoid cycles)
#
# Configurable Settings:
#   - Transmission ports in let block below
#   - hBlock toggle via services.hblock.enable
#
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  inherit (lib) mkEnableOption mkIf mkAfter;

  # --------------------------------------------------------------------------
  # Configurable Port Settings
  # --------------------------------------------------------------------------
  transmissionWebPort  = 9091;   # Transmission Web UI
  transmissionPeerPort = 51413;  # Transmission peer port (TCP/UDP)

  # --------------------------------------------------------------------------
  # hBlock Update Script
  # --------------------------------------------------------------------------
  hblockUpdateScript = pkgs.writeShellScript "hblock-update" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail

    for USER_HOME in /home/*; do
      if [ -d "$USER_HOME" ]; then
        USER="$(basename "$USER_HOME")"
        CONFIG_DIR="$USER_HOME/.config/hblock"
        HOSTS_FILE="$CONFIG_DIR/hosts"
        mkdir -p "$CONFIG_DIR"

        {
          echo "# Base entries"
          echo "localhost 127.0.0.1"
          echo "hay 127.0.0.2"
          echo "# hBlock entries (Updated: $(date))"

          # Build two-column alias entries from hblock output
          ${pkgs.hblock}/bin/hblock -O - | while read -r LINE; do
            if [[ $LINE =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)[[:space:]]+(.+)$ ]]; then
              dom="''${BASH_REMATCH[2]}"
              echo "''${dom} ''${dom}"
            fi
          done
        } > "$HOSTS_FILE"

        chown "$USER:users" "$HOSTS_FILE"
        chmod 0644 "$HOSTS_FILE"
      fi
    done
  '';
in
{
  # ============================================================================
  # Module Options
  # ============================================================================
  options.services.hblock.enable =
    mkEnableOption "hBlock per-user HOSTALIASES with daily auto-update (keeps /etc/hosts clean)";

  # ============================================================================
  # Security Configuration
  # ============================================================================
  config = {
    # --------------------------------------------------------------------------
    # Firewall (single authority here)
    # --------------------------------------------------------------------------
    # NOTE: We use iptables here because extraCommands below are iptables rules.
    networking.nftables.enable = false;

    networking.firewall = {
      enable = true;

      # Basic hardening
      allowPing = false;
      rejectPackets = true;
      logReversePathDrops = true;
      checkReversePath = "loose";

      # Tunnel interfaces (WireGuard / OpenVPN)
      trustedInterfaces = [ "wg+" "tun+" ];

      # ---------------------- Open Ports (all declared here) -------------------
      allowedTCPPorts = [
        53
        1401
        transmissionWebPort
      ];

      allowedUDPPorts = [
        53
        1194 1195 1196
        1401
        51820
      ];

      # Transmission peer port (single exact port)
      allowedTCPPortRanges = [{ from = transmissionPeerPort; to = transmissionPeerPort; }];
      allowedUDPPortRanges = [{ from = transmissionPeerPort; to = transmissionPeerPort; }];

      # ----------------------- iptables rules (stable set) ---------------------
      extraCommands = ''
        # Default policies (fail-closed)
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT

        # Essential connections
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -i lo -j ACCEPT

        # Basic DoS mitigation
        iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
        iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 15 -j REJECT

        # Drop port scanning patterns
        iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

        # ICMP rate limiting (permit minimal echo for diagnostics if needed)
        iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT

        # Conditional VPN rules (only if active)
        if systemctl is-active mullvad-daemon >/dev/null 2>&1; then
          iptables -A OUTPUT -o wg0-mullvad -j ACCEPT
          iptables -A INPUT  -i wg0-mullvad -j ACCEPT
          iptables -A OUTPUT -o tun0 -j ACCEPT
          iptables -A INPUT  -i tun0 -j ACCEPT
          iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
          iptables -A INPUT  -p udp --sport 53 -j ACCEPT
        fi
      '';
    };

    # --------------------------------------------------------------------------
    # System Security Services
    # --------------------------------------------------------------------------
    security = {
      rtkit.enable = true;
      sudo.enable = true;
      polkit.enable = true;

      apparmor = {
        enable = true;
        packages = with pkgs; [ apparmor-profiles apparmor-utils ];
      };

      auditd.enable = true;

      allowUserNamespaces = true;
      protectKernelImage = true;

      # -------------------- PAM: GNOME Keyring integration --------------------
      pam.services = {
        # GDM display manager
        gdm.enableGnomeKeyring = true;
        # GDM password auth (asıl gerekli olan)
        gdm-password.enableGnomeKeyring = true;

        # İstersen TTY/console için de açık kalsın:
        login.enableGnomeKeyring = true;
      };
    };

    # DBus schemas for gcr/gnome-keyring (append, don't replace)
    services.dbus.packages = mkAfter [ pkgs.gcr pkgs.gnome-keyring ];

    # --------------------------------------------------------------------------
    # Auditd daemon ayarları (tampon & rate tuning)
    # --------------------------------------------------------------------------
    environment.etc."audit/auditd.conf".text = ''
      #
      # NixOS — auditd.conf (tuned)
      #
      log_file = /var/log/audit/audit.log
      log_format = RAW
      flush = incremental_async
      freq = 50
  
      # Buffer / backpressure
      priority_boost = 4
      overflow_action = SYSLOG
  
      # Döngüsel log
      max_log_file = 50
      num_logs = 5
      max_log_file_action = ROTATE
  
      name_format = HOSTNAME
    '';
 
    # --------------------------------------------------------------------------
    # Audit: /etc/audit/filter.conf uyarısını sustur
    # --------------------------------------------------------------------------
    environment.etc."audit/filter.conf" = {
      mode = "0644";
      text = "# empty\n";
    };


    # --------------------------------------------------------------------------
    # Audit rules (1): /etc/audit/rules.d/99-local.rules
    # --------------------------------------------------------------------------
    environment.etc."audit/rules.d/99-local.rules".text = ''
      # Minimal, useful audit rules (personal workstation)

      -D
      -b 16384
      -r 0
  
      # Critical files
      -w /etc/passwd -p wa -k passwd_changes
      -w /etc/shadow -p wa -k shadow_changes
      -w /etc/sudoers -p wa -k sudoers_changes
      -w /etc/ssh/sshd_config -p wa -k sshd_config
  
      # Sadece root olarak çalışan exec'leri kaydet (kullanıcı oturumlarından)
      -a always,exit -F arch=b64 -S execve,execveat -F euid=0 -F auid>=1000 -F auid!=4294967295 -k exec_root

      # UID/GID değişimleri
      -a always,exit -F arch=b64 -S setuid,setgid -k id_change

      -k local_rules
    '';

    # --------------------------------------------------------------------------
    # Audit rules (2): /etc/audit/audit.rules (boot'ta doğrudan okunabilir)
    # --------------------------------------------------------------------------
    environment.etc."audit/audit.rules".text = ''
      -D
      -b 16384
      -r 0

      -w /etc/passwd -p wa -k passwd_changes
      -w /etc/shadow -p wa -k shadow_changes
      -w /etc/sudoers -p wa -k sudoers_changes
      -w /etc/ssh/sshd_config -p wa -k sshd_config
  
      -a always,exit -F arch=b64 -S execve,execveat -F euid=0 -F auid>=1000 -F auid!=4294967295 -k exec_root
      -a always,exit -F arch=b64 -S setuid,setgid -k id_change
  
      -k local_rules
    '';

    # --------------------------------------------------------------------------
    # Systemd units
    #  - auditd override: kuralları preStart'ta yükle, '-s nochange' kaldır
    #  - hBlock service/timer (opsiyonel)
    # --------------------------------------------------------------------------
    systemd = {
      services = {
        # ---- auditd override & preStart rules loader (NO separate loader unit) ----
        auditd = {
          # auditd’nin ExecStart’ını override et: '-s nochange' kullanma
          serviceConfig.ExecStart = lib.mkForce ''
            ${pkgs.audit}/bin/auditd -l -n
          '';

          # auditd başlamadan kural yükle (auditctl -> kernel; auditd gerekmez)
          preStart = ''
            set -eu
            PATH="${lib.makeBinPath [ pkgs.coreutils pkgs.findutils pkgs.gawk pkgs.gnugrep pkgs.audit ]}"

            # 1) /etc/audit/audit.rules varsa onu yükle
            if [ -s /etc/audit/audit.rules ]; then
              ${pkgs.audit}/sbin/auditctl -D || true
              ${pkgs.audit}/sbin/auditctl -R /etc/audit/audit.rules || true
            # 2) Yoksa rules.d/*.rules dosyalarını deterministik sırayla birleştir
            elif [ -d /etc/audit/rules.d ] && ls /etc/audit/rules.d/*.rules >/dev/null 2>&1; then
              TMP="$(mktemp)"
              find /etc/audit/rules.d -maxdepth 1 -type f -name '*.rules' -print0 \
                | sort -z \
                | xargs -0 cat -- >> "$TMP"
              ${pkgs.audit}/sbin/auditctl -D || true
              ${pkgs.audit}/sbin/auditctl -R "$TMP" || true
              rm -f "$TMP"
            fi
          '';
        };

        # ---- hBlock service (only when enabled) ----
        hblock = mkIf config.services.hblock.enable {
          description = "hBlock - Update user hosts files";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = hblockUpdateScript;
            RemainAfterExit = true;
          };
        };
      };

      timers = {
        # hBlock timer (only when enabled)
        hblock = mkIf config.services.hblock.enable {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            RandomizedDelaySec = 3600;
            Persistent = true;
          };
        };
      };
    };

    # --------------------------------------------------------------------------
    # SSH Client Configuration
    # --------------------------------------------------------------------------
    programs.ssh = {
      startAgent = false;          # using GPG agent elsewhere
      enableAskPassword = false;

      extraConfig = ''
        Host *
          ServerAliveInterval 60
          ServerAliveCountMax 2
          TCPKeepAlive yes
          ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
      '';
    };

    # --------------------------------------------------------------------------
    # hBlock Integration (UX)
    # --------------------------------------------------------------------------
    environment = {
      # Put HOSTALIASES into /etc/skel so new users inherit it
      etc."skel/.bashrc".text = mkAfter ''
        export HOSTALIASES="$HOME/.config/hblock/hosts"
      '';

      systemPackages = with pkgs; [
        polkit_gnome   # Polkit agent (Wayland-friendly; autostart HM'de önerilir)
        assh           # Advanced SSH config manager
        hblock
      ];

      shellAliases = {
        assh               = "${pkgs.assh}/bin/assh";
        sshconfig          = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
        sshtest            = "ssh -o ConnectTimeout=5 -o BatchMode=yes";
        hblock-update-now  = "${hblockUpdateScript}";
      };

      variables = {
        ASSH_CONFIG = "$HOME/.ssh/assh.yml";
      };
    };
  };

  # ============================================================================
  # Usage Notes
  # ============================================================================
  # - Transmission ports: edit transmissionWebPort/transmissionPeerPort above.
  # - Do NOT define firewall ports in other modules.
  # - nftables is disabled here because extraCommands uses iptables.
  # - If Mullvad/WireGuard interfaces differ, update the if names in rules.
}
