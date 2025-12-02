# systems/x86_64-linux/hay/default.nix
# ==============================================================================
# HAY Workstation: Main Host Configuration
# ==============================================================================
{ pkgs, lib, inputs, username, ... }:

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
      # user = username;
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
  # Time & Locale
  # ============================================================================
  time.timeZone = "Europe/Istanbul";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "tr_TR.UTF-8";
    LC_IDENTIFICATION = "tr_TR.UTF-8";
    LC_MEASUREMENT    = "tr_TR.UTF-8";
    LC_MONETARY       = "tr_TR.UTF-8";
    LC_NAME           = "tr_TR.UTF-8";
    LC_NUMERIC        = "tr_TR.UTF-8";
    LC_PAPER          = "tr_TR.UTF-8";
    LC_TELEPHONE      = "tr_TR.UTF-8";
    LC_TIME           = "tr_TR.UTF-8";
  };

  # ============================================================================
  # SSH / Security
  # ============================================================================
  services.openssh = {
    enable = true;
    ports  = [ 22 ];

    settings = {
      PasswordAuthentication = false;
      AllowUsers             = [ username ];
      PermitRootLogin        = "no";
    };
  };

  security.polkit.enable = true;

  # ============================================================================
  # System Services
  # ============================================================================
  services.flatpak.enable = true;

  # ============================================================================
  # System Packages
  # ============================================================================
  environment.systemPackages = with pkgs; [
    wget git tmux ncurses file sops age vim
    htop lm_sensors powertop tldr ripgrep fd
    networkmanager wireguard-tools
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

  # ============================================================================
  # System State Version
  # ============================================================================
  system.stateVersion = "25.11";
}
