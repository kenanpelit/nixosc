# modules/core/services/default.nix
{ pkgs, ... }:
{
  # Temel sistem servisleri
  services = {
    gvfs.enable = true;                # Sanal dosya sistemi desteği
    fstrim.enable = true;              # SSD optimizasyonu
    dbus = {
      enable = true;
      packages = [ pkgs.gcr ];         # GPG ve şifreleme altyapısı için
    };
    touchegg.enable = false;           # Touchégg hizmeti
    
    # systemd-logind yapılandırması
    logind.extraConfig = ''
      HandlePowerKey=ignore
    '';
  };

  # Sistem güvenliği
  security.polkit.enable = true;

  # Transmission için güvenlik duvarı kuralları
  networking.firewall = {
    allowedTCPPorts = [ 9091 ];       # Transmission web arayüzü
    allowedTCPPortRanges = [{ 
      from = 51413; 
      to = 51413; 
    }];
    allowedUDPPortRanges = [{ 
      from = 51413; 
      to = 51413; 
    }];
  };
}
