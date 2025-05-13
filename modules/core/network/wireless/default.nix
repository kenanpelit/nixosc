# modules/core/network/wireless/default.nix
# ==============================================================================
# Kablosuz Ağ Yapılandırması - NetworkManager + nm-applet İkon Özelleştirme
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

  # nm-applet için ikon özelleştirme
  environment.systemPackages = with pkgs; [
    networkmanagerapplet  # nm-applet paketi
    beautyline-icon-theme  # BeautyLine ikon teması (paket adını kontrol edin)
  ];

  # GTK ikon temasını BeautyLine olarak ayarla
  environment.variables = {
    GTK_ICON_THEME = "BeautyLine";
  };

  # Alternatif: Doğrudan hicolor temasına özel ikon ekleme (kalıcı çözüm)
  environment.etc = {
    "icons/hicolor/22x22/apps/nm-device-wireless.png" = {
      source = "${pkgs.beautyline-icon-theme}/share/icons/BeautyLine/apps/scalable/nm-device-wireless.svg";
    };
  };

  # nm-applet'i otomatik başlat (opsiyonel)
  systemd.user.services.nm-applet = {
    description = "NetworkManager Applet";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      Restart = "on-failure";
    };
  };
}

