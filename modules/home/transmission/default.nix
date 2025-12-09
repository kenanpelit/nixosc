# modules/home/transmission/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for transmission.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.transmission;
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
    
    # Blocklist Settings
    blocklist-enabled = true;
    blocklist-url = "http://www.example.com/blocklist";  # Lokal dosya kullanıldığı için URL önemsiz
    
    # Performance Settings
    cache-size-mb = 64;  # Varsayılan 4 MB'dan artırıldı
    peer-limit-global = 200;
    peer-limit-per-torrent = 50;
    
    # Network Settings
    peer-port = 51413;
    peer-port-random-on-start = false;
    port-forwarding-enabled = true;
    
    # Protocol Settings
    dht-enabled = true;
    lpd-enabled = true;
    pex-enabled = true;
    utp-enabled = true;
    
    # Security Settings
    encryption = 1;  # 0=off, 1=preferred, 2=required
    
    # Queue Settings
    download-queue-enabled = true;
    download-queue-size = 5;
    seed-queue-enabled = false;
    seed-queue-size = 10;
    queue-stalled-enabled = true;
    queue-stalled-minutes = 30;
    
    # Seeding Settings
    ratio-limit = 2;
    ratio-limit-enabled = false;
    idle-seeding-limit = 30;
    idle-seeding-limit-enabled = false;
    
    # Alternative Speed Limits (Scheduler)
    alt-speed-enabled = false;
    alt-speed-up = 50;
    alt-speed-down = 50;
    alt-speed-time-enabled = false;
    alt-speed-time-begin = 540;   # 09:00
    alt-speed-time-end = 1020;    # 17:00
    alt-speed-time-day = 127;     # All days
    
    # Advanced Settings
    preallocation = 1;            # Fast preallocation
    prefetch-enabled = true;
    scrape-paused-torrents-enabled = true;
    upload-slots-per-torrent = 8;
    
    # Behavior Settings
    start-added-torrents = true;
    trash-original-torrent-files = false;
    rename-partial-files = false;
    torrent-added-verify-mode = "fast";
    umask = 18;  # 022 in octal
    
    # Logging
    message-level = 2;  # 0=None, 1=Error, 2=Info, 3=Debug
    
    # Scripts (disabled by default)
    script-torrent-added-enabled = false;
    script-torrent-added-filename = "";
    script-torrent-done-enabled = false;
    script-torrent-done-filename = "";
    script-torrent-done-seeding-enabled = false;
    script-torrent-done-seeding-filename = "";
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
    ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/${settingsDir}/blocklists"
    
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
  options.my.user.transmission = {
    enable = lib.mkEnableOption "Transmission daemon";
  };

  config = lib.mkIf cfg.enable {
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
# Blocklist Management:
#   - Blocklist enabled by default
#   - Place blocklist files in ~/.config/transmission-daemon/blocklists/
#   - Use the separate blocklist update script for automated updates
#   - Restart service after blocklist updates: tr-restart
#
# Performance Tuning:
#   - cache-size-mb increased to 64 MB (from default 4 MB)
#   - Adjust based on available RAM and usage patterns
#   - Monitor with: tr-list and system resource monitors
#
# ==============================================================================
