{ inputs, lib, config, pkgs, ... }:
let
  cfg = config.my.user.dms;
  dmsPkg = inputs.dankMaterialShell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dmsEditor = cfg.screenshotEditor;
  pluginList = lib.concatStringsSep " " (map lib.escapeShellArg cfg.plugins);
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
in
lib.mkIf cfg.enable {
  programs.dankMaterialShell.enable = true;

  # Autostart DMS for the user session
  home.packages = [ dmsPkg ];

  # Ensure DMS config/cache dirs exist
  home.file.".config/DankMaterialShell/.keep".text = "";
  home.file.".cache/DankMaterialShell/.keep".text = "";

  # Ensure Qt icon theme matches Candy (Kvantum/qt6ct fallback)
  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    icon_theme=a-candy-beauty-icon-theme
  '';
  # Kvantum config hint for icon theme (platform = kvantum)
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    iconTheme=a-candy-beauty-icon-theme
  '';
  # Export icon theme globally for Qt (systemd --user env)
  xdg.configFile."environment.d/99-dms-icons.conf".text = ''
    QT_ICON_THEME=a-candy-beauty-icon-theme
    XDG_ICON_THEME=a-candy-beauty-icon-theme
    QT_QPA_PLATFORMTHEME=gtk3
  '';

  # Default screenshot editor for DMS (can be overridden by user env)
  home.sessionVariables = {
    DMS_SCREENSHOT_EDITOR = dmsEditor;
    QT_ICON_THEME = "a-candy-beauty-icon-theme";
    XDG_ICON_THEME = "a-candy-beauty-icon-theme";
  };

  systemd.user.services.dms = {
    Unit = {
      Description = "DankMaterialShell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
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
        "QT_ICON_THEME=a-candy-beauty-icon-theme"
        "XDG_ICON_THEME=a-candy-beauty-icon-theme"
        "QT_QPA_PLATFORMTHEME=gtk3"
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
}
