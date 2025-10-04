# modules/home/zsh/zsh_profile.nix
{ config, lib, pkgs, ... }:
{
  xdg.configFile = {
    "zsh/.zprofile" = {
      text = ''
        # =============================================================================
        # NixOS Multi-TTY Desktop Environment Auto-Start Configuration
        # =============================================================================
        # Bu profil SADECE TTY kontrolü ve session yönlendirmesi yapar.
        # Tüm environment değişkenleri ilgili başlatma script'lerinde ayarlanır.
        # =============================================================================
        # TTY Atamaları:
        #   TTY1: Display Manager (cosmic-greeter) - Session Selection
        #   TTY2: Hyprland (hyprland_tty script ile)
        #   TTY3: GNOME (gnome-session ile)
        #   TTY4: COSMIC (cosmic-session ile)
        #   TTY5: Ubuntu VM (Sway)
        #   TTY6: NixOS VM (Sway)
        # =============================================================================

        # Sadece login shell ve henüz aktif desktop yoksa çalıştır
        if [[ $- == *l* ]] && [ -z "''${WAYLAND_DISPLAY}" ] && [ -z "''${DISPLAY}" ] && [[ "''${XDG_VTNR}" =~ ^[1-6]$ ]]; then
            
            # TTY1 özel kontrol: Display manager için session type kontrolü
            if [ "''${XDG_VTNR}" = "1" ] && [ -n "''${XDG_SESSION_TYPE}" ]; then
                # Session zaten aktif, müdahale etme
                return
            fi
            
            # ==========================================================================
            # TTY1: Display Manager (cosmic-greeter)
            # ==========================================================================
            if [ "''${XDG_VTNR}" = "1" ]; then
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║  TTY1: Display Manager (cosmic-greeter)                   ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                echo ""
                echo "Available Desktop Sessions:"
                echo "  • COSMIC   - Rust-based desktop (Beta)"
                echo "  • Hyprland - Dynamic tiling Wayland compositor"
                echo "  • GNOME    - Traditional GNOME desktop"
                echo ""
                echo "Manual Start Commands:"
                echo "  exec hyprland_tty    - Start Hyprland with optimizations"
                echo "  exec cosmic-session  - Start COSMIC desktop"
                echo "  exec gnome-session   - Start GNOME desktop"
                echo ""
            
            # ==========================================================================
            # TTY2: Hyprland Wayland Compositor
            # ==========================================================================
            # Tüm environment ayarları hyprland_tty script'inde yapılır
            elif [ "''${XDG_VTNR}" = "2" ]; then
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║  TTY2: Launching Hyprland via hyprland_tty                ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                
                # Minimum gerekli değişkenler - geri kalanı hyprland_tty'de
                export XDG_SESSION_TYPE=wayland
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                # hyprland_tty script'i kontrol et
                if command -v hyprland_tty >/dev/null 2>&1; then
                    echo "Starting Hyprland with optimized configuration..."
                    exec hyprland_tty
                else
                    echo "ERROR: hyprland_tty script not found in PATH"
                    echo "Falling back to direct Hyprland launch (not recommended)"
                    sleep 3
                    exec Hyprland
                fi
            
            # ==========================================================================
            # TTY3: GNOME Desktop Environment
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "3" ]; then
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║  TTY3: Starting GNOME Wayland Desktop                     ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                
                # Diğer desktop session'larından kalıntıları temizle
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                unset HYPRLAND_INSTANCE_SIGNATURE WLR_NO_HARDWARE_CURSORS
                
                # XDG_RUNTIME_DIR kontrolü ve oluşturma
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                if [ ! -d "$XDG_RUNTIME_DIR" ]; then
                    echo "Creating XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
                    sudo mkdir -p "$XDG_RUNTIME_DIR"
                    sudo chown $(id -u):$(id -g) "$XDG_RUNTIME_DIR"
                    sudo chmod 700 "$XDG_RUNTIME_DIR"
                fi
                
                # GNOME environment değişkenleri
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=gnome
                export XDG_CURRENT_DESKTOP=GNOME
                export DESKTOP_SESSION=gnome
                
                # Wayland backend tercihleri
                export WAYLAND_DISPLAY=wayland-0
                export QT_QPA_PLATFORM=wayland
                export GDK_BACKEND=wayland
                export MOZ_ENABLE_WAYLAND=1
                
                # GNOME özel ayarlar
                export GNOME_SHELL_SESSION_MODE=user
                export MUTTER_DEBUG_DUMMY_MODE_SPECS=1024x768
                
                # Keyring ayarları
                export GNOME_KEYRING_CONTROL="$XDG_RUNTIME_DIR/keyring"
                export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"
                
                echo "Environment: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP"
                echo "Runtime Dir: $XDG_RUNTIME_DIR"
                
                # GNOME binary kontrolü
                if ! command -v gnome-session >/dev/null; then
                    echo "ERROR: gnome-session not found in PATH!"
                    echo "Available GNOME binaries:"
                    find /run/current-system/sw/bin -name "*gnome*" 2>/dev/null | head -10
                    sleep 5
                    return
                fi
                
                # D-Bus session ile GNOME başlat
                echo "Starting GNOME with D-Bus session..."
                if command -v dbus-run-session >/dev/null; then
                    exec dbus-run-session -- gnome-session --session=gnome 2>&1 | tee /tmp/gnome-session-tty3.log
                else
                    echo "Starting D-Bus manually..."
                    eval $(dbus-launch --sh-syntax --exit-with-session)
                    export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
                    exec gnome-session --session=gnome 2>&1 | tee /tmp/gnome-session-tty3.log
                fi
            
            # ==========================================================================
            # TTY4: COSMIC Desktop Environment (Beta)
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "4" ]; then
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║  TTY4: Starting COSMIC Desktop (Beta)                     ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                
                # Tüm diğer desktop kalıntılarını temizle
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                unset HYPRLAND_INSTANCE_SIGNATURE WLR_NO_HARDWARE_CURSORS
                unset GNOME_SHELL_SESSION_MODE MUTTER_DEBUG_DUMMY_MODE_SPECS
                unset DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
                
                # XDG_RUNTIME_DIR kontrolü
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                if [ ! -d "$XDG_RUNTIME_DIR" ]; then
                    echo "Creating XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
                    sudo mkdir -p "$XDG_RUNTIME_DIR"
                    sudo chown $(id -u):$(id -g) "$XDG_RUNTIME_DIR"
                    sudo chmod 700 "$XDG_RUNTIME_DIR"
                fi
                
                # COSMIC environment değişkenleri
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=cosmic
                export XDG_CURRENT_DESKTOP=COSMIC
                export DESKTOP_SESSION=cosmic
                
                # Wayland backend ayarları
                export QT_QPA_PLATFORM=wayland
                export GDK_BACKEND=wayland
                export MOZ_ENABLE_WAYLAND=1
                export SDL_VIDEODRIVER=wayland
                
                # COSMIC özel özellikler
                export COSMIC_DATA_CONTROL_ENABLED=1
                export NIXOS_OZONE_WL=1
                
                echo "Environment: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP"
                echo "Runtime Dir: $XDG_RUNTIME_DIR"
                echo "NOTE: COSMIC is in Beta - expect occasional issues"
                
                # COSMIC binary kontrolü
                if ! command -v cosmic-session >/dev/null; then
                    echo "ERROR: cosmic-session not found in PATH!"
                    echo "Available COSMIC binaries:"
                    find /run/current-system/sw/bin -name "*cosmic*" 2>/dev/null | head -10
                    sleep 5
                    return
                fi
                
                # D-Bus kontrolü
                if ! pgrep -u $(id -u) dbus-daemon >/dev/null 2>&1; then
                    echo "Starting D-Bus daemon..."
                    eval $(dbus-launch --sh-syntax)
                    export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
                fi
                
                # COSMIC başlat - portal servisleri otomatik başlar
                echo "Starting COSMIC session..."
                echo "Portal services will start automatically when Wayland is ready"
                exec cosmic-session 2>&1 | tee /tmp/cosmic-session-tty4.log
            
            # ==========================================================================
            # TTY5: Ubuntu VM in Sway
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "5" ]; then
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║  TTY5: Starting Ubuntu VM in Sway                         ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                
                # Environment temizliği
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                
                # Sway environment
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=sway
                export XDG_CURRENT_DESKTOP=sway
                export DESKTOP_SESSION=sway
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                echo "Environment: Sway compositor for Ubuntu VM"
                
                # Sway config kontrolü
                if [ -f ~/.config/sway/qemu_vmubuntu ]; then
                    exec sway -c ~/.config/sway/qemu_vmubuntu
                else
                    echo "ERROR: Sway config not found: ~/.config/sway/qemu_vmubuntu"
                    echo "Please create the configuration file first"
                    sleep 5
                    return
                fi
            
            # ==========================================================================
            # TTY6: NixOS VM in Sway
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "6" ]; then
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║  TTY6: Starting NixOS VM in Sway                          ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                
                # Environment temizliği
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                
                # Sway environment
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=sway
                export XDG_CURRENT_DESKTOP=sway
                export DESKTOP_SESSION=sway
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                echo "Environment: Sway compositor for NixOS VM"
                
                # Sway config kontrolü
                if [ -f ~/.config/sway/qemu_vmnixos ]; then
                    exec sway -c ~/.config/sway/qemu_vmnixos
                else
                    echo "ERROR: Sway config not found: ~/.config/sway/qemu_vmnixos"
                    echo "Please create the configuration file first"
                    sleep 5
                    return
                fi
            
            # ==========================================================================
            # Diğer TTY'ler: Manuel kullanım için bilgilendirme
            # ==========================================================================
            else
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║  TTY''${XDG_VTNR}: No auto-start configured                       ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                echo ""
                echo "Available TTY Assignments:"
                echo "  TTY1: Display Manager (cosmic-greeter)"
                echo "  TTY2: Hyprland (hyprland_tty)"
                echo "  TTY3: GNOME (gnome-session)"
                echo "  TTY4: COSMIC (cosmic-session)"
                echo "  TTY5: Ubuntu VM (Sway)"
                echo "  TTY6: NixOS VM (Sway)"
                echo ""
                echo "Manual Start Commands:"
                echo "  exec hyprland_tty    - Hyprland with optimizations"
                echo "  exec gnome-session   - GNOME desktop"
                echo "  exec cosmic-session  - COSMIC desktop"
                echo ""
            fi
            
        fi
        # Login shell değilse veya desktop zaten çalışıyorsa sessizce devam et
      '';
      executable = true;
    };
  };
}

