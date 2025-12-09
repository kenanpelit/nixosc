# modules/home/gnupg/default.nix
# ==============================================================================
# Home Manager module for gnupg.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.gnupg;
in
{
  options.my.user.gnupg = {
    enable = lib.mkEnableOption "GnuPG security suite";
  };

  config = lib.mkIf cfg.enable {
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
      defaultCacheTtl = 864000;        # 10 days for normal GPG
      maxCacheTtl = 864000;
      defaultCacheTtlSsh = 864000;     # 10 days for SSH as well
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
  };
}
