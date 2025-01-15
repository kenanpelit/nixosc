{ config, lib, pkgs, ... }:

{
  home.file.".config/hypr/pyprland.toml".text = ''
    [pyprland]
    plugins = [
      "scratchpads",
      "lost_windows",
      "monitors",
      "shift_monitors",
      "toggle_dpms",
      "expose",
      "workspaces_follow_focus",
    ]

    [workspaces_follow_focus]
    max_workspaces = 9

    [expose]
    include_special = false

    [lost_windows]
    include_special = false

    [shift_monitors]
    raise_monitor = true

    [toggle_dpms]
    dpms_timeout = 600

    [scratchpads.volume]
    animation = "fromRight"
    command = "pavucontrol"
    class = "org.pulseaudio.pavucontrol"
    size = "40% 90%"
    unfocus = "hide"
    lazy = true

    [scratchpads.yazi]
    animation = "fromTop"
    command = "kitty --class yazi yazi"
    class = "ranger"
    size = "75% 60%"
    unfocus = "hide"
    lazy = true

    [scratchpads.music]
    animation = "fromTop"
    command = "spotify"
    class = "Spotify"
    size = "80% 80%"
    unfocus = "hide"
    lazy = true

    [scratchpads.terminal]
    animation = "fromTop"
    command = "kitty --class kitty-scratch"
    class = "kitty-scratch"
    size = "75% 60%"
    unfocus = "hide"
    lazy = true

    [scratchpads.ncmpcpp]
    animation = "fromRight"
    command = "__kitty-ncmpcpp.sh"
    class = "ncmpcpp"
    size = "70% 70%"
    unfocus = "hide"
    lazy = true

    [scratchpads.notes]
    animation = "fromBottom"
    command = "kitty --class notes nvim"
    class = "notes"
    size = "70% 50%"
    unfocus = "hide"
    lazy = true
  '';

  home.packages = with pkgs; [
    pyprland
  ];
}
