# mullvad.nix
{ config, pkgs, lib, ... }:
{
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  environment.systemPackages = with pkgs; [
    mullvad-vpn
  ];

  networking.firewall = {
    allowedTCPPorts = [ 53 1401 ];
    allowedUDPPorts = [ 53 1401 51820 ];
    checkReversePath = "strict";
    trustedInterfaces = [ "mullvad-" ];
    
    extraCommands = ''
      ip46tables -P INPUT ACCEPT
      ip46tables -P OUTPUT ACCEPT
      ip46tables -P FORWARD DROP

      if systemctl is-active mullvad-daemon; then
        ip46tables -A OUTPUT -o mullvad-* -j ACCEPT
        ip46tables -A INPUT -i mullvad-* -j ACCEPT
        ip46tables -A OUTPUT -p udp --dport 53 -j ACCEPT
        ip46tables -A INPUT -p udp --sport 53 -j ACCEPT
      fi

      ip46tables -A OUTPUT -o lo -j ACCEPT
      ip46tables -A INPUT -i lo -j ACCEPT
      ip46tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      ip46tables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    '';
  };

  # VPN DNS sunucuları (sadece Mullvad aktifken)
  networking.nameservers = lib.mkIf config.services.mullvad-vpn.enable [
    "193.138.218.74"
    "1.1.1.1"
  ];
}
