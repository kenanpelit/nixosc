# modules/home/transmission/transmission.nix
{ config, lib, pkgs, ... }:

{
  services.transmission = {
    enable = true;
    user = "kenan";  # Kullanıcı adınızı buraya yazın
    group = "users";
    settings = {
      # Servis seviyesinde override edilmesi gereken ayarlar buraya
      rpc-bind-address = "127.0.0.1";
      rpc-port = 9091;
    };
  };

  # Güvenlik duvarı kuralları (opsiyonel)
  networking.firewall = {
    allowedTCPPorts = [ 9091 ]; # Web arayüzü için
    allowedTCPPortRanges = [{ 
      from = 51413; 
      to = 51413; 
    }]; # Peer bağlantıları için
    allowedUDPPortRanges = [{ 
      from = 51413; 
      to = 51413; 
    }];
  };
}
