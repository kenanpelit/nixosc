# modules/mpd/default.nix
# ==============================================================================
# Music Player Daemon Configuration
# ==============================================================================
{ config, pkgs, lib, ... }:
{
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = with pkgs; [
    mpc-cli   # MPD command line interface
    rmpc      # Remote MPD client
  ];

  # =============================================================================
  # MPD Service Configuration
  # =============================================================================
  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    
    # ---------------------------------------------------------------------------
    # Audio and Performance Settings
    # ---------------------------------------------------------------------------
    extraConfig = ''
      # Audio Output Configuration
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
        mixer_type "software"
      }
      
      # Playback Settings
      restore_paused "yes"
      auto_update "yes"
      
      # Performance Tuning
      audio_buffer_size "4096"
    '';
  };
}
