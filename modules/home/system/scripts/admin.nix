{ pkgs, ... }:
let
  check_images = pkgs.writeShellScriptBin "check_images" (
    builtins.readFile ./admin/check_images.sh
  );
  chroot_manager = pkgs.writeShellScriptBin "chroot_manager" (
    builtins.readFile ./admin/chroot_manager.sh
  );
  crypto-manager = pkgs.writeShellScriptBin "crypto-manager" (
    builtins.readFile ./admin/crypto-manager.sh
  );
  dotfiles-manager = pkgs.writeShellScriptBin "dotfiles-manager" (
    builtins.readFile ./admin/dotfiles-manager.sh
  );
  gitgo = pkgs.writeShellScriptBin "gitgo" (
    builtins.readFile ./admin/gitgo.sh
  );
  gitsumo = pkgs.writeShellScriptBin "gitsumo" (
    builtins.readFile ./admin/gitsumo.sh
  );
  m2w2 = pkgs.writeShellScriptBin "m2w2" (
    builtins.readFile ./admin/m2w2.sh
  );
  osc-assh-manager = pkgs.writeShellScriptBin "osc-assh-manager" (
    builtins.readFile ./admin/osc-assh-manager.sh
  );
  osc-audio-init = pkgs.writeShellScriptBin "osc-audio-init" (
    builtins.readFile ./admin/osc-audio-init.sh
  );
  osc-backup = pkgs.writeShellScriptBin "osc-backup" (
    builtins.readFile ./admin/osc-backup.sh
  );
  osc-blocklist = pkgs.writeShellScriptBin "osc-blocklist" (
    builtins.readFile ./admin/osc-blocklist.sh
  );
  osc-cleaup-grub = pkgs.writeShellScriptBin "osc-cleaup-grub" (
    builtins.readFile ./admin/osc-cleaup-grub.sh
  );
  osc-generate_nix = pkgs.writeShellScriptBin "osc-generate_nix" (
    builtins.readFile ./admin/osc-generate_nix.sh
  );
  osc-gist = pkgs.writeShellScriptBin "osc-gist" (
    builtins.readFile ./admin/osc-gist.sh
  );
  osc-gpg_unlock = pkgs.writeShellScriptBin "osc-gpg_unlock" (
    builtins.readFile ./admin/osc-gpg_unlock.sh
  );
  osc-mrelay = pkgs.writeShellScriptBin "osc-mrelay" (
    builtins.readFile ./admin/osc-mrelay.sh
  );
  osc-nix-cleanup-script = pkgs.writeShellScriptBin "osc-nix-cleanup-script" (
    builtins.readFile ./admin/osc-nix-cleanup-script.sh
  );
  osc-pass-tool = pkgs.writeShellScriptBin "osc-pass-tool" (
    builtins.readFile ./admin/osc-pass-tool.sh
  );
  osc-profiles = pkgs.writeShellScriptBin "osc-profiles" (
    builtins.readFile ./admin/osc-profiles.sh
  );
  osc-radio = pkgs.writeShellScriptBin "osc-radio" (
    builtins.readFile ./admin/osc-radio.sh
  );
  osc-rsync_backup = pkgs.writeShellScriptBin "osc-rsync_backup" (
    builtins.readFile ./admin/osc-rsync_backup.sh
  );
  osc-rsync = pkgs.writeShellScriptBin "osc-rsync" (
    builtins.readFile ./admin/osc-rsync.sh
  );
  osc-scrcpy = pkgs.writeShellScriptBin "osc-scrcpy" (
    builtins.readFile ./admin/osc-scrcpy.sh
  );
  osc-soundctl = pkgs.writeShellScriptBin "osc-soundctl" (
    builtins.readFile ./admin/osc-soundctl.sh
  );
  osc-spotify = pkgs.writeShellScriptBin "osc-spotify" (
    builtins.readFile ./admin/osc-spotify.sh
  );
  osc-ssh-hosts-backup-script = pkgs.writeShellScriptBin "osc-ssh-hosts-backup-script" (
    builtins.readFile ./admin/osc-ssh-hosts-backup-script.sh
  );
  osc-ssh-passwordless = pkgs.writeShellScriptBin "osc-ssh-passwordless" (
    builtins.readFile ./admin/osc-ssh-passwordless.sh
  );
  osc-ssh-session-manager = pkgs.writeShellScriptBin "osc-ssh-session-manager" (
    builtins.readFile ./admin/osc-ssh-session-manager.sh
  );
  osc-start-all = pkgs.writeShellScriptBin "osc-start-all" (
    builtins.readFile ./admin/osc-start-all.sh
  );
  osc-start-brave = pkgs.writeShellScriptBin "osc-start-brave" (
    builtins.readFile ./admin/osc-start-brave.sh
  );
  osc-start-zen = pkgs.writeShellScriptBin "osc-start-zen" (
    builtins.readFile ./admin/osc-start-zen.sh
  );
  osc-subliminal = pkgs.writeShellScriptBin "osc-subliminal" (
    builtins.readFile ./admin/osc-subliminal.sh
  );
  osc-symlink_manager = pkgs.writeShellScriptBin "osc-symlink_manager" (
    builtins.readFile ./admin/osc-symlink_manager.sh
  );
  osc-sync = pkgs.writeShellScriptBin "osc-sync" (
    builtins.readFile ./admin/osc-sync.sh
  );
  osc-test = pkgs.writeShellScriptBin "osc-test" (
    builtins.readFile ./admin/osc-test.sh
  );
  osc-tv-splitter = pkgs.writeShellScriptBin "osc-tv-splitter" (
    builtins.readFile ./admin/osc-tv-splitter.sh
  );
  osc-ulauncher_ext = pkgs.writeShellScriptBin "osc-ulauncher_ext" (
    builtins.readFile ./admin/osc-ulauncher_ext.sh
  );
  osc-video-converter = pkgs.writeShellScriptBin "osc-video-converter" (
    builtins.readFile ./admin/osc-video-converter.sh
  );
  osc-vradio = pkgs.writeShellScriptBin "osc-vradio" (
    builtins.readFile ./admin/osc-vradio.sh
  );
  semsumo = pkgs.writeShellScriptBin "semsumo" (
    builtins.readFile ./admin/semsumo.sh
  );
  svmarch = pkgs.writeShellScriptBin "svmarch" (
    builtins.readFile ./admin/svmarch.sh
  );
  svmnixos = pkgs.writeShellScriptBin "svmnixos" (
    builtins.readFile ./admin/svmnixos.sh
  );
  svmubuntu = pkgs.writeShellScriptBin "svmubuntu" (
    builtins.readFile ./admin/svmubuntu.sh
  );
  vmarch = pkgs.writeShellScriptBin "vmarch" (
    builtins.readFile ./admin/vmarch.sh
  );
  vmnixos = pkgs.writeShellScriptBin "vmnixos" (
    builtins.readFile ./admin/vmnixos.sh
  );
  zen_profile_launcher = pkgs.writeShellScriptBin "zen_profile_launcher" (
    builtins.readFile ./admin/zen_profile_launcher.sh
  );
  zen_terminate_sessions = pkgs.writeShellScriptBin "zen_terminate_sessions" (
    builtins.readFile ./admin/zen_terminate_sessions.sh
  );
in {
  home.packages = with pkgs; [
    check_images
    chroot_manager
    crypto-manager
    dotfiles-manager
    gitgo
    gitsumo
    m2w2
    osc-assh-manager
    osc-audio-init
    osc-backup
    osc-blocklist
    osc-cleaup-grub
    osc-generate_nix
    osc-gist
    osc-gpg_unlock
    osc-mrelay
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
    osc-start-brave
    osc-start-zen
    osc-subliminal
    osc-symlink_manager
    osc-sync
    osc-test
    osc-tv-splitter
    osc-ulauncher_ext
    osc-video-converter
    osc-vradio
    semsumo
    svmarch
    svmnixos
    svmubuntu
    vmarch
    vmnixos
    zen_profile_launcher
    zen_terminate_sessions
  ];
}
