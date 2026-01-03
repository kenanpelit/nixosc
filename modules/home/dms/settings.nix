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
  dmsTargets = [
    # Only start DMS inside compositor sessions that are known to support it.
    "hyprland-session.target"
    "niri-session.target"
  ];
in
lib.mkIf cfg.enable {
  programs.dank-material-shell = {
    enable = true;
    # Do not autostart via `config.wayland.systemd.target`; we manage our own
    # compositor-scoped systemd service below.
    systemd.enable = false;

    # Upstream DMS no longer bundles dgop; provide it from our flake input.
    dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
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

  systemd.user.services.dms = {
    Unit = {
      Description = "DankMaterialShell";
      After = dmsTargets;
      PartOf = dmsTargets;
    };
    Service = {
      Type = "simple";
      ExecStart = "${dmsPkg}/bin/dms run --session";
      Restart = "always";
      RestartSec = 3;
      TimeoutStopSec = 10;
      KillSignal = "SIGINT";
      Environment = [
        "DMS_SCREENSHOT_EDITOR=${dmsEditor}"
        "XDG_RUNTIME_DIR=/run/user/%U"
        "XDG_SESSION_TYPE=wayland"
        "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
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
    Install.WantedBy = dmsTargets;
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
      After = dmsTargets ++ [ "dms.service" ];
      PartOf = dmsTargets;
    };
    Service = {
      Type = "oneshot";
      TimeoutStartSec = 60;
      ExecStart = pkgs.writeShellScript "dms-plugin-sync" ''
        set -euo pipefail
        pluginsDir="$HOME/.config/DankMaterialShell/plugins"
        mkdir -p "$pluginsDir"

        # Check for missing plugins first
        missing_plugins=()
        for plugin in ${pluginList}; do
          if [ ! -d "$pluginsDir/$plugin" ]; then
            missing_plugins+=("$plugin")
          fi
        done

        if [ ${"$"}{#missing_plugins[@]} -eq 0 ]; then
          exit 0
        fi

        # Ensure dms binary is reachable
        if ! command -v dms >/dev/null 2>&1 && [ ! -x "${dmsPkg}/bin/dms" ]; then
          echo "[dms] plugin-sync: dms binary not found, skipping" >&2
          exit 0
        fi

        # Network check: only if we actually need to download something
        if ! ${pkgs.coreutils}/bin/timeout 2s ${pkgs.glibc}/bin/getent hosts github.com >/dev/null 2>&1; then
          echo "[dms] plugin-sync: github.com unreachable, skipping installation of ${"$"}{#missing_plugins[@]} plugins"
          exit 0
        fi

        for plugin in "${"$"}{missing_plugins[@]}"; do
          echo "[dms] plugin-sync: installing $plugin..."
          if ! ${pkgs.coreutils}/bin/timeout 30s ${dmsPkg}/bin/dms plugins install "$plugin" >/dev/null 2>&1; then
            echo "[dms] plugin-sync: failed to install $plugin" >&2
          fi
        done
      '';
    };
    Install.WantedBy = dmsTargets;
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
