# modules/core/logind/default.nix
# ==============================================================================
# Logind Power Policy
# ==============================================================================
# Configures systemd-logind settings for power button and lid switch behavior.
# - Lid switch action (suspend)
# - Power key action (ignore/poweroff)
#
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
