# modules/home/dms/default.nix
# ==============================================================================
# Home module for DankMaterialShell: imports upstream HM module plus local
# settings/themes splits. Exposes screenshot editor and plugin list options.
# Central place to manage DMS runtime config for the user session.
# ==============================================================================

{ inputs, lib, config, pkgs, ... }:
{
  # Upstream DMS module + local splits (settings, themes)
  imports = [
    ./settings.nix
    ./themes.nix
  ];

  options.my.user.dms = {
    enable = lib.mkEnableOption "DankMaterialShell";

    screenshotEditor = lib.mkOption {
      type = lib.types.str;
      default = "swappy";
      description = "Preferred DMS screenshot editor (exported as DMS_SCREENSHOT_EDITOR).";
    };

    plugins = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "alarmClock"
        "calculator"
        "commandRunner"
        "dankActions"
        "dankBatteryAlerts"
        "dankHooks"
        "dankPomodoroTimer"
        "displayMirror"
        "displaySettings"
        "dockerManager"
        "dolarBlue"
        "easyEffects"
        "emojiLauncher"
        "gitmojiLauncher"
        "grimblast"
        "linuxWallpaperEngine"
        "powerUsagePlugin"
        "pulsarX3"
        "webSearch"
        "worldClock"
      ];
      description = ''
        Plugins to ensure are installed via the DMS plugin registry. Missing ones
        are installed during Home Manager activation using `dms plugins install`.
      '';
    };
  };

  # Stub option so settings.nix can enable the program even when upstream HM
  # module is not imported.
  options.programs.dankMaterialShell.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable DankMaterialShell (stub option for local DMS setup).";
  };
}
