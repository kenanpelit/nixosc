# modules/home/scripts/helpers.nix
# ==============================================================================
# Helper scripts installed in profile but not on $PATH
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  cfg = config.my.user.scripts;

  helperNames = [
    "hypr-airplane_mode.sh"
    "hypr-colorpicker.sh"
    "hypr-init.sh"
    "hypr-layout_toggle.sh"
    "hypr-start-batteryd.sh"
    "hypr-switch.sh"
    "hypr-vlc_toggle.sh"
    "hypr-wifi-power-save.sh"
    "hypr-workspace-monitor.sh"
    "hyprland_tty.sh"
  ];

  installLines = lib.concatStringsSep "\n" (map (name:
    let
      src = "${./bin}/${name}";
      dst = "$out/share/osc/hypr/${name}";
    in
    "${pkgs.coreutils}/bin/install -m 0755 ${lib.escapeShellArg src} ${lib.escapeShellArg dst}"
  ) helperNames);

  hyprHelpers = pkgs.runCommand "osc-hypr-helpers" { } ''
    set -euo pipefail
    mkdir -p "$out/share/osc/hypr"
    ${installLines}
  '';
in
lib.mkIf cfg.enable {
  home.packages = [ hyprHelpers ];
}
