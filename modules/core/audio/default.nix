# modules/core/audio/default.nix
# ==============================================================================
# Audio Configuration for ThinkPad X1 Carbon Gen 6 & E14 Gen 6
# ==============================================================================
# This configuration manages audio system settings optimized for:
# - ThinkPad X1 Carbon 6th Gen (8th Gen Intel Core i7-8650U)
# - ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H - Meteor Lake)
#
# Features:
# - PipeWire sound server with Intel audio optimizations
# - Dynamic configuration based on CPU generation
# - ALSA support with ThinkPad-specific ACPI settings
# - PulseAudio compatibility layer
# - Real-time audio latency management
# - Intel Smart Sound Technology (SST) support for Meteor Lake
# - Legacy HD Audio support for Kaby Lake Refresh
#
# Author: Kenan Pelit
# Modified: 2025-01-28 (Dual system optimization)
# ==============================================================================
{ config, lib, pkgs, ... }:

let
  # CPU detection helpers
  cpuInfo = builtins.readFile "/proc/cpuinfo";
  
  # Check for Meteor Lake (E14 Gen 6 - Core Ultra 7 155H)
  isMeteorLake = lib.strings.hasInfix "Core Ultra" cpuInfo ||
                 lib.strings.hasInfix "155H" cpuInfo;
  
  # Check for Kaby Lake Refresh (X1 Carbon Gen 6 - i7-8650U)
  isKabyLakeR = lib.strings.hasInfix "8650U" cpuInfo ||
                lib.strings.hasInfix "8550U" cpuInfo ||
                lib.strings.hasInfix "8250U" cpuInfo;

  # System-specific module configurations
  audioModuleConfig = if isMeteorLake then ''
    # Meteor Lake (E14 Gen 6) - SOF firmware with DSP
    options snd-intel-dspcfg dsp_driver=1
    options snd-sof-pci-intel-mtl enable=1
    options snd-sof sof_debug=0
    options snd-sof-intel-hda-common hda_model=thinkpad
    
    # HD Audio configuration
    options snd-hda-intel model=thinkpad
    options snd-hda-intel position_fix=1
    options snd-hda-intel enable=yes
    options snd-hda-intel power_save=1
    options snd-hda-intel power_save_controller=Y
    
    # ThinkPad ACPI volume controls
    options thinkpad_acpi volume_mode=1
    options thinkpad_acpi volume_capabilities=1
    options thinkpad_acpi fan_control=1
  '' else if isKabyLakeR then ''
    # Kaby Lake Refresh (X1 Carbon Gen 6) - Legacy HD Audio
    options snd-hda-intel model=thinkpad
    options snd-hda-intel position_fix=1
    options snd-hda-intel enable=yes
    options snd-hda-intel power_save=10
    options snd-hda-intel power_save_controller=Y
    options snd-hda-intel probe_mask=1
    options snd-hda-intel probe_only=0
    options snd-hda-intel index=0
    
    # ThinkPad ACPI for X1 Carbon
    options thinkpad_acpi volume_mode=1
    options thinkpad_acpi volume_capabilities=1
    options thinkpad_acpi fan_control=1
    options thinkpad_acpi experimental=1
    
    # PCH audio optimizations for 8th Gen
    options snd-hda-codec-realtek power_save_node=1
  '' else ''
    # Generic ThinkPad configuration
    options snd-hda-intel model=thinkpad
    options snd-hda-intel position_fix=1
    options snd-hda-intel enable=yes
    options snd-hda-intel power_save=1
    options thinkpad_acpi volume_mode=1
  '';

  # PipeWire configuration optimizations
  pipewireConfig = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.quantum" = if isMeteorLake then 256 else 512;
      "default.clock.min-quantum" = if isMeteorLake then 128 else 256;
      "default.clock.max-quantum" = 2048;
    };
    
    "context.modules" = [
      {
        name = "libpipewire-module-rtkit";
        args = {
          "nice.level" = -15;
          "rt.prio" = 88;
          "rt.time.soft" = 200000;
          "rt.time.hard" = 200000;
        };
      }
      {
        name = "libpipewire-module-protocol-pulse";
        args = { };
      }
    ];
  };

  # WirePlumber configuration
  wireplumberConfig = ''
    monitor.alsa.rules = [
      {
        matches = [
          { node.name = "~alsa_output.*" }
        ]
        actions = {
          update-props = {
            session.suspend-timeout-seconds = 5
            api.alsa.period-size = ${if isMeteorLake then "256" else "512"}
            api.alsa.period-num = 2
            api.alsa.headroom = ${if isMeteorLake then "256" else "512"}
            resample.quality = 4
          }
        }
      }
    ]
  '';

in
{
  # Core audio services
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
    
    config.pipewire = pipewireConfig;
  };
  
  # Kernel module configuration
  boot.extraModprobeConfig = audioModuleConfig;
  
  # Kernel parameters for audio optimization
  boot.kernelParams = [
    "snd_hda_intel.power_save=1"
  ] ++ lib.optionals isMeteorLake [
    "snd_sof.sof_debug=0"
    "snd_intel_dspcfg.dsp_driver=1"
  ] ++ lib.optionals isKabyLakeR [
    "snd_hda_codec_realtek.power_save_node=1"
    "intel_pstate=active"
  ];
  
  # Audio packages
  environment.systemPackages = with pkgs; [
    # Core audio tools
    pulseaudioFull
    alsa-utils
    alsa-firmware
    
    # GUI tools
    pavucontrol
    pamixer
    pwvucontrol
    helvum
    qpwgraph
    
    # System-specific firmware
  ] ++ lib.optionals isMeteorLake [
    sof-firmware
    alsa-ucm-conf
  ] ++ lib.optionals isKabyLakeR [
    alsa-plugins
    alsa-tools
  ];
  
  # UDEV rules for power management
  services.udev.extraRules = ''
    # Intel HD Audio power management
    SUBSYSTEM=="sound", ATTRS{id}=="PCH", ATTR{power/control}="auto"
    SUBSYSTEM=="sound", ATTRS{id}=="HDMI", ATTR{power/control}="auto"
    
    # ThinkPad-specific audio device permissions
    SUBSYSTEM=="sound", GROUP="audio", MODE="0660"
    
    ${lib.optionalString isMeteorLake ''
    # Meteor Lake SOF firmware loading
    ACTION=="add", SUBSYSTEM=="firmware", ATTR{loading}="-1"
    ''}
    
    ${lib.optionalString isKabyLakeR ''
    # X1 Carbon Gen 6 microphone LED control
    KERNEL=="*::micmute", SUBSYSTEM=="leds", MODE="0660", GROUP="audio"
    ''}
    
    # Real-time scheduling for audio group
    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
  '';
  
  # WirePlumber configuration
  environment.etc."wireplumber/main.lua.d/51-thinkpad.lua".text = wireplumberConfig;
  
  # System-specific optimizations
  systemd.services.audio-optimization = {
    description = "Audio optimization for ThinkPad";
    after = [ "sound.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    
    script = ''
      # Set CPU governor for better audio performance
      ${lib.optionalString isKabyLakeR ''
        echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
      ''}
      
      ${lib.optionalString isMeteorLake ''
        echo balanced_performance > /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference 2>/dev/null || true
      ''}
      
      # Configure audio device latency
      if [ -d /sys/module/snd_hda_intel/parameters ]; then
        echo 1 > /sys/module/snd_hda_intel/parameters/power_save 2>/dev/null || true
      fi
      
      # ThinkPad-specific optimizations
      if [ -d /proc/acpi/ibm ]; then
        echo 1 > /proc/acpi/ibm/volume 2>/dev/null || true
      fi
    '';
  };
  
  # Hardware configuration assertions
  assertions = [
    {
      assertion = config.hardware.pulseaudio.enable == false;
      message = "PulseAudio must be disabled when using PipeWire";
    }
  ];
  
  # Performance tweaks
  powerManagement.cpuFreqGovernor = lib.mkDefault (
    if isMeteorLake then "powersave"
    else if isKabyLakeR then "performance"
    else "ondemand"
  );
}

# ==============================================================================
# Supported Systems:
# - ThinkPad X1 Carbon 6th Gen (Intel Core i7-8650U, 16GB RAM)
#   * Kaby Lake Refresh architecture
#   * Realtek ALC285 codec
#   * Legacy HD Audio with enhanced power management
#
# - ThinkPad E14 Gen 6 (Intel Core Ultra 7 155H, 64GB RAM)
#   * Meteor Lake-P architecture  
#   * SOF (Sound Open Firmware) support
#   * Intel Smart Sound Technology with DSP
# ==============================================================================
