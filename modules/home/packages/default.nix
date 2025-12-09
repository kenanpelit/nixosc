# modules/user-modules/packages/default.nix
# ==============================================================================
# User Package Installation
# ==============================================================================
# Comprehensive set of user-level applications and tools.
# Organized by function for clarity.
# ==============================================================================

{ pkgs, lib, inputs, config, ... }:

let
  cfg = config.my.user.packages;
  # Custom Python Environment
  customPython = pkgs.python3.withPackages (ps: with ps; [
    ipython libtmux pip pipx
  ]);
in
{
  options.my.user.packages = {
    enable = lib.mkEnableOption "user packages";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # -- Custom Fonts ----------------------------------------------------------
      maple-mono.NF
      maple-mono.truetype
  
      # -- File Management -------------------------------------------------------
      yazi                  # Modern terminal file manager (via alias 'yy')
      lf                    # Lightweight terminal file manager
      eza                   # Modern 'ls' alternative
      lsd                   # Colorful 'ls' alternative
      fd                    # Fast 'find' alternative
      ripgrep               # Fast 'grep' alternative (rg)
      fzf                   # Command-line fuzzy finder
      zoxide                # Smarter 'cd' command
      bat                   # Cat clone with syntax highlighting
      duf                   # Disk usage utility (better df)
      ncdu                  # Disk usage analyzer (interactive)
      gtrash trash-cli      # Trash management
      unzip p7zip atool     # Archive management
      rsync lftp            # File transfer
      nemo                  # File manager
      tree                  # Directory tree viewer
      czkawka fdupes        # Duplicate file finders
      detox                 # Filename sanitizer
      mlocate               # Fast file locator
  
      # -- Development Tools -----------------------------------------------------
      git lazygit gh tig    # Version control stack
      direnv                # Environment switcher
      gnumake gcc           # Basic build tools
      jq yq                 # JSON/YAML processors
      
      # Language Tools
      go_1_25 customPython
      lua-language-server stylua
      nixd nil nixfmt-rfc-style
      shellcheck shfmt
      treefmt inputs.alejandra.defaultPackage.${pkgs.stdenv.hostPlatform.system}
      
      # Debugging & Analysis
      gdb strace lsof
      hexdump xxd binsider bitwise
      programmer-calculator
  
      # Nix Utilities
      nvd cachix nix-output-monitor nix-search-tv
  
      # -- Terminal Utilities ----------------------------------------------------
      tmux wezterm foot     # Terminal multiplexer & emulators
      starship              # Cross-shell prompt
      fastfetch neofetch    # System info
      htop btop procs       # Process viewers
      tldr                  # Simplified man pages
      killall               # Process killer
      wl-clipboard clipse   # Clipboard tools
      wtype                 # Wayland key typer for scripts/gestures
      libnotify             # Notification tools
      translate-shell       # Translator
      
      # -- Network Tools ---------------------------------------------------------
      curl wget aria2       # Downloaders
      transmission_4        # Transmission suite (includes transmission-remote CLI)
      pirate-get            # Pirate Bay magnet search/download helper
      dig                   # DNS tools
      nmap mtr iputils fping # Network diagnostics
      iftop iptraf-ng       # Traffic monitoring
      speedtest-cli iperf   # Speed testing
      tcpdump               # Packet analyzer
      
      # Remote Access
      openssh assh pssh     # SSH tools
      tigervnc anydesk      # Remote desktop
      
      # VPN
      openvpn openconnect openfortivpn
      mullvad mullvad-closest wireguard-tools
  
      # -- Media & Audio ---------------------------------------------------------
      mpv vlc               # Video players
      imv qview             # Image viewers
      ffmpeg imagemagick    # Media processing
      yt-dlp pipe-viewer    # YouTube tools
      spotify spotify-cli-linux # Music streaming
      easyeffects           # PipeWire audio effects
      mpc                   # MPD client
      pavucontrol playerctl # Audio control
      
      # Screenshot/Recording
      grim slurp            # Wayland screenshot
      wf-recorder           # Screen recorder
      swappy satty          # Screenshot editing
      inputs.hypr-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
  
      # -- Desktop & Productivity ------------------------------------------------
      libreoffice           # Office suite
      obsidian              # Note taking
      zathura evince        # PDF viewers
      qalculate-gtk         # Calculator
      
      # Communication
      discord webcord-vencord
      catppuccin-discord
      ferdium               # Multi-messenger
      
      # Launchers
      rofi ulauncher        # App launchers
  
      # Security
      keepassxc gopass      # Password managers
      ente-auth             # 2FA
      age sops              # Encryption
      pwgen                 # Password generator
  
      # -- Hyprland & Wayland ----------------------------------------------------
      hyprlock hypridle     # Lock & Idle
      hyprpaper wpaperd     # Wallpaper
      #mako                  # Notifications
      brightnessctl         # Brightness control
      wl-gammactl           # Gamma control
      gnome-monitor-config  # Display layout manager
      hyprpicker            # Color picker
      
      # -- Browsers --------------------------------------------------------------
      browsh lynx w3m       # Text browsers
      
      # -- Fun & Misc ------------------------------------------------------------
      cmatrix pipes cbonsai # Terminal candy
      figlet toilet         # ASCII art
      tty-clock             # Clock
      ytfzf                 # Terminal YouTube
      localsend             # File sharing
      ventoy                # Bootable USB tool
      gparted               # Partition manager
    ];
  };
}
