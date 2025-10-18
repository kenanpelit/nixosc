# modules/home/password-store/default.nix
# ==============================================================================
# Password Store (pass) - GPG-Based Password Management
# ==============================================================================
#
# Module:      modules/home/password-store
# Purpose:     Unified password management with desktop integration
#
# Components:
#   • Pass CLI - Command-line password manager with GPG encryption
#   • Pass Extensions - OTP, audit, update functionality
#   • Secret Service - D-Bus integration for desktop apps
#   • Secret Tool - CLI interface to Secret Service API
#
# Architecture:
#   Pass Storage (~/.pass)
#      ↓ (GPG encrypted)
#   Pass CLI (password-store)
#      ↓ (D-Bus Secret Service API)
#   Desktop Apps (Firefox, NetworkManager, etc.)
#
# Features:
#   ✓ GPG-encrypted password storage
#   ✓ Git synchronization support
#   ✓ OTP/2FA token generation
#   ✓ Password audit (strength/breach check)
#   ✓ Desktop application integration
#   ✓ Browser autofill support
#   ✓ WiFi password storage (NetworkManager)
#
# Usage:
#   pass insert website/example.com       # Add password
#   pass show website/example.com         # Show password
#   pass generate website/example.com 20  # Generate strong password
#   pass otp website/example.com          # Show OTP token
#   secret-tool lookup service myapp      # Query via Secret Service
#
# ==============================================================================

{ config, lib, pkgs, ... }:

{
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
  # Secret Service Integration - Desktop Application Bridge
  # =============================================================================
  # Implements freedesktop.org Secret Service API via D-Bus
  # Allows desktop applications to securely access Pass storage
  #
  # Compatible Applications:
  #   • Browsers: Firefox, Chrome (password autofill)
  #   • Email: Thunderbird, Evolution
  #   • Network: NetworkManager (WiFi passwords)
  #   • Chat: Pidgin, HexChat
  #   • Any app using libsecret/secret-tool
  #
  # How it works:
  #   1. App requests password via D-Bus Secret Service API
  #   2. pass-secret-service queries ~/.pass (GPG-encrypted)
  #   3. GPG decrypts entry (may prompt for passphrase)
  #   4. Password returned to app securely
  
  services.pass-secret-service = {
    enable = true;
    
    # Must match PASSWORD_STORE_DIR above
    # This is where encrypted password files are stored
    storePath = "${config.home.homeDirectory}/.pass";
  };

  # =============================================================================
  # Secret Tool - CLI Interface to Secret Service
  # =============================================================================
  # Provides command-line access to the Secret Service API
  # Useful for scripts and manual password retrieval
  #
  # Common Operations:
  #   secret-tool store --label='MyApp' service myapp username myuser
  #   secret-tool lookup service myapp username myuser
  #   secret-tool search --all
  #   secret-tool clear service myapp username myuser
  #
  # Integration with Pass:
  #   When pass-secret-service is running, secret-tool queries
  #   will return passwords from ~/.pass storage
  
  home.packages = with pkgs; [
    libsecret  # Provides secret-tool binary and libsecret library
  ];

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
    
    # Secret Service queries
    "secret-list" = "secret-tool search --all"; # List all secrets
    "secret-get" = "secret-tool lookup";        # Get specific secret
  };
}

# ==============================================================================
# Post-Configuration Setup
# ==============================================================================
#
# After enabling this module, initialize your password store:
#
# 1. Initialize Pass with GPG key:
#    pass init your-gpg-key-id
#
# 2. (Optional) Initialize Git repository:
#    pass git init
#    pass git remote add origin git@github.com:user/pass-store.git
#
# 3. Add your first password:
#    pass insert email/gmail.com
#
# 4. Generate a strong password:
#    pass generate website/example.com 20
#
# 5. Add OTP/2FA token:
#    pass otp insert website/example.com
#    # Enter otpauth:// URI from QR code
#
# 6. Test Secret Service integration:
#    secret-tool lookup title email/gmail.com
#
# 7. Verify pass-secret-service is running:
#    systemctl --user status pass-secret-service
#
# ==============================================================================
# Troubleshooting
# ==============================================================================
#
# Issue: GPG passphrase prompt not appearing
# Fix:   echo "use-agent" >> ~/.gnupg/gpg.conf
#        systemctl --user restart gpg-agent
#
# Issue: pass-secret-service not starting
# Fix:   systemctl --user restart pass-secret-service
#        journalctl --user -u pass-secret-service
#
# Issue: Browser not using Pass for autofill
# Fix:   Install browser extension (browserpass for Firefox/Chrome)
#        Or configure browser to use system keyring
#
# Issue: NetworkManager not saving WiFi passwords
# Fix:   Ensure pass-secret-service is running
#        Check: busctl --user list | grep secret
#
# ==============================================================================
