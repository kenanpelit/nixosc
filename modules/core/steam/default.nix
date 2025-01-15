# modules/core/steam/default.nix
# ==============================================================================
# Steam Gaming Platform Configuration
# ==============================================================================
{ pkgs, lib, ... }:
{
  programs = {
    # =============================================================================
    # Steam Configuration
    # =============================================================================
    steam = {
      enable = true;
      remotePlay.openFirewall = true;      # Enable Remote Play
      dedicatedServer.openFirewall = false; # Disable server ports
      gamescopeSession.enable = true;       # Enable Gamescope session
      extraCompatPackages = [ pkgs.proton-ge-bin ];  # Additional Proton versions
    };

    # =============================================================================
    # Gamescope Configuration
    # =============================================================================
    gamescope = {
      enable = true;
      capSysNice = true;  # Process priority management
      args = [
        "--rt"              # Enable realtime priority
        "--expose-wayland"  # Wayland compositing
      ];
    };
  };
}
