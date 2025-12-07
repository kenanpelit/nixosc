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
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
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

    # Ensure Qt icon theme matches Candy (Kvantum/qt6ct fallback)
    xdg.configFile."qt6ct/qt6ct.conf".text = ''
      [Appearance]
      icon_theme=a-candy-beauty
    '';

    # Custom DMS theme (Tokyo Night inspired)
    home.file.".config/DankMaterialShell/themes/tokyo-night.json".text = ''
      {
        "name": "Tokyo Night",
        "primary": "#7aa2f7",
        "primaryText": "#1a1b26",
        "primaryContainer": "#2f334d",
        "secondary": "#bb9af7",
        "surfaceTint": "#7aa2f7",
        "surface": "#1a1b26",
        "surfaceText": "#c0caf5",
        "surfaceVariant": "#24283b",
        "surfaceVariantText": "#9aa5ce",
        "surfaceContainer": "#1f2335",
        "surfaceContainerHigh": "#252a3f",
        "surfaceContainerHighest": "#2c3047",
        "background": "#0f111a",
        "backgroundText": "#c0caf5",
        "outline": "#414868",
        "error": "#f7768e",
        "warning": "#e0af68",
        "info": "#7dcfff",
        "matugen_type": "scheme-tonal-spot"
      }
    '';

    # Catppuccin Mocha (dark)
    home.file.".config/DankMaterialShell/themes/catppuccin-mocha.json".text = ''
      {
        "name": "Catppuccin Mocha",
        "primary": "#cba6f7",
        "primaryText": "#1e1e2e",
        "primaryContainer": "#312b45",
        "secondary": "#89dceb",
        "surfaceTint": "#cba6f7",
        "surface": "#1e1e2e",
        "surfaceText": "#cdd6f4",
        "surfaceVariant": "#313244",
        "surfaceVariantText": "#a6adc8",
        "surfaceContainer": "#1f2230",
        "surfaceContainerHigh": "#24283a",
        "surfaceContainerHighest": "#2a3042",
        "background": "#11111b",
        "backgroundText": "#cdd6f4",
        "outline": "#45475a",
        "error": "#f38ba8",
        "warning": "#f9e2af",
        "info": "#89b4fa",
        "matugen_type": "scheme-tonal-spot"
      }
    '';

    # Nord (dark)
    home.file.".config/DankMaterialShell/themes/nord.json".text = ''
      {
        "name": "Nord Dark",
        "primary": "#88c0d0",
        "primaryText": "#2e3440",
        "primaryContainer": "#4c566a",
        "secondary": "#b48ead",
        "surfaceTint": "#88c0d0",
        "surface": "#2e3440",
        "surfaceText": "#e5e9f0",
        "surfaceVariant": "#3b4252",
        "surfaceVariantText": "#d8dee9",
        "surfaceContainer": "#323845",
        "surfaceContainerHigh": "#373e4c",
        "surfaceContainerHighest": "#3d4554",
        "background": "#242933",
        "backgroundText": "#e5e9f0",
        "outline": "#4c566a",
        "error": "#bf616a",
        "warning": "#d08770",
        "info": "#5e81ac",
        "matugen_type": "scheme-tonal-spot"
      }
    '';

    # Gruvbox (dark)
    home.file.".config/DankMaterialShell/themes/gruvbox-dark.json".text = ''
      {
        "name": "Gruvbox Dark",
        "primary": "#d79921",
        "primaryText": "#1d2021",
        "primaryContainer": "#3c3836",
        "secondary": "#b16286",
        "surfaceTint": "#d79921",
        "surface": "#1d2021",
        "surfaceText": "#ebdbb2",
        "surfaceVariant": "#282828",
        "surfaceVariantText": "#d5c4a1",
        "surfaceContainer": "#222525",
        "surfaceContainerHigh": "#262a2a",
        "surfaceContainerHighest": "#2b3030",
        "background": "#141617",
        "backgroundText": "#ebdbb2",
        "outline": "#504945",
        "error": "#fb4934",
        "warning": "#fabd2f",
        "info": "#83a598",
        "matugen_type": "scheme-tonal-spot"
      }
    '';

    # Dracula (dark)
    home.file.".config/DankMaterialShell/themes/dracula.json".text = ''
      {
        "name": "Dracula",
        "primary": "#bd93f9",
        "primaryText": "#1e1f29",
        "primaryContainer": "#343746",
        "secondary": "#50fa7b",
        "surfaceTint": "#bd93f9",
        "surface": "#1e1f29",
        "surfaceText": "#f8f8f2",
        "surfaceVariant": "#282a36",
        "surfaceVariantText": "#e2e2dc",
        "surfaceContainer": "#22232f",
        "surfaceContainerHigh": "#272937",
        "surfaceContainerHighest": "#2d3040",
        "background": "#14141c",
        "backgroundText": "#f8f8f2",
        "outline": "#44475a",
        "error": "#ff5555",
        "warning": "#f1fa8c",
        "info": "#8be9fd",
        "matugen_type": "scheme-tonal-spot"
      }
    '';

    # Solarized Dark
    home.file.".config/DankMaterialShell/themes/solarized-dark.json".text = ''
      {
        "name": "Solarized Dark",
        "primary": "#268bd2",
        "primaryText": "#002b36",
        "primaryContainer": "#073642",
        "secondary": "#b58900",
        "surfaceTint": "#268bd2",
        "surface": "#002b36",
        "surfaceText": "#93a1a1",
        "surfaceVariant": "#073642",
        "surfaceVariantText": "#839496",
        "surfaceContainer": "#03303c",
        "surfaceContainerHigh": "#083743",
        "surfaceContainerHighest": "#0d3e4a",
        "background": "#001f27",
        "backgroundText": "#93a1a1",
        "outline": "#586e75",
        "error": "#dc322f",
        "warning": "#b58900",
        "info": "#2aa198",
        "matugen_type": "scheme-tonal-spot"
      }
    '';

    # Hotline Miami (neon, dark)
    home.file.".config/DankMaterialShell/themes/hotline-miami.json".text = ''
      {
        "name": "Hotline Miami",
        "primary": "#ff71ce",
        "primaryText": "#0b0b12",
        "primaryContainer": "#2b1a2f",
        "secondary": "#01fdf6",
        "surfaceTint": "#ff71ce",
        "surface": "#0b0b12",
        "surfaceText": "#f5f5ff",
        "surfaceVariant": "#1a1a2a",
        "surfaceVariantText": "#c2c2dc",
        "surfaceContainer": "#151520",
        "surfaceContainerHigh": "#1c1c2a",
        "surfaceContainerHighest": "#232332",
        "background": "#07070c",
        "backgroundText": "#f5f5ff",
        "outline": "#37374a",
        "error": "#ff3f78",
        "warning": "#ffc857",
        "info": "#01fdf6",
        "matugen_type": "scheme-expressive"
      }
    '';

    # Cyberpunk Electric (neon, dark)
    home.file.".config/DankMaterialShell/themes/cyberpunk-electric.json".text = ''
      {
        "name": "Cyberpunk Electric",
        "primary": "#00ffcc",
        "primaryText": "#000000",
        "primaryContainer": "#00cc99",
        "secondary": "#ff4dff",
        "surfaceTint": "#00ffcc",
        "surface": "#0f0f0f",
        "surfaceText": "#e0ffe0",
        "surfaceVariant": "#1f2f1f",
        "surfaceVariantText": "#ccffcc",
        "surfaceContainer": "#1a2b1a",
        "surfaceContainerHigh": "#264026",
        "surfaceContainerHighest": "#33553f",
        "background": "#000000",
        "backgroundText": "#f0fff0",
        "outline": "#80ff80",
        "error": "#ff0066",
        "warning": "#ccff00",
        "info": "#00ffcc",
        "matugen_type": "scheme-expressive"
      }
    '';

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
    home.activation.dmsPlugins = dag.entryAfter [ "writeBoundary" ] ''
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
