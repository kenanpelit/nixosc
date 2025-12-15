{ lib, pkgs, config, osConfig, ... }:
# ==============================================================================
# Home Manager profile for kenan@hay (x86_64-linux).
# Role: daily-driver Hyprland/GNOME setup with curated apps, terminals,
# theming (Catppuccin), and dev tools. Adjust module toggles below to
# enable/disable components per host while keeping user defaults consistent.
# ==============================================================================
{
  # Set the state version for Home Manager
  # Configure user-specific settings here if needed
  home.stateVersion = "25.11";

  # ============================================================================
  # System & Core
  # ============================================================================
  my.user.bash.enable = true;
  my.user.zsh.enable = true;
  my.user.git.enable = true;
  my.user.starship.enable = true;
  my.user.fzf.enable = true;
  my.user.fastfetch.enable = true;
  my.user.btop.enable = true;
  my.user.packages.enable = true;
  my.user.scripts.enable = true;
  my.user.command-not-found.enable = true;
  my.user.xdg-dirs.enable = true;
  my.user.xdg-mimes.enable = true;
  my.user.xdg-portal.enable = true;
  my.user.xserver.enable = true;
  my.user.core-programs.enable = true;

  # ============================================================================
  # Desktop Environment (Hyprland & GNOME)
  # ============================================================================
  my.desktop.hyprland.enable = true;
  my.desktop.gnome.enable = true;
  my.desktop.sway.enable = true; # VM management
  my.desktop.niri.enable = true;
  
  # Components
  my.user.waybar.enable = false;
  my.user.hyprpanel.enable = false;
  my.user.rofi.enable = true;
  my.user.walker.enable = true;
  my.user.ulauncher.enable = true;
  my.user.mako.enable = false;
  my.user.dms.enable = true;
  my.user.stasis.enable = true;
  my.user.fusuma.enable = true;
  my.user.blue.enable = false;
  my.user.sunsetr.enable = true;
  my.user.ghostty.enable = true;

  # ============================================================================
  # Browsers
  # ============================================================================
  my.browser.brave = {
    enable = true;
    setAsDefault = true;
  };
  my.browser.firefox.enable = true;
  my.browser.chrome-preview.enable = true;

  # ============================================================================
  # Communication
  # ============================================================================
  my.user.webcord.enable = true;
  my.user.connect.enable = true; # KDE Connect

  # ============================================================================
  # Media & Audio
  # ============================================================================
  my.user.mpv.enable = true;
  my.user.vlc.enable = true;
  my.user.mpd.enable = true;
  my.user.audacious.enable = true;
  my.user.cava.enable = true;
  my.user.radio.enable = true;
  my.user.subliminal.enable = true;
  my.user.ytdlp.enable = true;

  # ============================================================================
  # Tools & Utilities
  # ============================================================================
  # File Management
  my.user.nemo.enable = true;
  my.user.yazi.enable = true;
  my.user.rsync.enable = true;

  # Productivity
  my.user.obsidian.enable = true;
  my.user.anydesk.enable = true;
  my.user.transmission.enable = true;
  
  # Clipboard
  my.user.copyq.enable = false;
  my.user.clipse.enable = true;
  
  # Security
  my.user.sops.enable = true;
  my.user.gnupg.enable = true;
  my.user.pass.enable = true;
  
  # Search
  my.user.search.enable = false;
  
  # Other
  my.user.flatpak.enable = true;
  my.user.electron.enable = true;

  # Night light manager (Gammastep/HyprSunset only)

  # ============================================================================
  # Development
  # ============================================================================
  # Editors
  my.user.nvim.enable = true;
  
  # Terminals
  my.user.kitty.enable = true;
  my.user.wezterm.enable = true;
  my.user.tmux.enable = true;
  my.user.sesh.enable = true;
  
  # Git
  my.user.lazygit.enable = true;
  
  # AI
  my.user.ai.enable = true;
  my.user.ollama = {
    enable = true;
    useGPU = false;
  };

  # ============================================================================
  # Theming
  # ============================================================================
  my.user.catppuccin.enable = true;
  my.user.gtk.enable = true;
  my.user.qt.enable = true;
  my.user.candy.enable = true;
}
