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
  # (Çekirdek/power tarafı modules/core/system altında; burada sadece boot politikası)
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
  # Burada sadece high-level tercihleri söylüyoruz; implementasyon core/display’de.
  my.display = {
    enable = true;

    # Desktop / WM seçimleri
    enableHyprland = true;
    enableGnome    = true;
    enableCosmic   = true;

    # Ses
    enableAudio = true;

    # Font stack
    fonts.enable         = true;
    fonts.hiDpiOptimized = true;

    # Klavye (TR-F + Caps→Ctrl)
    keyboard = {
      layout  = "tr";
      variant = "f";
      options = [ "ctrl:nocaps" ];
    };

    # GDM auto-login (şu an kapalı, istersen user = username ile açarsın)
    autoLogin = {
      enable = false;
      # user = username;
    };
  };

  # ============================================================================
  # Graphics / Wayland
  # (Detaylı GPU/power tuning modules/core/system altında)
  # ============================================================================
  hardware.graphics = {
    enable      = true;
    enable32Bit = true;  # Steam / 32-bit oyunlar için
  };

  programs.xwayland.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL     = "1";  # Electron / Chromium için Wayland
    MOZ_ENABLE_WAYLAND = "1";  # Firefox için Wayland
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

      # ÖNEMLİ NOT:
      # Daha önce buraya statik IP profilleri (connectionConfig) yazıyorduk.
      # Bu opsiyon INI key/value bekliyor; attrset verdiğin için build patlıyordu.
      # Evde tek modem + tek makine senaryosunda:
      #   - Statik IP’yi modemde MAC-based DHCP reservation ile çözmek,
      #   - NetworkManager tarafını DHCP’de bırakmak çok daha temiz.
      #
      # Eğer ileride gerçekten deklaratif NM profili yazmak istersen,
      # networking.networkmanager.ensureProfiles yoluna gitmek daha doğru.
    };

    wireless.enable = false;  # Eski wireless.* arayüzünü kapalı tut
    firewall = {
      allowPing           = false;
      logReversePathDrops = true;
    };
  };

  # ============================================================================
  # Time & Locale
  # (core/system ile aynı değerlere sahip; merge ederken tutarlı kalıyor)
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
      PasswordAuthentication = true;   # Konforlu ama zayıf halka burada
      AllowUsers             = [ username ];
      PermitRootLogin        = "yes";  # Gerçek hayatta "no" ya da "prohibit-password" olmalı
    };
  };

  security.polkit.enable = true;

  # ============================================================================
  # System Services
  # ============================================================================
  services.flatpak.enable = true;
  # DBus, portals vs. core/display modülünde düzgün şekilde ele alınıyor.

  # ============================================================================
  # System Packages
  # (Power / CPU tools core/system altında; burada genel günlük araçlar)
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

    # NetworkManager için GUI applet
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
