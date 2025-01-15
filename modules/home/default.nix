{ inputs, username, host, ... }: {
  imports = [
    ./anydesk
    ./audacious                     # Music player
    ./bat                           # Better 'cat' command
    ./browser                       # Firefox-based browser
    ./btop                          # Resource monitor
    ./candy
    ./cava                          # Audio visualizer
    ./command-not-found             # Command-not-found handler
    ./copyq
    ./discord                       # Discord with mocha theme
    ./fastfetch                     # System fetch tool
    ./foot                          # Foot terminal emulator
    ./fusuma                        # Fusuma is multitouch gesture
    ./fzf                           # Fuzzy finder
    ./gammastep                     # Screen color temperature adjuster
    ./git                           # Version control system
    ./gnome                         # GNOME applications
    ./gnupg                         # GnuPG configuration
    ./gtk                           # GTK theme configuration
    ./iwmenu                        # iwmenu (iNet Wireless Menu) 
    ./hyprsunset
    ./hyprland                      # Window manager configuration
    ./kitty                         # Kitty terminal emulator
    ./lazygit                       # Git TUI interface
    ./mpd                           # Music player daemon
    ./mpv                           # Media player
    ./nemo                          # File manager
    ./nvim                          # Neovim editor
    ./obsidian                      # Note-taking application
    ./p10k                          # Powerlevel10k is a theme for Zsh
    ./packages                      # Other miscellaneous packages
    ./password-store                # Password store for secure password management
    ./rofi                          # Application launcher
    ./qt                            # QT configuration for GUI applications
    ./services                      # Optional services configuration (commented out)
    ./sem                           # Terminal session manager
    ./sesh                          # Terminal session manager
    ./spicetify                     # Spotify client customization
    ./sops                          # Sops for managing secrets
    ./swaync                        # Sway notification daemon
    ./scripts                       # Personal scripts
    ./tmux                          # Tmux configuration assets
    ./swaylock                      # Screen locker for sway
    ./swayosd                       # Brightness/volume widget for sway
    ./transmission
    ./touchegg                      # Touch gestures for Linux
    ./waypaper                      # GUI wallpaper picker
    ./wezterm                       # WezTerm terminal emulator
    ./xdg-mimes                     # XDG MIME configuration
    ./xdg-portal                    # XDG portal integration
    ./ulauncher                     # Ulauncher for application launching
    ./yazi                          # Terminal-based file manager
    ./ytdlp                         # Command-line audio/video downloader
    ./waybar                        # Status bar configuration for sway
    ./wpaperd
    #./zotfiles
    ./zsh                           # Shell configuration for Zsh
  ];
}
