# modules/core/media/audio/default.nix
# ==============================================================================
# Audio Configuration for ThinkPad E14 Gen 6
# ==============================================================================
# This configuration manages audio system settings including:
# - PipeWire sound server with modern Intel audio optimizations
# - ALSA support and ThinkPad ACPI configuration
# - PulseAudio compatibility layer
# - Real-time audio latency management
# - Intel Smart Sound Technology (SST) support
# - LED control for audio functions
#
# Target Hardware:
# - ThinkPad E14 Gen 6 (21M7006LTX)
# - Intel Meteor Lake-P HD Audio
# - SOF (Sound Open Firmware) audio driver
# - Integrated speakers and microphone array
#
# Author: Kenan Pelit
# Modified: 2025-05-23 (E14 Gen 6 optimization)
# ==============================================================================
{ pkgs, ... }:
{
  # Real-time Kit - Audio Latency Management
  # Essential for low-latency audio processing on modern hardware
  security.rtkit.enable = true;
  
  # Disable PulseAudio in favor of PipeWire
  # PipeWire provides better performance and modern audio routing
  services.pulseaudio.enable = false;
  
  # PipeWire Configuration
  # Optimized for Intel Meteor Lake-P audio hardware
  services.pipewire = {
    enable = true;
    
    # ALSA Support
    # Full ALSA compatibility for legacy applications
    alsa = {
      enable = true;
      support32Bit = true;    # Enable 32-bit application support for compatibility
    };
    
    # PulseAudio Compatibility Layer
    # Ensures compatibility with PulseAudio-based applications
    pulse.enable = true;
    
    # WirePlumber Session Manager
    # Modern session manager for audio routing and device management
    wireplumber.enable = true;
  };
  
  # ThinkPad E14 Gen 6 specific audio configurations
  boot.extraModprobeConfig = ''
    options snd-intel-dspcfg dsp_driver=1
    options snd-sof-pci-intel-mtl enable=1
    options snd-hda-intel model=thinkpad
    options snd-hda-intel position_fix=1
    options snd-hda-intel enable=yes
    options snd-hda-intel power_save=1
    options thinkpad_acpi volume_mode=1
    options thinkpad_acpi volume_capabilities=1
    options snd-sof sof_debug=0
    options snd-sof-intel-hda-common hda_model=thinkpad
  '';
  
  # Required Audio Packages
  # Comprehensive audio toolkit for E14 Gen 6
  environment.systemPackages = with pkgs; [
    pulseaudioFull    # Full PulseAudio suite for maximum compatibility
    alsa-utils        # ALSA utilities for debugging and configuration
    alsa-firmware     # Additional firmware for audio devices
    sof-firmware      # Sound Open Firmware for Intel audio
    pavucontrol       # Graphical PulseAudio volume control
    pamixer           # Command line mixer for PulseAudio/PipeWire
    pwvucontrol       # Native PipeWire volume control (modern alternative)
    helvum            # PipeWire patchbay for advanced audio routing
    qpwgraph          # Qt-based PipeWire graph manager
  ];
  
  # Hardware-specific optimizations
  # Ensure proper audio device detection and power management
  services.udev.extraRules = ''
    # ThinkPad E14 Gen 6 audio device optimizations
    SUBSYSTEM=="sound", ATTRS{id}=="PCH", ATTR{power/control}="auto"
    SUBSYSTEM=="sound", ATTRS{id}=="HDMI", ATTR{power/control}="auto"
  '';
}

