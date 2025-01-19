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

{ config, pkgs, host, lib, ... }:

{
  # =============================================================================
  # TCP/IP Stack Optimizations
  # =============================================================================
  boot.kernel.sysctl = {
    # TCP BBR and Performance
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # TCP Memory Settings
    "net.ipv4.tcp_rmem" = "4096 87380 6291456";
    "net.ipv4.tcp_wmem" = "4096 87380 6291456";

    # Security Settings
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
  };

  # =============================================================================
  # Base Networking Configuration
  # =============================================================================
  networking = {
    hostName = "${host}";
    enableIPv6 = false;
    
    # DNS Configuration - Conditional based on Mullvad status
    nameservers = lib.mkMerge [
      (lib.mkIf (!config.services.mullvad-vpn.enable) [
       "1.1.1.1"  # Cloudflare Primary
       "1.0.0.1"  # Cloudflare Secondary
       "9.9.9.9"  # Quad9
      ])
      (lib.mkIf config.services.mullvad-vpn.enable [
       "193.138.218.74"  # Mullvad DNS
       "1.1.1.1"         # Cloudflare DNS (fallback)
      ])
    ];
  
    # =============================================================================
    # Firewall Configuration
    # =============================================================================
    firewall = {
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

    # =============================================================================
    # Wireless Configuration (IWD)
    # =============================================================================
    wireless.iwd = {
      enable = true;
      settings = {
        General = {
          EnableNetworkConfiguration = "true";
          AddressRandomization = "none";
          RoamRetryInterval = "15";
          DisableANQP = "true";
          MacAddressRandomization = "vendor";
          RoamThreshold = "-70";
          RoamThresholdSet = "true";
        };

        Network = {
          EnableIPv6 = "false";
          NameResolvingService = "systemd";
          RoutePriorityOffset = "300";
          PowerSave = "false";
          EnableAutoConnect = "true";
        };

        # Network Profiles
        "Network.Ken_5" = {
          Address = "192.168.1.100/24";
          Gateway = "192.168.1.1";
          DNS = "1.1.1.1";
          AutoConnect = "true";
          Hidden = "false";
          PowerSave = "false";
        };

        "Network.Ken_2_4" = {
          Address = "192.168.1.101/24";
          Gateway = "192.168.1.1";
          DNS = "1.1.1.1";
          AutoConnect = "true";
          Hidden = "false";
          PowerSave = "false";
        };
      };
    };
  };

  # =============================================================================
  # Mullvad VPN Configuration
  # =============================================================================
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # =============================================================================
  # SSH Configuration
  # =============================================================================
  programs.ssh = {
    startAgent = false;         # GPG agent kullanacağız
    enableAskPassword = false;  # GUI parola sorgusunu devre dışı bırak
    
    extraConfig = ''
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 2
        AddKeysToAgent yes
        UseKeychain yes
    '';
  };

  # =============================================================================
  # DNS Resolution Service
  # =============================================================================
  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
  };

  # =============================================================================
  # WiFi Power Management Services
  # =============================================================================
  systemd.user.services.wifi-power-save-notify = {
    description = "Notify WiFi power save status";
    after = [ "graphical-session.target" "disable-wifi-power-save.service" ];
    bindsTo = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    
    environment = {
      WAYLAND_DISPLAY = "wayland-1";
      XDG_RUNTIME_DIR = "/run/user/1000";
      DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    };
    
    path = [ pkgs.iw pkgs.gawk pkgs.libnotify ];
    
    script = ''
      interface=$(iw dev | awk '$1=="Interface"{print $2}')
      if [ -n "$interface" ]; then
        notify-send -t 10000 "Wi-Fi Güç Tasarrufu" "$interface için güç tasarrufu kapatıldı."
      fi
    '';
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
  };

  systemd.services.disable-wifi-power-save = {
    description = "Disable WiFi power save";
    after = [ "iwd.service" ];
    requires = [ "iwd.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iw pkgs.gawk ];
    
    script = ''
      for interface in $(iw dev | awk '$1=="Interface"{print $2}')
      do
        iw "$interface" set power_save off
      done
    '';
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      User = "root";
    };
  };

  # =============================================================================
  # Environment Configuration
  # =============================================================================
  environment = {
    # Variables
    variables = {
      ASSH_CONFIG = "$HOME/.ssh/assh.yml";
    };
    # Shell Aliases
    shellAliases = {
      assh = "${pkgs.assh}/bin/assh";
      sshconfig = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
    };
    # System Packages
    systemPackages = with pkgs; [
      mullvad-vpn
    ];
  };

  # =============================================================================
  # Service Disablement
  # =============================================================================
  systemd.services."NetworkManager-wait-online".enable = false;
}
