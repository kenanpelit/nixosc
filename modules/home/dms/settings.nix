#
# modules/home/dms/settings.nix
# ==============================================================================
# DMS core settings: service wiring, env vars, plugins, and key options.
# Consumed by default.nix alongside themes.nix; keep runtime config here.
# ==============================================================================
{ inputs, lib, config, pkgs, ... }:
let
  cfg = config.my.user.dms;
  dmsPkg = inputs.dankMaterialShell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  qsPkg = pkgs.quickshell;
  dmsEditor = cfg.screenshotEditor;
  pluginList = lib.concatStringsSep " " (map lib.escapeShellArg cfg.plugins);
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
in
lib.mkIf cfg.enable {
  programs.dankMaterialShell.enable = true;

  # Autostart DMS for the user session
  home.packages = [ dmsPkg qsPkg ];

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
        "XDG_SESSION_TYPE=wayland"
        "PATH=${qsPkg}/bin:/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
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

  # Lock davranışı:
  # `loginctlLockIntegration=true` iken DMS bazen loginctl üzerinden kilitleyip
  # kendi (güzel) lock UI'ını devreye sokmayabiliyor ve "başka" bir lock ekranı
  # görünüyormuş gibi oluyor. Niri/Hyprland altında tutarlı olması için bunu
  # kapatıyoruz ve DMS'in WlSessionLock UI'ını her zaman kullandırıyoruz.
  home.activation.dmsLockSettings = dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.config/DankMaterialShell/settings.json"
    if [ -f "$settings" ]; then
      current="$(${pkgs.jq}/bin/jq -r '.loginctlLockIntegration // empty' "$settings" 2>/dev/null || true)"
      if [ "$current" != "false" ]; then
        tmp="$(mktemp)"
        ${pkgs.jq}/bin/jq '.loginctlLockIntegration = false' "$settings" >"$tmp"
        mv "$tmp" "$settings"
        ${pkgs.systemd}/bin/systemctl --user try-restart dms.service >/dev/null 2>&1 || true
      fi
    fi
  '';
}
