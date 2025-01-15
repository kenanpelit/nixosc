# modules/core/services/default.nix - Sistem seviyesi servisler
{ pkgs, ... }:
{
  services = {
    # Temel sistem servisleri
    gvfs.enable = true;                # Sanal dosya sistemi desteği
    fstrim.enable = true;              # SSD optimizasyonu
    dbus = {
      enable = true;
      packages = [ pkgs.gcr ];         # GPG ve şifreleme altyapısı için
    };
    
    # Touchégg hizmeti - dokunmatik hareketler için
    touchegg.enable = false;
    
    # systemd-logind yapılandırması
    logind.extraConfig = ''
      # Güç düğmesine kısa basıldığında sistemi kapatma
      HandlePowerKey=ignore
    '';
  };

  # Sistem genelinde gerekli programlar
  programs.dconf.enable = true;        # Sistem ayarları veritabanı
  
  # Sistem güvenliği
  security = {
    polkit.enable = true;              # Yetkilendirme sistemi
  };
  
  # Temel sistem paketleri
  environment.systemPackages = with pkgs; [
    gcr                                # GPG ve şifreleme altyapısı
  ];
}
