# modules/core/pipewire/default.nix
# ==============================================================================
# PipeWire Audio Configuration
# ==============================================================================
{ pkgs, ... }:
{
  # =============================================================================
  # Service Configuration
  # =============================================================================
  # Disable PulseAudio
  services.pulseaudio.enable = false;

  # PipeWire Configuration
  services.pipewire = {
    enable = true;
    
    # ALSA Configuration
    alsa = {
      enable = true;
      support32Bit = true;
    };
    
    # PulseAudio Compatibility
    pulse.enable = true;
    
    # Low Latency Mode (currently disabled)
    # lowLatency.enable = true;
  };

  # =============================================================================
  # Required Packages
  # =============================================================================
  environment.systemPackages = with pkgs; [
    pulseaudioFull  # Full PulseAudio suite for compatibility
  ];
}
