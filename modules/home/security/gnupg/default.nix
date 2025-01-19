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
  };
  
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 60;  # 1 dakika
    maxCacheTtl = 120;     # 2 dakika
    defaultCacheTtlSsh = 60;
    maxCacheTtlSsh = 120;
    pinentryPackage = pkgs.pinentry-gnome3;
    enableExtraSocket = true;
    extraConfig = ''
      enable-ssh-support
      use-standard-socket
      grab
    '';
  };

  # SSH için GPG agent'ı zorunlu kıl
  home.sessionVariables = {
    SSH_AUTH_SOCK = "$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)";
  };

  # Sistem SSH agent'ını devre dışı bırak
  services.ssh-agent.enable = false;
}
