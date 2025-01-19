# modules/core/gaming/default.nix
# ==============================================================================
# Gaming Configuration
# ==============================================================================
# This configuration file manages gaming-related settings including:
# - Steam platform integration
# - Gamescope compositor
# - Gaming performance optimizations
#
# Key components:
# - Steam client and Proton compatibility layer
# - Gamescope session management
# - Remote play functionality
# - Gaming-specific performance settings
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, lib, ... }:
{
 # =============================================================================
 # Steam Configuration
 # =============================================================================
 programs.steam = {
   enable = true;
   remotePlay.openFirewall = true;      # Enable Remote Play
   dedicatedServer.openFirewall = false; # Disable server ports
   gamescopeSession.enable = true;       # Enable Gamescope session
   extraCompatPackages = [ 
     pkgs.proton-ge-bin   # Additional Proton versions
   ];
 };

 # =============================================================================
 # Gamescope Configuration
 # =============================================================================
 programs.gamescope = {
   enable = true;
   capSysNice = true;  # Process priority management
   args = [
     "--rt"              # Enable realtime priority
     "--expose-wayland"  # Wayland compositing
   ];
 };

 # =============================================================================
 # Gaming Performance Optimizations
 # =============================================================================
 # Bu bölüme oyun performansını artıracak ek optimizasyonlar eklenebilir
 # Örneğin:
 # - CPU governor ayarları
 # - I/O scheduler optimizasyonları
 # - GPU performans ayarları
 # - Memory management optimizasyonları
}
