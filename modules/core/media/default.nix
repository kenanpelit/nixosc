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

{ config, lib, pkgs, ... }:
{
 # =============================================================================
 # Audio & PipeWire Configuration
 # =============================================================================
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

 # =============================================================================
 # Bluetooth Configuration
 # =============================================================================
 hardware.bluetooth = {
   enable = true;        # Enable Bluetooth support
   powerOnBoot = true;   # Auto-start on boot
 };
 
 services.blueman.enable = true;  # Bluetooth management interface

 # =============================================================================
 # Required Packages
 # =============================================================================
 environment.systemPackages = with pkgs; [
   pulseaudioFull  # Full PulseAudio suite for compatibility
 ];
}
