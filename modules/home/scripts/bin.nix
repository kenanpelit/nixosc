# modules/home/scripts/bin.nix
# ==============================================================================
# Custom Binary Scripts (auto-discovered)
# ==============================================================================
# Reads all executable shell scripts under ./bin and exposes them in PATH.
# Filters to *.sh files to skip backups/other assets.
#
# ==============================================================================

{ pkgs, lib, config, ... }:

let
  excludedFromPath = [
    # Hyprland helpers are reachable via `hypr-set` only.
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

  scripts = lib.filterAttrs (name: type:
    type == "regular"
    && lib.hasSuffix ".sh" name
    && !(lib.elem name excludedFromPath)
  ) (builtins.readDir ./bin);

  mkScript = name: _: pkgs.writeShellScriptBin
    (lib.removeSuffix ".sh" name)
    (builtins.readFile (./bin + "/${name}"));
  cfg = config.my.user.scripts;
in lib.mkIf cfg.enable {
  home.packages = builtins.attrValues (lib.mapAttrs mkScript scripts);
}
