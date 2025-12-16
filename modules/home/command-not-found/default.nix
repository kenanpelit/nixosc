# modules/home/command-not-found/default.nix
# ==============================================================================
# Home module enabling command-not-found suggestions in the shell.
# Centralizes the hook so shells get helpful package hints uniformly.
# ==============================================================================
{ pkgs, lib, config, ... }:
let
  cfg = config.my.user.command-not-found;
  dag = (lib.hm or config.lib).dag or lib.dag;
  system = pkgs.stdenv.hostPlatform.system;
  dbUrl = "https://github.com/nix-community/nix-index-database/releases/latest/download/index-${system}";
in
{
  imports = [];
  options.my.user.command-not-found = {
    enable = lib.mkEnableOption "command-not-found handler";
  };
  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Nix-Index Configuration
    # =============================================================================
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
    };
    # =============================================================================
    # Prebuilt nix-index database (fast download)
    # =============================================================================
    # Download weekly via systemd timer; also refresh on activation to repair
    # corrupt db in ~/.cache/nix-index/files.
    # Note: The database file is not compressed, downloaded directly.
    systemd.user.timers."nix-index-download" = {
      Unit.Description = "Download prebuilt nix-index database weekly";
      Timer = {
        OnCalendar = "weekly";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
    systemd.user.services."nix-index-download" = {
      Unit.Description = "Download prebuilt nix-index database";
      Service = {
        Type = "oneshot";
        ExecStart = toString (pkgs.writeShellScript "nix-index-download" ''
          set -euo pipefail
          cache="$HOME/.cache/nix-index"
          mkdir -p "$cache"
          tmp="$cache/files.tmp"
          dest="$cache/files"
          # Don't let slow/captive networks block the user session.
          # If this fails, the existing DB (if any) stays in place.
          ${pkgs.coreutils}/bin/timeout 20s \
            ${pkgs.curl}/bin/curl -fL --connect-timeout 3 --max-time 15 \
            "${dbUrl}" -o "$tmp"
          mv "$tmp" "$dest"
        '');
        TimeoutStartSec = 25;
      };
    };
    # Refresh DB on HM activation to fix corrupt/missing files
    home.activation.nixIndexDatabase = dag.entryAfter [ "writeBoundary" ] ''
      cache="$HOME/.cache/nix-index"
      dest="$cache/files"
      # Only download if missing or corrupt
      if [ ! -f "$dest" ] || ! ${pkgs.nix-index}/bin/nix-locate --db "$cache" --top-level coreutils >/dev/null 2>&1; then
        mkdir -p "$cache"
        tmp="$cache/files.tmp"
        # Never block HM activation on a slow network; fail fast and continue.
        if ${pkgs.coreutils}/bin/timeout 20s \
          ${pkgs.curl}/bin/curl -fL --connect-timeout 3 --max-time 15 \
          "${dbUrl}" -o "$tmp"; then
          mv "$tmp" "$dest"
        else
          rm -f "$tmp"
          echo "nix-index: download failed (skipping update)" >&2
        fi
      fi
    '';
  };
}
