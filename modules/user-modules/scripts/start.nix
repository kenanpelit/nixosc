# modules/home/scripts/start.nix
# ==============================================================================
# Startup/launcher scripts (auto-discovered)
# ==============================================================================
# Reads all *.sh scripts under ./start and exposes them in PATH.
#
# ==============================================================================

{ pkgs, lib, ... }:

let
  scripts = lib.filterAttrs (name: type:
    type == "regular" && lib.hasSuffix ".sh" name
  ) (builtins.readDir ./start);

  mkScript = name: _: pkgs.writeShellScriptBin
    (lib.removeSuffix ".sh" name)
    (builtins.readFile (./start + "/${name}"));
in {
  home.packages = builtins.attrValues (lib.mapAttrs mkScript scripts);
}
