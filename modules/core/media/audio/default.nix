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
  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  
  services.pipewire = {
    enable = true;
    
    alsa = {
      enable = true;
      support32Bit = true;
    };
    
    pulse.enable = true;
    wireplumber.enable = true;
  };
  
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
  
  environment.systemPackages = with pkgs; [
    pulseaudioFull
    alsa-utils
    alsa-firmware
    sof-firmware
    pavucontrol
    pamixer
    pwvucontrol
    helvum
    qpwgraph
  ];
  
  services.udev.extraRules = ''
    SUBSYSTEM=="sound", ATTRS{id}=="PCH", ATTR{power/control}="auto"
    SUBSYSTEM=="sound", ATTRS{id}=="HDMI", ATTR{power/control}="auto"
  '';
}
