# modules/home/dms/default.nix
# ==============================================================================
# DankMaterialShell (DMS) - Home Manager integration
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
