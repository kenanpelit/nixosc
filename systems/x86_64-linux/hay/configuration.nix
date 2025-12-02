# hosts/hay/configuration.nix
# ==============================================================================
# HAY Workstation: Legacy Configuration Wrapper
# ==============================================================================
# This file serves as a compatibility wrapper for the 'hay' workstation.
#
# IMPORTANT: The primary host configuration is now managed in:
#   hosts/hay/default.nix
#
# This wrapper exists solely for backward compatibility with any older references
# that might directly import './hosts/hay/configuration.nix'.
#
# ==============================================================================
{ ... } @ args:
import ./default.nix args
