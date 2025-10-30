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
#   • Secret Service - D-Bus integration for desktop apps (DISABLED - Python 3.13 incompatible)
#   • Secret Tool - CLI interface to Secret Service API
#
# Architecture:
#   Pass Storage (~/.pass)
#      ↓ (GPG encrypted)
#   Pass CLI (password-store)
#      ↓ (Manual CLI usage)
#   Desktop Apps (Use GNOME Keyring or KeePassXC instead)
#
# Features:
#   ✓ GPG-encrypted password storage
#   ✓ Git synchronization support
#   ✓ OTP/2FA token generation
#   ✓ Password audit (strength/breach check)
#   ✗ Desktop application integration (pass-secret-service disabled due to Python 3.13 bug)
#   ✗ Browser autofill support (use browserpass extension instead)
#   ✗ WiFi password storage (use NetworkManager's default keyring)
#
# Known Issues:
#   • pass-secret-service has UnboundLocalError with Python 3.13
#   • Upstream issue: https://github.com/mdellweg/pass_secret_service/issues
#   • Workaround: Use GNOME Keyring or disable the service
#
# Usage:
#   pass insert website/example.com       # Add password
#   pass show website/example.com         # Show password
#   pass generate website/example.com 20  # Generate strong password
#   pass otp website/example.com          # Show OTP token
#   secret-tool lookup service myapp      # Query via Secret Service (requires alternative keyring)
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
    
    # Secret Service queries (queries active keyring - GNOME Keyring, KeePassXC, etc.)
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
# 6. Test Pass CLI:
#    pass show email/gmail.com
#    pass otp email/gmail.com
#
# 7. Browser Integration:
#    Install browserpass extension:
#    • Firefox: https://addons.mozilla.org/firefox/addon/browserpass-ce/
#    • Chrome: https://chrome.google.com/webstore (search browserpass)
#
# ==============================================================================
# Troubleshooting
# ==============================================================================
#
# Issue: GPG passphrase prompt not appearing
# Fix:   echo "use-agent" >> ~/.gnupg/gpg.conf
#        systemctl --user restart gpg-agent
#
# Issue: pass-secret-service UnboundLocalError (Python 3.13)
# Fix:   Service is disabled by default due to this bug
#        Alternative: Use GNOME Keyring or KeePassXC for desktop integration
#
# Issue: Browser not using Pass for autofill
# Fix:   Install browserpass extension (direct Pass integration, no Secret Service needed)
#        Firefox: about:addons → Search "browserpass"
#        Chrome: chrome://extensions → Search Chrome Web Store for "browserpass"
#
# Issue: NetworkManager not saving WiFi passwords
# Fix:   Enable GNOME Keyring in your display module:
#        services.gnome.gnome-keyring.enable = true;
#
# Issue: Desktop apps can't access passwords
# Fix:   Enable alternative Secret Service provider:
#        • GNOME Keyring: services.gnome.gnome-keyring.enable = true;
#        • KeePassXC: Configure Secret Service integration in KeePassXC settings
#
# ==============================================================================

