# modules/home/mpd/default.nix
# ==============================================================================
# Home module for MPD client helpers (ncmpcpp/mpc etc.).
# Installs tools and manages user-side MPD client config.
# Keep player settings here instead of scattered dotfiles.
# ==============================================================================

{ config, pkgs, lib, ... }:
let
  cfg = config.my.user.mpd;
in
{
  options.my.user.mpd = {
    enable = lib.mkEnableOption "Music Player Daemon";
  };

  config = lib.mkIf cfg.enable {
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

        audio_output {
          type "fifo"
          name "Visualizer"
          path "/tmp/mpd.fifo"
          format "44100:16:2"
        }
        
        # Playback Settings
        restore_paused "yes"
        auto_update "yes"
        
        # Performance Tuning
        audio_buffer_size "4096"
      '';
    };
  };
}
