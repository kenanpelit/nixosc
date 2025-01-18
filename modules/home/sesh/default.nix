# modules/home/sesh/default.nix
# ==============================================================================
# Sesh Terminal Session Manager Configuration 
# ==============================================================================
{ config, lib, pkgs, username, ... }:
{
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
   # ---------------------------------------------------------------------------
   # System Tools
   # ---------------------------------------------------------------------------
   [[session]]
   name = "Tunnelshow  "
   path = "~/"
   startup_command = "tunnelshow"
   [[session]]
   name = "Podman-Tui 󱘖 "
   path = "~/"
   startup_command = "podman-tui"
   # ---------------------------------------------------------------------------
   # File Management
   # ---------------------------------------------------------------------------
   [[session]]
   name = "Downloads 󰇚 "
   path = "~/Downloads"
   startup_command = "ranger"
   [[session]]
   name = "Ranger 󰀶 "
   path = "~/"
   startup_command = "ranger"
   # [... diğer oturumlar benzer şekilde gruplandırılmış...]
 '';
}
