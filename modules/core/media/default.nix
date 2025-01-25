# modules/core/media/default.nix
# ==============================================================================
# Media System Configuration
# ==============================================================================
# This configuration file manages all media-related settings including audio,
# PipeWire, and Bluetooth functionality. It provides a unified approach to
# handling sound systems and wireless connectivity for media devices.
#
# Key components:
# - Audio system configuration with PipeWire as the main sound server
# - ALSA and PulseAudio compatibility layers
# - Bluetooth connectivity and management
# - Real-time kit for audio latency optimization
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  imports = [
    ./audio
    ./bluetooth
  ];
}
