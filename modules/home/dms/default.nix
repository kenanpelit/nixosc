# modules/home/dms/default.nix
# ==============================================================================
# DankMaterialShell (DMS) - Home Manager integration
# ==============================================================================
{ inputs, lib, config, pkgs, ... }:
let
  cfg = config.my.user.dms;
  dmsPkg = inputs.dankMaterialShell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dmsEditor = config.home.sessionVariables.DMS_SCREENSHOT_EDITOR or "swappy";
  pluginList = lib.concatStringsSep " " (map lib.escapeShellArg cfg.plugins);
in
{
  # Always import the upstream DMS Home Manager module; actual enable is gated below
  imports = [ inputs.dankMaterialShell.homeModules.dankMaterialShell.default ];

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
        "wallpaperDiscovery"
        "wallpaperShufflerPlugin"
        "webSearch"
        "worldClock"
      ];
      description = ''
        Plugins to ensure are installed via the DMS plugin registry. Missing ones
        are installed during Home Manager activation using `dms plugins install`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.dankMaterialShell.enable = true;

    # Autostart DMS for the user session
    home.packages = [ dmsPkg ];

    # Ensure DMS config/cache dirs exist
    home.file.".config/DankMaterialShell/.keep".text = "";
    home.file.".cache/DankMaterialShell/.keep".text = "";

    # Default screenshot editor for DMS (can be overridden by user env)
    home.sessionVariables.DMS_SCREENSHOT_EDITOR = "swappy";

    systemd.user.services.dms = {
      Unit = {
        Description = "DankMaterialShell";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        # Keep in foreground so systemd tracks the process
        ExecStart = "${dmsPkg}/bin/dms run --session";
        Restart = "on-failure";
        RestartSec = 3;
        TimeoutStopSec = 10;
        KillSignal = "SIGINT";
        Environment = [
          "DMS_SCREENSHOT_EDITOR=${dmsEditor}"
          "XDG_RUNTIME_DIR=/run/user/%U"
          "XDG_CURRENT_DESKTOP=Hyprland"
          "XDG_SESSION_TYPE=wayland"
        ];
        PassEnvironment = [
          "WAYLAND_DISPLAY"
          "HYPRLAND_INSTANCE_SIGNATURE"
          "HYPRLAND_SOCKET"
        ];
        StandardOutput = "journal";
        StandardError = "journal";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Ensure DMS plugins are present; install from registry when missing
    home.activation.dmsPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      pluginsDir="$HOME/.config/DankMaterialShell/plugins"
      mkdir -p "$pluginsDir"

      for plugin in ${pluginList}; do
        if [ ! -d "$pluginsDir/$plugin" ]; then
          echo "[dms] installing plugin: $plugin"
          if ! ${dmsPkg}/bin/dms plugins install "$plugin"; then
            echo "[dms] warning: failed to install plugin $plugin" >&2
          fi
        fi
      done
    '';
  };
}
