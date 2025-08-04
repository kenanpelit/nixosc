# modules/core/security/default.nix
# ==============================================================================
# Security Configuration
# ==============================================================================
# This configuration manages security settings including:
# - Firewall rules and network security
# - PolicyKit authorization and AppArmor profiles
# - PAM services and authentication
# - SSH client configuration
# - System security hardening
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:
{
  # Network Security - Firewall
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

  # System Security
  security = {
    # Basic Security Services
    rtkit.enable = true;     # Realtime Kit for audio
    sudo.enable = true;      # Superuser permissions
    
    # PolicyKit authorization manager
    polkit.enable = true;
    
    # AppArmor security profiles
    apparmor = {
      enable = true;
      packages = with pkgs; [
        apparmor-profiles
        apparmor-utils
      ];
    };
    
    # Audit daemon for security monitoring
    auditd.enable = true;
    
    # Kernel Security
    allowUserNamespaces = true;
    protectKernelImage = true;
    
    # PAM Service Configuration
    pam.services = {
      # Login and Authentication
      login.enableGnomeKeyring = true;
      
      # Screen Lockers
      swaylock.enableGnomeKeyring = true;   # Sway screen locker
      hyprlock.enableGnomeKeyring = true;   # Hyprland screen locker
      
      # System Authentication
      sudo.enableGnomeKeyring = true;       # Sudo operations
      polkit-1.enableGnomeKeyring = true;   # PolicyKit (GNOME privileges)
    };
  };

  # SSH Configuration
  programs.ssh = {
    startAgent = false;         # Using GPG agent instead
    enableAskPassword = false;  # Disable GUI password prompt
    
    # Global SSH client configuration
    extraConfig = ''
      # Connection optimization
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 2
        TCPKeepAlive yes
        ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
    '';
  };

  # Security Tools and Packages
  environment.systemPackages = with pkgs; [
    polkit_gnome  # GNOME PolicyKit agent
    assh          # Advanced SSH config manager
  ];
  
  # Environment Configuration
  environment = {
    # Variables
    variables = {
      ASSH_CONFIG = "$HOME/.ssh/assh.yml";
    };
    
    # Shell Aliases
    shellAliases = {
      assh = "${pkgs.assh}/bin/assh";
      sshconfig = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
      sshtest = "ssh -o ConnectTimeout=5 -o BatchMode=yes";
    };
  };
}

