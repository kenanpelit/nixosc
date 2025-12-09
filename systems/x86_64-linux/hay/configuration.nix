# systems/x86_64-linux/hay/configuration.nix
# ==============================================================================
# Compatibility wrapper: forwards old imports to systems/x86_64-linux/hay/default.nix
# for the HAY workstation. Keep for legacy references; main config lives in default.nix.
# ==============================================================================
{ ... } @ args:
import ./default.nix args
