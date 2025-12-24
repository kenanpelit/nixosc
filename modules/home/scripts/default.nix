# modules/home/scripts/default.nix
# ==============================================================================
# Home module packaging custom user scripts into $PATH.
# Build and install script set from modules/home/scripts/bin.
# Keep script distribution centralized here instead of manual copies.
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
    ./libexec.nix
    ./start.nix
  ];
}
