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
  osc-backup = pkgs.writeShellScriptBin "osc-backup" (
    builtins.readFile ./admin/osc-backup.sh
  );
  osc-blocklist = pkgs.writeShellScriptBin "osc-blocklist" (
    builtins.readFile ./admin/osc-blocklist.sh
  );
  osc-generate_nix_admin = pkgs.writeShellScriptBin "osc-generate_nix_admin" (
    builtins.readFile ./admin/osc-generate_nix_admin.sh
  );
  osc-generate_nix_bin = pkgs.writeShellScriptBin "osc-generate_nix_bin" (
    builtins.readFile ./admin/osc-generate_nix_bin.sh
  );
  osc-generate_nix_start = pkgs.writeShellScriptBin "osc-generate_nix_start" (
    builtins.readFile ./admin/osc-generate_nix_start.sh
  );
  osc-gpg_unlock = pkgs.writeShellScriptBin "osc-gpg_unlock" (
    builtins.readFile ./admin/osc-gpg_unlock.sh
  );
  osc-mrelay = pkgs.writeShellScriptBin "osc-mrelay" (
    builtins.readFile ./admin/osc-mrelay.sh
  );
  osc-pass-tool = pkgs.writeShellScriptBin "osc-pass-tool" (
    builtins.readFile ./admin/osc-pass-tool.sh
  );
  osc-profiles = pkgs.writeShellScriptBin "osc-profiles" (
    builtins.readFile ./admin/osc-profiles.sh
  );
  osc-rsync_backup = pkgs.writeShellScriptBin "osc-rsync_backup" (
    builtins.readFile ./admin/osc-rsync_backup.sh
  );
  osc-semsumo-create = pkgs.writeShellScriptBin "osc-semsumo-create" (
    builtins.readFile ./admin/osc-semsumo-create.sh
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
  osc-start-semsumo-all = pkgs.writeShellScriptBin "osc-start-semsumo-all" (
    builtins.readFile ./admin/osc-start-semsumo-all.sh
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
  osc-ulauncher_ext = pkgs.writeShellScriptBin "osc-ulauncher_ext" (
    builtins.readFile ./admin/osc-ulauncher_ext.sh
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
    osc-backup
    osc-blocklist
    osc-generate_nix_admin
    osc-generate_nix_bin
    osc-generate_nix_start
    osc-gpg_unlock
    osc-mrelay
    osc-pass-tool
    osc-profiles
    osc-rsync_backup
    osc-semsumo-create
    osc-ssh-hosts-backup-script
    osc-ssh-passwordless
    osc-ssh-session-manager
    osc-start-semsumo-all
    osc-subliminal
    osc-symlink_manager
    osc-sync
    osc-test
    osc-ulauncher_ext
    semsumo
    svmarch
    svmnixos
    vmarch
    vmnixos
    zen_profile_launcher
    zen_terminate_sessions
  ];
}
