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
        ExecStart = "${pkgs.bash}/bin/bash -c '\n          cache=\"$HOME/.cache/nix-index\"\n          mkdir -p \"$cache\"\n          tmp=\"$cache/index-${system}.tmp\"\n          dest=\"$cache/index-${system}\"\n          if ${pkgs.curl}/bin/curl -fL \"${dbUrl}\" -o \"$tmp\"; then\n            mv \"$tmp\" \"$dest\"\n            ln -sf \"$dest\" \"$cache/files\"\n          fi\n        '";
      };
    };

    # Refresh DB on HM activation to fix corrupt/missing files
    home.activation.nixIndexDatabase = dag.entryAfter [ "writeBoundary" ] ''
      cache="$HOME/.cache/nix-index"
      mkdir -p "$cache"
      tmp="$cache/index-${system}.tmp"
      dest="$cache/index-${system}"
      if ${pkgs.curl}/bin/curl -fL "${dbUrl}" -o "$tmp"; then
        mv "$tmp" "$dest"
        ln -sf "$dest" "$cache/files"
      else
        echo "nix-index: download failed (skipping update)" >&2
      fi
    '';
  };
}
