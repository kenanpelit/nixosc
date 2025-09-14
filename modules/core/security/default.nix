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
#   - Audit logging
#   - SSH client configuration
#   - Transmission ports
#   - hBlock domain blocking (per-user HOSTALIASES)
#
# Design Principles:
#   1. Single Authority: Firewall ports defined ONLY here
#   2. iptables Preservation: Keep proven stable rules (nftables migration later)
#   3. Conditional Rules: Tunnel interfaces accepted conditionally via systemd
#   4. hBlock Integration: Per-user ~/.config/hblock/hosts without polluting /etc/hosts
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
  
  # Transmission BitTorrent Client
  transmissionWebPort = 9091;     # Web UI port
  transmissionPeerPort = 51413;   # Peer port (TCP/UDP)

  # --------------------------------------------------------------------------
  # hBlock Update Script
  # --------------------------------------------------------------------------
  # Creates per-user hosts files for HOSTALIASES without modifying /etc/hosts
  # Updated daily via systemd timer
  
  hblockUpdateScript = pkgs.writeShellScript "hblock-update" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    
    for USER_HOME in /home/*; do
      if [ -d "$USER_HOME" ]; then
        USER=$(basename "$USER_HOME")
        CONFIG_DIR="$USER_HOME/.config/hblock"
        HOSTS_FILE="$CONFIG_DIR/hosts"
        mkdir -p "$CONFIG_DIR"
        
        {
          echo "# Base entries"
          echo "localhost 127.0.0.1"
          echo "hay 127.0.0.2"
          echo "# hBlock entries (Updated: $(date))"
          
          # Parse hblock output and create two-column alias entries
          ${pkgs.hblock}/bin/hblock -O - | while read DOMAIN; do
            if [[ $DOMAIN =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]+(.+)$ ]]; then
              echo "''${BASH_REMATCH[1]} ''${BASH_REMATCH[1]}"
            fi
          done
        } > "$HOSTS_FILE"
        
        chown "$USER:users" "$HOSTS_FILE"
        chmod 644 "$HOSTS_FILE"
      fi
    done
  '';
in
{
  # ============================================================================
  # Module Options
  # ============================================================================
  
  options.services.hblock.enable = mkEnableOption
    "hBlock per-user HOSTALIASES with daily auto-update (keeps /etc/hosts clean)";

  # ============================================================================
  # Security Configuration
  # ============================================================================
  
  config = {
    # ==========================================================================
    # Network Firewall (Single Authority for Ports)
    # ==========================================================================
    
    networking.firewall = {
      enable = true;
      
      # Basic hardening
      allowPing = false;              # Disable ICMP echo (reduces attack surface)
      rejectPackets = true;           # Reject instead of drop (fail-closed)
      logReversePathDrops = true;     # Log suspicious routing
      checkReversePath = "loose";     # Allow asymmetric routing (VPN friendly)
      
      # Trusted tunnel interfaces
      trustedInterfaces = [ "wg+" "tun+" ];  # WireGuard and OpenVPN
      
      # --------------------------------------------------------------------------
      # Open Ports (Define ALL ports here, nowhere else)
      # --------------------------------------------------------------------------
      
      allowedTCPPorts = [
        53                             # DNS (local resolver/captive portal)
        1401                           # Custom service
        transmissionWebPort            # Transmission Web UI
      ];
      
      allowedUDPPorts = [
        53                             # DNS
        1194 1195 1196                 # OpenVPN endpoints
        1401                           # Custom service
        51820                          # WireGuard
      ];
      
      # Transmission peer port (single port range)
      allowedTCPPortRanges = [{ from = transmissionPeerPort; to = transmissionPeerPort; }];
      allowedUDPPortRanges = [{ from = transmissionPeerPort; to = transmissionPeerPort; }];
      
      # --------------------------------------------------------------------------
      # iptables Rules (Proven Stable Configuration)
      # --------------------------------------------------------------------------
      
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
        
        # ICMP rate limiting (prevent ping flood)
        iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
        
        # Conditional Mullvad/VPN rules
        if systemctl is-active mullvad-daemon; then
          iptables -A OUTPUT -o wg0-mullvad -j ACCEPT
          iptables -A INPUT  -i wg0-mullvad -j ACCEPT
          iptables -A OUTPUT -o tun0 -j ACCEPT
          iptables -A INPUT  -i tun0 -j ACCEPT
          iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
          iptables -A INPUT  -p udp --sport 53 -j ACCEPT
        fi
      '';
    };
    
    # ==========================================================================
    # System Security Services
    # ==========================================================================
    
    security = {
      # Audio stack real-time kit
      rtkit.enable = true;
      
      # Privilege escalation
      sudo.enable = true;
      polkit.enable = true;
      
      # Mandatory Access Control
      apparmor = {
        enable = true;
        packages = with pkgs; [ 
          apparmor-profiles 
          apparmor-utils 
        ];
      };
      
      # System audit logging
      auditd.enable = true;
      
      # Kernel hardening
      allowUserNamespaces = true;      # Required for containers
      protectKernelImage = true;       # Prevent kernel modification
      
      # PAM configuration for GNOME Keyring
      pam.services = {
        login.enableGnomeKeyring = true;
        swaylock.enableGnomeKeyring = true;
        hyprlock.enableGnomeKeyring = true;
        sudo.enableGnomeKeyring = true;
        polkit-1.enableGnomeKeyring = true;
      };
    };
    
    # ==========================================================================
    # SSH Client Configuration
    # ==========================================================================
    
    programs.ssh = {
      startAgent = false;               # Using GPG agent instead
      enableAskPassword = false;        # No GUI password prompts
      
      extraConfig = ''
        Host *
          ServerAliveInterval 60
          ServerAliveCountMax 2
          TCPKeepAlive yes
          ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
      '';
    };
    
    # ==========================================================================
    # hBlock Integration
    # ==========================================================================
    
    environment = {
      # Add HOSTALIASES to skeleton for new users
      etc."skel/.bashrc".text = mkAfter ''
        export HOSTALIASES="$HOME/.config/hblock/hosts"
      '';
      
      # Security tools
      systemPackages = with pkgs; [
        polkit_gnome      # GNOME PolicyKit agent
        assh              # Advanced SSH config manager
        hblock            # Domain blocker
      ];
      
      # Convenience aliases
      shellAliases = {
        assh              = "${pkgs.assh}/bin/assh";
        sshconfig         = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
        sshtest           = "ssh -o ConnectTimeout=5 -o BatchMode=yes";
        hblock-update-now = "${hblockUpdateScript}";
      };
      
      # Environment variables
      variables = {
        ASSH_CONFIG = "$HOME/.ssh/assh.yml";
      };
    };
    
    # hBlock service and timer (only when enabled)
    systemd = mkIf config.services.hblock.enable {
      services.hblock = {
        description = "hBlock - Update user hosts files";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = hblockUpdateScript;
          RemainAfterExit = true;
        };
      };
      
      timers.hblock = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          RandomizedDelaySec = 3600;    # 0-3600s delay (prevent burst)
          Persistent = true;             # Catch up on missed runs
        };
      };
    };
  };
  
  # ============================================================================
  # Usage Notes
  # ============================================================================
  # - To change Transmission ports: modify transmissionWebPort/transmissionPeerPort above
  # - DO NOT define firewall ports in other modules (causes conflicts)
  # - To disable hBlock: set services.hblock.enable = false
  # - If Mullvad/WireGuard interface names differ, update iptables rules accordingly
}
