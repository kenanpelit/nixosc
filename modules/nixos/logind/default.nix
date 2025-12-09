# modules/nixos/logind/default.nix
# ------------------------------------------------------------------------------
# NixOS module for logind (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

{ lib, ... }:

{
  services.logind.settings.Login = {
    HandleLidSwitch              = "suspend";
    HandleLidSwitchDocked        = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandlePowerKey               = "ignore";
    HandlePowerKeyLongPress      = "poweroff";
    HandleSuspendKey             = "suspend";
    HandleHibernateKey           = "hibernate";
  };
}
