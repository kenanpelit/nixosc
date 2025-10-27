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
  askpass = pkgs.writeShellScriptBin "askpass" (
    builtins.readFile ./bin/askpass.sh
  );
  bluetooth_toggle = pkgs.writeShellScriptBin "bluetooth_toggle" (
    builtins.readFile ./bin/bluetooth_toggle.sh
  );
  brave-extensions = pkgs.writeShellScriptBin "brave-extensions" (
    builtins.readFile ./bin/brave-extensions.sh
  );
  brave_killer = pkgs.writeShellScriptBin "brave_killer" (
    builtins.readFile ./bin/brave_killer.sh
  );
  bulk_rename = pkgs.writeShellScriptBin "bulk_rename" (
    builtins.readFile ./bin/bulk_rename.sh
  );
  chroot_manager = pkgs.writeShellScriptBin "chroot_manager" (
    builtins.readFile ./bin/chroot_manager.sh
  );
  clearam = pkgs.writeShellScriptBin "clearam" (
    builtins.readFile ./bin/clearam.sh
  );
  clipmaster = pkgs.writeShellScriptBin "clipmaster" (
    builtins.readFile ./bin/clipmaster.sh
  );
  clustergit = pkgs.writeShellScriptBin "clustergit" (
    builtins.readFile ./bin/clustergit.sh
  );
  cosmic_tty = pkgs.writeShellScriptBin "cosmic_tty" (
    builtins.readFile ./bin/cosmic_tty.sh
  );
  crypto-manager = pkgs.writeShellScriptBin "crypto-manager" (
    builtins.readFile ./bin/crypto-manager.sh
  );
  gitgo = pkgs.writeShellScriptBin "gitgo" (
    builtins.readFile ./bin/gitgo.sh
  );
  gnome-extensions-installer = pkgs.writeShellScriptBin "gnome-extensions-installer" (
    builtins.readFile ./bin/gnome-extensions-installer.sh
  );
  gnome-flow = pkgs.writeShellScriptBin "gnome-flow" (
    builtins.readFile ./bin/gnome-flow.sh
  );
  gnome-kr-fix = pkgs.writeShellScriptBin "gnome-kr-fix" (
    builtins.readFile ./bin/gnome-kr-fix.sh
  );
  gnome-mpv-manager = pkgs.writeShellScriptBin "gnome-mpv-manager" (
    builtins.readFile ./bin/gnome-mpv-manager.sh
  );
  gnome-settings = pkgs.writeShellScriptBin "gnome-settings" (
    builtins.readFile ./bin/gnome-settings.sh
  );
  gnome_tty = pkgs.writeShellScriptBin "gnome_tty" (
    builtins.readFile ./bin/gnome_tty.sh
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
  hypr-colorpicker = pkgs.writeShellScriptBin "hypr-colorpicker" (
    builtins.readFile ./bin/hypr-colorpicker.sh
  );
  hyprland_tty = pkgs.writeShellScriptBin "hyprland_tty" (
    builtins.readFile ./bin/hyprland_tty.sh
  );
  hypr-layout_toggle = pkgs.writeShellScriptBin "hypr-layout_toggle" (
    builtins.readFile ./bin/hypr-layout_toggle.sh
  );
  hypr_move_app_from_workspace = pkgs.writeShellScriptBin "hypr_move_app_from_workspace" (
    builtins.readFile ./bin/hypr_move_app_from_workspace.sh
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
  hypr-vlc_toggle = pkgs.writeShellScriptBin "hypr-vlc_toggle" (
    builtins.readFile ./bin/hypr-vlc_toggle.sh
  );
  hypr-workspace-monitor = pkgs.writeShellScriptBin "hypr-workspace-monitor" (
    builtins.readFile ./bin/hypr-workspace-monitor.sh
  );
  lofi = pkgs.writeShellScriptBin "lofi" (
    builtins.readFile ./bin/lofi.sh
  );
  m2w2 = pkgs.writeShellScriptBin "m2w2" (
    builtins.readFile ./bin/m2w2.sh
  );
  mako-status = pkgs.writeShellScriptBin "mako-status" (
    builtins.readFile ./bin/mako-status.sh
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
  osc-backup = pkgs.writeShellScriptBin "osc-backup" (
    builtins.readFile ./bin/osc-backup.sh
  );
  osc-blocklist = pkgs.writeShellScriptBin "osc-blocklist" (
    builtins.readFile ./bin/osc-blocklist.sh
  );
  osc-cleaup-grub = pkgs.writeShellScriptBin "osc-cleaup-grub" (
    builtins.readFile ./bin/osc-cleaup-grub.sh
  );
  osc-gist = pkgs.writeShellScriptBin "osc-gist" (
    builtins.readFile ./bin/osc-gist.sh
  );
  osc-gpg_unlock = pkgs.writeShellScriptBin "osc-gpg_unlock" (
    builtins.readFile ./bin/osc-gpg_unlock.sh
  );
  osc-hypr-update = pkgs.writeShellScriptBin "osc-hypr-update" (
    builtins.readFile ./bin/osc-hypr-update.sh
  );
  osc-imagekeeper = pkgs.writeShellScriptBin "osc-imagekeeper" (
    builtins.readFile ./bin/osc-imagekeeper.sh
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
  osc-perf-mode = pkgs.writeShellScriptBin "osc-perf-mode" (
    builtins.readFile ./bin/osc-perf-mode.sh
  );
  osc-profiles = pkgs.writeShellScriptBin "osc-profiles" (
    builtins.readFile ./bin/osc-profiles.sh
  );
  osc-proxy = pkgs.writeShellScriptBin "osc-proxy" (
    builtins.readFile ./bin/osc-proxy.sh
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
  osc-safe-reboot = pkgs.writeShellScriptBin "osc-safe-reboot" (
    builtins.readFile ./bin/osc-safe-reboot.sh
  );
  osc-scrcpy = pkgs.writeShellScriptBin "osc-scrcpy" (
    builtins.readFile ./bin/osc-scrcpy.sh
  );
  osc-sops = pkgs.writeShellScriptBin "osc-sops" (
    builtins.readFile ./bin/osc-sops.sh
  );
  osc-soundctl = pkgs.writeShellScriptBin "osc-soundctl" (
    builtins.readFile ./bin/osc-soundctl.sh
  );
  osc-spotify = pkgs.writeShellScriptBin "osc-spotify" (
    builtins.readFile ./bin/osc-spotify.sh
  );
  osc-ssh = pkgs.writeShellScriptBin "osc-ssh" (
    builtins.readFile ./bin/osc-ssh.sh
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
  osc-system = pkgs.writeShellScriptBin "osc-system" (
    builtins.readFile ./bin/osc-system.sh
  );
  osc-test = pkgs.writeShellScriptBin "osc-test" (
    builtins.readFile ./bin/osc-test.sh
  );
  osc-tmux-plugins-install = pkgs.writeShellScriptBin "osc-tmux-plugins-install" (
    builtins.readFile ./bin/osc-tmux-plugins-install.sh
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
  osc-wifi-home = pkgs.writeShellScriptBin "osc-wifi-home" (
    builtins.readFile ./bin/osc-wifi-home.sh
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
  rofi-iwmenu = pkgs.writeShellScriptBin "rofi-iwmenu" (
    builtins.readFile ./bin/rofi-iwmenu.sh
  );
  rofi-launcher = pkgs.writeShellScriptBin "rofi-launcher" (
    builtins.readFile ./bin/rofi-launcher.sh
  );
  rofi-performance = pkgs.writeShellScriptBin "rofi-performance" (
    builtins.readFile ./bin/rofi-performance.sh
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
  tlp-status = pkgs.writeShellScriptBin "tlp-status" (
    builtins.readFile ./bin/tlp-status.sh
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
  toggle-mic = pkgs.writeShellScriptBin "toggle-mic" (
    builtins.readFile ./bin/toggle-mic.sh
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
  videokes = pkgs.writeShellScriptBin "videokes" (
    builtins.readFile ./bin/videokes.sh
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
  vpn-waybar = pkgs.writeShellScriptBin "vpn-waybar" (
    builtins.readFile ./bin/vpn-waybar.sh
  );
  vv = pkgs.writeShellScriptBin "vv" (
    builtins.readFile ./bin/vv.sh
  );
  wallpaper-manager = pkgs.writeShellScriptBin "wallpaper-manager" (
    builtins.readFile ./bin/wallpaper-manager.sh
  );
  waybar-status = pkgs.writeShellScriptBin "waybar-status" (
    builtins.readFile ./bin/waybar-status.sh
  );
  workspace-switcher = pkgs.writeShellScriptBin "workspace-switcher" (
    builtins.readFile ./bin/workspace-switcher.sh
  );
  wrename = pkgs.writeShellScriptBin "wrename" (
    builtins.readFile ./bin/wrename.sh
  );
  ws-next = pkgs.writeShellScriptBin "ws-next" (
    builtins.readFile ./bin/ws-next.sh
  );
  ws-prev = pkgs.writeShellScriptBin "ws-prev" (
    builtins.readFile ./bin/ws-prev.sh
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
    askpass
    bluetooth_toggle
    brave-extensions
    brave_killer
    bulk_rename
    chroot_manager
    clearam
    clipmaster
    clustergit
    cosmic_tty
    crypto-manager
    gitgo
    gnome-extensions-installer
    gnome-flow
    gnome-kr-fix
    gnome-mpv-manager
    gnome-settings
    gnome_tty
    hypr-airplane_mode
    hypr-blue-gammastep-manager
    hypr-blue-hyprsunset-manager
    hypr-colorpicker
    hyprland_tty
    hypr-layout_toggle
    hypr_move_app_from_workspace
    hypr-mpv-manager
    hypr-start-batteryd
    hypr-start-disable_wifi_power_save
    hypr-vlc_toggle
    hypr-workspace-monitor
    lofi
    m2w2
    mako-status
    monitor_brightness
    move_media_files
    mpc-control
    music
    ntodo
    osc-backup
    osc-blocklist
    osc-cleaup-grub
    osc-gist
    osc-gpg_unlock
    osc-hypr-update
    osc-imagekeeper
    osc-mullvad
    osc-nix-cleanup-script
    osc-pass-tool
    osc-perf-mode
    osc-profiles
    osc-proxy
    osc-radio
    osc-rsync_backup
    osc-rsync
    osc-safe-reboot
    osc-scrcpy
    osc-sops
    osc-soundctl
    osc-spotify
    osc-ssh
    osc-subliminal
    osc-symlink_manager
    osc-sync
    osc-system
    osc-test
    osc-tmux-plugins-install
    osc-tv-splitter
    osc-ulauncher_ext
    osc-video-converter
    osc-vradio
    osc-wifi-home
    pdfkes
    playlist
    ports
    profile_brave
    profile_chrome
    publicip
    record
    renew_env
    rofi-iwmenu
    rofi-launcher
    rofi-performance
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
    svmarch
    svmnixos
    svmubuntu
    tarchiver
    ter
    tlp-status
    tm
    toggle_blur
    toggle_float
    toggle-mic
    toggle_oppacity
    toggle_waybar
    tsm
    tty_config
    videokes
    vir
    vmarch
    vmnixos
    vm-start
    vnc-connect
    vpn-waybar
    vv
    wallpaper-manager
    waybar-status
    workspace-switcher
    wrename
    ws-next
    ws-prev
    zen_profile_launcher
    zen_terminate_sessions
  ];
}
