# modules/home/blue/default.nix
# ==============================================================================
# Hypr Blue Manager Service Configuration
# ==============================================================================
# Unified Gammastep + HyprSunset + wl-gammarelay service for automatic
# color temperature adjustment in Hyprland.
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, username, ... }:
let
  cfg = config.services.blue;
in
{
  options.services.blue = {
    enable = lib.mkEnableOption "Hypr Blue Manager servisi (Gammastep + HyprSunset)";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.writeShellScriptBin "hypr-blue-manager" (builtins.readFile ./hypr-blue-manager.sh);
      description = "Hypr Blue Manager paketi";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.gammastep
      pkgs.hyprsunset
      pkgs.wl-gammarelay-rs
    ];

    systemd.user.services.blue = {
      Unit = {
        Description = "Hypr Blue Manager - Unified Gammastep + HyprSunset";
        After = [ "hyprland-session.target" ];
        PartOf = [ "hyprland-session.target" ];
      };
      Service = {
        Type = "simple";
        Environment = "PATH=/etc/profiles/per-user/${username}/bin:$PATH";
        ExecStart = "/etc/profiles/per-user/${username}/bin/hypr-blue-manager daemon";
        ExecStop  = "/etc/profiles/per-user/${username}/bin/hypr-blue-manager stop";
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "mixed";
        KillSignal = "SIGTERM";
      };
      Install.WantedBy = [ "hyprland-session.target" ];
    };

    # wl-gammarelay daemon with 4000K default
    systemd.user.services.wl-gammarelay = {
      Unit = {
        Description = "wl-gammarelay (Night Light 4000K default)";
        After = [ "hyprland-session.target" ];
        PartOf = [ "hyprland-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.wl-gammarelay-rs}/bin/wl-gammarelay-rs";

        # 💡 Kritik fark burada:
        # Çok satırlı string yerine array (list) kullanıyoruz
        ExecStartPost = [
          "${pkgs.systemd}/bin/busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q 4000"
          "${pkgs.systemd}/bin/busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Brightness d 1.0"
          "${pkgs.systemd}/bin/busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Gamma d 1.0"
        ];

        Restart = "on-failure";
        RestartSec = 3;
      };

      Install.WantedBy = [ "hyprland-session.target" ];
    };
  };
}


