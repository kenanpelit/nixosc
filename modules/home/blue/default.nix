# modules/home/blue/default.nix
# ==============================================================================
# Hypr Blue Manager Service Configuration
# ==============================================================================
# Unified Gammastep + HyprSunset service for automatic color temperature
# adjustment in Hyprland. Combines both tools for optimal night light control.
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, username, ... }:
let
  cfg = config.services.blue;
in
{
  # =============================================================================
  # Servis Seçenekleri
  # =============================================================================
  options.services.blue = {
    enable = lib.mkEnableOption "Hypr Blue Manager servisi (Gammastep + HyprSunset)";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.writeShellScriptBin "hypr-blue-manager" (builtins.readFile ./hypr-blue-manager.sh);
      description = "Hypr Blue Manager paketi";
    };
  };
  
  # =============================================================================
  # Servis Uygulaması
  # =============================================================================
  config = lib.mkIf cfg.enable {
    # Script'i kullanıcı home'una kur
    home.packages = [ cfg.package ];
    
    # Systemd user servisi
    systemd.user.services.blue = {
      Unit = {
        Description = "Hypr Blue Manager - Unified Gammastep + HyprSunset";
        After = ["hyprland-session.target"];
        PartOf = ["hyprland-session.target"];
      };
      
      Service = {
        Type = "simple";
        Environment = "PATH=/etc/profiles/per-user/${username}/bin:$PATH";
        ExecStart = "/etc/profiles/per-user/${username}/bin/hypr-blue-manager daemon";
        ExecStop = "/etc/profiles/per-user/${username}/bin/hypr-blue-manager stop";
        Restart = "on-failure";
        RestartSec = 3;
        KillMode = "mixed";
        KillSignal = "SIGTERM";
      };
      
      Install = {
        WantedBy = ["hyprland-session.target"];
      };
    };
    
    # Cache dizinini oluştur
    home.file.".cache/.keep".text = "";
  };
}

