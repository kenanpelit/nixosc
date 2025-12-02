{ lib, ... }:
{
  imports = let
    path = ./.;
    dir = builtins.readDir path;
    validFiles = lib.filterAttrs (name: type:
      (type == "directory") ||
      (type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix")
    ) dir;
  in
    lib.mapAttrsToList (name: type: path + "/${name}") validFiles;
}
