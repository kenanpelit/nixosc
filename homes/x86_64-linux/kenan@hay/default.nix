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
  my.user.direnv.enable = true;
  my.user.fastfetch.enable = true;
  my.user.btop.enable = true;
  my.user.packages.enable = true;
  my.user.scripts.enable = true;
  my.user.bt.enable = true;
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
  my.desktop.cosmic.enable = true;
  
  # Components
  my.user.hyprpanel.enable = false;
  my.user.rofi.enable = true;
  my.user.walker.enable = false;
  my.user.mako.enable = false;
  my.user.dms.enable = true;
  my.user.stasis.enable = true;
  my.user.fusuma.enable = true;
  my.user.blue.enable = false;
  my.user.sunsetr.enable = false;
  my.user.ghostty.enable = true;

  # ============================================================================
  # Browsers
  # ============================================================================
  my.browser.brave = {
    enable = true;
    setAsDefault = true;
    defaultProfileName = "Kenp";
    defaultDesktopFile = "brave-kenp.desktop";
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
  my.user.rmpc.enable = true;
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
  my.user.cliphist.enable = true;
  
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

  # ============================================================================
  # On-demand services
  # ============================================================================
  # Keep CompecTA remote support available, but do not auto-start it on login.
  systemd.user.services.compecta-support = {
    Unit = {
      Description = "CompecTA Remote Support Service";
      Wants = [ "network-online.target" ];
      After = [ "network.target" "network-online.target" ];
      ConditionPathExists = "%h/.compecta/compecta_support_key_rsa";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.autossh}/bin/autossh -M 0 -o \"ServerAliveInterval 30\" -o \"ServerAliveCountMax 4\" -o \"StrictHostKeyChecking=no\" -o \"ControlMaster=no\" -o \"ControlPath=none\" -i %h/.compecta/compecta_support_key_rsa -N -p36499 -R22217:127.0.0.1:22 autossh@terminal.compecta.com";
      Restart = "always";
      RestartSec = "1m";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };

  home.activation.disableCompectaSupportAutostart = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # If the unit was previously enabled, systemd keeps a symlink in
    # `default.target.wants/` even if we remove the [Install] section later.
    # Remove that symlink so the service becomes truly on-demand.
    rm -f "$HOME/.config/systemd/user/default.target.wants/compecta-support.service"
    rm -f "$HOME/.config/systemd/user/timers.target.wants/compecta-support.timer"
    rm -f "$HOME/.config/systemd/user/compecta-support.timer"

    # Best-effort: if we're in a live user session, also stop+disable it.
    if command -v systemctl >/dev/null 2>&1; then
      systemctl --user disable --now compecta-support.service >/dev/null 2>&1 || true
      systemctl --user disable --now compecta-support.timer >/dev/null 2>&1 || true
      systemctl --user daemon-reload >/dev/null 2>&1 || true
    fi
  '';
}
