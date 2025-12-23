# modules/home/cosmic/default.nix
# ==============================================================================
# Home module for COSMIC (Epoch) desktop support.
#
# Scope (Home Manager):
# - Installs COSMIC userland packages (apps/daemon/session bits).
# - Keeps config minimal; COSMIC session/greeter enabling is handled on the NixOS
#   side via:
#     my.display.enableCosmic = true;
#
# Greeter:
# - This repo uses `dms-greeter` (greetd) and explicitly disables COSMIC's greeter
#   if it exists in the option tree.
#
# Notes:
# - Package availability depends on the pinned nixpkgs. Missing packages are
#   skipped with a warning so evaluation doesn't fail.
# ==============================================================================

{ lib, config, pkgs, ... }:

let
  cfg = config.my.desktop.cosmic;

  defaultPackageNames = [
    # Core session + compositor
    "cosmic-session"
    "cosmic-comp"

    # Shell components
    "cosmic-panel"
    "cosmic-launcher"
    "cosmic-applets"
    "cosmic-applibrary"
    "cosmic-notifications"
    "cosmic-osd"
    "cosmic-bg"

    # Settings
    "cosmic-settings"
    "cosmic-settings-daemon"

    # Apps
    "cosmic-files"
    "cosmic-term"
    "cosmic-store"
    "cosmic-edit"
    "cosmic-player"
    "cosmic-screenshot"
    "cosmic-randr"

    # Misc
    "cosmic-icons"
    "pop-launcher"
    "xdg-desktop-portal-cosmic"
  ];

  hasPkg = name: builtins.hasAttr name pkgs;
  pkgsFound = builtins.filter hasPkg defaultPackageNames;
  pkgsMissing = builtins.filter (name: !(hasPkg name)) defaultPackageNames;

  basePackages = map (name: pkgs.${name}) pkgsFound;
in
{
  options.my.desktop.cosmic = {
    enable = lib.mkEnableOption "COSMIC desktop (user packages)";

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = "Extra packages to install when COSMIC is enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = basePackages ++ cfg.extraPackages;

    warnings =
      map (name: "my.desktop.cosmic: package `${name}` not found in pkgs; skipping")
        pkgsMissing;
  };
}
