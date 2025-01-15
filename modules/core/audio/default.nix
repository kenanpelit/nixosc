# modules/core/audio/default.nix
# ==============================================================================
# Audio System Configuration
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:

{
 # =============================================================================
 # Real-time Kit - Audio Latency Management
 # =============================================================================
 security.rtkit.enable = true;

 # =============================================================================
 # PipeWire Audio Server Configuration
 # =============================================================================
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
 };
}
