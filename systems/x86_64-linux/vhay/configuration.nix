# hosts/vhay/configuration.nix
# ==============================================================================
# VHAY Virtual Machine: Legacy Configuration Wrapper
# ==============================================================================
# This file serves as a compatibility wrapper for the 'vhay' virtual machine.
#
# IMPORTANT: The primary host configuration is now managed in:
#   hosts/vhay/default.nix
#
# This wrapper exists solely for backward compatibility with any older references
# that might directly import './hosts/vhay/configuration.nix'.
#
# ==============================================================================
{ ... } @ args:
import ./default.nix args