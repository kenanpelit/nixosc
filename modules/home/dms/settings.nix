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
  dmsEditor = cfg.screenshotEditor;
  pluginList = lib.concatStringsSep " " (map lib.escapeShellArg cfg.plugins);
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
  hasWaylandTarget = lib.hasAttrByPath [ "wayland" "systemd" "target" ] config;
  sessionTarget =
    if hasWaylandTarget then config.wayland.systemd.target else "graphical-session.target";
in
lib.mkIf cfg.enable {
  programs."dank-material-shell" = {
    enable = true;
    # Upstream HM module prefers `config.wayland.systemd.target` for session startup.
    # Bu repo'da (ve bazı HM kurulumlarında) bu target olmayabiliyor; o durumda
    # `graphical-session.target` ile kendi servisimiz üzerinden devam ediyoruz.
    systemd.enable = hasWaylandTarget;
    quickshell.package = pkgs.quickshell;
  };

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

  systemd.user.services.dms = lib.mkIf (!hasWaylandTarget) {
    Unit = {
      Description = "DankMaterialShell";
      After = [ sessionTarget ];
      PartOf = [ sessionTarget ];
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
        "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
        "QT_ICON_THEME=a-candy-beauty-icon-theme"
        "XDG_ICON_THEME=a-candy-beauty-icon-theme"
        "QT_QPA_PLATFORMTHEME=gtk3"
      ];
      PassEnvironment = [
        "WAYLAND_DISPLAY"
        "NIRI_SOCKET"
        "HYPRLAND_INSTANCE_SIGNATURE"
        "HYPRLAND_SOCKET"
        "SWAYSOCK"
        "XDG_CURRENT_DESKTOP"
        "XDG_SESSION_TYPE"
        "XDG_SESSION_DESKTOP"
      ];
      StandardOutput = "journal";
      StandardError = "journal";
    };
    Install.WantedBy = [ sessionTarget ];
  };

  # Ensure DMS plugins are present; install from registry when missing.
  #
  # Önemli: Bu adım network gerektirebiliyor. Home-Manager activation sırasında
  # çalıştırmak `home-manager-kenan.service` timeout'larına sebep olabiliyor.
  # Bu yüzden ayrı bir user service olarak, kısa timeout + network guard ile
  # "best-effort" şekilde çalıştırıyoruz.
  systemd.user.services.dms-plugin-sync = {
    Unit = {
      Description = "DMS plugin sync (best-effort)";
      After = [ sessionTarget "dms.service" ];
      PartOf = [ sessionTarget ];
    };
    Service = {
      Type = "oneshot";
      TimeoutStartSec = 60;
      ExecStart = pkgs.writeShellScript "dms-plugin-sync" ''
        set -euo pipefail
        pluginsDir="$HOME/.config/DankMaterialShell/plugins"
        mkdir -p "$pluginsDir"

        missing=0
        for plugin in ${pluginList}; do
          if [ ! -d "$pluginsDir/$plugin" ]; then
            missing=1
            break
          fi
        done

        if [ "$missing" -eq 0 ]; then
          exit 0
        fi

        # Cheap network check: if DNS isn't ready, don't hang.
        if ! ${pkgs.coreutils}/bin/timeout 2s ${pkgs.glibc}/bin/getent hosts github.com >/dev/null 2>&1; then
          echo "[dms] plugin-sync: network/DNS not ready, skipping"
          exit 0
        fi

        for plugin in ${pluginList}; do
          if [ -d "$pluginsDir/$plugin" ]; then
            continue
          fi

          echo "[dms] plugin-sync: installing $plugin"
          if ! ${pkgs.coreutils}/bin/timeout 20s ${dmsPkg}/bin/dms plugins install "$plugin"; then
            echo "[dms] plugin-sync: failed to install $plugin (skipping)" >&2
          fi
        done

        exit 0
      '';
    };
    Install.WantedBy = [ sessionTarget ];
  };

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
