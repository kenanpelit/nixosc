# modules/home/scripts/default.nix
# ==============================================================================
# Home Manager module for scripts.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ==============================================================================

{ lib, config, ... }:
let
  cfg = config.my.user.scripts;
in
{
  options.my.user.scripts = {
    enable = lib.mkEnableOption "custom user scripts";
  };

  # Submodules are internally gated; import unconditionally
  imports = [
    ./bin.nix
    ./start.nix
  ];
}
