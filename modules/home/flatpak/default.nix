# modules/home/flatpak/default.nix
# ==============================================================================
# Home Manager module for flatpak.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ==============================================================================

{ pkgs, lib, inputs, config, ... }:

let
  cfg = config.my.user.flatpak;
in
{
  # ============================================================================
  # Module Imports
  # ============================================================================
  # Import nix-flatpak Home Manager module for declarative Flatpak management
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  options.my.user.flatpak = {
    enable = lib.mkEnableOption "User-level Flatpak management";
  };

  config = lib.mkIf cfg.enable {
    # ============================================================================
    # Flatpak Service Configuration
    # ============================================================================
    services.flatpak = {
      # Enable Flatpak management via nix-flatpak
      enable = true;

      # --------------------------------------------------------------------------
      # Automatic Updates
      # --------------------------------------------------------------------------
      # Disable automatic update service to prevent startup failures
      # Manual updates: flatpak update
      update.auto.enable = false;

      # --------------------------------------------------------------------------
      # Remote Repositories
      # --------------------------------------------------------------------------
      # Configure Flatpak repositories (application sources)
      remotes = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];

      # --------------------------------------------------------------------------
      # Installed Applications
      # --------------------------------------------------------------------------
      # Declarative list of Flatpak applications to install
      # 
      # IMPORTANT: Use ONLY the application ID, not the full flatpak URL
      # Format: "app-id" (NOT "flathub:app/app-id/x86_64/stable")
      #
      # Correct:   "io.ente.auth"
      # Wrong:     "flathub:app/io.ente.auth/x86_64/stable"
      #
      # To find application IDs:
      #   1. Search on Flathub: https://flathub.org
      #   2. Use command: flatpak search <app-name>
      #   3. The ID is shown in the "Application ID" column
      packages = [
        # Authentication and Security
        "io.ente.auth"  # Ente Auth - 2FA authenticator
        
        # Add more applications here (just the app ID):
        # "com.example.App"
        # "org.mozilla.firefox"
      ];
    };

    # ============================================================================
    # Systemd Service Override - Delayed Boot Start
    # ============================================================================
    # Override the flatpak-managed-install service to delay boot startup
    # This prevents repeated failures when network isn't ready
    systemd.user.services.flatpak-managed-install = {
      Unit = {
        # Wait for network before starting
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      
      Service = {
        # More lenient restart policy
        Restart = lib.mkForce "on-failure";
        RestartSec = lib.mkForce "5min";  # Wait 5 minutes between retries
        
        # Limit restart attempts
        StartLimitBurst = 3;
        StartLimitIntervalSec = "1h";  # Max 3 attempts per hour
      };
    };

    # ============================================================================
    # Systemd Timer - Delayed Boot Installation
    # ============================================================================
    # Timer ensures Flatpak installation starts 90 seconds after boot
    # This prevents boot-time network errors
    systemd.user.timers.flatpak-managed-install = {
      Unit = {
        Description = "Delayed start timer for Flatpak installation";
      };
      
      Timer = {
        # Start 90 seconds after boot (after Transmission at 60s)
        OnBootSec = "90s";
        
        # Don't run on calendar schedule
        # Only trigger once after boot
      };
      
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    # ============================================================================
    # Shell Integration
    # ============================================================================
    # Add helpful aliases for Flatpak management
    programs.bash.shellAliases = {
      # Application management
      flatpak-list = "flatpak list --app --columns=name,application,version";
      flatpak-search = "flatpak search";
      flatpak-info = "flatpak info";
      
      # Updates and maintenance
      flatpak-update = "flatpak update";
      flatpak-cleanup = "flatpak uninstall --unused";
      
      # Repository management
      flatpak-remotes = "flatpak remotes --show-details";
      
      # Service management
      flatpak-status = "systemctl --user status flatpak-managed-install";
      flatpak-logs = "journalctl --user -u flatpak-managed-install -f";
      flatpak-install-now = "systemctl --user start flatpak-managed-install";
    };
  };
}
