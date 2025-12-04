{ lib, ... }:
{
  imports = let
    path = ./.;
    dir = builtins.readDir path;
    skipNames = [ "experimental" "archive" ".git" ".direnv" ];
    validFiles = lib.filterAttrs (name: type:
      !(lib.hasPrefix "." name) &&
      !(lib.elem name skipNames) &&
      ((type == "directory") ||
       (type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"))
    ) dir;
  in
    lib.mapAttrsToList (name: type: path + "/${name}") validFiles;
}
