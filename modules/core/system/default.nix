# modules/core/system/default.nix
# ==============================================================================
# NixOS System Configuration - Minimal with Battery Health
# ==============================================================================
#
# Module:    modules/core/system
# Version:   10.1 - Zero Intervention + Battery Health
# Date:      2025-10-10
#
# PHILOSOPHY:
# -----------
# "MINIMAL power management intervention - pure hardware control"
#
# This configuration is designed for modern laptops and follows a simple rule:
# Let the hardware and kernel handle power management. It avoids complex
# userspace daemons and scripts that can become brittle or conflict with
# modern hardware's own intelligent power-saving features.
#
# ✅ Basic system configuration (locale, timezone, keyboard)
# ✅ Hardware enablement (graphics, firmware, bluetooth)
# ✅ Standard boot configuration
# ✅ SELECTIVE ADDITION: A single, non-intrusive service for battery charge
#    thresholds to improve longevity. This is a feature the hardware/kernel
#    does not manage by default.
#
# ==============================================================================

{ pkgs, config, lib, inputs, system, ... }:

let
  # ============================================================================
  # SYSTEM IDENTIFICATION & HELPER FUNCTIONS
  # ============================================================================
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = hostname == "hay";
  isVirtualMachine  = hostname == "vhay";

  # Robust Script Helper for Systemd Services
  # This helper ensures that script output is properly logged to the system journal.
  # It's imported from the more complex configuration solely for the battery service.
  mkRobustScript = name: content: pkgs.writeShellScript name ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    exec 1> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.info)
    exec 2> >(${pkgs.util-linux}/bin/logger -t "power-mgmt-${name}" -p user.err)
    ${content}
  '';

in
{
  # ============================================================================
  # LOCALIZATION & TIMEZONE
  # ============================================================================
  time.timeZone = "Europe/Istanbul";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS        = "tr_TR.UTF-8";
      LC_IDENTIFICATION = "tr_TR.UTF-8";
      LC_MEASUREMENT    = "tr_TR.UTF-8";
      LC_MONETARY       = "tr_TR.UTF-8";
      LC_NAME           = "tr_TR.UTF-8";
      LC_NUMERIC        = "tr_TR.UTF-8";
      LC_PAPER          = "tr_TR.UTF-8";
      LC_TELEPHONE      = "tr_TR.UTF-8";
      LC_TIME           = "tr_TR.UTF-8";
      LC_MESSAGES       = "en_US.UTF-8";
    };
  };

  services.xserver.xkb = {
    layout  = "tr";
    variant = "f";
    options = "ctrl:nocaps";
  };

  console = {
    keyMap = "trf";
    font = "ter-v20b";
    packages = [ pkgs.terminus_font ];
  };

  system.stateVersion = "25.11";

  # ============================================================================
  # BOOT CONFIGURATION
  # ============================================================================
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [
      "coretemp"
      "i915"
    ] ++ lib.optionals isPhysicalMachine [
      "thinkpad_acpi"
    ];

    extraModprobeConfig = lib.optionalString isPhysicalMachine ''
      options thinkpad_acpi fan_control=1 experimental=1
    '';

    # Minimal kernel parameters - no power management interference.
    # We let the kernel use its defaults for p-state and governors.
    kernelParams = [
      "i915.enable_guc=3"
      "i915.enable_fbc=1"
      "mem_sleep_default=s2idle"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 60;
      "kernel.nmi_watchdog" = 0;
    };

    loader = {
      grub = {
        enable = true;
        device = lib.mkForce (if isVirtualMachine then "/dev/vda" else "nodev");
        efiSupport = isPhysicalMachine;
        useOSProber = true;
        configurationLimit = 10;
        gfxmodeEfi  = "1920x1200";
        gfxmodeBios = if isVirtualMachine then "1920x1080" else "1920x1200";
        theme = inputs.distro-grub-themes.packages.${system}.nixos-grub-theme;
      };

      efi = lib.mkIf isPhysicalMachine {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
  };

  # ============================================================================
  # HARDWARE CONFIGURATION
  # ============================================================================
  hardware = {
    trackpoint = lib.mkIf isPhysicalMachine {
      enable = true;
      speed = 200;
      sensitivity = 200;
      emulateWheel = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        intel-media-driver
        mesa
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime
      ];

      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
      ];
    };

    enableRedistributableFirmware = true;
    enableAllFirmware             = true;
    cpu.intel.updateMicrocode     = true;
    bluetooth.enable              = true;
  };

  # ============================================================================
  # POWER MANAGEMENT - MINIMAL INTERVENTION
  # ============================================================================
  # All common power management daemons are explicitly disabled.
  # The system relies on the Linux kernel and modern hardware firmware
  # (e.g., Intel P-State in `active` mode with the `schedutil` governor)
  # for efficient power management. This is the most reliable and
  # maintenance-free approach for modern hardware.
  services.auto-cpufreq.enable          = false;
  services.power-profiles-daemon.enable = false;
  services.tlp.enable                   = false;
  services.thermald.enable              = false;
  services.thinkfan.enable              = false;

  # ============================================================================
  # BATTERY HEALTH MANAGEMENT (SELECTIVE ADDITION)
  # ============================================================================
  # This is the ONLY active power-related service in this configuration.
  # It sets the battery charge thresholds to 75-80% to prolong battery
  # lifespan, a feature not handled by the kernel or BIOS automatically.
  # It is a 'oneshot' service that runs once at boot and then exits,
  # causing no background load or performance impact.
  systemd.services.battery-thresholds = lib.mkIf isPhysicalMachine {
    description = "Set battery charge thresholds (75-80%) for longevity";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "30s";
      StartLimitBurst = 3;
      ExecStart = mkRobustScript "set-battery-thresholds" ''
        echo "Configuring battery charge thresholds..."

        SUCCESS=0
        for bat in /sys/class/power_supply/BAT*; do
          [[ ! -d "$bat" ]] && continue

          BAT_NAME=$(basename "$bat")

          if [[ -w "$bat/charge_control_start_threshold" ]]; then
            echo 75 > "$bat/charge_control_start_threshold" 2>/dev/null && \
            echo "  $BAT_NAME: start threshold set to 75%" && SUCCESS=1 || \
            echo "  $BAT_NAME: failed to set start threshold" >&2
          fi

          if [[ -w "$bat/charge_control_end_threshold" ]]; then
            echo 80 > "$bat/charge_control_end_threshold" 2>/dev/null && \
            echo "  $BAT_NAME: stop threshold set to 80%" && SUCCESS=1 || \
            echo "  $BAT_NAME: failed to set stop threshold" >&2
          fi
        done

        if [[ "$SUCCESS" == "1" ]]; then
          echo "✓ Battery thresholds successfully configured: 75-80%"
        else
          echo "⚠ No writable battery threshold interface found." >&2
          # We don't exit with 1, as this is not a critical failure on all systems.
          exit 0
        fi
      '';
    };
  };

  # ============================================================================
  # SYSTEM SERVICES
  # ============================================================================
  services = {
    upower.enable = true;

    logind.settings.Login = {
      HandleLidSwitch              = "suspend";
      HandleLidSwitchDocked        = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandlePowerKey               = "ignore";
      HandlePowerKeyLongPress      = "poweroff";
      HandleSuspendKey             = "suspend";
      HandleHibernateKey           = "hibernate";
    };

    spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
  };
}
