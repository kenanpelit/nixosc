# modules/home/sesh/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for sesh.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ config, lib, pkgs, username, ... }:
let
  cfg = config.my.user.sesh;
in
{
  options.my.user.sesh = {
    enable = lib.mkEnableOption "Sesh session manager";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Configuration File
    # =============================================================================
    home.file.".config/sesh/sesh.toml".text = ''
      # ---------------------------------------------------------------------------
      # Default Session Settings
      # ---------------------------------------------------------------------------
      [default_session]
      startup_command = "lsd"
      
      # ---------------------------------------------------------------------------
      # SSH Sessions
      # ---------------------------------------------------------------------------
      [[session]]
      name = "Feynman  "
      path = "~/"
      startup_command = "ssh grid -t 'byobu has -t ${username} || byobu new-session -d -s ${username} && byobu a -t ${username}'"
      
      [[session]]
      name = "Terminal  "
      path = "~/"
      startup_command = "ssh terminal -t 'byobu has -t ${username} || byobu new-session -d -s ${username} && byobu a -t ${username}'"
      
      [[session]]
      name = "SSH  "
      path = "~/"
      startup_command = "t3"
      
      # ---------------------------------------------------------------------------
      # System Tools & Monitoring
      # ---------------------------------------------------------------------------
      [[session]]
      name = "Tunnelshow  "
      path = "~/"
      startup_command = "tunnelshow"
      
      [[session]]
      name = "Podman-Tui 󱘖 "
      path = "~/"
      startup_command = "podman-tui"
      
      [[session]]
      name = "System Monitor 󰘳 "
      path = "~/"
      startup_command = "btop"
      
      [[session]]
      name = "Logs 󰌱 "
      path = "/var/log"
      startup_command = "sudo journalctl -f"
      
      # ---------------------------------------------------------------------------
      # File Management
      # ---------------------------------------------------------------------------
      [[session]]
      name = "Downloads 󰇚 "
      path = "~/Downloads"
      startup_command = "ranger"
      
      [[session]]
      name = "Yazi 󱂵 "
      path = "~/"
      startup_command = "yazi"
      
      [[session]]
      name = "Home 󰉋 "
      path = "~/"
      startup_command = "lsd -la"
      
      [[session]]
      name = "Documents 󰉖 "
      path = "~/Documents"
      startup_command = "lsd -la"
      
      # ---------------------------------------------------------------------------
      # Development & Configuration
      # ---------------------------------------------------------------------------
      [[session]]
      name = "TmuxConfig 󰆍 "
      path = "~/.config/tmux"
      startup_command = "vim ~/.config/tmux/tmux.conf.local"
      
      [[session]]
      name = "Project 󱌢 "
      path = "~/Work/projects"
      startup_command = "tm tmx --layout 3"
      
      [[session]]
      name = "NixOS Config  "
      path = "~/.nixosc"
      startup_command = "vim ."
      
      [[session]]
      name = "Git Status 󰊢 "
      path = "~/.nixosc"
      startup_command = "command lazygit"
      
      [[session]]
      name = "Neovim 󰆦 "
      path = "~/"
      startup_command = "nvim"
      
      # ---------------------------------------------------------------------------
      # Media & Entertainment
      # ---------------------------------------------------------------------------
      [[session]]
      name = "Music 󰎈 "
      path = "~/Music"
      startup_command = "rmpc"
      
      [[session]]
      name = "MPV Player 󰦝 "
      path = "~/Videos"
      startup_command = "yazi"
      
      [[session]]
      name = "Radio 󱉺 "
      path = "~/"
      startup_command = "radio-cli"
      
      [[session]]
      name = "YouTube 󰗃 "
      path = "~/Downloads"
      startup_command = "yt-dlp --help"
      
      # ---------------------------------------------------------------------------
      # Network & Security
      # ---------------------------------------------------------------------------
      [[session]]
      name = "Tor 󰖟 "
      path = "/repo/tor"
      startup_command = "tm tmx --layout 3"
      
      [[session]]
      name = "Network Monitor 󰛳 "
      path = "~/"
      startup_command = "nethogs"
      
      [[session]]
      name = "WiFi Scanner 󰀂 "
      path = "~/"
      startup_command = "nmcli dev wifi"
      
      [[session]]
      name = "Firewall 󰓾 "
      path = "~/"
      startup_command = "sudo ufw status verbose"
      
      # ---------------------------------------------------------------------------
      # Productivity & Notes
      # ---------------------------------------------------------------------------
      [[session]]
      name = "Anote  "
      path = "~/"
      startup_command = "anote"
      
      [[session]]
      name = "Notes 󰠮 "
      path = "~/Notes"
      startup_command = "vim ."
      
      [[session]]
      name = "Obsidian 󰈙 "
      path = "~/.anotes/obsi"
      startup_command = "obsidian"
      
      [[session]]
      name = "Calendar 󰃭 "
      path = "~/"
      startup_command = "cal -y"
      
      [[session]]
      name = "Tasks 󰄬 "
      path = "~/"
      startup_command = "task"
      
      # ---------------------------------------------------------------------------
      # System Information
      # ---------------------------------------------------------------------------
      [[session]]
      name = "System Info 󰘳 "
      path = "~/"
      startup_command = "fastfetch"
      
      [[session]]
      name = "Hardware 󰇄 "
      path = "~/"
      startup_command = "lscpu && echo && lsmem && echo && lsblk"
      
      [[session]]
      name = "Disk Usage 󰋊 "
      path = "~/"
      startup_command = "ncdu /"
      
      [[session]]
      name = "Processes 󰘳 "
      path = "~/"
      startup_command = "htop"
      
      # ---------------------------------------------------------------------------
      # Development Tools
      # ---------------------------------------------------------------------------
      [[session]]
      name = "Podman 󰡨 "
      path = "~/"
      startup_command = "podman ps -a"
      
      [[session]]
      name = "API Test 󰜏 "
      path = "~/"
      startup_command = "curl --help"
      
      # ---------------------------------------------------------------------------
      # Gaming & Fun
      # ---------------------------------------------------------------------------
      [[session]]
      name = "Games 󰊖 "
      path = "~/.steam"
      startup_command = "steam"
      
      [[session]]
      name = "Terminal Games 󰮂 "
      path = "~/"
      startup_command = "bastet"
      
      # ---------------------------------------------------------------------------
      # Backup & Sync
      # ---------------------------------------------------------------------------
      [[session]]
      name = "Backup 󰆓 "
      path = "~/"
      startup_command = "rsync --help"
      
      [[session]]
      name = "Cloud Sync ☁️ "
      path = "~/"
      startup_command = "rclone listremotes"
    '';
  };
}

