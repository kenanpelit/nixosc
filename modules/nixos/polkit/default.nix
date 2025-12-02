# modules/core/polkit/default.nix
# ==============================================================================
# Polkit Configuration
# ==============================================================================
# Enables Polkit for managing system-wide privileges.
# - Enable security.polkit
#
# ==============================================================================

{ ... }: { security.polkit.enable = true; }
