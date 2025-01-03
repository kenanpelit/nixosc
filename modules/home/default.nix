{ inputs, username, host, ... }: {
 imports = [
   ./audacious.nix                   # Music player
   ./bat.nix                         # Better 'cat' command
   ./bin/bin.nix                     # Binary files configuration  
   ./browser.nix                     # Firefox-based browser
   ./btop.nix                        # Resource monitor
   ./cava.nix                        # Audio visualizer
   # ./discord/discord.nix            # Discord with Gruvbox theme
   ./fastfetch.nix                   # System fetch tool
   ./fzf.nix                         # Fuzzy finder
   # ./gaming.nix                     # Gaming-related packages
   ./gammastep                       # Screen color temperature adjuster
   ./git.nix                         # Version control system
   ./gnome.nix                       # GNOME applications
   ./gtk.nix                         # GTK theme configuration
   ./hyprland                        # Window manager configuration
   ./kitty.nix                       # Kitty terminal emulator
   ./lazygit.nix                     # Git TUI interface
   ./micro.nix                       # Nano replacement text editor
   ./nemo.nix                        # File manager
   ./nvim.nix                        # Neovim editor 
   ./obsidian.nix                    # Note-taking application
   ./packages.nix                    # Other miscellaneous packages
   ./retroarch.nix                   # Emulator frontend
   ./rofi.nix                        # Application launcher
   ./scripts/scripts.nix             # Personal scripts
   ./spicetify.nix                   # Spotify client customization
   ./starship.nix                    # Shell prompt customization
   ./swaylock.nix                    # Screen locker
   ./swayosd.nix                     # Brightness/volume widget 
   ./swaync/swaync.nix               # Notification daemon
   ./tmux                            # Tmux configuration
   ./waybar                          # Status bar configuration
   ./waypaper.nix                    # GUI wallpaper picker
   # ./viewnior.nix                   # Image viewer
   ./wezterm.nix                     # WezTerm terminal emulator
   ./xdg-mimes.nix                   # XDG MIME configuration
   ./yazi.nix                        # Terminal-based file manager
   ./zsh                             # Shell configuration
 ];
}
