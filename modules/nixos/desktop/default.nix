# modules/nixos/desktop/default.nix
# ------------------------------------------------------------------------------
# NixOS module for desktop (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

{ pkgs, lib, config, ... }:

let
  isVirtualHost = config.my.host.isVirtualHost;
in
{
  services = {
    gvfs.enable = true;
    fstrim.enable = true;

    dbus = {
      enable = true;
      packages = with pkgs; [ gcr gnome-keyring ];
    };

    blueman.enable = true;
    touchegg.enable = false;
    tumbler.enable = true;
    fwupd.enable = true;
    spice-vdagentd.enable = lib.mkDefault false;
    printing.enable = false;
    avahi = { enable = false; nssmdns4 = false; };
    speechd.enable = lib.mkForce false;
  };

  systemd.user.services.speech-dispatcher = {
    enable = false;
    unitConfig.ConditionPathExists = "!/dev/null";
  };
  systemd.user.sockets.speech-dispatcher = {
    enable = false;
    unitConfig.ConditionPathExists = "!/dev/null";
  };

  environment.sessionVariables = {
    GTK_A11Y = "none";
    NO_AT_BRIDGE = "1";
  };
}
