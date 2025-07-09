# modules/home/gnupg/default.nix
# ==============================================================================
# GnuPG Yapılandırması
# ==============================================================================
# Bu modül GnuPG ve ilgili kriptografik ayarları yönetir:
# - GPG agent yapılandırması
# - SSH agent entegrasyonu
# - Pinentry ayarları
# - Önbellek zaman aşımları
#
# Temel bileşenler:
# - GnuPG program ayarları
# - GPG agent servisi
# - SSH desteği yapılandırması
#
# Yazar: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      # Temel Ayarlar
      use-agent = true;
      keyid-format = "LONG";
      with-fingerprint = true;
      
      # Algoritma Tercihleri
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP";
      
      # Güvenlik Ayarları
      require-cross-certification = true;
      no-emit-version = true;
      no-comments = true;
      keyserver = "hkps://keys.openpgp.org";
    };
    scdaemonSettings = {
      disable-ccid = true;
      reader-port = "Disabled";
    };
  };
  
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 864000;        # Normal GPG için 10 gün
    maxCacheTtl = 864000;
    defaultCacheTtlSsh = 864000;     # SSH için de 10 gün
    maxCacheTtlSsh = 864000;
    pinentry = {
      package = pkgs.pinentry-gnome3;
    };
    enableExtraSocket = true;
    extraConfig = ''
      no-allow-external-cache
      ignore-cache-for-signing
      grab
    '';
    enableScDaemon = false;
  };
}

