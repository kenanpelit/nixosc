{ config, lib, pkgs, ... }:

{
  home.file.".config/sesh/sesh.toml".text = ''
    [default_session]
    startup_command = "lsd"

    [[session]]
    name = "Feynman  "
    path = "~/"
    startup_command = "ssh grid -t 'byobu has -t kenan || byobu new-session -d -s kenan && byobu a -t kenan'"

    [[session]]
    name = "Terminal  "
    path = "~/"
    startup_command = "ssh terminal -t 'byobu has -t kenan || byobu new-session -d -s kenan && byobu a -t kenan'"

    [[session]]
    name = "Tunnelshow  "
    path = "~/"
    startup_command = "tunnelshow"

    [[session]]
    name = "Podman-Tui 󱘖 "
    path = "~/"
    startup_command = "podman-tui"

    [[session]]
    name = "Anote  "
    path = "~/"
    startup_command = "anote_snippets.sh"

    [[session]]
    name = "Downloads 󰇚 "
    path = "~/Downloads"
    startup_command = "ranger"

    [[session]]
    name = "TmuxConfig 󰆍 "
    path = "~/.tmux"
    startup_command = "vim ~/.tmux.conf.local"

    [[session]]
    name = "Ranger 󰀶 "
    path = "~/"
    startup_command = "ranger"

    [[session]]
    name = "Update 󰚰 "
    path = "~/"
    startup_command = "upall"

    [[session]]
    name = "SSH  "
    path = "~/"
    startup_command = "t3"

    [[session]]
    name = "Project 󱌢 "
    path = "~/.projects"
    startup_command = "t3"

    [[session]]
    name = "Tor 󰖟 "
    path = "/repo/tor"
    startup_command = "t3"

    [[session]]
    name = "Music 󰎈 "
    path = "~/Music"
    startup_command = "ncmpcpp"
  '';
}
