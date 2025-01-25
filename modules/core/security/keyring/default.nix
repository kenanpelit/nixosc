# modules/core/security/keyring/default.nix
# ==============================================================================
# GNOME Keyring Configuration
# ==============================================================================
# This configuration manages credential storage including:
# - GNOME Keyring service
# - DBus integration
# - GCR configuration
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:
{
  services = {
    gnome.gnome-keyring.enable = true;
    dbus = {
      enable = true;
      packages = [ pkgs.gcr ];
    };
  };

  environment = {
    # Session Variables
    sessionVariables = {
      GCR_PKCS11_MODULE = "${pkgs.gcr}/lib/pkcs11/gcr-pkcs11.so";
      GCR_PROVIDER_PRIORITY = "1";
    };
    
    # System Packages
    systemPackages = with pkgs; [ 
      gcr 
      pinentry-gnome3
    ];
  };
}
