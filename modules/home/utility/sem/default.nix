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
      "args": ["--class", "TmuxKenp", "-T", "Tmux", "-e", "tmux_kenp"],
      "vpn": "bypass"
    },
    "wkenp": {
      "command": "wezterm",
      "args": ["start", "--class", "TmuxKenp", "-e", "tmux_kenp"],
      "vpn": "bypass"
    },
    "wezterm": {
      "command": "wezterm",
      "args": ["start", "--class", "wezterm"],
      "vpn": "secure"
    },
    "kitty-single": {
      "command": "kitty",
      "args": ["--class", "kitty", "-T", "kitty", "--single-instance"],
      "vpn": "secure"
    },
    "wezterm-rmpc": {
      "command": "wezterm",
      "args": ["start", "--class", "rmpc", "-e", "rmpc"],
      "vpn": "secure"
    },
    "discord": {
      "command": "discord",
      "args": ["-m", "--class=discord", "--title=discord"],
      "vpn": "bypass"
    },
    "webcord": {
      "command": "webcord",
      "args": ["-m", "--class=WebCord", "--title=Webcord"],
      "vpn": "bypass"
    },
    "Chrome-Kenp": {
      "command": "profile_chrome",
      "args": ["Kenp", "--class", "Kenp"],
      "vpn": "secure"
    },
    "Chrome-CompecTA": {
      "command": "profile_chrome",
      "args": ["CompecTA", "--class", "CompecTA"],
      "vpn": "secure"
    },
    "Chrome-AI": {
      "command": "profile_chrome",
      "args": ["AI", "--class", "AI"],
      "vpn": "secure"
    },
    "Chrome-Whats": {
      "command": "profile_chrome",
      "args": ["Whats", "--class", "Whats"],
      "vpn": "secure"
    },
    "Brave-Kenp": {
      "command": "profile_brave",
      "args": ["Kenp", "--class", "Kenp"],
      "vpn": "secure"
    },
    "Brave-CompecTA": {
      "command": "profile_brave",
      "args": ["CompecTA", "--class", "CompecTA" , "--title", "CompecTA"],
      "vpn": "secure"
    },
    "Brave-Ai": {
      "command": "profile_brave",
      "args": ["Ai", "--class", "Ai", "--title", "Ai"],
      "vpn": "secure"
    },
    "Brave-Whats": {
      "command": "profile_brave",
      "args": ["Whats", "--class", "Whats", "--title", "Whats"],
      "vpn": "secure"
    },
    "Brave-Yotube": {
      "command": "profile_brave",
      "args": ["--youtube"],
      "vpn": "secure"
    },
    "Brave-Tiktok": {
      "command": "profile_brave",
      "args": ["--tiktok"],
      "vpn": "secure"
    },
    "Brave-Spotify": {
      "command": "profile_brave",
      "args": ["--spotify"],
      "vpn": "secure"
    },
    "Brave-Discord": {
      "command": "profile_brave",
      "args": ["--discord"],
      "vpn": "secure"
    },
    "Brave-Whatsapp": {
      "command": "profile_brave",
      "args": ["--whatsapp"],
      "vpn": "secure"
    },
    "Zen-Kenp": {
      "command": "zen",
      "args": ["-P", "Kenp", "--class", "Kenp", "--name", "Kenp", "--restore-session"],
      "vpn": "secure"
    },
    "Zen-CompecTA": {
      "command": "zen",
      "args": ["-P", "CompecTA", "--class", "CompecTA", "--name", "CompecTA", "--restore-session"],
      "vpn": "secure"
    },
    "Zen-Discord": {
      "command": "zen",
      "args": ["-P", "Discord", "--class", "Discord", "--name", "Discord", "--restore-session"],
      "vpn": "secure"
    },
    "Zen-NoVpn": {
      "command": "zen",
      "args": ["-P", "NoVpn", "--class", "AI", "--name", "AI", "--restore-session"],
      "vpn": "bypass"
    },
    "Zen-Proxy": {
      "command": "zen",
      "args": ["-P", "Proxy", "--class", "Proxy", "--name", "Proxy", "--restore-session"],
      "vpn": "bypass"
    },
    "Zen-Spotify": {
      "command": "zen",
      "args": ["-P", "Spotify", "--class", "Spotify", "--name", "Spotify", "--restore-session"],
      "vpn": "bypass"
    },
    "Zen-Whats": {
      "command": "zen",
      "args": ["-P", "Whats", "--class", "Whats", "--name", "Whats", "--restore-session"],
      "vpn": "secure"
    },
    "spotify": {
      "command": "spotify",
      "args": ["--class", "Spotify", "-T", "Spotify"],
      "vpn": "bypass"
    },
    "mpv": {
      "command": "mpv",
      "args": [],
      "vpn": "bypass"
    }
  }
}
      '';
    };
  };
}

