# modules/core/nixpkgs/default.nix
# ==============================================================================
# Nixpkgs Configuration
# ==============================================================================
# This configuration manages nixpkgs settings including:
# - Package configuration
# - Overlay management
# - Unfree package permissions
#
# Author: Kenan Pelit
# ==============================================================================

{ inputs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [ inputs.nur.overlays.default ];
  };
}
