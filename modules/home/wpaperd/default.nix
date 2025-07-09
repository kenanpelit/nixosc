# modules/home/wpaperd/default.nix
# ==============================================================================
# Wpaperd Wallpaper Daemon Configuration
# ==============================================================================
{ config, lib, pkgs, username, ... }:
{
  # =============================================================================
  # Module Options
  # =============================================================================
  options.services.wpaperd = {
    enable = lib.mkEnableOption "Wpaperd service";
  };

  # =============================================================================
  # Module Configuration
  # =============================================================================
  config = {
    # ---------------------------------------------------------------------------
    # Service Configuration
    # ---------------------------------------------------------------------------
    services = {
      wpaperd.enable = true;
    };

    # ---------------------------------------------------------------------------
    # Systemd Service
    # ---------------------------------------------------------------------------
    systemd.user.services = {
      wpaperd = {
        Unit = {
          Description = "Wallpaper daemon for Wayland";
          After = ["hyprland-session.target"];
          PartOf = ["hyprland-session.target"];
        };

        Service = {
          Type = "simple";
          Environment = "PATH=/etc/profiles/per-user/${username}/bin:$PATH";
          ExecStart = "${pkgs.wpaperd}/bin/wpaperd";
          Restart = "on-failure";
          RestartSec = 3;
        };

        Install = {
          WantedBy = ["hyprland-session.target"];
        };
      };
    };

    # ---------------------------------------------------------------------------
    # Wallpaper Configuration
    # ---------------------------------------------------------------------------
    xdg.configFile."wpaperd/config.toml".text = ''
      # Default Settings
      [default]
      path = "/home/${username}/Pictures/wallpapers/others"
      mode = "center"
      duration = "3m"
      sorting = "ascending"

      # Generic Monitor Settings
      [any]
      path = "/home/${username}/Pictures/wallpapers/others"

      # Primary Monitor Settings
      [eDP-1]
      path = "/home/${username}/Pictures/wallpapers/others"
      apply-shadow = true
      sorting = "ascending"
      transition-time = 1000

      # Secondary Monitor Settings
      [DP-5]
      path = "/home/${username}/Pictures/wallpapers/others"
      apply-shadow = true
      sorting = "descending"
      transition-time = 1000
    '';
  };
}
