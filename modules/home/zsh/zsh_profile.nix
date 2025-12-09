# modules/home/zsh/zsh_profile.nix
# ==============================================================================
# Zsh login profile: environment for login shells, sources zshrc/starship.
# Keeps login shell env consistent; complements zsh.nix rc settings.
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.zsh;
in
lib.mkIf cfg.enable {
  xdg.configFile = {
    "zsh/.zprofile" = {
      text = ''
        # =============================================================================
        # NixOS Multi-TTY Desktop Environment Auto-Start Configuration
        # =============================================================================
        # This profile handles ONLY TTY detection and session routing.
        # All environment variables are set in their respective startup scripts.
        # =============================================================================
        # TTY Assignments:
        #   TTY1: Display Manager - Session Selection
        #   TTY2: Hyprland (via hyprland_tty script)
        #   TTY3: GNOME (via gnome_tty script)
        #   TTY5: Ubuntu VM (Sway)
        # =============================================================================

        # Only run in login shell when no desktop is active
        # CRITICAL: Also check if we're being called from a desktop session startup
        # (gnome-session etc. may re-exec shell during startup)
        if [[ $- == *l* ]] && [ -z "''${WAYLAND_DISPLAY}" ] && [ -z "''${DISPLAY}" ] && [[ "''${XDG_VTNR}" =~ ^[1-6]$ ]]; then

            # TTY1 special check: Don't interfere if session already active
            if [ "''${XDG_VTNR}" = "1" ] && [ -n "''${XDG_SESSION_TYPE}" ]; then
                return
            fi

            # CRITICAL FIX: Prevent re-running when called from desktop session startup
            # Desktop sessions (GNOME) may re-exec shell with login flag
            # Check if we're in a desktop session startup context
            # IMPORTANT: Only check for actual running sessions, not just env vars
            if pgrep -x "gnome-shell" >/dev/null 2>&1 || \
               [ -n "''${GNOME_DESKTOP_SESSION_ID:-}" ] || \
               [ -n "''${GNOME_SHELL_SESSION_MODE:-}" ]; then
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
            elif [ "''${XDG_VTNR}" = "2" ]; then
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║  TTY2: Launching Hyprland via hyprland_tty                 ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                
                # Minimum required variables - rest configured in hyprland_tty
                export XDG_SESSION_TYPE=wayland
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                # Check for hyprland_tty script
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
                echo "║  TTY3: Launching GNOME via gnome_tty                       ║"
                echo "╚════════════════════════════════════════════════════════════╝"

                # CRITICAL: Only set XDG_RUNTIME_DIR - let gnome_tty handle everything else
                # Setting XDG_SESSION_TYPE, XDG_SESSION_DESKTOP etc here causes problems
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"

                # Check for gnome_tty script
                if command -v gnome_tty >/dev/null 2>&1; then
                    echo "Starting GNOME with optimized configuration..."
                    exec gnome_tty
                else
                    echo "ERROR: gnome_tty script not found in PATH"
                    echo "Falling back to direct GNOME launch (not recommended)"
                    sleep 3

                    # Fallback: Start GNOME with proper environment
                    export XDG_SESSION_TYPE=wayland
                    export SYSTEMD_OFFLINE=0

                    # Start GNOME session directly (no dbus-run-session wrapper)
                    exec gnome-session --session=gnome 2>&1 | tee /tmp/gnome-session-tty3.log
                fi
            
            # ==========================================================================
            # TTY5: Ubuntu VM in Sway
            # ==========================================================================
            elif [ "''${XDG_VTNR}" = "5" ]; then
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║  TTY5: Starting Ubuntu VM in Sway                          ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                
                # Clean environment
                unset XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP DESKTOP_SESSION
                
                # Sway environment settings
                export XDG_SESSION_TYPE=wayland
                export XDG_SESSION_DESKTOP=sway
                export XDG_CURRENT_DESKTOP=sway
                export DESKTOP_SESSION=sway
                export XDG_RUNTIME_DIR="/run/user/$(id -u)"
                
                # Add user bin to PATH for svmubuntu command
                export PATH="/etc/profiles/per-user/$(whoami)/bin:$PATH"
                
                echo "Environment: Sway compositor for Ubuntu VM"
                echo "VM Command: svmubuntu"
                
                # Check Sway config
                if [ -f ~/.config/sway/qemu_vmubuntu ]; then
                    echo "Starting Sway with Ubuntu VM configuration..."
                    exec sway -c ~/.config/sway/qemu_vmubuntu 2>&1 | tee /tmp/sway-tty5.log
                else
                    echo "ERROR: Sway config not found: ~/.config/sway/qemu_vmubuntu"
                    echo "Expected location: ~/.config/sway/qemu_vmubuntu"
                    echo "Please verify the configuration file exists"
                    sleep 5
                    return
                fi
            
            # ==========================================================================
            # Other TTYs: Manual use information
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
                echo "  TTY6: Available for manual use"
                echo ""
                echo "Manual Start Commands:"
                echo "  exec hyprland_tty    - Hyprland with optimizations"
                echo "  exec gnome_tty       - GNOME with optimizations"
                echo "  exec sway            - Sway compositor"
                echo ""
            fi
            
        fi
        # Silent continue if not login shell or desktop already running
      '';
      executable = true;
    };
  };
}
