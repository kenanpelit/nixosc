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
  check_images = pkgs.writeShellScriptBin "check_images" (
    builtins.readFile ./bin/check_images.sh
  );
  chroot_manager = pkgs.writeShellScriptBin "chroot_manager" (
    builtins.readFile ./bin/chroot_manager.sh
  );
  clearam = pkgs.writeShellScriptBin "clearam" (
    builtins.readFile ./bin/clearam.sh
  );
  clustergit = pkgs.writeShellScriptBin "clustergit" (
    builtins.readFile ./bin/clustergit.sh
  );
  container-engine-manager = pkgs.writeShellScriptBin "container-engine-manager" (
    builtins.readFile ./bin/container-engine-manager.sh
  );
  crypto-manager = pkgs.writeShellScriptBin "crypto-manager" (
    builtins.readFile ./bin/crypto-manager.sh
  );
  gitgo = pkgs.writeShellScriptBin "gitgo" (
    builtins.readFile ./bin/gitgo.sh
  );
  hypr-airplane_mode = pkgs.writeShellScriptBin "hypr-airplane_mode" (
    builtins.readFile ./bin/hypr-airplane_mode.sh
  );
  hypr-blue-gammastep-manager = pkgs.writeShellScriptBin "hypr-blue-gammastep-manager" (
    builtins.readFile ./bin/hypr-blue-gammastep-manager.sh
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
  m2w2 = pkgs.writeShellScriptBin "m2w2" (
    builtins.readFile ./bin/m2w2.sh
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
  osc-assh-manager = pkgs.writeShellScriptBin "osc-assh-manager" (
    builtins.readFile ./bin/osc-assh-manager.sh
  );
  osc-backup = pkgs.writeShellScriptBin "osc-backup" (
    builtins.readFile ./bin/osc-backup.sh
  );
  osc-blocklist = pkgs.writeShellScriptBin "osc-blocklist" (
    builtins.readFile ./bin/osc-blocklist.sh
  );
  osc-cleaup-grub = pkgs.writeShellScriptBin "osc-cleaup-grub" (
    builtins.readFile ./bin/osc-cleaup-grub.sh
  );
  osc-generate_nix = pkgs.writeShellScriptBin "osc-generate_nix" (
    builtins.readFile ./bin/osc-generate_nix.sh
  );
  osc-gist = pkgs.writeShellScriptBin "osc-gist" (
    builtins.readFile ./bin/osc-gist.sh
  );
  osc-gpg_unlock = pkgs.writeShellScriptBin "osc-gpg_unlock" (
    builtins.readFile ./bin/osc-gpg_unlock.sh
  );
  osc-mullvad = pkgs.writeShellScriptBin "osc-mullvad" (
    builtins.readFile ./bin/osc-mullvad.sh
  );
  osc-nix-cleanup-script = pkgs.writeShellScriptBin "osc-nix-cleanup-script" (
    builtins.readFile ./bin/osc-nix-cleanup-script.sh
  );
  osc-pass-tool = pkgs.writeShellScriptBin "osc-pass-tool" (
    builtins.readFile ./bin/osc-pass-tool.sh
  );
  osc-profiles = pkgs.writeShellScriptBin "osc-profiles" (
    builtins.readFile ./bin/osc-profiles.sh
  );
  osc-radio = pkgs.writeShellScriptBin "osc-radio" (
    builtins.readFile ./bin/osc-radio.sh
  );
  osc-rsync_backup = pkgs.writeShellScriptBin "osc-rsync_backup" (
    builtins.readFile ./bin/osc-rsync_backup.sh
  );
  osc-rsync = pkgs.writeShellScriptBin "osc-rsync" (
    builtins.readFile ./bin/osc-rsync.sh
  );
  osc-scrcpy = pkgs.writeShellScriptBin "osc-scrcpy" (
    builtins.readFile ./bin/osc-scrcpy.sh
  );
  osc-soundctl = pkgs.writeShellScriptBin "osc-soundctl" (
    builtins.readFile ./bin/osc-soundctl.sh
  );
  osc-spotify = pkgs.writeShellScriptBin "osc-spotify" (
    builtins.readFile ./bin/osc-spotify.sh
  );
  osc-ssh-hosts-backup-script = pkgs.writeShellScriptBin "osc-ssh-hosts-backup-script" (
    builtins.readFile ./bin/osc-ssh-hosts-backup-script.sh
  );
  osc-ssh-passwordless = pkgs.writeShellScriptBin "osc-ssh-passwordless" (
    builtins.readFile ./bin/osc-ssh-passwordless.sh
  );
  osc-ssh-session-manager = pkgs.writeShellScriptBin "osc-ssh-session-manager" (
    builtins.readFile ./bin/osc-ssh-session-manager.sh
  );
  osc-start-all = pkgs.writeShellScriptBin "osc-start-all" (
    builtins.readFile ./bin/osc-start-all.sh
  );
  osc-start-zen = pkgs.writeShellScriptBin "osc-start-zen" (
    builtins.readFile ./bin/osc-start-zen.sh
  );
  osc-subliminal = pkgs.writeShellScriptBin "osc-subliminal" (
    builtins.readFile ./bin/osc-subliminal.sh
  );
  osc-symlink_manager = pkgs.writeShellScriptBin "osc-symlink_manager" (
    builtins.readFile ./bin/osc-symlink_manager.sh
  );
  osc-sync = pkgs.writeShellScriptBin "osc-sync" (
    builtins.readFile ./bin/osc-sync.sh
  );
  osc-test = pkgs.writeShellScriptBin "osc-test" (
    builtins.readFile ./bin/osc-test.sh
  );
  osc-tv-splitter = pkgs.writeShellScriptBin "osc-tv-splitter" (
    builtins.readFile ./bin/osc-tv-splitter.sh
  );
  osc-ulauncher_ext = pkgs.writeShellScriptBin "osc-ulauncher_ext" (
    builtins.readFile ./bin/osc-ulauncher_ext.sh
  );
  osc-video-converter = pkgs.writeShellScriptBin "osc-video-converter" (
    builtins.readFile ./bin/osc-video-converter.sh
  );
  osc-vradio = pkgs.writeShellScriptBin "osc-vradio" (
    builtins.readFile ./bin/osc-vradio.sh
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
  semsumo = pkgs.writeShellScriptBin "semsumo" (
    builtins.readFile ./bin/semsumo.sh
  );
  sil_ayni_mp4 = pkgs.writeShellScriptBin "sil_ayni_mp4" (
    builtins.readFile ./bin/sil_ayni_mp4.sh
  );
  smart-suspend = pkgs.writeShellScriptBin "smart-suspend" (
    builtins.readFile ./bin/smart-suspend.sh
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
  svmarch = pkgs.writeShellScriptBin "svmarch" (
    builtins.readFile ./bin/svmarch.sh
  );
  svmnixos = pkgs.writeShellScriptBin "svmnixos" (
    builtins.readFile ./bin/svmnixos.sh
  );
  svmubuntu = pkgs.writeShellScriptBin "svmubuntu" (
    builtins.readFile ./bin/svmubuntu.sh
  );
  tarchiver = pkgs.writeShellScriptBin "tarchiver" (
    builtins.readFile ./bin/tarchiver.sh
  );
  ter = pkgs.writeShellScriptBin "ter" (
    builtins.readFile ./bin/ter.sh
  );
  tm = pkgs.writeShellScriptBin "tm" (
    builtins.readFile ./bin/tm.sh
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
  vir = pkgs.writeShellScriptBin "vir" (
    builtins.readFile ./bin/vir.sh
  );
  vmarch = pkgs.writeShellScriptBin "vmarch" (
    builtins.readFile ./bin/vmarch.sh
  );
  vmnixos = pkgs.writeShellScriptBin "vmnixos" (
    builtins.readFile ./bin/vmnixos.sh
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
  zen_profile_launcher = pkgs.writeShellScriptBin "zen_profile_launcher" (
    builtins.readFile ./bin/zen_profile_launcher.sh
  );
  zen_terminate_sessions = pkgs.writeShellScriptBin "zen_terminate_sessions" (
    builtins.readFile ./bin/zen_terminate_sessions.sh
  );
in {
  home.packages = with pkgs; [
    anote
    anotes
    ascii
    bulk_rename
    check_images
    chroot_manager
    clearam
    clustergit
    container-engine-manager
    crypto-manager
    gitgo
    hypr-airplane_mode
    hypr-blue-gammastep-manager
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
    hypr-startup-manager
    hypr-vlc_toggle
    hypr-workspace-monitor
    image-deduplicator
    lofi
    m2w2
    monitor_brightness
    move_media_files
    mpc-control
    music
    ntodo
    osc-assh-manager
    osc-backup
    osc-blocklist
    osc-cleaup-grub
    osc-generate_nix
    osc-gist
    osc-gpg_unlock
    osc-mullvad
    osc-nix-cleanup-script
    osc-pass-tool
    osc-profiles
    osc-radio
    osc-rsync_backup
    osc-rsync
    osc-scrcpy
    osc-soundctl
    osc-spotify
    osc-ssh-hosts-backup-script
    osc-ssh-passwordless
    osc-ssh-session-manager
    osc-start-all
    osc-start-zen
    osc-subliminal
    osc-symlink_manager
    osc-sync
    osc-test
    osc-tv-splitter
    osc-ulauncher_ext
    osc-video-converter
    osc-vradio
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
    semsumo
    sil_ayni_mp4
    smart-suspend
    ssh-launcher
    startup-manager
    st
    svmarch
    svmnixos
    svmubuntu
    tarchiver
    ter
    tm
    toggle_blur
    toggle_float
    toggle_oppacity
    toggle_waybar
    tsm
    tty_config
    vir
    vmarch
    vmnixos
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
    zen_profile_launcher
    zen_terminate_sessions
  ];
}
