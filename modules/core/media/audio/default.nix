# modules/core/media/audio/default.nix
# ==============================================================================
# Audio Configuration for ThinkPad X1 Carbon 6th
# ==============================================================================
# This configuration manages audio system settings including:
# - PipeWire sound server with ThinkPad-specific optimizations
# - ALSA support and ThinkPad ACPI configuration
# - PulseAudio compatibility layer
# - Real-time audio latency management
# - LED control for audio functions
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
  };

  # ThinkPad-specific audio configurations
  boot.extraModprobeConfig = ''
    # ThinkPad-specific ALSA configurations
    options snd-hda-intel model=thinkpad
    options snd-hda-intel position_fix=1
    options snd-hda-intel enable=yes
    # ThinkPad ACPI sound control
    options thinkpad_acpi volume_mode=enable
    options thinkpad_acpi volume_capabilities=1
  '';

  # Required Audio Packages
  environment.systemPackages = with pkgs; [
    pulseaudioFull  # Full PulseAudio suite for compatibility
    alsa-utils      # ALSA utilities for debugging
    pavucontrol     # PulseAudio volume control
    pamixer         # Command line mixer for PulseAudio
  ];
}

