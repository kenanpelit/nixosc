# modules/core/logind/default.nix
# logind/lid/power policy.

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
