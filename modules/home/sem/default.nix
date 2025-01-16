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
   "foot": {
     "command": "foot",
     "args": ["-a", "foot", "-T", "foot"],
     "vpn_mode": "default"
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
   "kitty-single": {
     "command": "kitty",
     "args": ["--class", "kitty", "-T", "kitty", "--single-instance"],
     "vpn_mode": "default" 
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
   "wezterm": {
     "command": "wezterm",
     "args": ["start", "--class", "wezterm"],
     "vpn_mode": "default"
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
   "alacritty-ncmpcpp": {
     "command": "alacritty",
     "args": ["--class", "ncmpcpp", "-T", "ncmpcpp", "-e", "ncmpcpp"],
     "vpn_mode": "default"
   },
   "alacritty": {
     "command": "alacritty", 
     "args": ["--class", "alacritty", "-T", "alacritty"],
     "vpn_mode": "default"
   },
   "discord": {
     "command": "spotify",
     "args": ["--class", "Spotify", "-m"],
     "vpn_mode": "always"
   },
   "webcord": {
     "command": "webcord",
     "args": ["-m", "--class=WebCord", "--title=Webcord"],
     "vpn_mode": "never"
   },
   "Zen-Kenp": {
     "command": "zen",
     "args": ["-P", "Kenp", "--class", "Zen-Kenp", "--name", "Zen-Kenp", "--restore-session"],
     "vpn_mode": "default"
   },
   "Zen-CompecTA": {
     "command": "zen",
     "args": ["-P", "CompecTA", "--class", "Zen-CompecTA", "--name", "Zen-CompecTA", "--restore-session"],
     "vpn_mode": "always" 
   },
   "Zen-Discord": {
     "command": "zen",
     "args": ["-P", "Discord", "--class", "Zen-Discord", "--name", "Zen-Discord", "--restore-session"],
     "vpn_mode": "always"
   },
   "Zen-NoVpn": {
     "command": "zen", 
     "args": ["-P", "NoVpn", "--class", "Zen-NoVpn", "--name", "Zen-NoVpn", "--restore-session"],
     "vpn_mode": "never"
   },
   "Zen-Proxy": {
     "command": "zen",
     "args": ["-P", "Proxy", "--class", "Zen-Proxy", "--name", "Zen-Proxy", "--restore-session"],
     "vpn_mode": "never"
   },
   "Zen-Spotify": {
     "command": "zen",
     "args": ["-P", "Spotify", "--class", "Zen-Spotify", "--name", "Zen-Spotify", "--restore-session"],
     "vpn_mode": "never"
   },
   "Zen-Whats": {
     "command": "zen",
     "args": ["-P", "Whats", "--class", "Zen-Whats", "--name", "Zen-Whats", "--restore-session"],
     "vpn_mode": "always"
   },
   "spotify": {
     "command": "spotify",
     "args": ["--class", "Spotify", "-T", "Spotify"],
     "vpn_mode": "never"
   },
   "mpv": {
     "command": "mpv",
     "args": [],
     "vpn_mode": "never"
   },
   "transmission-gtk": {
     "command": "transmission-gtk",
     "args": [],
     "vpn_mode": "never"
   }
 }
}
     '';
   };
 };
}
