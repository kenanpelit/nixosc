# modules/core/apparmor/default.nix
# ==============================================================================
# AppArmor Configuration
# ==============================================================================
# Enables AppArmor Mandatory Access Control (MAC) and provides shell aliases.
# - Enable AppArmor
# - Shell aliases for status and enforcement management
#
# ==============================================================================

{ ... }:
{
  security.apparmor.enable = true;

  environment.shellAliases = {
    aa-status   = "sudo aa-status";
    aa-enforce  = "sudo aa-enforce";
    aa-complain = "sudo aa-complain";
  };
}
