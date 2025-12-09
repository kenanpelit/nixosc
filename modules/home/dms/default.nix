# modules/home/dms/default.nix
# ==============================================================================
# Home Manager module for dms.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ==============================================================================

{ inputs, lib, config, pkgs, ... }:
{
  # Upstream DMS module + local splits (settings, themes)
  imports = [
    inputs.dankMaterialShell.homeModules.dankMaterialShell.default
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
}
