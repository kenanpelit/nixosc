# systems/x86_64-linux/vhay/configuration.nix
# ==============================================================================
# Compatibility wrapper: forwards old imports to systems/x86_64-linux/vhay/default.nix
# for the vHAY VM. Keep for legacy references; main config lives in default.nix.
# ==============================================================================
{ ... } @ args:
import ./default.nix args
