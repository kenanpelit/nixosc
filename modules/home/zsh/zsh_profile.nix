# modules/home/zsh/zsh_profile.nix
{ config, lib, pkgs, ... }:
{
  xdg.configFile = {
    "zsh/.zprofile" = {
      text = ''
        # =============================================================================
        # NixOS Multi-TTY Desktop Environment Auto-Start Configuration
        # =============================================================================
        # TTY1: Hyprland (Primary Wayland Compositor)
        # TTY2: GNOME Wayland (Secondary Desktop Environment)  
        # TTY3: Available for manual use
        # TTY4-6: QEMU VMs with Sway
        # =============================================================================

        # Only run if this is a login shell and no desktop is running
        if [[ $- == *l* ]] && [ -z "''${WAYLAND_DISPLAY}" ] && [ -z "''${DISPLAY}" ] && [[ "''${XDG_VTNR}" =~ ^[1-6]$ ]]; then
            
            # ==========================================================================
            # TTY1: Hyprland Wayland Compositor
            # ==========================================================================
            if [ "''${XDG_VTNR}" = "1" ]; then
                echo "=== TTY1: Starting Hyprland Wayland Compositor ==="
                
                # Clean any conflicting environment variables
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                unset GNOME_SHELL_SESSION_MODE MUTTER_DEBUG_DUMMY_MODE_SPECS
                
                # Set Hyprland-specific environment
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=Hyprland
                export XDG_CURRENT_DESKTOP=Hyprland
                export DESKTOP_SESSION=hyprland
                
                # Runtime directory setup
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                # Wayland backend preferences
                export QT_QPA_PLATFORM="wayland;xcb"
                export GDK_BACKEND="wayland,x11"
                export MOZ_ENABLE_WAYLAND=1
                export SDL_VIDEODRIVER=wayland
                
                echo "Environment: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP / $DESKTOP_SESSION"
                
                # Start Hyprland
                if command -v hyprland_tty >/dev/null 2>&1; then
                    exec hyprland_tty
                else
                    echo "ERROR: hyprland_tty script not found!"
                    sleep 3
                    exec startup-manager
                fi
            
            # ==========================================================================
            # TTY2: GNOME Wayland Desktop Environment
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "2" ]; then
                echo "=== TTY2: Starting GNOME Wayland Desktop Environment ==="
                
                # Clean any conflicting environment variables from other DEs
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                unset HYPRLAND_INSTANCE_SIGNATURE WLR_NO_HARDWARE_CURSORS
                
                # Runtime directory setup
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                if [ ! -d "$XDG_RUNTIME_DIR" ]; then
                    echo "Creating XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
                    sudo mkdir -p "$XDG_RUNTIME_DIR"
                    sudo chown $(id -u):$(id -g) "$XDG_RUNTIME_DIR"
                    sudo chmod 700 "$XDG_RUNTIME_DIR"
                fi
                
                # Set GNOME-specific environment variables
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=gnome
                export XDG_CURRENT_DESKTOP=GNOME
                export DESKTOP_SESSION=gnome
                
                # GNOME Wayland backend settings
                export WAYLAND_DISPLAY=wayland-0
                export QT_QPA_PLATFORM=wayland
                export GDK_BACKEND=wayland
                export MOZ_ENABLE_WAYLAND=1
                
                # GNOME-specific environment
                export GNOME_SHELL_SESSION_MODE=user
                export MUTTER_DEBUG_DUMMY_MODE_SPECS=1024x768
                
                # Keyring environment
                export GNOME_KEYRING_CONTROL="$XDG_RUNTIME_DIR/keyring"
                export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"
                
                echo "Environment: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP / $DESKTOP_SESSION"
                echo "Runtime Dir: $XDG_RUNTIME_DIR"
                
                # Verify required GNOME components
                if ! command -v gnome-session >/dev/null; then
                    echo "ERROR: gnome-session not found!"
                    echo "Available GNOME commands:"
                    find /run/current-system/sw/bin -name "*gnome*" 2>/dev/null | head -10
                    sleep 5
                    exec startup-manager
                fi
                
                if ! command -v gnome-shell >/dev/null; then
                    echo "ERROR: gnome-shell not found!"
                    sleep 5
                    exec startup-manager
                fi
                
                # Start GNOME with proper D-Bus session
                if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
                    echo "Starting GNOME with new D-Bus session..."
                    if command -v dbus-run-session >/dev/null; then
                        exec dbus-run-session -- gnome-session --session=gnome --debug 2>&1 | tee /tmp/gnome-session-tty2.log
                    else
                        echo "Starting D-Bus session manually..."
                        eval $(dbus-launch --sh-syntax --exit-with-session)
                        export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
                        exec gnome-session --session=gnome --debug 2>&1 | tee /tmp/gnome-session-tty2.log
                    fi
                else
                    echo "Using existing D-Bus session for GNOME..."
                    exec gnome-session --session=gnome --debug 2>&1 | tee /tmp/gnome-session-tty2.log
                fi
            
            # ==========================================================================
            # TTY3: Manual Use / Available
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "3" ]; then
                echo "=== TTY3: Available for manual use ==="
                echo "You can manually start any desktop environment here"
                echo "Available options:"
                echo "  - startup-manager (interactive selector)"
                echo "  - sway (manual Sway compositor)"
                echo "  - Any other window manager"
                # Don't auto-exec anything, leave for manual use
            
            # ==========================================================================
            # TTY4: Ubuntu QEMU VM with Sway
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "4" ]; then
                echo "=== TTY4: Starting Ubuntu QEMU VM with Sway ==="
                
                # Clean environment for VM session
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                
                # Set Sway environment for VM display
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=sway
                export XDG_CURRENT_DESKTOP=sway
                export DESKTOP_SESSION=sway
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                echo "Environment: $XDG_CURRENT_DESKTOP (for Ubuntu VM)"
                
                if [ -f ~/.config/sway/qemu_vmubuntu ]; then
                    exec sway -c ~/.config/sway/qemu_vmubuntu
                else
                    echo "ERROR: Ubuntu VM Sway config not found!"
                    sleep 3
                    exec sway
                fi
            
            # ==========================================================================
            # TTY5: NixOS QEMU VM with Sway
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "5" ]; then
                echo "=== TTY5: Starting NixOS QEMU VM with Sway ==="
                
                # Clean environment for VM session
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                
                # Set Sway environment for VM display
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=sway
                export XDG_CURRENT_DESKTOP=sway
                export DESKTOP_SESSION=sway
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                echo "Environment: $XDG_CURRENT_DESKTOP (for NixOS VM)"
                
                if [ -f ~/.config/sway/qemu_vmnixos ]; then
                    exec sway -c ~/.config/sway/qemu_vmnixos
                else
                    echo "ERROR: NixOS VM Sway config not found!"
                    sleep 3
                    exec sway
                fi
            
            # ==========================================================================
            # TTY6: Arch QEMU VM with Sway (Optional)
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "6" ]; then
                echo "=== TTY6: Starting Arch QEMU VM with Sway ==="
                
                # Clean environment for VM session
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                
                # Set Sway environment for VM display
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=sway
                export XDG_CURRENT_DESKTOP=sway
                export DESKTOP_SESSION=sway
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                echo "Environment: $XDG_CURRENT_DESKTOP (for Arch VM)"
                
                if [ -f ~/.config/sway/qemu_vmarch ]; then
                    exec sway -c ~/.config/sway/qemu_vmarch
                else
                    echo "ERROR: Arch VM Sway config not found!"
                    sleep 3
                    exec sway
                fi
            
            # ==========================================================================
            # Other TTYs: No auto-start
            # ==========================================================================
            else
                echo "=== TTY''${XDG_VTNR}: No auto-start configured ==="
                echo "Available TTY assignments:"
                echo "  TTY1: Hyprland (Primary)"
                echo "  TTY2: GNOME Wayland"
                echo "  TTY3: Manual use"
                echo "  TTY4: Ubuntu VM"
                echo "  TTY5: NixOS VM" 
                echo "  TTY6: Arch VM"
                echo ""
                echo "Start desktop manually or switch to configured TTY"
            fi
            
        else
            # Display server already running - show current environment
            echo "=== Desktop Environment Already Running ==="
            echo "WAYLAND_DISPLAY: ''${WAYLAND_DISPLAY:-not set}"
            echo "DISPLAY: ''${DISPLAY:-not set}"
            echo "XDG_CURRENT_DESKTOP: ''${XDG_CURRENT_DESKTOP:-not set}"
            echo "XDG_SESSION_DESKTOP: ''${XDG_SESSION_DESKTOP:-not set}"
            echo "DESKTOP_SESSION: ''${DESKTOP_SESSION:-not set}"
            echo "TTY: ''${XDG_VTNR:-unknown}"
        fi
      '';
      executable = true;
    };
  };
}

