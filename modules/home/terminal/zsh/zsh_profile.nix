# modules/home/zsh/zsh_profile.nix
{ config, lib, pkgs, ... }:

{
  xdg.configFile = {
    "zsh/.zprofile" = {
      text = ''
        if [ -z "''${WAYLAND_DISPLAY}" ] && [[ "''${XDG_VTNR}" =~ ^(1|5|6)$ ]]; then
            exec startup-manager
        elif [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "2" ]; then
            export XDG_RUNTIME_DIR=/run/user/$(id -u)
            exec sway -c ~/.config/sway/qemu_vmnixos
        elif [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "3" ]; then
            export XDG_RUNTIME_DIR=/run/user/$(id -u)
            exec sway -c ~/.config/sway/qemu_vmarch
        fi
      '';
      executable = true;
    };
  };
}

