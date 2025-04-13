{ pkgs, ... }:
let
  anote = pkgs.writeShellScriptBin "anote" (
    builtins.readFile ./bin/anote.sh
  );
  anotes = pkgs.writeShellScriptBin "anotes" (
    builtins.readFile ./bin/anotes.sh
  );
  ascii = pkgs.writeShellScriptBin "ascii" (
    builtins.readFile ./bin/ascii.sh
  );
  bulk_rename = pkgs.writeShellScriptBin "bulk_rename" (
    builtins.readFile ./bin/bulk_rename.sh
  );
  clearam = pkgs.writeShellScriptBin "clearam" (
    builtins.readFile ./bin/clearam.sh
  );
  clustergit = pkgs.writeShellScriptBin "clustergit" (
    builtins.readFile ./bin/clustergit.sh
  );
  compress = pkgs.writeShellScriptBin "compress" (
    builtins.readFile ./bin/compress.sh
  );
  container-engine-manager = pkgs.writeShellScriptBin "container-engine-manager" (
    builtins.readFile ./bin/container-engine-manager.sh
  );
  extract = pkgs.writeShellScriptBin "extract" (
    builtins.readFile ./bin/extract.sh
  );
  gnome-start-all = pkgs.writeShellScriptBin "gnome-start-all" (
    builtins.readFile ./bin/gnome-start-all.sh
  );
  hypr-airplane_mode = pkgs.writeShellScriptBin "hypr-airplane_mode" (
    builtins.readFile ./bin/hypr-airplane_mode.sh
  );
  hypr-blue-gammastep-manager = pkgs.writeShellScriptBin "hypr-blue-gammastep-manager" (
    builtins.readFile ./bin/hypr-blue-gammastep-manager.sh
  );
  hypr-blue-hyprshade-manager = pkgs.writeShellScriptBin "hypr-blue-hyprshade-manager" (
    builtins.readFile ./bin/hypr-blue-hyprshade-manager.sh
  );
  hypr-blue-hyprsunset-manager = pkgs.writeShellScriptBin "hypr-blue-hyprsunset-manager" (
    builtins.readFile ./bin/hypr-blue-hyprsunset-manager.sh
  );
  hypr-bluetooth_toggle = pkgs.writeShellScriptBin "hypr-bluetooth_toggle" (
    builtins.readFile ./bin/hypr-bluetooth_toggle.sh
  );
  hypr-colorpicker = pkgs.writeShellScriptBin "hypr-colorpicker" (
    builtins.readFile ./bin/hypr-colorpicker.sh
  );
  hypr-ctl_focusmonitor = pkgs.writeShellScriptBin "hypr-ctl_focusmonitor" (
    builtins.readFile ./bin/hypr-ctl_focusmonitor.sh
  );
  hypr-ctl_setup_dual_monitors = pkgs.writeShellScriptBin "hypr-ctl_setup_dual_monitors" (
    builtins.readFile ./bin/hypr-ctl_setup_dual_monitors.sh
  );
  hypr-mpv-manager = pkgs.writeShellScriptBin "hypr-mpv-manager" (
    builtins.readFile ./bin/hypr-mpv-manager.sh
  );
  hypr-start-batteryd = pkgs.writeShellScriptBin "hypr-start-batteryd" (
    builtins.readFile ./bin/hypr-start-batteryd.sh
  );
  hypr-start-disable_wifi_power_save = pkgs.writeShellScriptBin "hypr-start-disable_wifi_power_save" (
    builtins.readFile ./bin/hypr-start-disable_wifi_power_save.sh
  );
  hypr-start-manager = pkgs.writeShellScriptBin "hypr-start-manager" (
    builtins.readFile ./bin/hypr-start-manager.sh
  );
  hypr-start-semsumo-all = pkgs.writeShellScriptBin "hypr-start-semsumo-all" (
    builtins.readFile ./bin/hypr-start-semsumo-all.sh
  );
  hypr-start-semsumo-light = pkgs.writeShellScriptBin "hypr-start-semsumo-light" (
    builtins.readFile ./bin/hypr-start-semsumo-light.sh
  );
  hypr-start-update = pkgs.writeShellScriptBin "hypr-start-update" (
    builtins.readFile ./bin/hypr-start-update.sh
  );
  hypr-startup-manager = pkgs.writeShellScriptBin "hypr-startup-manager" (
    builtins.readFile ./bin/hypr-startup-manager.sh
  );
  hypr-vlc_toggle = pkgs.writeShellScriptBin "hypr-vlc_toggle" (
    builtins.readFile ./bin/hypr-vlc_toggle.sh
  );
  hypr-workspace-monitor = pkgs.writeShellScriptBin "hypr-workspace-monitor" (
    builtins.readFile ./bin/hypr-workspace-monitor.sh
  );
  image-deduplicator = pkgs.writeShellScriptBin "image-deduplicator" (
    builtins.readFile ./bin/image-deduplicator.sh
  );
  lofi = pkgs.writeShellScriptBin "lofi" (
    builtins.readFile ./bin/lofi.sh
  );
  monitor_brightness = pkgs.writeShellScriptBin "monitor_brightness" (
    builtins.readFile ./bin/monitor_brightness.sh
  );
  move_media_files = pkgs.writeShellScriptBin "move_media_files" (
    builtins.readFile ./bin/move_media_files.sh
  );
  mpc-control = pkgs.writeShellScriptBin "mpc-control" (
    builtins.readFile ./bin/mpc-control.sh
  );
  music = pkgs.writeShellScriptBin "music" (
    builtins.readFile ./bin/music.sh
  );
  ntodo = pkgs.writeShellScriptBin "ntodo" (
    builtins.readFile ./bin/ntodo.sh
  );
  pass-clip-both = pkgs.writeShellScriptBin "pass-clip-both" (
    builtins.readFile ./bin/pass-clip-both.sh
  );
  pdfkes = pkgs.writeShellScriptBin "pdfkes" (
    builtins.readFile ./bin/pdfkes.sh
  );
  playlist = pkgs.writeShellScriptBin "playlist" (
    builtins.readFile ./bin/playlist.sh
  );
  ports = pkgs.writeShellScriptBin "ports" (
    builtins.readFile ./bin/ports.sh
  );
  power-menu = pkgs.writeShellScriptBin "power-menu" (
    builtins.readFile ./bin/power-menu.sh
  );
  profile_brave = pkgs.writeShellScriptBin "profile_brave" (
    builtins.readFile ./bin/profile_brave.sh
  );
  profile_chrome = pkgs.writeShellScriptBin "profile_chrome" (
    builtins.readFile ./bin/profile_chrome.sh
  );
  publicip = pkgs.writeShellScriptBin "publicip" (
    builtins.readFile ./bin/publicip.sh
  );
  record = pkgs.writeShellScriptBin "record" (
    builtins.readFile ./bin/record.sh
  );
  renew_env = pkgs.writeShellScriptBin "renew_env" (
    builtins.readFile ./bin/renew_env.sh
  );
  rofi-frecency = pkgs.writeShellScriptBin "rofi-frecency" (
    builtins.readFile ./bin/rofi-frecency.sh
  );
  rofi-hypr-keybinds = pkgs.writeShellScriptBin "rofi-hypr-keybinds" (
    builtins.readFile ./bin/rofi-hypr-keybinds.sh
  );
  rofi-iwmenu = pkgs.writeShellScriptBin "rofi-iwmenu" (
    builtins.readFile ./bin/rofi-iwmenu.sh
  );
  rofi-launcher = pkgs.writeShellScriptBin "rofi-launcher" (
    builtins.readFile ./bin/rofi-launcher.sh
  );
  rofi-power-menu = pkgs.writeShellScriptBin "rofi-power-menu" (
    builtins.readFile ./bin/rofi-power-menu.sh
  );
  rofi-power = pkgs.writeShellScriptBin "rofi-power" (
    builtins.readFile ./bin/rofi-power.sh
  );
  rofi-wifi = pkgs.writeShellScriptBin "rofi-wifi" (
    builtins.readFile ./bin/rofi-wifi.sh
  );
  rsync_backup = pkgs.writeShellScriptBin "rsync_backup" (
    builtins.readFile ./bin/rsync_backup.sh
  );
  rsync-retry = pkgs.writeShellScriptBin "rsync-retry" (
    builtins.readFile ./bin/rsync-retry.sh
  );
  rsync-tool = pkgs.writeShellScriptBin "rsync-tool" (
    builtins.readFile ./bin/rsync-tool.sh
  );
  runbg = pkgs.writeShellScriptBin "runbg" (
    builtins.readFile ./bin/runbg.sh
  );
  screenshot = pkgs.writeShellScriptBin "screenshot" (
    builtins.readFile ./bin/screenshot.sh
  );
  sil_ayni_mp4 = pkgs.writeShellScriptBin "sil_ayni_mp4" (
    builtins.readFile ./bin/sil_ayni_mp4.sh
  );
  smart-suspend = pkgs.writeShellScriptBin "smart-suspend" (
    builtins.readFile ./bin/smart-suspend.sh
  );
  snippets = pkgs.writeShellScriptBin "snippets" (
    builtins.readFile ./bin/snippets.sh
  );
  ssh-launcher = pkgs.writeShellScriptBin "ssh-launcher" (
    builtins.readFile ./bin/ssh-launcher.sh
  );
  startup-manager = pkgs.writeShellScriptBin "startup-manager" (
    builtins.readFile ./bin/startup-manager.sh
  );
  st = pkgs.writeShellScriptBin "st" (
    builtins.readFile ./bin/st.sh
  );
  ter = pkgs.writeShellScriptBin "ter" (
    builtins.readFile ./bin/ter.sh
  );
  tm = pkgs.writeShellScriptBin "tm" (
    builtins.readFile ./bin/tm.sh
  );
  tmux-backup = pkgs.writeShellScriptBin "tmux-backup" (
    builtins.readFile ./bin/tmux-backup.sh
  );
  tmux-copy = pkgs.writeShellScriptBin "tmux-copy" (
    builtins.readFile ./bin/tmux-copy.sh
  );
  tmux-fspeed = pkgs.writeShellScriptBin "tmux-fspeed" (
    builtins.readFile ./bin/tmux-fspeed.sh
  );
  tmux_kenp = pkgs.writeShellScriptBin "tmux_kenp" (
    builtins.readFile ./bin/tmux_kenp.sh
  );
  tmux-plugins = pkgs.writeShellScriptBin "tmux-plugins" (
    builtins.readFile ./bin/tmux-plugins.sh
  );
  tmux-startup = pkgs.writeShellScriptBin "tmux-startup" (
    builtins.readFile ./bin/tmux-startup.sh
  );
  toggle_blur = pkgs.writeShellScriptBin "toggle_blur" (
    builtins.readFile ./bin/toggle_blur.sh
  );
  toggle_float = pkgs.writeShellScriptBin "toggle_float" (
    builtins.readFile ./bin/toggle_float.sh
  );
  toggle_oppacity = pkgs.writeShellScriptBin "toggle_oppacity" (
    builtins.readFile ./bin/toggle_oppacity.sh
  );
  toggle_waybar = pkgs.writeShellScriptBin "toggle_waybar" (
    builtins.readFile ./bin/toggle_waybar.sh
  );
  tsm = pkgs.writeShellScriptBin "tsm" (
    builtins.readFile ./bin/tsm.sh
  );
  tty_config = pkgs.writeShellScriptBin "tty_config" (
    builtins.readFile ./bin/tty_config.sh
  );
  turbo-boost-setup = pkgs.writeShellScriptBin "turbo-boost-setup" (
    builtins.readFile ./bin/turbo-boost-setup.sh
  );
  vir = pkgs.writeShellScriptBin "vir" (
    builtins.readFile ./bin/vir.sh
  );
  vm-start = pkgs.writeShellScriptBin "vm-start" (
    builtins.readFile ./bin/vm-start.sh
  );
  vnc-connect = pkgs.writeShellScriptBin "vnc-connect" (
    builtins.readFile ./bin/vnc-connect.sh
  );
  wallpaper-manager = pkgs.writeShellScriptBin "wallpaper-manager" (
    builtins.readFile ./bin/wallpaper-manager.sh
  );
  waybar-bluelightfilter-monitor = pkgs.writeShellScriptBin "waybar-bluelightfilter-monitor" (
    builtins.readFile ./bin/waybar-bluelightfilter-monitor.sh
  );
  waybar-bluelightfilter-toggle = pkgs.writeShellScriptBin "waybar-bluelightfilter-toggle" (
    builtins.readFile ./bin/waybar-bluelightfilter-toggle.sh
  );
  waybar-bluetooth-menu = pkgs.writeShellScriptBin "waybar-bluetooth-menu" (
    builtins.readFile ./bin/waybar-bluetooth-menu.sh
  );
  waybar-hyprshade_toggle = pkgs.writeShellScriptBin "waybar-hyprshade_toggle" (
    builtins.readFile ./bin/waybar-hyprshade_toggle.sh
  );
  waybar-idle-inhibitor = pkgs.writeShellScriptBin "waybar-idle-inhibitor" (
    builtins.readFile ./bin/waybar-idle-inhibitor.sh
  );
  waybar-mic = pkgs.writeShellScriptBin "waybar-mic" (
    builtins.readFile ./bin/waybar-mic.sh
  );
  waybar-vpn-mullvad-check = pkgs.writeShellScriptBin "waybar-vpn-mullvad-check" (
    builtins.readFile ./bin/waybar-vpn-mullvad-check.sh
  );
  waybar-vpn-other-check = pkgs.writeShellScriptBin "waybar-vpn-other-check" (
    builtins.readFile ./bin/waybar-vpn-other-check.sh
  );
  waybar-vpn-status-check = pkgs.writeShellScriptBin "waybar-vpn-status-check" (
    builtins.readFile ./bin/waybar-vpn-status-check.sh
  );
  waybar-weather-full = pkgs.writeShellScriptBin "waybar-weather-full" (
    builtins.readFile ./bin/waybar-weather-full.sh
  );
  waybar-weather-update = pkgs.writeShellScriptBin "waybar-weather-update" (
    builtins.readFile ./bin/waybar-weather-update.sh
  );
  waybar-wf-recorder = pkgs.writeShellScriptBin "waybar-wf-recorder" (
    builtins.readFile ./bin/waybar-wf-recorder.sh
  );
  wrename = pkgs.writeShellScriptBin "wrename" (
    builtins.readFile ./bin/wrename.sh
  );
in {
  home.packages = with pkgs; [
    anote
    anotes
    ascii
    bulk_rename
    clearam
    clustergit
    compress
    container-engine-manager
    extract
    gnome-start-all
    hypr-airplane_mode
    hypr-blue-gammastep-manager
    hypr-blue-hyprshade-manager
    hypr-blue-hyprsunset-manager
    hypr-bluetooth_toggle
    hypr-colorpicker
    hypr-ctl_focusmonitor
    hypr-ctl_setup_dual_monitors
    hypr-mpv-manager
    hypr-start-batteryd
    hypr-start-disable_wifi_power_save
    hypr-start-manager
    hypr-start-semsumo-all
    hypr-start-semsumo-light
    hypr-start-update
    hypr-startup-manager
    hypr-vlc_toggle
    hypr-workspace-monitor
    image-deduplicator
    lofi
    monitor_brightness
    move_media_files
    mpc-control
    music
    ntodo
    pass-clip-both
    pdfkes
    playlist
    ports
    power-menu
    profile_brave
    profile_chrome
    publicip
    record
    renew_env
    rofi-frecency
    rofi-hypr-keybinds
    rofi-iwmenu
    rofi-launcher
    rofi-power-menu
    rofi-power
    rofi-wifi
    rsync_backup
    rsync-retry
    rsync-tool
    runbg
    screenshot
    sil_ayni_mp4
    smart-suspend
    snippets
    ssh-launcher
    startup-manager
    st
    ter
    tm
    tmux-backup
    tmux-copy
    tmux-fspeed
    tmux_kenp
    tmux-plugins
    tmux-startup
    toggle_blur
    toggle_float
    toggle_oppacity
    toggle_waybar
    tsm
    tty_config
    turbo-boost-setup
    vir
    vm-start
    vnc-connect
    wallpaper-manager
    waybar-bluelightfilter-monitor
    waybar-bluelightfilter-toggle
    waybar-bluetooth-menu
    waybar-hyprshade_toggle
    waybar-idle-inhibitor
    waybar-mic
    waybar-vpn-mullvad-check
    waybar-vpn-other-check
    waybar-vpn-status-check
    waybar-weather-full
    waybar-weather-update
    waybar-wf-recorder
    wrename
  ];
}
