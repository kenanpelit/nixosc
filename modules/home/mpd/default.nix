# modules/home/mpd/default.nix
# ==============================================================================
# Home Manager module for mpd.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
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
        
        # Playback Settings
        restore_paused "yes"
        auto_update "yes"
        
        # Performance Tuning
        audio_buffer_size "4096"
      '';
    };
  };
}
