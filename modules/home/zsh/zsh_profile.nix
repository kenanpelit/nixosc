# modules/home/zsh/zsh_profile.nix
{ config, lib, pkgs, ... }:
{
  xdg.configFile = {
    "zsh/.zprofile" = {
      text = ''
        # Masaüstü oturumlarını otomatik başlatma yapılandırması
        # TTY1: Hyprland (birincil ekran)
        # TTY2: GNOME Wayland (Fixed Version)
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
            # TTY2'de GNOME Wayland başlat - FIXED VERSION
            
            # Runtime directory kurulumu
            export XDG_RUNTIME_DIR="/run/user/$(id -u)"
            if [ ! -d "$XDG_RUNTIME_DIR" ]; then
                echo "XDG_RUNTIME_DIR oluşturuluyor: $XDG_RUNTIME_DIR"
                sudo mkdir -p "$XDG_RUNTIME_DIR"
                sudo chown $(id -u):$(id -g) "$XDG_RUNTIME_DIR"
                sudo chmod 700 "$XDG_RUNTIME_DIR"
            fi
            
            # Session environment variables
            export XDG_SESSION_TYPE=wayland
            export XDG_SESSION_DESKTOP=gnome
            export XDG_CURRENT_DESKTOP=GNOME
            export WAYLAND_DISPLAY=wayland-0
            export QT_QPA_PLATFORM=wayland
            export GDK_BACKEND=wayland
            export MOZ_ENABLE_WAYLAND=1
            
            # GNOME specific environment
            export GNOME_SHELL_SESSION_MODE=user
            export MUTTER_DEBUG_DUMMY_MODE_SPECS=1024x768
            
            # Keyring environment
            export GNOME_KEYRING_CONTROL="$XDG_RUNTIME_DIR/keyring"
            export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"
            
            echo "=== GNOME Wayland Başlatılıyor ==="
            echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
            echo "XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
            echo "XDG_CURRENT_DESKTOP: $XDG_CURRENT_DESKTOP"
            
            # Komut kontrolü
            if ! command -v gnome-session >/dev/null; then
                echo "HATA: gnome-session bulunamadı!"
                echo "Mevcut komutlar:"
                find /run/current-system/sw/bin -name "*gnome*" 2>/dev/null | head -10
                sleep 5
                exec startup-manager
            fi
            
            if ! command -v gnome-shell >/dev/null; then
                echo "HATA: gnome-shell bulunamadı!"
                sleep 5
                exec startup-manager
            fi
            
            # D-Bus session kontrolü
            if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
                echo "D-Bus session başlatılıyor..."
                if command -v dbus-run-session >/dev/null; then
                    echo "dbus-run-session ile GNOME başlatılıyor..."
                    exec dbus-run-session -- gnome-session --session=gnome --debug 2>&1 | tee /tmp/gnome-session.log
                else
                    echo "dbus-launch ile GNOME başlatılıyor..."
                    eval $(dbus-launch --sh-syntax --exit-with-session)
                    export DBUS_SESSION_BUS_ADDRESS
                    export DBUS_SESSION_BUS_PID
                    exec gnome-session --session=gnome --debug 2>&1 | tee /tmp/gnome-session.log
                fi
            else
                echo "Mevcut D-Bus session ile GNOME başlatılıyor..."
                exec gnome-session --session=gnome --debug 2>&1 | tee /tmp/gnome-session.log
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

