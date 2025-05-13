# modules/core/network/wireless/default.nix
# ==============================================================================
# Kablosuz Ağ Yapılandırması - NetworkManager + Candy Beauty Icons
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # NetworkManager yapılandırması
  networking = {
    enableIPv6 = false;
    wireless.enable = false;
    
    networkmanager = {
      enable = true;
      wifi = {
        backend = "wpa_supplicant";
        scanRandMacAddress = true;
        powersave = false;
      };
    };
  };

  # DNS çözümleme servisi
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
  };

  # Gerekli paketler
  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    candy-beauty-icon-theme  # Candy Beauty ikon teması
  ];

  # GTK ikon temasını ayarla
  environment.variables = {
    GTK_ICON_THEME = "al-beautyline";  # candy-beauty-icon-theme paketinin gerçek tema adı
  };

  # Doğrudan ikon override (22px boyutunda)
  environment.etc = {
    "icons/hicolor/22x22/apps/nm-device-wireless.png" = {
      source = "${pkgs.candy-beauty-icon-theme}/share/icons/al-beautyline/panel/22/network-wireless.png";
    };
    
    # Alternatif SVG versiyonu (eğer PNG çalışmazsa)
    "icons/hicolor/scalable/apps/nm-device-wireless.svg" = {
      source = "${pkgs.candy-beauty-icon-theme}/share/icons/al-beautyline/devices/scalable/network-wireless.svg";
    };
  };

  # nm-applet otomatik başlatma
  systemd.user.services.nm-applet = {
    description = "NetworkManager Applet";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      Restart = "on-failure";
    };
  };

  # İkon temasının doğru yüklendiğinden emin olmak için
  system.activationScripts.icon-theme-check = ''
    if [ ! -d "${pkgs.candy-beauty-icon-theme}/share/icons/al-beautyline" ]; then
      echo "HATA: al-beautyline ikon teması bulunamadı!"
      exit 1
    fi
  '';
}

