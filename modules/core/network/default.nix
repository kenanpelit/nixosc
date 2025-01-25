# modules/core/network/default.nix
# ==============================================================================
# Network Configuration
# ==============================================================================
# This configuration file manages all network-related settings including:
# - Core network configuration and TCP/IP optimizations
# - Firewall rules and security settings
# - Wireless (IWD) configuration
# - Mullvad VPN integration
# - SSH client settings
#
# Key components:
# - TCP/IP stack optimizations for better performance
# - Advanced firewall rules and security measures
# - Wireless network management with IWD
# - Mullvad VPN configuration and security
# - SSH client configuration with GPG agent integration
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  imports = [
    ./tcp
    ./base
    ./firewall
    ./wireless
    ./vpn
    ./ssh
    ./dns
    ./powersave
  ];

  systemd.services."NetworkManager-wait-online".enable = false;
}
