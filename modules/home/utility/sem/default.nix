# modules/home/utility/sem/default.nix
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
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tm"],
      "vpn": "bypass"
    },
    "mkenp": {
      "command": "kitty",
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tm"],
      "vpn": "secure"
    },
    "wkenp": {
      "command": "wezterm",
      "args": ["start", "--class", "TmuxKenp", "-e", "tm"],
      "vpn": "bypass"
    },
    "wezterm": {
      "command": "wezterm",
      "args": ["start", "--class", "wezterm"],
      "vpn": "secure",
      "workspace": "2"
    },
    "kitty-single": {
      "command": "kitty",
      "args": ["--class", "kitty", "-T", "kitty", "--single-instance"],
      "vpn": "secure",
      "workspace": "2"
    },
    "wezterm-rmpc": {
      "command": "wezterm",
      "args": ["start", "--class", "rmpc", "-e", "rmpc"],
      "vpn": "secure"
    },
    "discord": {
      "command": "discord",
      "args": ["-m", "--class=discord", "--title=discord"],
      "vpn": "bypass",
      "workspace": "5",
      "fullscreen": "true",
      "final_workspace": "2"
    },
    "webcord": {
      "command": "webcord",
      "args": ["-m", "--class=WebCord", "--title=Webcord"],
      "vpn": "bypass",
      "workspace": "5",
      "fullscreen": "true"
    },
    "Chrome-Kenp": {
      "command": "profile_chrome",
      "args": ["Kenp", "--class", "Kenp"],
      "vpn": "secure",
      "workspace": "1"
    },
    "Chrome-CompecTA": {
      "command": "profile_chrome",
      "args": ["CompecTA", "--class", "CompecTA"],
      "vpn": "secure",
      "workspace": "4"
    },
    "Chrome-AI": {
      "command": "profile_chrome",
      "args": ["AI", "--class", "AI"],
      "vpn": "secure",
      "workspace": "3"
    },
    "Chrome-Whats": {
      "command": "profile_chrome",
      "args": ["Whats", "--class", "Whats"],
      "vpn": "secure",
      "workspace": "9"
    },
    "Brave-Kenp": {
      "command": "profile_brave",
      "args": ["Kenp"],
      "vpn": "secure",
      "workspace": "1"
    },
    "Brave-CompecTA": {
      "command": "profile_brave",
      "args": ["CompecTA"],
      "vpn": "secure",
      "workspace": "4"
    },
    "Brave-Ai": {
      "command": "profile_brave",
      "args": ["Ai"],
      "vpn": "secure",
      "workspace": "3"
    },
    "Brave-Whats": {
      "command": "profile_brave",
      "args": ["Whats"],
      "vpn": "secure",
      "workspace": "9"
    },
    "Brave-Exclude": {
      "command": "profile_brave",
      "args": ["Exclude"],
      "vpn": "bypass",
      "workspace": "6"
    },
    "Brave-Yotube": {
      "command": "profile_brave",
      "args": ["--youtube"],
      "vpn": "secure",
      "workspace": "6",
      "fullscreen": "true"
    },
    "Brave-Tiktok": {
      "command": "profile_brave",
      "args": ["--tiktok"],
      "vpn": "secure",
      "workspace": "6",
      "fullscreen": "true"
    },
    "Brave-Spotify": {
      "command": "profile_brave",
      "args": ["--spotify"],
      "vpn": "secure",
      "workspace": "8",
      "fullscreen": "true"
    },
    "Brave-Discord": {
      "command": "profile_brave",
      "args": ["--discord"],
      "vpn": "secure",
      "workspace": "5",
      "final_workspace": "2",
      "wait_time": "2",
      "fullscreen": "true"
    },
    "Brave-Whatsapp": {
      "command": "profile_brave",
      "args": ["--whatsapp"],
      "vpn": "secure",
      "workspace": "9",
      "fullscreen": "true"
    },
    "Zen-Kenp": {
      "command": "zen",
      "args": ["-P", "Kenp", "--class", "Kenp", "--name", "Kenp", "--restore-session"],
      "vpn": "secure",
      "workspace": "1"
    },
    "Zen-CompecTA": {
      "command": "zen",
      "args": ["-P", "CompecTA", "--class", "CompecTA", "--name", "CompecTA", "--restore-session"],
      "vpn": "secure",
      "workspace": "4"
    },
    "Zen-Discord": {
      "command": "zen",
      "args": ["-P", "Discord", "--class", "Discord", "--name", "Discord", "--restore-session"],
      "vpn": "secure",
      "workspace": "5",
      "fullscreen": "true"
    },
    "Zen-NoVpn": {
      "command": "zen",
      "args": ["-P", "NoVpn", "--class", "AI", "--name", "AI", "--restore-session"],
      "vpn": "bypass",
      "workspace": "3"
    },
    "Zen-Proxy": {
      "command": "zen",
      "args": ["-P", "Proxy", "--class", "Proxy", "--name", "Proxy", "--restore-session"],
      "vpn": "bypass",
      "workspace": "7"
    },
    "Zen-Spotify": {
      "command": "zen",
      "args": ["-P", "Spotify", "--class", "Spotify", "--name", "Spotify", "--restore-session"],
      "vpn": "bypass",
      "workspace": "7",
      "fullscreen": "true"
    },
    "Zen-Whats": {
      "command": "zen",
      "args": ["-P", "Whats", "--class", "Whats", "--name", "Whats", "--restore-session"],
      "vpn": "secure",
      "workspace": "9",
      "fullscreen": "true"
    },
    "spotify": {
      "command": "spotify",
      "args": ["--class", "Spotify", "-T", "Spotify"],
      "vpn": "bypass",
      "workspace": "8",
      "fullscreen": "true"
    },
    "mpv": {
      "command": "mpv",
      "args": [],
      "vpn": "bypass",
      "workspace": "6",
      "fullscreen": "true"
    }
  }
}
      '';
    };
  };
}

