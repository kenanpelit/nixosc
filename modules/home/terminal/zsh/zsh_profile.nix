# modules/home/zsh/zsh_profile.nix
{ config, lib, pkgs, ... }:
{
  xdg.configFile = {
    "zsh/.zprofile" = {
      text = ''
        # Masaüstü oturumlarını otomatik başlatma yapılandırması
        # TTY1: Hyprland (birincil ekran)
        # TTY2: GNOME Wayland (Debug Mode)
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
            # TTY2'de GNOME Wayland başlat - DEBUG MODE
            export XDG_SESSION_TYPE=wayland
            export XDG_SESSION_DESKTOP=gnome
            export XDG_CURRENT_DESKTOP=GNOME
            export XDG_RUNTIME_DIR=/run/user/$(id -u)
            export WAYLAND_DISPLAY=wayland-1
            export QT_QPA_PLATFORM=wayland
            export GDK_BACKEND=wayland
            
            # Debug modunda çalıştır
            echo "=== GNOME Debug Modu ==="
            echo "Session dosyası kontrolü:"
            
            # Session dosyası kontrolü
            if [ -f "/etc/wayland-sessions/gnome.desktop" ]; then
                echo "✓ GNOME Wayland session dosyası bulundu"
                echo "İçeriği:"
                cat /etc/wayland-sessions/gnome.desktop
            else
                echo "✗ GNOME Wayland session dosyası bulunamadı!"
            fi
            
            echo ""
            echo "GNOME komutları kontrolü:"
            if command -v gnome-session >/dev/null; then
                echo "✓ gnome-session bulundu: $(which gnome-session)"
            else
                echo "✗ gnome-session bulunamadı"
            fi
            
            if command -v gnome-shell >/dev/null; then
                echo "✓ gnome-shell bulundu: $(which gnome-shell)"
            else
                echo "✗ gnome-shell bulunamadı"
            fi
            
            if command -v dbus-run-session >/dev/null; then
                echo "✓ dbus-run-session bulundu: $(which dbus-run-session)"
            else
                echo "✗ dbus-run-session bulunamadı"
            fi
            
            echo ""
            echo "Mevcut GNOME komutları:"
            ls /run/current-system/sw/bin/*gnome* 2>/dev/null || echo "Hiç GNOME komutu yok!"
            
            echo ""
            echo "Environment variables:"
            echo "XDG_SESSION_TYPE=$XDG_SESSION_TYPE"
            echo "XDG_SESSION_DESKTOP=$XDG_SESSION_DESKTOP" 
            echo "XDG_CURRENT_DESKTOP=$XDG_CURRENT_DESKTOP"
            echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
            
            echo ""
            echo "GNOME başlatılıyor... (10 saniye sonra otomatik başlayacak)"
            echo "Şimdi durdurmak için Ctrl+C'ye basın"
            sleep 10
            
            # GNOME için gerekli servisler başlat
            echo "GNOME session başlatılıyor..."
            if command -v dbus-run-session >/dev/null 2>&1; then
                echo "dbus-run-session ile başlatılıyor..."
                exec dbus-run-session gnome-session --debug 2>&1 | tee /tmp/gnome-debug.log
            elif command -v gnome-session >/dev/null 2>&1; then
                echo "Doğrudan gnome-session ile başlatılıyor..."
                exec gnome-session --debug 2>&1 | tee /tmp/gnome-debug.log
            else
                echo "GNOME session bulunamadı!"
                echo "Sistem paketleri:"
                echo "gnome-session paketi yüklü mü kontrol ediliyor..."
                nix-shell -p gnome.gnome-session --run "gnome-session --version" 2>/dev/null || echo "GNOME paketleri sistem seviyesinde yüklü değil!"
                echo ""
                echo "5 saniye sonra startup-manager'a geçiliyor..."
                sleep 5
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

