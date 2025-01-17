# modules/home/sway/default.nix
{ config, lib, pkgs, ... }:

{
  xdg.configFile = {
    "sway/qemu_vmnixos" = {
      text = ''
        exec svmnixos
        for_window [app_id="qemu"] fullscreen enable
      '';
      executable = true;
    };

    "sway/qemu_vmarch" = {
      text = ''
        exec svmarch
        for_window [app_id="qemu"] fullscreen enable
      '';
      executable = true;
    };
  };
}

