# ==============================================================================
# modules/core/services/default.nix
# ==============================================================================
# Base System Services Configuration
# ==============================================================================
# Manages core services:
# - Virtual filesystem (GVFS)
# - SSD TRIM
# - D-Bus setup (with keyring bits)
# - Bluetooth tooling
# - Security/maintenance daemons
# - Optional printing/discovery
#
# Notes:
# - We explicitly disable old "thinkfan-sleep" and "thinkfan-wakeup" units,
#   which some distros ship as helper hooks. Our suspend/resume handling is
#   implemented elsewhere, so we hard-disable these to avoid conflicts.
#
# Author: Kenan Pelit
# ==============================================================================

{ lib, pkgs, ... }:

{
  ###############################################################################
  # Core services
  ###############################################################################
  services = {
    # Filesystem / storage
    gvfs.enable   = true;    # Virtual filesystem integration (MTP, smb, etc)
    fstrim.enable = true;    # Weekly TRIM for SSDs

    # D-Bus and keyring
    dbus = {
      enable = true;
      packages = with pkgs; [
        gcr            # crypto/GPG integration helpers
        gnome-keyring  # secret storage (used by many apps)
      ];
    };

    # Bluetooth
    blueman.enable = true;   # GUI manager (works fine with BlueZ)

    # Input helpers
    touchegg.enable = false; # gesture daemon (off by default)

    # Security & maintenance
    hblock.enable = true;    # hosts-based ad/tracker blocking
    fwupd.enable  = true;    # firmware updates via LVFS

    # Thumbnails (file managers)
    tumbler.enable = true;

    # Printing (opt-in)
    printing.enable = false; # set true if you actually print
    avahi = {
      enable   = false;      # mDNS/Bonjour for network printers
      nssmdns4 = false;
    };
  };

  ###############################################################################
  # Disable legacy thinkfan sleep/wakeup units (avoid double-handling suspend)
  #
  # Why this way?
  # - NixOS does NOT have `systemd.maskedServices`.
  # - Use `systemd.services.<name>.enable = lib.mkForce false;`
  #   to ensure they cannot be pulled in by any module.
  # - Clearing WantedBy prevents sleep.target symlinks from being created.
  ###############################################################################
  systemd.services."thinkfan-sleep" = {
    enable   = lib.mkForce false;
    wantedBy = lib.mkForce [ ];
  };

  systemd.services."thinkfan-wakeup" = {
    enable   = lib.mkForce false;
    wantedBy = lib.mkForce [ ];
  };
}
