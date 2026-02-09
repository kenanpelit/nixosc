# modules/home/anydesk/default.nix
# ==============================================================================
# Home module for AnyDesk remote desktop client.
# Installs the client and keeps user-level settings in one place.
# Adjust launch/desktop integration here instead of manual installs.
# ==============================================================================

{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.anydesk;
  # =============================================================================
  # Custom Script Configuration
  # =============================================================================
  run-anydesk = pkgs.writeShellScriptBin "run-anydesk" ''
    # Do not hard-force theme/style here: it can degrade AnyDesk font rendering.
    # Optional overrides can be provided by env when needed.
    if [ -n "''${RUN_ANYDESK_GTK_THEME:-}" ]; then
      export GTK_THEME="$RUN_ANYDESK_GTK_THEME"
    fi

    if [ -n "''${RUN_ANYDESK_QT_STYLE_OVERRIDE:-}" ]; then
      export QT_STYLE_OVERRIDE="$RUN_ANYDESK_QT_STYLE_OVERRIDE"
    else
      unset QT_STYLE_OVERRIDE || true
    fi

    # AnyDesk is X11-only and needs a valid DISPLAY (Xorg or Xwayland).
    if [ -z "''${DISPLAY:-}" ]; then
      echo "run-anydesk: DISPLAY is empty (no X11 display available in this session)." >&2
      echo "run-anydesk: ensure your session provides X11/Xwayland before launching AnyDesk." >&2
      exit 1
    fi

    # Force Qt/XCB path explicitly for AnyDesk.
    export QT_QPA_PLATFORM="xcb"
    anydesk "$@"
  '';
in
{
  options.my.user.anydesk = {
    enable = lib.mkEnableOption "AnyDesk remote desktop";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Package Installation
    # =============================================================================
    home.packages = [
      run-anydesk
    ];

    # =============================================================================
    # Desktop Entry Configuration
    # =============================================================================
    xdg.desktopEntries.anydesk = {
      name = "RunAnyDesk";
      exec = "run-anydesk %u";
      icon = "anydesk";
      terminal = false;
      type = "Application";
      categories = [ "Network" "RemoteAccess" ];
      mimeType = [ "x-scheme-handler/anydesk" ];
    };
  };
}
