# ==============================================================================
# User Home Packages Configuration
# modules/home/system/packages/default.nix
# ==============================================================================
#
# This configuration manages user-level packages including:
# - Development tools and utilities
# - Media applications
# - System monitoring tools
# - Desktop utilities
#
# Author: Kenan Pelit
# ==============================================================================

{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    # File Management -------------------------------
    caligula       # Vim-like file manager
    duf            # Disk usage analyzer
    eza            # Modern ls alternative
    fd             # Fast file finder
    file           # File type identifier
    gtrash         # GNOME trash manager
    lsd            # Colorful ls alternative
    ncdu           # Disk usage analyzer
    tree           # Directory tree viewer
    trash-cli      # Trash CLI manager
    unzip          # Archive extractor

    # Development Tools ---------------------------
    binsider               # Binary analyzer
    bitwise                # Bit manipulation
    hexdump                # Hex viewer
    lazygit                # Git TUI
    lua-language-server    # Lua LSP
    nixd                   # Nix LSP
    nixfmt-rfc-style       # Nix formatter
    nil                    # Nix language tools
    programmer-calculator  # Dev calculator
    psmisc                 # Process utilities
    shellcheck            # Shell analyzer
    shfmt                 # Shell formatter
    stylua                # Lua formatter
    tree-sitter           # Parser generator
    treefmt2              # Multi-language formatter
    xxd                   # Hex editor
    inputs.alejandra.defaultPackage.${pkgs.system} # Nix formatter

    # Terminal Utilities -------------------------
    bc              # Calculator
    docfd           # Document finder
    entr            # File watcher
    jq              # JSON processor
    killall         # Process termination
    mimeo           # MIME handler
    most            # Pager
    ripgrep         # Text search
    sesh            # Session manager
    tldr            # Simple man pages
    wezterm         # Terminal emulator
    zoxide          # Directory jumper
    wl-clipboard    # Wayland clipboard
    bat             # Better cat
    detox           # Filename cleaner
    pv              # Pipe viewer
    gist            # GitHub gist tool
    python312Packages.subliminal  # Subtitles
    python312Packages.googletrans # Translation
    translate-shell # Translation tool

    # Media Tools -------------------------------
    ani-cli         # Anime CLI
    ffmpeg          # Media converter
    gifsicle        # GIF editor
    imv             # Image viewer
    qview           # Quick viewer
    mpv             # Media player
    pamixer         # Audio mixer
    pavucontrol     # Audio control
    playerctl       # Media control
    satty           # Screenshot
    soundwireserver # Audio streaming
    #spotify         # Spotify music service
    swappy          # Screenshot editor
    tdf             # File manager
    vlc             # Media player
    yt-dlp          # Video downloader
    radiotray-ng    # Internet radio player

    # System Tools -----------------------------
    atop            # System monitor
    cpulimit        # CPU limiter
    dool            # System stats
    glances         # System monitor
    iotop           # I/O monitor
    lshw            # Hardware lister
    lsof            # Open files lister
    nmon            # Performance monitor
    pciutils        # PCI utilities
    strace          # System call tracer
    inxi            # System info
    neofetch        # System info
    nitch           # System info
    onefetch        # Git repo info
    resources       # Resource monitor
    mlocate         # File locator

    # Network Tools ---------------------------
    aria2           # Download manager
    bmon            # Bandwidth monitor
    ethtool         # Ethernet tool
    fping           # Fast ping
    iptraf-ng       # IP traffic monitor
    pssh            # Parallel SSH
    traceroute      # Network tracer
    vnstat          # Network monitor
    dig             # DNS tool

    # Desktop Tools ---------------------------
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
    zenity           # GTK dialogs
    copyq            # Clipboard manager
    keepassxc        # Password manager
    gopass           # Password CLI
    pdftk            # PDF tools
    zathura          # PDF viewer
    evince           # PDF viewer
    candy-icons      # Icon theme
    wpaperd          # Wallpaper daemon
    sway             # Window manager
    beauty-line-icon-theme # Icons
    gnomeExtensions.gsconnect # KDE Connect
    wtype            # Key simulator
    whatsie          # WhatsApp
    whatsapp-for-linux # WhatsApp

    # System Integration ----------------------
    gnome-keyring      # Password store
    polkit_gnome       # Privilege manager
    blueman            # Bluetooth
    seahorse           # Password GUI

    # Browsers -------------------------------
    lynx                # Text browser
    links2              # Text browser
    elinks              # Text browser

    # Remote Desktop ------------------------
    anydesk             # Remote desktop

    # Waybar Extensions --------------------
    waybar-mpris        # Media control

    # Nix Tools ---------------------------
    nix-prefetch-git    # Git prefetch
    nix-prefetch-github # GitHub prefetch
    #nix-search-tv       # An integration nix-search

    # Tmux Dependencies -------------------
    gnutar              # Archiver
    gzip                # Compression
    coreutils           # Core utils
    yq-go               # YAML parser
    gawk                # Text processor

    # Terminal Fun -----------------------
    cbonsai             # Bonsai tree
    cmatrix             # Matrix effect
    figlet              # ASCII art
    pipes               # Pipes screensaver
    sl                  # Steam locomotive
    toilet              # ASCII art
    tty-clock           # Terminal clock
    transmission_4      # Torrent client
    pirate-get          # Torrent search

    # Productivity Tools -----------------
    gtt                 # Time tracker
    todo                # Todo manager
    toipe               # Typing tutor
    ttyper              # Typing game
    gparted             # Partition editor

    # Preview Tools: Basic --------------
    file                # File identifier
    jq                  # JSON tool
    bat                 # Code viewer
    glow                # Markdown viewer
    w3m                 # Text browser
    eza                 # File lister
    openssl             # SSL tools

    # Preview Tools: Archive -----------
    atool               # Archive tool
    p7zip               # Compression
    libcdio             # CD/DVD tool

    # Preview Tools: Documents --------
    odt2txt             # ODT converter
    catdoc              # DOC viewer
    gnumeric            # Spreadsheet

    # Preview Tools: Media -----------
    exiftool            # Metadata tool
    chafa               # Image viewer
    mediainfo           # Media info
    ffmpegthumbnailer   # Thumbnails
    poppler_utils       # PDF tools

    # VPN Tools ---------------------
    gpauth                    # GlobalProtect
    globalprotect-openconnect # VPN client
    openvpn                   # VPN client
    openconnect               # VPN client
    openfortivpn              # VPN client
  ];
}
