# systems/x86_64-linux/hay/default.nix
# ==============================================================================
# HAY Workstation: Main Host Configuration
# ==============================================================================
{ pkgs, lib, inputs, config, ... }:

{
  imports = [
    ./hardware-configuration.nix
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

  # Set User (Defaults to "kenan" but good to be explicit)
  my.user.name = "kenan";

  # ============================================================================
  # Host Identity
  # ============================================================================
  networking.hostName = "hay";

  # ============================================================================
  # Display Stack (Delegated to core/display)
  # ============================================================================
  my.display = {
    enable = true;
    enableHyprland = true;
    enableGnome    = true;
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
    };
  };

  # ============================================================================
  # Security
  # ============================================================================
  security.polkit.enable = true;

  # ============================================================================
  # System Services
  # ============================================================================
  services.flatpak.enable = true;

  # ============================================================================
  # System Packages
  # ============================================================================
  environment.systemPackages = with pkgs; [
    lm_sensors powertop tldr
    networkmanager wireguard-tools
    gnupg openssl
  ];

  # ============================================================================
  # ZRAM Swap
  # ============================================================================
  zramSwap = {
    enable        = true;
    algorithm     = "zstd";
    memoryPercent = 30;
  };

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

  # DankGreeter (system-level)
  programs.dankMaterialShell.greeter = {
    enable = true;
    compositor = {
      name = "hyprland";
      customConfig = "";
    };
    configHome = "/home/${config.my.user.name}";
    configFiles = [ "/home/${config.my.user.name}/.config/DankMaterialShell/settings.json" ];
    logs = {
      save = true;
      path = "/var/log/dms-greeter.log";
    };
    quickshell.package = pkgs.quickshell;
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
