# hosts/hay/default.nix
# ==============================================================================
# HAY - NixOS Host Configuration
# Main system configuration for the "hay" workstation
# ==============================================================================
{ pkgs, lib, inputs, username, ... }:

{
  # ============================================================================
  # Imports
  # ============================================================================
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
  ];

  # ============================================================================
  # Host Identity
  # ============================================================================
  networking.hostName = "hay";

  # ============================================================================
  # Boot Loader
  # (Kernel/power side is under modules/core/system; here only boot policy)
  # ============================================================================
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;

    grub = {
      enable           = true;
      device           = "nodev";
      useOSProber      = true;
      efiSupport       = true;
      configurationLimit = 10;
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint     = "/boot";
    };
  };

  # ============================================================================
  # Display Stack (delegated to modules/core/display)
  # ============================================================================
  # Here we only state high-level preferences; implementation is in core/display.
  my.display = {
    enable = true;

    # Desktop / WM selections
    enableHyprland = true;
    enableGnome    = true;
    enableCosmic   = true;

    # Audio
    enableAudio = true;

    # Font stack
    fonts.enable         = true;
    fonts.hiDpiOptimized = true;

    # Keyboard (TR-F + Caps->Ctrl)
    keyboard = {
      layout  = "tr";
      variant = "f";
      options = [ "ctrl:nocaps" ];
    };

    # GDM auto-login (currently disabled, uncomment user = username to enable)
    autoLogin = {
      enable = false;
      # user = username;
    };
  };

  # ============================================================================
  # Graphics / Wayland
  # (Detailed GPU/power tuning is under modules/core/system)
  # ============================================================================
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;  # For Steam / 32-bit games
  };

  programs.xwayland.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL     = "1";  # For Electron / Chromium Wayland support
    MOZ_ENABLE_WAYLAND = "1";  # For Firefox Wayland support
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

      # IMPORTANT NOTE:
      # Previously static IP profiles (connectionConfig) were here.
      # This option expects INI key/value; passing attrset caused build failure.
      # In a single modem + single machine scenario:
      #   - Solve static IP via MAC-based DHCP reservation on modem,
      #   - Keeping NetworkManager on DHCP is much cleaner.
      #
      # If you really want declarative NM profiles in the future,
      # networking.networkmanager.ensureProfiles is the better way.
    };

    wireless.enable = false;  # Keep old wireless.* interface disabled
    firewall = {
      allowPing           = false;
      logReversePathDrops = true;
    };
  };

  # ============================================================================
  # Time & Locale
  # (Same values as core/system; remains consistent when merged)
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
      PasswordAuthentication = true;   # Convenient but weak link here
      AllowUsers             = [ username ];
      PermitRootLogin        = "yes";  # In real life should be "no" or "prohibit-password"
    };
  };

  security.polkit.enable = true;

  # ============================================================================
  # System Services
  # ============================================================================
  services.flatpak.enable = true;
  # DBus, portals etc. are handled properly in core/display module.

  # ============================================================================
  # System Packages
  # (Power / CPU tools are under core/system; here general daily tools)
  # ============================================================================
  environment.systemPackages = with pkgs; [
    # Core tools
    wget git tmux ncurses file sops age vim

    # Monitoring / utils
    htop lm_sensors powertop tldr ripgrep fd

    # Networking helpers
    networkmanager
    wireguard-tools
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

    # GUI applet for NetworkManager
    nm-applet.enable = true;
  };

  # ============================================================================
  # Nixpkgs / Licensing
  # ============================================================================
  nixpkgs.config = {
    allowUnfree = true;

    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "spotify"
      ];
  };

  # ============================================================================
  # System State Version
  # ============================================================================
  system.stateVersion = "25.11";
}