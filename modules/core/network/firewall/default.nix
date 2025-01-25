# modules/core/network/firewall/default.nix
# ==============================================================================
# Firewall Configuration
# ==============================================================================
# This configuration manages firewall settings including:
# - Basic firewall rules
# - Port configurations
# - Security measures and port scan protection
# - Mullvad VPN integration
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  networking.firewall = {
    enable = true;
    allowPing = false;
    rejectPackets = true;
    logReversePathDrops = true;
    checkReversePath = "strict";
    
    # Mullvad VPN Ports
    allowedTCPPorts = [ 53 1401 ];
    allowedUDPPorts = [ 53 1401 51820 ];
    trustedInterfaces = [ "mullvad-" ];
    
    extraCommands = ''
      # Default Policies
      iptables -P INPUT DROP
      iptables -P FORWARD DROP
      iptables -P OUTPUT ACCEPT

      # Basic Permissions
      iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      iptables -A INPUT -i lo -j ACCEPT
      
      # Security Measures
      iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
      iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 15 -j REJECT
      
      # Port Scan Protection
      iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
      iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
      iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
      iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
      
      # ICMP Rate Limiting
      iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT

      # Mullvad VPN Rules
      if systemctl is-active mullvad-daemon; then
        ip46tables -A OUTPUT -o mullvad-* -j ACCEPT
        ip46tables -A INPUT -i mullvad-* -j ACCEPT
        ip46tables -A OUTPUT -p udp --dport 53 -j ACCEPT
        ip46tables -A INPUT -p udp --sport 53 -j ACCEPT
      fi
    '';
  };
}
