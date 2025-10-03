# modules/home/zsh/zsh_profile.nix
{ config, lib, pkgs, ... }:
{
  xdg.configFile = {
    "zsh/.zprofile" = {
      text = ''
        # =============================================================================
        # NixOS Multi-TTY Desktop Environment Auto-Start Configuration
        # =============================================================================
        # TTY1: Display Manager (cosmic-greeter) - Session Selection
        # TTY2: Hyprland (Manual Wayland Compositor)
        # TTY3: GNOME (Manual Desktop Environment)
        # TTY4: COSMIC (Manual Rust-based Desktop - Beta)
        # TTY5-6: QEMU VMs with Sway
        # =============================================================================

        # Only run if this is a login shell and no desktop is running
        # TTY1: Requires no session type (display manager)
        # TTY2-6: Can run even if session type is set (manual sessions)
        if [[ $- == *l* ]] && [ -z "''${WAYLAND_DISPLAY}" ] && [ -z "''${DISPLAY}" ] && [[ "''${XDG_VTNR}" =~ ^[1-6]$ ]]; then
            
            # For TTY1, check that no session is active (display manager control)
            if [ "''${XDG_VTNR}" = "1" ] && [ -n "''${XDG_SESSION_TYPE}" ]; then
                # Session already active on TTY1, don't interfere
                return
            fi
            
            # ==========================================================================
            # TTY1: Reserved for Display Manager (cosmic-greeter)
            # ==========================================================================
            if [ "''${XDG_VTNR}" = "1" ]; then
                echo "=== TTY1: Display Manager (cosmic-greeter) ==="
                echo ""
                echo "Available sessions:"
                echo "  • COSMIC  - Rust-based desktop (Beta)"
                echo "  • Hyprland - Tiling Wayland compositor"
                echo "  • GNOME   - Traditional desktop"
                echo ""
                echo "Manual start options:"
                echo "  exec Hyprland        - Start Hyprland directly"
                echo "  exec cosmic-session  - Start COSMIC directly"
                echo "  exec gnome-session   - Start GNOME directly"
                echo "  exec startup-manager - Interactive menu"
                echo ""
            
            # ==========================================================================
            # TTY2: Hyprland Wayland Compositor (Manual)
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "2" ]; then
                echo "=== TTY2: Starting Hyprland Wayland Compositor ==="
                
                # Clean environment from other desktop sessions
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                unset GNOME_SHELL_SESSION_MODE MUTTER_DEBUG_DUMMY_MODE_SPECS
                
                # Set Hyprland-specific environment
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=Hyprland
                export XDG_CURRENT_DESKTOP=Hyprland
                export DESKTOP_SESSION=hyprland
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                # Wayland backend preferences for applications
                export QT_QPA_PLATFORM="wayland;xcb"
                export GDK_BACKEND="wayland,x11"
                export MOZ_ENABLE_WAYLAND=1
                export SDL_VIDEODRIVER=wayland
                
                echo "Environment: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP"
                
                # Start Hyprland with custom wrapper if available
                if command -v hyprland_tty >/dev/null 2>&1; then
                    exec hyprland_tty
                else
                    echo "WARNING: hyprland_tty not found, using default Hyprland"
                    sleep 2
                    exec Hyprland
                fi
            
            # ==========================================================================
            # TTY3: GNOME Wayland Desktop Environment (Manual)
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "3" ]; then
                echo "=== TTY3: Starting GNOME Wayland Desktop Environment ==="
                
                # Clean environment from other desktop sessions
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                unset HYPRLAND_INSTANCE_SIGNATURE WLR_NO_HARDWARE_CURSORS
                
                # Ensure XDG_RUNTIME_DIR exists
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
                
                # GNOME-specific settings
                export GNOME_SHELL_SESSION_MODE=user
                export MUTTER_DEBUG_DUMMY_MODE_SPECS=1024x768
                
                # Keyring environment
                export GNOME_KEYRING_CONTROL="$XDG_RUNTIME_DIR/keyring"
                export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/keyring/ssh"
                
                echo "Environment: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP"
                echo "Runtime Dir: $XDG_RUNTIME_DIR"
                
                # Verify GNOME components are available
                if ! command -v gnome-session >/dev/null; then
                    echo "ERROR: gnome-session not found!"
                    echo "Available GNOME commands:"
                    find /run/current-system/sw/bin -name "*gnome*" 2>/dev/null | head -10
                    sleep 5
                    return
                fi
                
                # Start GNOME with D-Bus session
                echo "Starting GNOME with new D-Bus session..."
                if command -v dbus-run-session >/dev/null; then
                    exec dbus-run-session -- gnome-session --session=gnome 2>&1 | tee /tmp/gnome-session-tty3.log
                else
                    echo "Starting D-Bus manually..."
                    eval $(dbus-launch --sh-syntax --exit-with-session)
                    export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
                    exec gnome-session --session=gnome 2>&1 | tee /tmp/gnome-session-tty3.log
                fi
            
            # ==========================================================================
            # TTY4: COSMIC Desktop Environment (Manual - Beta)
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "4" ]; then
                echo "=== TTY4: Starting COSMIC Desktop Environment (Beta) ==="
                
                # Clean environment from ALL other desktop sessions
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                unset HYPRLAND_INSTANCE_SIGNATURE WLR_NO_HARDWARE_CURSORS
                unset GNOME_SHELL_SESSION_MODE MUTTER_DEBUG_DUMMY_MODE_SPECS
                unset DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
                
                # Ensure XDG_RUNTIME_DIR exists with correct permissions
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                if [ ! -d "$XDG_RUNTIME_DIR" ]; then
                    echo "Creating XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
                    sudo mkdir -p "$XDG_RUNTIME_DIR"
                    sudo chown $(id -u):$(id -g) "$XDG_RUNTIME_DIR"
                    sudo chmod 700 "$XDG_RUNTIME_DIR"
                fi
                
                # Set COSMIC-specific environment variables
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=cosmic
                export XDG_CURRENT_DESKTOP=COSMIC
                export DESKTOP_SESSION=cosmic
                
                # Wayland backend settings
                export QT_QPA_PLATFORM=wayland
                export GDK_BACKEND=wayland
                export MOZ_ENABLE_WAYLAND=1
                export SDL_VIDEODRIVER=wayland
                
                # COSMIC-specific features
                export COSMIC_DATA_CONTROL_ENABLED=1
                export NIXOS_OZONE_WL=1
                
                echo "Environment: $XDG_CURRENT_DESKTOP / $XDG_SESSION_DESKTOP"
                echo "Runtime Dir: $XDG_RUNTIME_DIR"
                echo "Note: COSMIC is in Beta - expect occasional issues"
                
                # Verify COSMIC components are available
                if ! command -v cosmic-session >/dev/null; then
                    echo "ERROR: cosmic-session not found!"
                    echo "Available COSMIC commands:"
                    find /run/current-system/sw/bin -name "*cosmic*" 2>/dev/null | head -10
                    sleep 5
                    return
                fi
                
                # COSMIC startup - let cosmic-session handle everything
                # REMOVED: Manual systemd service management
                # REMOVED: Forced workspace/dock configuration
                # cosmic-session will start portals automatically when Wayland is ready
                
                echo "Starting COSMIC session..."
                echo "Portal services will start automatically"
                
                # Start with D-Bus if not running
                if ! pgrep -u $(id -u) dbus-daemon >/dev/null 2>&1; then
                    echo "Starting D-Bus daemon..."
                    eval $(dbus-launch --sh-syntax)
                    export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
                fi
                
                # Start COSMIC and let it handle portal initialization
                exec cosmic-session 2>&1 | tee /tmp/cosmic-session-tty4.log
            
            # ==========================================================================
            # TTY5: Ubuntu VM in Sway
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "5" ]; then
                echo "=== TTY5: Starting Ubuntu VM in Sway ==="
                
                # Clean environment for Sway session
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                
                # Set Sway environment
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=sway
                export XDG_CURRENT_DESKTOP=sway
                export DESKTOP_SESSION=sway
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                echo "Environment: Sway compositor for Ubuntu VM"
                
                if [ -f ~/.config/sway/qemu_vmubuntu ]; then
                    exec sway -c ~/.config/sway/qemu_vmubuntu
                else
                    echo "ERROR: Sway config not found: ~/.config/sway/qemu_vmubuntu"
                    echo "Create the config file first"
                    sleep 5
                    return
                fi
            
            # ==========================================================================
            # TTY6: NixOS VM in Sway
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "6" ]; then
                echo "=== TTY6: Starting NixOS VM in Sway ==="
                
                # Clean environment for Sway session
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                
                # Set Sway environment
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=sway
                export XDG_CURRENT_DESKTOP=sway
                export DESKTOP_SESSION=sway
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                echo "Environment: Sway compositor for NixOS VM"
                
                if [ -f ~/.config/sway/qemu_vmnixos ]; then
                    exec sway -c ~/.config/sway/qemu_vmnixos
                else
                    echo "ERROR: Sway config not found: ~/.config/sway/qemu_vmnixos"
                    echo "Create the config file first"
                    sleep 5
                    return
                fi
            
            # ==========================================================================
            # Other TTYs: No auto-start configured
            # ==========================================================================
            else
                echo "=== TTY''${XDG_VTNR}: No auto-start configured ==="
                echo ""
                echo "Available TTY assignments:"
                echo "  TTY1: Display Manager (cosmic-greeter)"
                echo "  TTY2: Hyprland (Manual)"
                echo "  TTY3: GNOME (Manual)"
                echo "  TTY4: COSMIC (Manual - Beta)"
                echo "  TTY5: Ubuntu VM"
                echo "  TTY6: NixOS VM"
                echo ""
                echo "To start a desktop manually:"
                echo "  exec Hyprland"
                echo "  exec gnome-session"
                echo "  exec cosmic-session"
                echo "  exec startup-manager"
            fi
            
        else
            # Not a login shell or desktop already running - do nothing silently
            :
        fi
      '';
      executable = true;
    };
  };
}

