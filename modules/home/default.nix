# ==============================================================================
# Home Environment Configuration
# Author: Kenan Pelit
# Description: Centralized imports for all home environment modules
# ==============================================================================
{ inputs, username, host, ... }: {
  imports = [
    # =============================================================================
    # Terminal and Shell Environment
    # =============================================================================
    ./bat                           # Better 'cat' command
    ./btop                          # Resource monitor
    ./foot                          # Foot terminal emulator
    ./fzf                           # Fuzzy finder
    ./kitty                         # Kitty terminal emulator
    ./p10k                          # Powerlevel10k theme for Zsh
    ./sem                           # Terminal session manager
    ./sesh                          # Terminal session manager
    ./tmux                          # Terminal multiplexer
    ./wezterm                       # WezTerm terminal emulator
    ./yazi                          # Terminal file manager
    ./zsh                           # Z shell configuration

    # =============================================================================
    # Desktop Environment and Window Management
    # =============================================================================
    ./hyprland                      # Window manager
    ./hyprsunset                    # Color temperature adjuster
    ./sway                          # Window manager
    ./swaync                        # Notification daemon
    ./swaylock                      # Screen locker
    ./swayosd                       # OSD notifications
    ./waybar                        # Status bar
    #./waypaper                      # Wallpaper manager
    ./wpaperd                       # Wallpaper daemon
    ./xdg-portal                    # Desktop integration
    ./xserver                       # X server configuration

    # =============================================================================
    # Applications and Utilities
    # =============================================================================
    ./anydesk                       # Remote desktop
    ./audacious                     # Music player
    ./browser                       # Web browser
    ./discord                       # Chat client
    ./eletron
    ./mpv                           # Media player
    ./nemo                          # File manager
    ./nvim                          # Text editor
    ./obsidian                      # Note-taking
    ./transmission                  # Torrent client
    ./ulauncher                     # Application launcher
    
    # =============================================================================
    # System Integration and Theming
    # =============================================================================
    ./gtk                          # GTK theming
    ./qt                           # Qt theming
    ./candy                        # Theme components
    ./gammastep                    # Color temperature
    
    # =============================================================================
    # Audio and Media
    # =============================================================================
    ./cava                         # Audio visualizer
    ./mpd                          # Music player daemon
    ./spicetify                    # Spotify customization
    ./ytdlp                        # Media downloader
    
    # =============================================================================
    # Security and Privacy
    # =============================================================================
    ./gnupg                        # GPG configuration
    ./password-store               # Password manager
    ./sops                         # Secrets management
    
    # =============================================================================
    # Development Tools
    # =============================================================================
    ./git                          # Version control
    ./lazygit                      # Git interface
    
    # =============================================================================
    # Input and Gesture Control
    # =============================================================================
    ./fusuma                       # Multitouch gestures
    ./iwmenu                       # Network menu
    ./rofi                         # Application launcher
    ./touchegg                     # Touch gestures
    
    # =============================================================================
    # System Components
    # =============================================================================
    ./command-not-found            # Command handler
    ./copyq                        # Clipboard manager
    ./fastfetch                    # System info
    ./packages                     # Additional packages
    ./rsync                        # File sync
    ./scripts                      # Custom scripts
    ./services                     # User services
    ./xdg-mimes                    # MIME handling
    
    # Disabled modules
    #./zotfiles                    # File management
  ];
}
