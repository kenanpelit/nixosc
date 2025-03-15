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
    "kkenp": {
      "command": "kitty",
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tmux_kenp"],
      "vpn_mode": "never"
    },
    "wkenp": {
      "command": "wezterm",
      "args": ["start", "--class", "TmuxKenp", "-e", "tmux_kenp"],
      "vpn_mode": "never"
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
      "command": "wezterm",
      "args": ["start", "--class", "rmpc", "-e", "rmpc"],
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
      "args": ["Kenp", "--class", "Kenp"],
      "vpn_mode": "default"
    },
    "Chrome-CompectTA": {
      "command": "profile_chrome",
      "args": ["CompecTA", "--class", "CompecTA"],
      "vpn_mode": "default"
    },
    "Chrome-AI": {
      "command": "profile_chrome",
      "args": ["AI", "--class", "AI"],
      "vpn_mode": "default"
    },
    "Chrome-Whats": {
      "command": "profile_chrome",
      "args": ["Whats", "--class", "Whats"],
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
