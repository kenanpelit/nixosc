# modules/home/zsh/zsh_profile.nix
{ config, lib, pkgs, ... }:
{
  xdg.configFile = {
    "zsh/.zprofile" = {
      text = ''
        # Masaüstü oturumlarını otomatik başlatma yapılandırması
        # TTY1: Hyprland (birincil ekran)
        # TTY2: GNOME Wayland
        # TTY3: COSMIC masaüstü ortamı
        # TTY4: QEMU Ubuntu VM (Sway ile)
        # TTY5: QEMU NixOS VM (Sway ile)
        # TTY6: QEMU Arch VM (Sway ile)
        
        if [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "1" ]; then
            # TTY1'de Hyprland başlat
            if command -v hyprland_tty >/dev/null 2>&1; then
                exec hyprland_tty
            else
                echo "Hyprland başlatma scripti bulunamadı!"
                exec startup-manager
            fi
        elif [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "2" ]; then
            # TTY2'de GNOME Wayland başlat
            export XDG_SESSION_TYPE=wayland
            export XDG_SESSION_DESKTOP=gnome
            export XDG_CURRENT_DESKTOP=GNOME
            export XDG_RUNTIME_DIR=/run/user/$(id -u)
            if command -v gnome-session >/dev/null 2>&1; then
                exec gnome-session
            else
                echo "GNOME session bulunamadı!"
                exec startup-manager
            fi
        elif [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "3" ]; then
            # TTY3'de COSMIC masaüstü ortamı başlat
            exec startup-manager
        elif [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "4" ]; then
            # TTY4'de Ubuntu VM için Sway çalıştır
            export XDG_RUNTIME_DIR=/run/user/$(id -u)
            exec sway -c ~/.config/sway/qemu_vmubuntu
        elif [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "5" ]; then
            # TTY5'de NixOS VM için Sway çalıştır
            export XDG_RUNTIME_DIR=/run/user/$(id -u)
            exec sway -c ~/.config/sway/qemu_vmnixos
        # TTY6 şimdilik devre dışı bırakıldı
        # elif [ -z "''${WAYLAND_DISPLAY}" ] && [ "''${XDG_VTNR}" = "6" ]; then
        #    # TTY6'da Arch VM için Sway çalıştır
        #    export XDG_RUNTIME_DIR=/run/user/$(id -u)
        #    exec sway -c ~/.config/sway/qemu_vmarch
        fi
      '';
      executable = true;
    };
  };
}

