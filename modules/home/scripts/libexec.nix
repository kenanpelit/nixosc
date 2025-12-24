# modules/home/scripts/libexec.nix
# ==============================================================================
# Private helper scripts (installed under $profile/libexec, not on $PATH)
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  cfg = config.my.user.scripts;

  hyprDir = ./libexec/hypr;
  hyprScripts = lib.filterAttrs (name: type:
    type == "regular" && lib.hasSuffix ".sh" name
  ) (builtins.readDir hyprDir);

  hyprNames = lib.sort (a: b: a < b) (builtins.attrNames hyprScripts);

  installLines = lib.concatStringsSep "\n" (map (name:
    let
      src = "${hyprDir}/${name}";
      dst = "$out/libexec/osc/hypr/${name}";
    in
    "${pkgs.coreutils}/bin/install -m 0755 ${lib.escapeShellArg src} ${lib.escapeShellArg dst}"
  ) hyprNames);

  hyprHelpers = pkgs.runCommand "osc-hypr-helpers" { } ''
    set -euo pipefail
    mkdir -p "$out/libexec/osc/hypr"
    ${installLines}
  '';
in
lib.mkIf cfg.enable {
  home.packages = [ hyprHelpers ];
}
