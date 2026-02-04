# systems/x86_64-linux/hay/default.nix
# ==============================================================================
# HAY physical workstation: main NixOS host config.
# Imports hardware config; module imports handled via flake/Snowfall.
# Set host metadata and enable services/desktops below.
# ==============================================================================
{ pkgs, lib, inputs, config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    # Modules are now automatically imported by flake.nix via Snowfall Lib
  ];

  # ============================================================================
  # Host Metadata
  # ============================================================================
  my.host = {
    role           = "physical";
    isPhysicalHost = true;
    isVirtualHost  = false;
  };

  # Power profiles via power-profiles-daemon (powerprofilesctl).
  # (moved to modules/nixos/hosts/hay.nix)

  # Set User (Defaults to "kenan" but good to be explicit)
  my.user.name = "kenan";

  # ============================================================================
  # Host Identity
  # ============================================================================
  networking.hostName = "hay";

  # ============================================================================
  # Kernel & Hardware Tuning
  # ============================================================================
  my.kernel.tweaks.gpu = {
    useXeDriver = true;
    xeForceProbeId = "7d55";
  };

  # ============================================================================
  # Display Stack (Delegated to core/display)
  # ============================================================================
  my.display = {
    enable = true;
    enableHyprland = true;
    enableGnome    = true;
    enableNiri     = true;
    enableAudio    = true;

    fonts.enable         = true;
    fonts.hiDpiOptimized = true;

    keyboard = {
      layout  = "tr";
      variant = "f";
      options = [ "ctrl:nocaps" ];
    };

    autoLogin = {
      enable = false;
      # user = config.my.user.name; # Can use config variable here if enabled
    };
  };

  # ============================================================================
  # Greeter (DMS Greeter via greetd)
  # ============================================================================
  my.greeter.dms = {
    enable     = true;
    compositor = "hyprland";
    layout     = "tr";
    variant    = "f";
  };

  # ============================================================================
  # Graphics / Wayland
  # ============================================================================
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;
  };

  programs.xwayland.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL     = "1";
    MOZ_ENABLE_WAYLAND = "1";
  };

  # ============================================================================
  # Networking
  # ============================================================================
  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        backend            = "wpa_supplicant";
        scanRandMacAddress = true;
        macAddress         = "preserve";
        powersave          = false;
      };
    };

    wireless.enable = false;
    firewall = {
      allowPing           = false;
      logReversePathDrops = true;

      # KDE Connect (GSConnect-compatible) device pairing / sync
      allowedTCPPortRanges = [
        { from = 1714; to = 1764; }
      ];
      allowedUDPPortRanges = [
        { from = 1714; to = 1764; }
      ];
    };
  };

  # ============================================================================
  # Security
  # ============================================================================
  security.polkit.enable = true;

  # ============================================================================
  # Boot Loader (GRUB + EFI) — enable os-prober to detect the backup NixOS on sda
  # ============================================================================
  boot.loader.grub.useOSProber = false;

  # os-prober sometimes fails with "mkdir /var/lock/dmraid" — ensure the path exists
  systemd.tmpfiles.rules = [
    "d /var/lock/dmraid 0755 root root - -"
  ];

  # ============================================================================
  # System Services
  # ============================================================================
  services.flatpak.enable = true;
  my.oomd.enable = true;

  # ============================================================================
  # System Packages
  # ============================================================================
  environment.systemPackages = with pkgs; [
    lm_sensors powertop tldr
    networkmanager wireguard-tools
    gnupg openssl
  ];

  # ============================================================================
  # Programs (system-level)
  # ============================================================================
  programs = {
    gnupg.agent = {
      enable           = true;
      enableSSHSupport = true;
    };

    zsh.enable = true;

    tmux = {
      enable   = true;
      shortcut = "a";
      terminal = "screen-256color";
    };

    nm-applet.enable = true;
  };

  # ============================================================================
  # User Modules
  # ============================================================================
  # Home Manager configuration is now handled in:
  # homes/x86_64-linux/kenan@hay/default.nix

  # ============================================================================
  # System State Version
  # ============================================================================
  system.stateVersion = "25.11";
}
