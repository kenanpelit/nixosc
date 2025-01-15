# network.nix
{ config, pkgs, host, lib, ... }:

{
  # TCP/IP Stack ve BBR optimizasyonları
  boot.kernel.sysctl = {
    # BBR congestion control algoritmasını etkinleştir
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    
    # TCP SYN flood koruması
    "net.ipv4.tcp_syncookies" = 1;
    
    # Kaynak rota doğrulaması
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    
    # TCP performans optimizasyonları
    "net.ipv4.tcp_fastopen" = 3;              
    "net.ipv4.tcp_slow_start_after_idle" = 0; 
    
    # TCP bellek parametreleri
    "net.ipv4.tcp_rmem" = "4096 87380 6291456";
    "net.ipv4.tcp_wmem" = "4096 87380 6291456";
    
    # Ek güvenlik parametreleri
    "net.ipv4.conf.all.accept_redirects" = 0;  
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;  
  };

  networking = {
    # Sistem host adı
    hostName = "${host}";
    
    # DNS yapılandırması
    nameservers = [
      "1.1.1.1"  
      "1.0.0.1"  
      "9.9.9.9"  
    ];

    # Güvenlik duvarı yapılandırması
    firewall = {
      enable = true;                    
      allowPing = false;               
      rejectPackets = true;            
      logReversePathDrops = true;      
      checkReversePath = "strict";     
      
      # Özel iptables kuralları
      extraCommands = ''
        # Varsayılan politikalar
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT

        # Temel izinler
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        iptables -A INPUT -i lo -j ACCEPT
        
        # SYN flood koruması
        iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
        iptables -A INPUT -p tcp --syn -m connlimit --connlimit-above 15 -j REJECT
        
        # Port tarama koruması
        iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
        iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
        
        # ICMP rate limiting
        iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT
      '';
    };

    # IPv6'yı devre dışı bırak
    enableIPv6 = false;

    # IWD yapılandırması
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

        # Ken_5 ağı yapılandırması
        "Network.Ken_5" = {
          Address = "192.168.1.100/24";
          Gateway = "192.168.1.1";
          DNS = "1.1.1.1";
          AutoConnect = "true";
          Hidden = "false";
          PowerSave = "false";
        };

        # Ken_2_4 ağı yapılandırması
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

  # Systemd resolved servisi
  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1" "1.0.0.1" ];
  };

  # WiFi güç tasarrufu bildirimi servisi
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

  # WiFi güç yönetimi devre dışı bırakma servisi
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

  # NetworkManager-wait-online servisini devre dışı bırak
  systemd.services."NetworkManager-wait-online".enable = false;
}
