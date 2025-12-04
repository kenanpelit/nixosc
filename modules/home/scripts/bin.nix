# modules/home/scripts/bin.nix
# ==============================================================================
# Custom Binary Scripts (auto-discovered)
# ==============================================================================
# Reads all executable shell scripts under ./bin and exposes them in PATH.
# Filters to *.sh files to skip backups/other assets.
#
# ==============================================================================

{ pkgs, lib, ... }:

let
  scripts = lib.filterAttrs (name: type:
    type == "regular" && lib.hasSuffix ".sh" name
  ) (builtins.readDir ./bin);

  mkScript = name: _: pkgs.writeShellScriptBin
    (lib.removeSuffix ".sh" name)
    (builtins.readFile (./bin + "/${name}"));
in {
  home.packages = builtins.attrValues (lib.mapAttrs mkScript scripts);
}
