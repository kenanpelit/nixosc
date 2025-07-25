# modules/core/hardware/default.nix
# ==============================================================================
# Hardware Configuration for ThinkPad E14 Gen 6
# ==============================================================================
# This configuration manages hardware settings including:
# - ThinkPad-specific ACPI and power management
# - Intel Arc Graphics drivers and hardware acceleration
# - NVMe storage optimizations for dual-drive setup
# - Intel Core Ultra 7 155H CPU configuration
# - LED control and function key management
# - TrackPoint and touchpad configuration
#
# Target Hardware:
# - ThinkPad E14 Gen 6 (21M7006LTX)
# - Intel Core Ultra 7 155H (16-core hybrid architecture)
# - Intel Arc Graphics (Meteor Lake-P)
# - 64GB DDR5 RAM
# - Dual NVMe setup: Transcend TS2TMTE400S + Timetec 35TT2280GEN4E-2TB
#
# Author: Kenan Pelit
# Modified: 2025-05-23 (E14 Gen 6 optimization)
# ==============================================================================
{ pkgs, ... }:
{
  hardware = {
    trackpoint.enable = true;
    
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiVdpau
        libvdpau-va-gl
        mesa
        intel-compute-runtime
        intel-ocl
      ];
    };
    
    enableRedistributableFirmware = true;
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = true;
  };
  
  services = {
    throttled.enable = true;
    
    tlp = {
      enable = false;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        START_CHARGE_THRESH_BAT0 = 70;
        STOP_CHARGE_THRESH_BAT0 = 85;
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";
        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";
      };
    };
  };
  
  boot = {
    kernelModules = [ "thinkpad_acpi" ];
    
    extraModprobeConfig = ''
      options thinkpad_acpi fan_control=1
      options thinkpad_acpi brightness_mode=1
      options thinkpad_acpi volume_mode=1
    '';
    
    kernelParams = [
      "nvme.noacpi=1"
      "intel_iommu=on"
    ];
  };
  
  environment.systemPackages = with pkgs; [
    linux-firmware
    wireless-regdb
    firmware-updater
    lm_sensors
    acpi
    powertop
    s-tui
    thinkfan
    nvme-cli
    intel-gpu-tools
  ];

  # LED and hotkey management for E14 Gen 6
  services.udev.extraRules = ''
    # Fix microphone LED permissions and initial state
    SUBSYSTEM=="leds", KERNEL=="platform::micmute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::micmute/brightness"
    SUBSYSTEM=="leds", KERNEL=="platform::mute", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod 666 /sys/class/leds/platform::mute/brightness"
  '';

  # Service to fix LED state on boot
  systemd.services.fix-led-state = {
    description = "Fix ThinkPad LED states on boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "fix-leds" ''
        # Set LED triggers for proper audio integration
        echo "audio-micmute" > /sys/class/leds/platform::micmute/trigger || true
        echo "audio-mute" > /sys/class/leds/platform::mute/trigger || true
        
        # Reset LED states
        echo 0 > /sys/class/leds/platform::micmute/brightness || true
        echo 0 > /sys/class/leds/platform::mute/brightness || true
      '';
      RemainAfterExit = true;
    };
  };
}

