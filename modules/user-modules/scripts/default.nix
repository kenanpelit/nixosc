# modules/home/scripts/default.nix
# ==============================================================================
# Custom Scripts Module
# ==============================================================================
# This module imports custom shell scripts for various functionalities.
# - Binaries (scripts intended to be in PATH)
# - Startup scripts (scripts executed on session start)
#
# ==============================================================================

{ ... }:
{
  imports = [
    ./bin.nix
    ./start.nix
  ];
}
