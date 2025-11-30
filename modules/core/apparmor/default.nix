# modules/core/security/apparmor/default.nix
# AppArmor enablement.

{ ... }:
{
  security.apparmor.enable = true;

  environment.shellAliases = {
    aa-status   = "sudo aa-status";
    aa-enforce  = "sudo aa-enforce";
    aa-complain = "sudo aa-complain";
  };
}
