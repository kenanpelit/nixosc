# modules/core/gnupg/default.nix
{ pkgs, ... }:
{
  programs.gnupg = {
    agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
      enableSSHSupport = true;
    };
  };

  # GCR ve DBUS entegrasyonu
  services.dbus = {
    enable = true;
    packages = [ pkgs.gcr ];
  };

  # GCR ayarları
  environment.sessionVariables = {
    GCR_PKCS11_MODULE = "${pkgs.gcr}/lib/pkcs11/gcr-pkcs11.so";
    GCR_PROVIDER_PRIORITY = "1";
  };
}
