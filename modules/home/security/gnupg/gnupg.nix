# modules/home/gnupg/gnupg.nix
# ==============================================================================
# GnuPG Program Configuration
# ==============================================================================
{ pkgs, ... }:
{
  # =============================================================================
  # GPG Settings
  # =============================================================================
  programs.gpg = {
    enable = true;
    settings = {
      use-agent = true;
      keyid-format = "LONG";
      with-fingerprint = true;
    };
  };

  # =============================================================================
  # GPG Agent Configuration
  # =============================================================================
  home.file.".gnupg/gpg-agent.conf".text = ''
    enable-ssh-support
    grab
    default-cache-ttl 864000
    max-cache-ttl 864000
    pinentry-program ${pkgs.pinentry-gnome3}/bin/pinentry-gnome3
    allow-preset-passphrase
  '';
}
