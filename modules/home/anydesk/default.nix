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
    # Theme overrides for a consistent UI.
    export GTK_THEME="Catppuccin-Mocha-Blue-Standard"
    export QT_STYLE_OVERRIDE="kvantum"

    # AnyDesk is X11-only. In Niri sessions it needs Xwayland (xwayland-satellite).
    if [ -z "''${DISPLAY:-}" ]; then
      echo "run-anydesk: DISPLAY is empty (Xwayland is not available in this session)." >&2
      echo "run-anydesk: ensure xwayland-satellite is installed and niri can spawn it." >&2
      echo "run-anydesk: check -> journalctl --user -b | rg -i 'xwayland-satellite|niri::utils::xwayland'" >&2
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
