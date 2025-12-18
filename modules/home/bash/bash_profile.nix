# modules/home/bash/bash_profile.nix
# ==============================================================================
# Bash login profile for TTY auto-start: routes login shells to DE sessions.
# Starts Hyprland/GNOME/Sway on assigned VTs, with fallbacks and messages.
# Converted from zsh_profile for Bash; keeps TTY handling in one place.
# ==============================================================================

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.bash;
in
lib.mkIf cfg.enable {
  xdg.configFile."bash/.bash_profile".text = ''
    # Source interactive shell config
    if [ -f "$HOME/.bashrc" ]; then
      . "$HOME/.bashrc"
    fi

    # ===== Converted from zsh_profile.nix =====
    # =============================================================================
            # NixOS Multi-TTY Desktop Environment Auto-Start Configuration
            # =============================================================================
            # Bu profil SADECE TTY kontrolü ve session yönlendirmesi yapar.
            # Tüm environment değişkenleri ilgili başlatma script'lerinde ayarlanır.
            # =============================================================================
            # TTY Atamaları:
            #   TTY1: Display Manager - Session Selection
            #   TTY2: Hyprland (hyprland_tty script ile)
            #   TTY3: GNOME (gnome_tty script ile)
            #   TTY5: Ubuntu VM (Sway)
            # =============================================================================

            # Sadece login shell ve henüz aktif desktop yoksa çalıştır
            if [[ $- == *l* ]] && [ -z "''${WAYLAND_DISPLAY}" ] && [ -z "''${DISPLAY}" ] && [[ "''${XDG_VTNR}" =~ ^[1-6]$ ]] && [ -z "''${GNOME_TTY_GUARD:-}" ]; then
            
                # TTY1 özel kontrol: Display manager için session type kontrolü
                if [ "''${XDG_VTNR}" = "1" ] && [ -n "''${XDG_SESSION_TYPE}" ]; then
                    # Session zaten aktif, müdahale etme
                    return
                fi
            
                # ==========================================================================
                # TTY1: Display Manager
                # ==========================================================================
                if [ "''${XDG_VTNR}" = "1" ]; then
                    echo "╔════════════════════════════════════════════════════════════╗"
                    echo "║  TTY1: Display Manager                                     ║"
                    echo "╚════════════════════════════════════════════════════════════╝"
                    echo ""
                    echo "Available Desktop Sessions:"
                    echo "  • Hyprland - Dynamic tiling Wayland compositor"
                    echo "  • GNOME    - Traditional GNOME desktop"
                    echo ""
                    echo "Manual Start Commands:"
                    echo "  exec hyprland_tty    - Start Hyprland with optimizations"
                    echo "  exec gnome_tty       - Start GNOME with optimizations"
                    echo ""
            
                # ==========================================================================
                # TTY2: Hyprland Wayland Compositor
                # ==========================================================================
                # Tüm environment ayarları hyprland_tty script'inde yapılır
                elif [ "''${XDG_VTNR}" = "2" ]; then
                    echo "╔════════════════════════════════════════════════════════════╗"
                    echo "║  TTY2: Launching Hyprland via hyprland_tty                 ║"
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
                # Tüm environment ayarları gnome_tty script'inde yapılır
                elif [ "''${XDG_VTNR}" = "3" ]; then
                    echo "╔════════════════════════════════════════════════════════════╗"
                    echo "║  TTY3: Launching GNOME via gnome_tty                       ║"
                    echo "╚════════════════════════════════════════════════════════════╝"
                
                    # Minimum gerekli değişkenler - geri kalanı gnome_tty'de
                    export XDG_SESSION_TYPE=wayland
                    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                    export GNOME_TTY_GUARD=1
                
                    # gnome_tty script'i kontrol et
                    if command -v gnome_tty >/dev/null 2>&1; then
                        echo "Starting GNOME with optimized configuration..."
                        exec gnome_tty
                    else
                        echo "ERROR: gnome_tty script not found in PATH"
                        echo "Falling back to direct GNOME launch (not recommended)"
                        sleep 3
                    
                        # D-Bus session ile GNOME başlat
                        if command -v dbus-run-session >/dev/null; then
                            exec dbus-run-session -- gnome-session --session=gnome 2>&1 | tee /tmp/gnome-session-tty3.log
                        else
                            eval $(dbus-launch --sh-syntax --exit-with-session)
                            export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
                            exec gnome-session --session=gnome 2>&1 | tee /tmp/gnome-session-tty3.log
                        fi
                    fi
            
                # ==========================================================================
                # TTY5: Ubuntu VM in Sway
                # ==========================================================================
                elif [ "''${XDG_VTNR}" = "5" ]; then
                    echo "╔════════════════════════════════════════════════════════════╗"
                    echo "║  TTY5: Starting Ubuntu VM in Sway                          ║"
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
                # Diğer TTY'ler: Manuel kullanım için bilgilendirme
                # ==========================================================================
                else
                    echo "╔════════════════════════════════════════════════════════════╗"
                    echo "║  TTY''${XDG_VTNR}: No auto-start configured                ║"
                    echo "╚════════════════════════════════════════════════════════════╝"
                    echo ""
                    echo "Available TTY Assignments:"
                    echo "  TTY1: Display Manager (gdm)"
                    echo "  TTY2: Hyprland (hyprland_tty)"
                    echo "  TTY3: GNOME (gnome_tty)"
                    echo "  TTY5: Ubuntu VM (Sway)"
                    echo "  TTY6: TTY6"
                    echo ""
                    echo "Manual Start Commands:"
                    echo "  exec hyprland_tty    - Hyprland with optimizations"
                    echo "  exec gnome_tty       - GNOME with optimizations"
                    echo ""
                fi
            
            fi
            # Login shell değilse veya desktop zaten çalışıyorsa sessizce devam et
  '';
}
