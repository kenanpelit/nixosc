# modules/core/gnupg/default.nix
# ==============================================================================
# GnuPG Configuration
# ==============================================================================
{ pkgs, ... }:
{
  # GnuPG Agent Yapılandırması
  programs.gnupg = {
    agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;  # GNOME PIN girişi arayüzü
      enableSSHSupport = true;                 # SSH anahtar yönetimi
    };
  };

  # DBus Entegrasyonu
  services.dbus = {
    enable = true;
    packages = [ pkgs.gcr ];  # GNOME kriptografi hizmetleri
  };

  # GCR Ortam Değişkenleri
  environment.sessionVariables = {
    GCR_PKCS11_MODULE = "${pkgs.gcr}/lib/pkcs11/gcr-pkcs11.so";
    GCR_PROVIDER_PRIORITY = "1";
  };
}
