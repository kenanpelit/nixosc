{ pkgs, ... }:
let
  anote = pkgs.writeShellScriptBin "anote" (
    builtins.readFile ./bin/anote.sh
  );
  ascii = pkgs.writeShellScriptBin "ascii" (
    builtins.readFile ./bin/ascii.sh
  );
  assh-manager = pkgs.writeShellScriptBin "assh-manager" (
    builtins.readFile ./bin/assh-manager.sh
  );
  backup_config = pkgs.writeShellScriptBin "backup_config" (
    builtins.readFile ./bin/backup_config.sh
  );
  blocklist = pkgs.writeShellScriptBin "blocklist" (
    builtins.readFile ./bin/blocklist.sh
  );
  bulk_rename = pkgs.writeShellScriptBin "bulk_rename" (
    builtins.readFile ./bin/bulk_rename.sh
  );
  clearam = pkgs.writeShellScriptBin "clearam" (
    builtins.readFile ./bin/clearam.sh
  );
  clustergit-bash = pkgs.writeShellScriptBin "clustergit-bash" (
    builtins.readFile ./bin/clustergit-bash.sh
  );
  compress = pkgs.writeShellScriptBin "compress" (
    builtins.readFile ./bin/compress.sh
  );
  container-engine-manager = pkgs.writeShellScriptBin "container-engine-manager" (
    builtins.readFile ./bin/container-engine-manager.sh
  );
  container-monitor = pkgs.writeShellScriptBin "container-monitor" (
    builtins.readFile ./bin/container-monitor.sh
  );
  crypto-manager = pkgs.writeShellScriptBin "crypto-manager" (
    builtins.readFile ./bin/crypto-manager.sh
  );
  desktop-files-ranger-yazi = pkgs.writeShellScriptBin "desktop-files-ranger-yazi" (
    builtins.readFile ./bin/desktop-files-ranger-yazi.sh
  );
  dotfiles-manager = pkgs.writeShellScriptBin "dotfiles-manager" (
    builtins.readFile ./bin/dotfiles-manager.sh
  );
  dotfiles = pkgs.writeShellScriptBin "dotfiles" (
    builtins.readFile ./bin/dotfiles.sh
  );
  extract = pkgs.writeShellScriptBin "extract" (
    builtins.readFile ./bin/extract.sh
  );
  generate_nix_bin = pkgs.writeShellScriptBin "generate_nix_bin" (
    builtins.readFile ./bin/generate_nix_bin.sh
  );
  generate_nix_start = pkgs.writeShellScriptBin "generate_nix_start" (
    builtins.readFile ./bin/generate_nix_start.sh
  );
  gitgo = pkgs.writeShellScriptBin "gitgo" (
    builtins.readFile ./bin/gitgo.sh
  );
  gitsumo = pkgs.writeShellScriptBin "gitsumo" (
    builtins.readFile ./bin/gitsumo.sh
  );
  gnome-start-all = pkgs.writeShellScriptBin "gnome-start-all" (
    builtins.readFile ./bin/gnome-start-all.sh
  );
  hypr-airplane_mode = pkgs.writeShellScriptBin "hypr-airplane_mode" (
    builtins.readFile ./bin/hypr-airplane_mode.sh
  );
  hypr-audio_switcher = pkgs.writeShellScriptBin "hypr-audio_switcher" (
    builtins.readFile ./bin/hypr-audio_switcher.sh
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
  hypr-blue-wlsunset-mananger = pkgs.writeShellScriptBin "hypr-blue-wlsunset-mananger" (
    builtins.readFile ./bin/hypr-blue-wlsunset-mananger.sh
  );
  hypr-clibp = pkgs.writeShellScriptBin "hypr-clibp" (
    builtins.readFile ./bin/hypr-clibp.sh
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
  hypr-monitor_toggle = pkgs.writeShellScriptBin "hypr-monitor_toggle" (
    builtins.readFile ./bin/hypr-monitor_toggle.sh
  );
  hypr-mpv-manager = pkgs.writeShellScriptBin "hypr-mpv-manager" (
    builtins.readFile ./bin/hypr-mpv-manager.sh
  );
  hypr-mullvad_toggle = pkgs.writeShellScriptBin "hypr-mullvad_toggle" (
    builtins.readFile ./bin/hypr-mullvad_toggle.sh
  );
  hypr-screenshot = pkgs.writeShellScriptBin "hypr-screenshot" (
    builtins.readFile ./bin/hypr-screenshot.sh
  );
  hypr-spotify_toggle = pkgs.writeShellScriptBin "hypr-spotify_toggle" (
    builtins.readFile ./bin/hypr-spotify_toggle.sh
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
  hypr-status-check = pkgs.writeShellScriptBin "hypr-status-check" (
    builtins.readFile ./bin/hypr-status-check.sh
  );
  hypr-vlc_toggle = pkgs.writeShellScriptBin "hypr-vlc_toggle" (
    builtins.readFile ./bin/hypr-vlc_toggle.sh
  );
  hypr-workspace-monitor = pkgs.writeShellScriptBin "hypr-workspace-monitor" (
    builtins.readFile ./bin/hypr-workspace-monitor.sh
  );
  keybinds = pkgs.writeShellScriptBin "keybinds" (
    builtins.readFile ./bin/keybinds.sh
  );
  kitty-toggle-font = pkgs.writeShellScriptBin "kitty-toggle-font" (
    builtins.readFile ./bin/kitty-toggle-font.sh
  );
  lofi = pkgs.writeShellScriptBin "lofi" (
    builtins.readFile ./bin/lofi.sh
  );
  maxfetch = pkgs.writeShellScriptBin "maxfetch" (
    builtins.readFile ./bin/maxfetch.sh
  );
  mkv2mp4 = pkgs.writeShellScriptBin "mkv2mp4" (
    builtins.readFile ./bin/mkv2mp4.sh
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
  mrelay = pkgs.writeShellScriptBin "mrelay" (
    builtins.readFile ./bin/mrelay.sh
  );
  mullvad-dns-setup = pkgs.writeShellScriptBin "mullvad-dns-setup" (
    builtins.readFile ./bin/mullvad-dns-setup.sh
  );
  mullvad_toggle = pkgs.writeShellScriptBin "mullvad_toggle" (
    builtins.readFile ./bin/mullvad_toggle.sh
  );
  music = pkgs.writeShellScriptBin "music" (
    builtins.readFile ./bin/music.sh
  );
  network-reset-all = pkgs.writeShellScriptBin "network-reset-all" (
    builtins.readFile ./bin/network-reset-all.sh
  );
  network-reset = pkgs.writeShellScriptBin "network-reset" (
    builtins.readFile ./bin/network-reset.sh
  );
  nixos-profiles = pkgs.writeShellScriptBin "nixos-profiles" (
    builtins.readFile ./bin/nixos-profiles.sh
  );
  pass-clip-both = pkgs.writeShellScriptBin "pass-clip-both" (
    builtins.readFile ./bin/pass-clip-both.sh
  );
  pass_tool = pkgs.writeShellScriptBin "pass_tool" (
    builtins.readFile ./bin/pass_tool.sh
  );
  pdfkes = pkgs.writeShellScriptBin "pdfkes" (
    builtins.readFile ./bin/pdfkes.sh
  );
  playlist = pkgs.writeShellScriptBin "playlist" (
    builtins.readFile ./bin/playlist.sh
  );
  pop-shell-install = pkgs.writeShellScriptBin "pop-shell-install" (
    builtins.readFile ./bin/pop-shell-install.sh
  );
  ports = pkgs.writeShellScriptBin "ports" (
    builtins.readFile ./bin/ports.sh
  );
  power-menu = pkgs.writeShellScriptBin "power-menu" (
    builtins.readFile ./bin/power-menu.sh
  );
  publicip = pkgs.writeShellScriptBin "publicip" (
    builtins.readFile ./bin/publicip.sh
  );
  random-wallpaper = pkgs.writeShellScriptBin "random-wallpaper" (
    builtins.readFile ./bin/random-wallpaper.sh
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
  rofi-launch = pkgs.writeShellScriptBin "rofi-launch" (
    builtins.readFile ./bin/rofi-launch.sh
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
  satty-screenshot = pkgs.writeShellScriptBin "satty-screenshot" (
    builtins.readFile ./bin/satty-screenshot.sh
  );
  ScrcpyUSB = pkgs.writeShellScriptBin "ScrcpyUSB" (
    builtins.readFile ./bin/ScrcpyUSB.sh
  );
  ScrcpyWiFi = pkgs.writeShellScriptBin "ScrcpyWiFi" (
    builtins.readFile ./bin/ScrcpyWiFi.sh
  );
  screenshot = pkgs.writeShellScriptBin "screenshot" (
    builtins.readFile ./bin/screenshot.sh
  );
  semsumo-create = pkgs.writeShellScriptBin "semsumo-create" (
    builtins.readFile ./bin/semsumo-create.sh
  );
  semsumo = pkgs.writeShellScriptBin "semsumo" (
    builtins.readFile ./bin/semsumo.sh
  );
  semsumo-wofi-start = pkgs.writeShellScriptBin "semsumo-wofi-start" (
    builtins.readFile ./bin/semsumo-wofi-start.sh
  );
  set-defaults-mimetype = pkgs.writeShellScriptBin "set-defaults-mimetype" (
    builtins.readFile ./bin/set-defaults-mimetype.sh
  );
  set-default-terminal = pkgs.writeShellScriptBin "set-default-terminal" (
    builtins.readFile ./bin/set-default-terminal.sh
  );
  sil_ayni_mp4 = pkgs.writeShellScriptBin "sil_ayni_mp4" (
    builtins.readFile ./bin/sil_ayni_mp4.sh
  );
  sil_ayni_wall = pkgs.writeShellScriptBin "sil_ayni_wall" (
    builtins.readFile ./bin/sil_ayni_wall.sh
  );
  smart-suspend = pkgs.writeShellScriptBin "smart-suspend" (
    builtins.readFile ./bin/smart-suspend.sh
  );
  snippetp = pkgs.writeShellScriptBin "snippetp" (
    builtins.readFile ./bin/snippetp.sh
  );
  snippets = pkgs.writeShellScriptBin "snippets" (
    builtins.readFile ./bin/snippets.sh
  );
  ssh-hosts-backup-script = pkgs.writeShellScriptBin "ssh-hosts-backup-script" (
    builtins.readFile ./bin/ssh-hosts-backup-script.sh
  );
  ssh-launcher = pkgs.writeShellScriptBin "ssh-launcher" (
    builtins.readFile ./bin/ssh-launcher.sh
  );
  ssh-passwordless = pkgs.writeShellScriptBin "ssh-passwordless" (
    builtins.readFile ./bin/ssh-passwordless.sh
  );
  ssh-session-manager = pkgs.writeShellScriptBin "ssh-session-manager" (
    builtins.readFile ./bin/ssh-session-manager.sh
  );
  start-foot-server = pkgs.writeShellScriptBin "start-foot-server" (
    builtins.readFile ./bin/start-foot-server.sh
  );
  startup-manager = pkgs.writeShellScriptBin "startup-manager" (
    builtins.readFile ./bin/startup-manager.sh
  );
  st = pkgs.writeShellScriptBin "st" (
    builtins.readFile ./bin/st.sh
  );
  tkenp = pkgs.writeShellScriptBin "tkenp" (
    builtins.readFile ./bin/tkenp.sh
  );
  tmo = pkgs.writeShellScriptBin "tmo" (
    builtins.readFile ./bin/tmo.sh
  );
  tmux-backup = pkgs.writeShellScriptBin "tmux-backup" (
    builtins.readFile ./bin/tmux-backup.sh
  );
  tmux-copy = pkgs.writeShellScriptBin "tmux-copy" (
    builtins.readFile ./bin/tmux-copy.sh
  );
  tmux_cta = pkgs.writeShellScriptBin "tmux_cta" (
    builtins.readFile ./bin/tmux_cta.sh
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
  transmission-install = pkgs.writeShellScriptBin "transmission-install" (
    builtins.readFile ./bin/transmission-install.sh
  );
  tsm = pkgs.writeShellScriptBin "tsm" (
    builtins.readFile ./bin/tsm.sh
  );
  tsms = pkgs.writeShellScriptBin "tsms" (
    builtins.readFile ./bin/tsms.sh
  );
  tty_config = pkgs.writeShellScriptBin "tty_config" (
    builtins.readFile ./bin/tty_config.sh
  );
  turbo-boost-setup = pkgs.writeShellScriptBin "turbo-boost-setup" (
    builtins.readFile ./bin/turbo-boost-setup.sh
  );
  ulauncher_ext = pkgs.writeShellScriptBin "ulauncher_ext" (
    builtins.readFile ./bin/ulauncher_ext.sh
  );
  video_info = pkgs.writeShellScriptBin "video_info" (
    builtins.readFile ./bin/video_info.sh
  );
  vmarchq = pkgs.writeShellScriptBin "vmarchq" (
    builtins.readFile ./bin/vmarchq.sh
  );
  vmarch = pkgs.writeShellScriptBin "vmarch" (
    builtins.readFile ./bin/vmarch.sh
  );
  vmbuntu = pkgs.writeShellScriptBin "vmbuntu" (
    builtins.readFile ./bin/vmbuntu.sh
  );
  vmnixosq = pkgs.writeShellScriptBin "vmnixosq" (
    builtins.readFile ./bin/vmnixosq.sh
  );
  vmnixos = pkgs.writeShellScriptBin "vmnixos" (
    builtins.readFile ./bin/vmnixos.sh
  );
  vmnixos_uefi = pkgs.writeShellScriptBin "vmnixos_uefi" (
    builtins.readFile ./bin/vmnixos_uefi.sh
  );
  vm-start = pkgs.writeShellScriptBin "vm-start" (
    builtins.readFile ./bin/vm-start.sh
  );
  vvmnixos = pkgs.writeShellScriptBin "vvmnixos" (
    builtins.readFile ./bin/vvmnixos.sh
  );
  wall-change = pkgs.writeShellScriptBin "wall-change" (
    builtins.readFile ./bin/wall-change.sh
  );
  wallpaper-picker = pkgs.writeShellScriptBin "wallpaper-picker" (
    builtins.readFile ./bin/wallpaper-picker.sh
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
  waybar-wofi-cliphist = pkgs.writeShellScriptBin "waybar-wofi-cliphist" (
    builtins.readFile ./bin/waybar-wofi-cliphist.sh
  );
  waybar-wofi-powerprofiles = pkgs.writeShellScriptBin "waybar-wofi-powerprofiles" (
    builtins.readFile ./bin/waybar-wofi-powerprofiles.sh
  );
  waybar-wofi-wifi = pkgs.writeShellScriptBin "waybar-wofi-wifi" (
    builtins.readFile ./bin/waybar-wofi-wifi.sh
  );
  wmarch = pkgs.writeShellScriptBin "wmarch" (
    builtins.readFile ./bin/wmarch.sh
  );
  wofi-bluetooth = pkgs.writeShellScriptBin "wofi-bluetooth" (
    builtins.readFile ./bin/wofi-bluetooth.sh
  );
  wofi-browser = pkgs.writeShellScriptBin "wofi-browser" (
    builtins.readFile ./bin/wofi-browser.sh
  );
  wofi-cliphist = pkgs.writeShellScriptBin "wofi-cliphist" (
    builtins.readFile ./bin/wofi-cliphist.sh
  );
  wofi-firefox = pkgs.writeShellScriptBin "wofi-firefox" (
    builtins.readFile ./bin/wofi-firefox.sh
  );
  wofi-font-manager = pkgs.writeShellScriptBin "wofi-font-manager" (
    builtins.readFile ./bin/wofi-font-manager.sh
  );
  wofi-keybinds = pkgs.writeShellScriptBin "wofi-keybinds" (
    builtins.readFile ./bin/wofi-keybinds.sh
  );
  wofi-launch-zen = pkgs.writeShellScriptBin "wofi-launch-zen" (
    builtins.readFile ./bin/wofi-launch-zen.sh
  );
  wofi-main = pkgs.writeShellScriptBin "wofi-main" (
    builtins.readFile ./bin/wofi-main.sh
  );
  wofi-manager = pkgs.writeShellScriptBin "wofi-manager" (
    builtins.readFile ./bin/wofi-manager.sh
  );
  wofi-media = pkgs.writeShellScriptBin "wofi-media" (
    builtins.readFile ./bin/wofi-media.sh
  );
  wofi-powerprofiles = pkgs.writeShellScriptBin "wofi-powerprofiles" (
    builtins.readFile ./bin/wofi-powerprofiles.sh
  );
  wofi-power = pkgs.writeShellScriptBin "wofi-power" (
    builtins.readFile ./bin/wofi-power.sh
  );
  wofi-run = pkgs.writeShellScriptBin "wofi-run" (
    builtins.readFile ./bin/wofi-run.sh
  );
  wofi-search = pkgs.writeShellScriptBin "wofi-search" (
    builtins.readFile ./bin/wofi-search.sh
  );
  wofi-ssh = pkgs.writeShellScriptBin "wofi-ssh" (
    builtins.readFile ./bin/wofi-ssh.sh
  );
  wofi-system = pkgs.writeShellScriptBin "wofi-system" (
    builtins.readFile ./bin/wofi-system.sh
  );
  wofi-themehypr = pkgs.writeShellScriptBin "wofi-themehypr" (
    builtins.readFile ./bin/wofi-themehypr.sh
  );
  wofi-themewofi = pkgs.writeShellScriptBin "wofi-themewofi" (
    builtins.readFile ./bin/wofi-themewofi.sh
  );
  wofi-tools = pkgs.writeShellScriptBin "wofi-tools" (
    builtins.readFile ./bin/wofi-tools.sh
  );
  wofi-wifi = pkgs.writeShellScriptBin "wofi-wifi" (
    builtins.readFile ./bin/wofi-wifi.sh
  );
  wofi-window-switcher = pkgs.writeShellScriptBin "wofi-window-switcher" (
    builtins.readFile ./bin/wofi-window-switcher.sh
  );
  wofi-zenall = pkgs.writeShellScriptBin "wofi-zenall" (
    builtins.readFile ./bin/wofi-zenall.sh
  );
  wofi-zen = pkgs.writeShellScriptBin "wofi-zen" (
    builtins.readFile ./bin/wofi-zen.sh
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
  t1 = pkgs.writeShellScriptBin "t1" (
    builtins.readFile ./bin/t1
  );
  t3 = pkgs.writeShellScriptBin "t3" (
    builtins.readFile ./bin/t3
  );
  t4 = pkgs.writeShellScriptBin "t4" (
    builtins.readFile ./bin/t4
  );
  tm = pkgs.writeShellScriptBin "tm" (
    builtins.readFile ./bin/tm
  );

in {
  home.packages = with pkgs; [
    anote
    ascii
    assh-manager
    backup_config
    blocklist
    bulk_rename
    clearam
    clustergit-bash
    compress
    container-engine-manager
    container-monitor
    crypto-manager
    desktop-files-ranger-yazi
    dotfiles-manager
    dotfiles
    extract
    generate_nix_bin
    generate_nix_start
    gitgo
    gitsumo
    gnome-start-all
    hypr-airplane_mode
    hypr-audio_switcher
    hypr-blue-gammastep-manager
    hypr-blue-hyprshade-manager
    hypr-blue-hyprsunset-manager
    hypr-bluetooth_toggle
    hypr-blue-wlsunset-mananger
    hypr-clibp
    hypr-colorpicker
    hypr-ctl_focusmonitor
    hypr-ctl_setup_dual_monitors
    hypr-monitor_toggle
    hypr-mpv-manager
    hypr-mullvad_toggle
    hypr-screenshot
    hypr-spotify_toggle
    hypr-start-batteryd
    hypr-start-disable_wifi_power_save
    hypr-start-manager
    hypr-start-semsumo-all
    hypr-start-semsumo-light
    hypr-start-update
    hypr-startup-manager
    hypr-status-check
    hypr-vlc_toggle
    hypr-workspace-monitor
    keybinds
    kitty-toggle-font
    lofi
    maxfetch
    mkv2mp4
    monitor_brightness
    move_media_files
    mpc-control
    mrelay
    mullvad-dns-setup
    mullvad_toggle
    music
    network-reset-all
    network-reset
    nixos-profiles
    pass-clip-both
    pass_tool
    pdfkes
    playlist
    pop-shell-install
    ports
    power-menu
    publicip
    random-wallpaper
    record
    renew_env
    rofi-iwmenu
    rofi-launch
    rofi-power-menu
    rofi-power
    rofi-wifi
    rsync_backup
    rsync-retry
    rsync-tool
    runbg
    satty-screenshot
    ScrcpyUSB
    ScrcpyWiFi
    screenshot
    semsumo-create
    semsumo
    semsumo-wofi-start
    set-defaults-mimetype
    set-default-terminal
    sil_ayni_mp4
    sil_ayni_wall
    smart-suspend
    snippetp
    snippets
    ssh-hosts-backup-script
    ssh-launcher
    ssh-passwordless
    ssh-session-manager
    start-foot-server
    startup-manager
    st
    tkenp
    tmo
    tmux-backup
    tmux-copy
    tmux_cta
    tmux-fspeed
    tmux_kenp
    tmux-plugins
    tmux-startup
    toggle_blur
    toggle_float
    toggle_oppacity
    toggle_waybar
    transmission-install
    tsm
    tsms
    tty_config
    turbo-boost-setup
    ulauncher_ext
    video_info
    vmarchq
    vmarch
    vmbuntu
    vmnixosq
    vmnixos
    vmnixos_uefi
    vm-start
    vvmnixos
    wall-change
    wallpaper-picker
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
    waybar-wofi-cliphist
    waybar-wofi-powerprofiles
    waybar-wofi-wifi
    wmarch
    wofi-bluetooth
    wofi-browser
    wofi-cliphist
    wofi-firefox
    wofi-font-manager
    wofi-keybinds
    wofi-launch-zen
    wofi-main
    wofi-manager
    wofi-media
    wofi-powerprofiles
    wofi-power
    wofi-run
    wofi-search
    wofi-ssh
    wofi-system
    wofi-themehypr
    wofi-themewofi
    wofi-tools
    wofi-wifi
    wofi-window-switcher
    wofi-zenall
    wofi-zen
    wrename
    zen_profile_launcher
    zen_terminate_sessions
    t1
    t3
    t4
    tm
  ];
}
