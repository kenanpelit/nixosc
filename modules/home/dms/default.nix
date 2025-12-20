# modules/home/dms/default.nix
# ==============================================================================
# Home module for DankMaterialShell: imports upstream HM module plus local
# settings/themes splits. Exposes screenshot editor and plugin list options.
# Central place to manage DMS runtime config for the user session.
# ==============================================================================

{ inputs, lib, ... }:
{
  # Upstream DMS module + local splits (settings, themes)
  imports = [
    # DMS upstream renamed `homeModules.dankMaterialShell.default` -> `homeModules.dank-material-shell`.
    # Using `default` keeps us compatible and avoids the deprecation warning.
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
  };
}
