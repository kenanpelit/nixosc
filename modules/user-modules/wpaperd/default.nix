# modules/home/wpaperd/default.nix
# ==============================================================================
# Wpaperd Wallpaper Daemon Configuration
# ==============================================================================
# This configuration manages wpaperd wallpaper daemon including:
# - Systemd user service configuration
# - Wallpaper rotation and display settings
# - Monitor-specific configurations
# - Wayland compositor integration
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, username, ... }:
let
  cfg = config.my.user.wpaperd;
in {
  # =============================================================================
  # Module Options
  # =============================================================================
  options.my.user.wpaperd = {
    enable = lib.mkEnableOption "wpaperd wallpaper daemon";
    
    wallpaperPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/${username}/Pictures/wallpapers/others";
      description = "Default path to wallpaper directory";
    };
    
    duration = lib.mkOption {
      type = lib.types.str;
      default = "3m";
      description = "Duration between wallpaper changes";
    };
    
    mode = lib.mkOption {
      type = lib.types.enum [ "center" "fit" "stretch" "tile" ];
      default = "center";
      description = "Wallpaper display mode";
    };
    
    transitionTime = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "Transition time in milliseconds";
    };
    
    applyShadow = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Apply shadow effect to wallpapers";
    };
  };

  # =============================================================================
  # Module Configuration
  # =============================================================================
  config = lib.mkIf cfg.enable {
    # ---------------------------------------------------------------------------
    # Systemd User Service
    # ---------------------------------------------------------------------------
    systemd.user.services.wpaperd = {
      Unit = {
        Description = "Wallpaper daemon for Wayland";
        Documentation = "man:wpaperd(1)";
        After = [ "hyprland-session.target" ];
        PartOf = [ "hyprland-session.target" ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };
      
      Service = {
        Type = "simple";
        Environment = [
          "PATH=/etc/profiles/per-user/${username}/bin:$PATH"
          "WAYLAND_DISPLAY=wayland-1"
        ];
        ExecStart = "${pkgs.wpaperd}/bin/wpaperd";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
        Restart = "on-failure";
        RestartSec = "3s";
        TimeoutStopSec = "10s";
      };
      
      Install = {
        WantedBy = [ "hyprland-session.target" ];
      };
    };

    # ---------------------------------------------------------------------------
    # Configuration File
    # ---------------------------------------------------------------------------
    xdg.configFile."wpaperd/config.toml".text = ''
      # ==============================================================================
      # Wpaperd Configuration
      # ==============================================================================
      
      # Default Settings
      [default]
      path = "${cfg.wallpaperPath}"
      mode = "${cfg.mode}"
      duration = "${cfg.duration}"
      sorting = "ascending"
      apply-shadow = ${if cfg.applyShadow then "true" else "false"}
      transition-time = ${toString cfg.transitionTime}
      
      # Generic Monitor Settings
      [any]
      path = "${cfg.wallpaperPath}"
      mode = "${cfg.mode}"
      duration = "${cfg.duration}"
      apply-shadow = ${if cfg.applyShadow then "true" else "false"}
      
      # Primary Monitor Settings (eDP-1 - Laptop screen)
      [eDP-1]
      path = "${cfg.wallpaperPath}"
      mode = "${cfg.mode}"
      duration = "${cfg.duration}"
      apply-shadow = ${if cfg.applyShadow then "true" else "false"}
      sorting = "ascending"
      transition-time = ${toString cfg.transitionTime}
      
      # Secondary Monitor Settings (DP-5 - External monitor)
      [DP-5]
      path = "${cfg.wallpaperPath}"
      mode = "${cfg.mode}"
      duration = "${cfg.duration}"
      apply-shadow = ${if cfg.applyShadow then "true" else "false"}
      sorting = "descending"
      transition-time = ${toString cfg.transitionTime}
      
      # Additional monitor configurations can be added here
      # Example for HDMI output:
      # [HDMI-A-1]
      # path = "${cfg.wallpaperPath}"
      # mode = "fit"
      # duration = "5m"
    '';

    # ---------------------------------------------------------------------------
    # Create wallpaper directory if it doesn't exist
    # ---------------------------------------------------------------------------
    home.activation.createWallpaperDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p "${cfg.wallpaperPath}"
    '';
  };
}
