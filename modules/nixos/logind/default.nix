# modules/nixos/logind/default.nix
# ==============================================================================
# NixOS logind policy: lid-close actions, power key behavior, session limits.
# Centralize user session and power button defaults here.
# Avoid per-host drift by editing logind settings in this module.
# ==============================================================================

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
