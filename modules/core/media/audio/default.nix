# modules/core/media/audio/default.nix
# ==============================================================================
# Audio Configuration
# ==============================================================================
# This configuration manages audio system settings including:
# - PipeWire sound server
# - ALSA support and configuration
# - PulseAudio compatibility layer
# - Real-time audio latency management
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, ... }:
{
  # Real-time Kit - Audio Latency Management
  security.rtkit.enable = true;
  
  # Disable PulseAudio in favor of PipeWire
  services.pulseaudio.enable = false;
  
  # PipeWire Configuration
  services.pipewire = {
    enable = true;
    
    # ALSA Support
    alsa = {
      enable = true;
      support32Bit = true;    # Enable 32-bit application support
    };
    
    # PulseAudio Compatibility Layer
    pulse.enable = true;
    
    # WirePlumber Session Manager
    wireplumber.enable = true;
    
    # Low Latency Mode (currently disabled)
    # lowLatency.enable = true;
  };

  # Required Audio Packages
  environment.systemPackages = with pkgs; [
    pulseaudioFull  # Full PulseAudio suite for compatibility
  ];
}
