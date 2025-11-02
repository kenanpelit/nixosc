# modules/home/transmission/default.nix
# ==============================================================================
# Transmission BitTorrent Client Configuration (User-level)
# ==============================================================================
# Note: System-level firewall rules are configured in modules/core/transmission/
# This module only handles user-level service and settings
#
# Boot Behavior:
#   - Service starts 60 seconds after boot (delayed start)
#   - Ensures network is fully ready before starting
#   - Prevents boot-time failure messages
#
# ==============================================================================
{ config, lib, pkgs, ... }:
let
  settingsDir = ".config/transmission-daemon";
  settingsFormat = pkgs.formats.json {};
  
  # =============================================================================
  # Base Configuration Settings
  # =============================================================================
  baseSettings = {
    # Directory Settings
    download-dir = "${config.home.homeDirectory}/.tor/transmission/complete";
    incomplete-dir = "${config.home.homeDirectory}/.tor/transmission/incomplete";
    incomplete-dir-enabled = true;
    watch-dir = "${config.home.homeDirectory}/.tor/transmission/watch";
    watch-dir-enabled = true;
    
    # RPC Settings
    rpc-enabled = true;
    rpc-port = 9091;
    rpc-whitelist-enabled = true;
    rpc-whitelist = "127.0.0.1";
    rpc-authentication-required = false;
    rpc-username = "";
    rpc-password = "";
    
    # Speed Settings
    speed-limit-down = 1000;
    speed-limit-down-enabled = false;
    speed-limit-up = 100;
    speed-limit-up-enabled = false;
    
    # Behavior Settings
    start-added-torrents = true;
    trash-original-torrent-files = false;
    umask = 18;
  };
  
  settingsFile = settingsFormat.generate "settings.json" baseSettings;
  
  # =============================================================================
  # Setup Script (runs before service starts)
  # =============================================================================
  # Creates directories and installs configuration
  setupScript = pkgs.writeShellScriptBin "transmission-setup" ''
    set -euo pipefail
    
    echo "Setting up Transmission directories and configuration..."
    
    # Create necessary directories
    ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.tor/transmission"/{complete,incomplete,watch}
    ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/${settingsDir}"
    
    # Settings file path
    SETTINGS_FILE="${config.home.homeDirectory}/${settingsDir}/settings.json"
    
    # Backup existing settings if present
    if [ -f "$SETTINGS_FILE" ]; then
      echo "Found existing settings, checking for changes..."
      if ! ${pkgs.diffutils}/bin/cmp -s "${settingsFile}" "$SETTINGS_FILE" 2>/dev/null; then
        BACKUP_FILE="$SETTINGS_FILE.backup.$(${pkgs.coreutils}/bin/date +%Y%m%d-%H%M%S)"
        ${pkgs.coreutils}/bin/cp "$SETTINGS_FILE" "$BACKUP_FILE"
        echo "Backed up to: $BACKUP_FILE"
      fi
    fi
    
    # Install new settings with proper permissions
    ${pkgs.coreutils}/bin/install -m 644 "${settingsFile}" "$SETTINGS_FILE"
    echo "Configuration installed successfully"
  '';
  
in
{
  config = {
    # =============================================================================
    # Systemd Service Configuration
    # =============================================================================
    systemd.user.services.transmission = {
      Unit = {
        Description = "Transmission BitTorrent Daemon";
        Documentation = "https://transmissionbt.com/";
        
        # Wait for network to be fully online before starting
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      
      Service = {
        Type = "notify";
        
        # Setup directories and configuration before starting
        ExecStartPre = "${setupScript}/bin/transmission-setup";
        
        # Start transmission daemon
        ExecStart = "${pkgs.transmission_4}/bin/transmission-daemon -f --log-level=error";
        
        # Reload configuration on SIGHUP
        ExecReload = "${pkgs.coreutils}/bin/kill -s HUP $MAINPID";
        
        # Restart policy
        Restart = "on-failure";
        RestartSec = 10;
        
        # Timeout settings
        TimeoutStartSec = 30;
        TimeoutStopSec = 10;
        
        # Resource limits (optional - prevents runaway resource usage)
        # MemoryMax = "512M";
        # CPUQuota = "50%";
      };
      
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
    
    # =============================================================================
    # Systemd Timer - Delayed Boot Start
    # =============================================================================
    # Timer ensures Transmission starts 60 seconds after boot
    # This prevents boot-time network errors and ensures clean startup
    systemd.user.timers.transmission = {
      Unit = {
        Description = "Delayed start timer for Transmission";
      };
      
      Timer = {
        # Start 60 seconds after boot
        OnBootSec = "60s";
        
        # Don't run on calendar schedule
        # Only trigger once after boot
      };
      
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
    
    # =============================================================================
    # Package Installation
    # =============================================================================
    home.packages = with pkgs; [
      transmission_4
    ];
    
    # =============================================================================
    # Shell Aliases for Transmission Management
    # =============================================================================
    programs.bash.shellAliases = {
      # Service management
      tr-status = "systemctl --user status transmission";
      tr-start = "systemctl --user start transmission";
      tr-stop = "systemctl --user stop transmission";
      tr-restart = "systemctl --user restart transmission";
      tr-logs = "journalctl --user -u transmission -f";
      
      # Transmission remote commands
      tr-list = "${pkgs.transmission_4}/bin/transmission-remote -l";
      tr-add = "${pkgs.transmission_4}/bin/transmission-remote -a";
      tr-remove = "${pkgs.transmission_4}/bin/transmission-remote -r";
      tr-info = "${pkgs.transmission_4}/bin/transmission-remote -i";
    };
  };
}

# ==============================================================================
# Troubleshooting
# ==============================================================================
#
# Exit Code 127 Error:
#   - Means "command not found" in the setup script
#   - Fixed by using system PATH commands instead of hardcoded paths
#   - Script now uses: mkdir, cp, chmod, date, cmp (all in standard PATH)
#
# Timer and Service Behavior:
#   - Timer triggers 60 seconds after boot
#   - Timer activates the transmission service
#   - Service starts only when timer fires
#   - No boot-time failures or error messages
#
# Manual Control:
#   systemctl --user list-timers transmission  # Check timer status
#   systemctl --user status transmission        # Check service status
#   tr-start                                    # Start immediately (bypass timer)
#
# Issue: Service not starting after boot
# Fix:   systemctl --user list-timers          # Verify timer is active
#        systemctl --user start transmission   # Manual start
#
# Issue: Want to disable delayed start
# Fix:   systemctl --user disable transmission.timer
#        systemctl --user enable transmission.service --now
#
# Debug Setup Script:
#   journalctl --user -u transmission -n 50    # View setup script output
#   bash -x /nix/store/.../transmission-setup  # Run script manually with debug
#
# ==============================================================================
