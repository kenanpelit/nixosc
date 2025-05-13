# modules/home/zsh/zsh_profile.nix
{ config, lib, pkgs, ... }:
{
  xdg.configFile = {
    "zsh/.zprofile" = {
      text = ''
        # Masaüstü oturumlarını otomatik başlatma yapılandırması
        # TTY1: Hyprland
        # TTY2: QEMU NixOS VM (Sway ile)
        # TTY3: QEMU Arch VM (Sway ile)
        # TTY4: QEMU Ubuntu VM (Sway ile)
        # TTY5: GNOME masaüstü ortamı
        # TTY6: COSMIC masaüstü ortamı
        
        if [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "1" ]; then
            # TTY1'de Hyprland başlat
            if command -v hyprland_tty >/dev/null 2>&1; then
                exec hyprland_tty
            else
                echo "Hyprland başlatma scripti bulunamadı!"
                exec startup-manager
            fi
        elif [ -z "''${WAYLAND_DISPLAY}" ] && [[ "''${XDG_VTNR}" =~ ^(5|6)$ ]]; then
            # TTY5 (GNOME) veya TTY6'da (COSMIC) ise startup-manager çalıştır
            exec startup-manager
        elif [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "2" ]; then
            # TTY2'de NixOS VM için Sway çalıştır
            export XDG_RUNTIME_DIR=/run/user/$(id -u)
            exec sway -c ~/.config/sway/qemu_vmnixos
        elif [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "3" ]; then
            # TTY3'de Arch VM için Sway çalıştır
            export XDG_RUNTIME_DIR=/run/user/$(id -u)
            exec sway -c ~/.config/sway/qemu_vmarch
        elif [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "4" ]; then
            # TTY4'de Ubuntu VM için Sway çalıştır
            export XDG_RUNTIME_DIR=/run/user/$(id -u)
            exec sway -c ~/.config/sway/qemu_vmubuntu
        fi
      '';
      executable = true;
    };
  };
}

