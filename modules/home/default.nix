{inputs, username, host, ...}: {
 imports = [
   #./alacritty.nix                   # terminal emulator
   ./audacious.nix                   # music player
   ./bat.nix                         # better cat command
   ./browser.nix                     # firefox based browser
   ./btop.nix                        # system monitor
   ./cava.nix                        # audio visualizer
   ./discord/discord.nix             # discord with gruvbox theme
   ./fastfetch.nix                   # system info fetch tool
   ./fzf.nix                         # fuzzy finder
   #./gaming.nix                      # packages related to gaming
   ./gammastep/gammastep.nix         # night light
   #./ghostty.nix                     # terminal
   ./git.nix                         # version control
   ./gnome.nix                       # gnome applications
   ./gtk.nix                         # gtk theming
   ./hyprland                        # wayland compositor
   ./kitty.nix                       # terminal emulator
   ./micro.nix                       # terminal text editor
   ./nemo.nix                        # file manager
   ./nvim.nix                        # neovim text editor
   ./obsidian.nix                    # note taking app
   ./p10k/p10k.nix                   # zsh theme
   ./packages.nix                    # additional packages
   ./retroarch.nix                   # retro game emulator
   ./rofi.nix                        # application launcher
   ./scripts/scripts.nix             # custom scripts
   ./spicetify.nix                   # spotify customization
   ./starship.nix                    # shell prompt
   ./swaylock.nix                    # screen locker
   ./swayosd.nix                     # on-screen display
   ./swaync/swaync.nix               # notification daemon
   #./ulauncher.nix                   # launcher
   ./waybar                          # status bar
   ./waypaper.nix                    # wallpaper manager
   #./viewnior.nix                    # image viewer
   #./wezterm.nix                     # GUI wallpaper picker
   ./xdg-mimes.nix                   # file associations
   ./tmux.nix                        # terminal multiplexer
   ./yazi.nix                        # terminal file manager
   ./zsh                             # shell
 ];
}
