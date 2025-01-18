{ pkgs, ... }:
let
  assh-manager = pkgs.writeShellScriptBin "assh-manager" (
    builtins.readFile ./admin/assh-manager.sh
  );
  backup_config = pkgs.writeShellScriptBin "backup_config" (
    builtins.readFile ./admin/backup_config.sh
  );
  blocklist = pkgs.writeShellScriptBin "blocklist" (
    builtins.readFile ./admin/blocklist.sh
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
  osc-generate_nix_admin = pkgs.writeShellScriptBin "osc-generate_nix_admin" (
    builtins.readFile ./admin/osc-generate_nix_admin.sh
  );
  osc-generate_nix_bin = pkgs.writeShellScriptBin "osc-generate_nix_bin" (
    builtins.readFile ./admin/osc-generate_nix_bin.sh
  );
  osc-generate_nix_start = pkgs.writeShellScriptBin "osc-generate_nix_start" (
    builtins.readFile ./admin/osc-generate_nix_start.sh
  );
  osc-profiles = pkgs.writeShellScriptBin "osc-profiles" (
    builtins.readFile ./admin/osc-profiles.sh
  );
  osc-sync = pkgs.writeShellScriptBin "osc-sync" (
    builtins.readFile ./admin/osc-sync.sh
  );
  pass_tool = pkgs.writeShellScriptBin "pass_tool" (
    builtins.readFile ./admin/pass_tool.sh
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
  vmnixos_uefi = pkgs.writeShellScriptBin "vmnixos_uefi" (
    builtins.readFile ./admin/vmnixos_uefi.sh
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
    backup_config
    blocklist
    crypto-manager
    dotfiles-manager
    gitgo
    gitsumo
    osc-generate_nix_admin
    osc-generate_nix_bin
    osc-generate_nix_start
    osc-profiles
    osc-sync
    pass_tool
    semsumo-create
    semsumo
    svmarch
    svmnixos
    vmarch
    vmnixos
    vmnixos_uefi
    zen_profile_launcher
    zen_terminate_sessions
  ];
}
