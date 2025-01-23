# modules/home/sem/default.nix
# ==============================================================================
# Session Manager Configuration
# ==============================================================================
{ config, pkgs, ... }:
{
  # =============================================================================
  # Directory Structure
  # =============================================================================
  home.file = {
    # Backup Directory
    ".config/sem/backups/.keep" = {
      text = "";
    };

    # Logs Directory  
    ".config/sem/logs/.keep" = {
      text = "";
    };

    # =============================================================================
    # Main Configuration
    # =============================================================================
    ".config/sem/config.json" = {
      text = ''
{
  "sessions": {
    "fkenp": {
      "command": "foot",
      "args": ["-a", "TmuxKenp", "-T", "Tmux", "-e", "tmux_kenp"],
      "vpn_mode": "never"
    },
    "fcta": {
      "command": "foot", 
      "args": ["-a", "TmuxCta", "-T", "Tmux", "-e", "tmux_cta"],
      "vpn_mode": "always"
    },
    "kkenp": {
      "command": "kitty",
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tmux_kenp"],
      "vpn_mode": "never"
    },
    "kcta": {
      "command": "kitty",
      "args": ["--class", "TmuxCta", "-T", "Tmux", "-e", "tmux_cta"],
      "vpn_mode": "always"
    },
    "wkenp": {
      "command": "wezterm",
      "args": ["start", "--class", "TmuxKenp", "-e", "tmux_kenp"],
      "vpn_mode": "never"
    },
    "wcta": {
      "command": "wezterm",
      "args": ["start", "--class", "TmuxCta", "-e", "tmux_cta"],
      "vpn_mode": "always"
    },
    "akenp": {
      "command": "alacritty",
      "args": ["--class", "TmuxKenp", "--title", "Tmux", "-e", "tmux_kenp"],
      "vpn_mode": "never"
    },
    "acta": {
      "command": "alacritty",
      "args": ["--class", "TmuxCta", "--title", "Tmux", "-e", "tmux_cta"],
      "vpn_mode": "always"
    },
    "foot": {
      "command": "foot",
      "args": ["-a", "foot", "-T", "foot"],
      "vpn_mode": "default"
    },
    "wezterm": {
      "command": "wezterm",
      "args": ["start", "--class", "wezterm"],
      "vpn_mode": "default"
    },
    "kitty-single": {
      "command": "kitty",
      "args": ["--class", "kitty", "-T", "kitty", "--single-instance"],
      "vpn_mode": "default"
    },
    "wezterm-rmpc": {
      "command": "alacritty",
      "args": ["--class", "rmpc", "-e", "rmpc"],
      "vpn_mode": "default"
    },
    "discord": {
      "command": "discord",
      "args": ["-m", "--class=discord", "--title=discord"],
      "vpn_mode": "never"
    },
    "webcord": {
      "command": "webcord",
      "args": ["-m", "--class=WebCord", "--title=Webcord"],
      "vpn_mode": "never"
    },
    "Chrome-Kenp": {
      "command": "profile_chrome",
      "args": ["Kenp", "--class", "Kenp", "--title", "Kenp"],
      "vpn_mode": "default"
    },
    "Chrome-CompectTA": {
      "command": "profile_chrome",
      "args": ["CompecTA", "--class", "CompecTA", "--title", "CompecTA"],
      "vpn_mode": "default"
    },
    "Chrome-AI": {
      "command": "profile_chrome",
      "args": ["AI", "--class", "AI", "--title", "AI"],
      "vpn_mode": "default"
    },
    "Chrome-Whats": {
      "command": "profile_chrome",
      "args": ["Whats", "--class", "Whats", "--title", "Whats"],
      "vpn_mode": "default"
    },
    "Zen-Kenp": {
      "command": "zen",
      "args": ["-P", "Kenp", "--class", "Kenp", "--name", "Kenp", "--restore-session"],
      "vpn_mode": "default"
    },
    "Zen-CompecTA": {
      "command": "zen",
      "args": ["-P", "CompecTA", "--class", "CompecTA", "--name", "CompecTA", "--restore-session"],
      "vpn_mode": "always"
    },
    "Zen-Discord": {
      "command": "zen",
      "args": ["-P", "Discord", "--class", "Discord", "--name", "Discord", "--restore-session"],
      "vpn_mode": "always"
    },
    "Zen-NoVpn": {
      "command": "zen",
      "args": ["-P", "NoVpn", "--class", "AI", "--name", "AI", "--restore-session"],
      "vpn_mode": "never"
    },
    "Zen-Proxy": {
      "command": "zen",
      "args": ["-P", "Proxy", "--class", "Proxy", "--name", "Proxy", "--restore-session"],
      "vpn_mode": "never"
    },
    "Zen-Spotify": {
      "command": "zen",
      "args": ["-P", "Spotify", "--class", "Spotify", "--name", "Spotify", "--restore-session"],
      "vpn_mode": "never"
    },
    "Zen-Whats": {
      "command": "zen",
      "args": ["-P", "Whats", "--class", "Whats", "--name", "Whats", "--restore-session"],
      "vpn_mode": "always"
    },
    "spotify": {
      "command": "spotify",
      "args": ["--class", "Spotify", "-T", "Spotify"],
      "vpn_mode": "never"
    },
    "transmission-gtk": {
      "command": "transmission-gtk",
      "args": [],
      "vpn_mode": "never"
    },
    "mpv": {
      "command": "mpv",
      "args": [],
      "vpn_mode": "never"
    }
  }
}
      '';
    };
  };
}
