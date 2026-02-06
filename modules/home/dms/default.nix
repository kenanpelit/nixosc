# modules/home/dms/default.nix
# ==============================================================================
# Home module for DankMaterialShell: imports upstream HM module plus local
# Central place to manage DMS runtime config for the user session.
# ==============================================================================

{ inputs, lib, ... }:
{
  # Upstream DMS module + local splits (settings, themes)
  imports = [
    inputs.dankMaterialShell.homeModules.default
    ./settings.nix
  ];

  options.my.user.dms = {
    enable = lib.mkEnableOption "DankMaterialShell";

    screenshotEditor = lib.mkOption {
      type = lib.types.str;
      default = "swappy";
      description = "Preferred DMS screenshot editor (exported as DMS_SCREENSHOT_EDITOR).";
    };

    restartOnResume = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Restart DMS/quickshell after system resume (workaround for some Wayland/QtWayland resume crashes).";
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
        "NiriWindows"
      ];
      description = ''
        Plugins to ensure are installed via the DMS plugin registry. Missing ones
        are installed by a non-blocking user service (not during HM activation).
      '';
    };

    blockedPlugins = lib.mkOption {
      type = with lib.types; listOf str;
      default = [
        "wallpaperBing"
        "wallpaperShufflerPlugin"
      ];
      description = ''
        Known incompatible plugins to quarantine before DMS starts.
        Use an empty list to disable this behavior.
      '';
    };
  };
}
