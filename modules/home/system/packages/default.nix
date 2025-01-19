# modules/home/packages/default.nix
# ==============================================================================
# Home Environment Package Configuration
# ==============================================================================
{ inputs, pkgs, ... }:
{
 home.packages = with pkgs; [
   # =============================================================================
   # File Management and Navigation
   # =============================================================================
   caligula       # Advanced file manager
   duf            # Disk usage analyzer
   eza            # Modern ls alternative
   fd             # Fast file finder
   file           # File type identifier
   gtrash         # GNOME trash manager
   lsd            # Modern ls with colors
   ncdu           # NCurses disk usage
   tree           # Directory tree viewer
   trash-cli      # Trash management CLI
   unzip          # Archive extractor
   
   # =============================================================================
   # Development Tools
   # =============================================================================
   binsider               # Binary analysis
   bitwise                # Bit manipulation
   hexdump                # Hex viewer
   lazygit                # Git TUI
   lua-language-server    # Lua LSP
   nixd                   # Nix language server
   nixfmt-rfc-style       # Nix formatter
   nil                    # Nix tooling
   programmer-calculator  # Dev calculator
   shellcheck             # Shell linter
   shfmt                  # Shell formatter
   stylua                 # Lua formatter
   tree-sitter            # Parser generator
   treefmt2               # Multi-language formatter
   xxd                    # Hex editor
   inputs.alejandra.defaultPackage.${pkgs.system} # Nix formatter

   # =============================================================================
   # Terminal Utilities
   # =============================================================================
   bc              # Calculator
   docfd           # Doc searcher
   entr            # File watcher
   jq              # JSON processor
   killall         # Process killer
   mimeo           # MIME handler
   most            # Pager
   ripgrep         # Fast grep
   sesh            # Session manager
   tldr            # Simplified man
   wezterm         # Terminal emulator
   zoxide          # Smart cd
   wl-clipboard    # Wayland clipboard
   bat             # Cat clone
   detox           # Filename cleaner
   pv              # Pipe viewer
   gist            # Upload code

   # =============================================================================
   # Media Tools
   # =============================================================================
   ani-cli         # Anime streaming
   ffmpeg          # Media converter
   gifsicle        # GIF editor
   imv             # Image viewer
   qview           # Image viewer
   mpv             # Media player
   pamixer         # Audio mixer
   pavucontrol     # Audio control
   playerctl       # Media controller
   satty           # Screenshot tool
   soundwireserver # Audio streaming
   swappy          # Screenshot editor
   tdf             # Terminal file manager
   vlc             # Media player
   yt-dlp          # Video downloader

   # =============================================================================
   # System Monitoring and Diagnostics
   # =============================================================================
   atop            # System monitor
   cpulimit        # CPU limiter
   dstat           # Stats collector
   glances         # System monitor
   iotop           # I/O monitor
   lshw            # Hardware lister
   lsof            # Open files lister
   nmon            # Performance monitor
   pciutils        # PCI utilities
   strace          # System call tracer
   inxi            # System info
   neofetch        # System fetch
   nitch           # Minimal fetch
   onefetch        # Git repo fetch
   resources       # Resource monitor

   # =============================================================================
   # Network Tools
   # =============================================================================
   aria2           # Download manager
   bmon            # Bandwidth monitor
   ethtool         # Ethernet tool
   fping           # Fast ping
   iptraf-ng       # IP traffic monitor
   pssh            # Parallel SSH
   traceroute      # Network tracer
   vnstat          # Network monitor
   dig             # DNS tool

   # =============================================================================
   # Desktop and Productivity
   # =============================================================================
   bleachbit        # System cleaner
   discord          # Chat platform
   ente-auth        # Auth tool
   hyprsunset       # Color temperature
   hypridle         # Idle manager
   brightnessctl    # Brightness control
   libreoffice      # Office suite
   pyprland         # Hyprland tools
   qalculate-gtk    # Calculator
   woomer           # Window manager
   zenity           # GUI dialogs
   copyq            # Clipboard manager
   keepassxc        # Password manager
   gopass           # Pass CLI
   pdftk            # PDF toolkit
   zathura          # PDF viewer
   evince           # PDF viewer
   candy-icons      # Icon theme
   wpaperd          # Modern wallpaper daemon
   sway             # Window manager
   beauty-line-icon-theme # Icon theme

   # =============================================================================
   # Productivity Tools
   # =============================================================================
   gtt                # Time tracker
   nix-prefetch-github # GitHub prefetch
   todo               # Task manager
   toipe              # Typing practice
   ttyper             # Terminal typing
   gparted            # Partition editor

   # =============================================================================
   # Terminal Entertainment
   # =============================================================================
   cbonsai        # ASCII bonsai
   cmatrix        # Matrix effect
   pipes          # Pipe animation
   sl             # Steam locomotive
   tty-clock      # Terminal clock
   transmission_4 # Torrent client
   pirate-get     # TPB interface

   # =============================================================================
   # Tmux Dependencies
   # =============================================================================
   gnutar        # Archive handling
   gzip          # Compression
   coreutils     # Core utilities
   yq-go         # YAML processor
   gawk          # Text processing

   # =============================================================================
   # System Integration
   # =============================================================================
   gnome-keyring      # Password manager
   polkit_gnome       # Auth framework
   blueman            # Bluetooth manager
   seahorse           # Key manager

   # =============================================================================
   # Remote Desktop
   # =============================================================================
   anydesk         # Remote desktop

   # =============================================================================
   # Waybar Extensions
   # =============================================================================
   waybar-mpris    # Media controls

   # =============================================================================
   # NixOS Tools
   # =============================================================================
   nix-prefetch-git # Git prefetcher
 ];
}
