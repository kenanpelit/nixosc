{ pkgs, ... }:
let
  assh-manager = pkgs.writeShellScriptBin "assh-manager" (
    builtins.readFile ./admin/assh-manager.sh
  );
  blocklist = pkgs.writeShellScriptBin "blocklist" (
    builtins.readFile ./admin/blocklist.sh
  );
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
  mrelay = pkgs.writeShellScriptBin "mrelay" (
    builtins.readFile ./admin/mrelay.sh
  );
  osc-backup = pkgs.writeShellScriptBin "osc-backup" (
    builtins.readFile ./admin/osc-backup.sh
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
  osc-pass-tool = pkgs.writeShellScriptBin "osc-pass-tool" (
    builtins.readFile ./admin/osc-pass-tool.sh
  );
  osc-profiles = pkgs.writeShellScriptBin "osc-profiles" (
    builtins.readFile ./admin/osc-profiles.sh
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
  osc-symlink_manager = pkgs.writeShellScriptBin "osc-symlink_manager" (
    builtins.readFile ./admin/osc-symlink_manager.sh
  );
  osc-sync = pkgs.writeShellScriptBin "osc-sync" (
    builtins.readFile ./admin/osc-sync.sh
  );
  osc-test = pkgs.writeShellScriptBin "osc-test" (
    builtins.readFile ./admin/osc-test.sh
  );
  semsumo-create = pkgs.writeShellScriptBin "semsumo-create" (
    builtins.readFile ./admin/semsumo-create.sh
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
    assh-manager
    blocklist
    check_images
    chroot_manager
    crypto-manager
    dotfiles-manager
    gitgo
    gitsumo
    m2w2
    mrelay
    osc-backup
    osc-generate_nix_admin
    osc-generate_nix_bin
    osc-generate_nix_start
    osc-gpg_unlock
    osc-pass-tool
    osc-profiles
    osc-ssh-hosts-backup-script
    osc-ssh-passwordless
    osc-ssh-session-manager
    osc-start-semsumo-all
    osc-symlink_manager
    osc-sync
    osc-test
    semsumo-create
    semsumo
    svmarch
    svmnixos
    vmarch
    vmnixos
    zen_profile_launcher
    zen_terminate_sessions
  ];
}
