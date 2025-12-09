# modules/home/password-store/default.nix
# ------------------------------------------------------------------------------
# Home Manager module for password-store.
# Exposes my.user options to install packages and write user config.
# Keeps per-user defaults centralized instead of scattered dotfiles.
# Adjust feature flags and templates in the module body below.
# ------------------------------------------------------------------------------

{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.pass;
in
{
  options.my.user.pass = {
    enable = lib.mkEnableOption "pass password manager";
  };

  config = lib.mkIf cfg.enable {
    # =============================================================================
    # Pass CLI - Core Password Manager
    # =============================================================================
    programs.password-store = {
      enable = true;
      
      # Pass with Extensions
      # Extensions add functionality beyond basic password storage
      package = pkgs.pass.withExtensions (exts: [
        # OTP/2FA Support
        # Generate time-based one-time passwords (TOTP)
        # Usage: pass otp insert website/example.com
        #        pass otp show website/example.com
        exts.pass-otp
        
        # Password Audit
        # Check password strength and breach database (HIBP)
        # Usage: pass audit
        # Note: doCheck=false to avoid flaky test failures during build
        (exts.pass-audit.overrideAttrs (old: {
          doCheck = false;
        }))
        
        # Password Update
        # Easily update existing passwords while preserving metadata
        # Usage: pass update website/example.com
        exts.pass-update
      ]);
      
      # ---------------------------------------------------------------------------
      # Core Settings
      # ---------------------------------------------------------------------------
      settings = {
        # Password store location (GPG-encrypted files)
        PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.pass";
        
        # Clipboard timeout (seconds)
        # Password cleared from clipboard after 45s for security
        PASSWORD_STORE_CLIP_TIME = "45";
        
        # Default generated password length
        # Strong passwords: 20+ characters recommended
        PASSWORD_STORE_GENERATED_LENGTH = "20";
      };
    };
  
    # =============================================================================
    # Secret Service Integration - DISABLED DUE TO PYTHON 3.13 BUG
    # =============================================================================
    # pass-secret-service currently has a critical bug with Python 3.13:
    # UnboundLocalError: cannot access local variable 'service' where it is not associated with a value
    #
    # Alternative Solutions:
    #   1. Use GNOME Keyring (services.gnome-keyring.enable = true in display module)
    #   2. Use KeePassXC with Secret Service integration
    #   3. Use browserpass extension for browser password management
    #   4. Wait for upstream fix or downgrade to Python 3.12
    #
    # Tracking Issue:
    #   • GitHub: https://github.com/mdellweg/pass_secret_service/issues
    #   • NixOS: https://github.com/NixOS/nixpkgs/issues (search pass-secret-service python 3.13)
    #
    # To Re-enable (when fixed):
    #   Uncomment the block below and change enable to true
    
    services.pass-secret-service = {
      # DISABLED: Python 3.13 incompatibility causes UnboundLocalError on startup
      enable = false;
      
      # Uncomment when bug is fixed:
      # enable = true;
      # storePath = "${config.home.homeDirectory}/.pass";
    };
  
    # =============================================================================
    # Secret Tool - CLI Interface to Secret Service
    # =============================================================================
    # Provides command-line access to the Secret Service API
    # Note: With pass-secret-service disabled, this will query GNOME Keyring
    # or other active Secret Service provider instead
    #
    # Common Operations:
    #   secret-tool store --label='MyApp' service myapp username myuser
    #   secret-tool lookup service myapp username myuser
    #   secret-tool search --all
    #   secret-tool clear service myapp username myuser
    
    # =============================================================================
    # Shell Aliases - Convenience Commands
    # =============================================================================
    home.shellAliases = {
      # Pass shortcuts
      "p" = "pass";                              # Quick access
      "pc" = "pass -c";                          # Copy to clipboard
      "pg" = "pass generate";                    # Generate password
      "pi" = "pass insert";                      # Insert new password
      "psh" = "pass show";                       # Show password
      "pe" = "pass edit";                        # Edit password entry
      "pr" = "pass rm";                          # Remove password
      "pf" = "pass find";                        # Search passwords
      
      # OTP shortcuts
      "potp" = "pass otp";                       # OTP token
      "potpc" = "pass otp -c";                   # Copy OTP to clipboard
      
      # Git sync (if using pass git integration)
      "ppush" = "pass git push";                 # Push to remote
      "ppull" = "pass git pull";                 # Pull from remote
      
      # Password audit
      "paudit" = "pass audit";                   # Check password strength
      
      # Secret Service queries (queries active keyring - GNOME Keyring, KeePassXC, etc.)
      "secret-list" = "secret-tool search --all"; # List all secrets
      "secret-get" = "secret-tool lookup";        # Get specific secret
    };
  };
}
