# modules/home/security/gnupg/default.nix
# ==============================================================================
# GnuPG Configuration
# ==============================================================================
# This module manages GnuPG and related cryptographic settings including:
# - GPG agent configuration
# - SSH agent integration
# - Pinentry settings
# - Cache timeouts
#
# Key components:
# - GnuPG program settings
# - GPG agent service
# - SSH support configuration
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      # Basic Settings
      use-agent = true;
      keyid-format = "LONG";
      with-fingerprint = true;
      
      # Algorithm Preferences
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP";
      
      # Security Settings
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
    pinentryPackage = pkgs.pinentry-gnome3;
    enableExtraSocket = true;
    extraConfig = ''
      no-allow-external-cache
      ignore-cache-for-signing
      grab
    '';
    enableScDaemon = false;
  };
}
