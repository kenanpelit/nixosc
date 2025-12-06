# modules/home/scripts/default.nix
# ==============================================================================
# Custom Scripts Module
# ==============================================================================
# This module imports custom shell scripts for various functionalities.
# - Binaries (scripts intended to be in PATH)
# - Startup scripts (scripts executed on session start)
#
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
