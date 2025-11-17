# modules/home/brave/initial-setup.nix
# ==============================================================================
# Brave Browser Initial Setup
# ==============================================================================
# Bu modül sadece ilk kurulumda çalışır ve temel ayarları yapar
# Sonrasında kullanıcı ayarları korunur
#
# Author: Kenan Pelit
# ==============================================================================
{ config, pkgs, lib, ... }:

let
  profilePath = ".config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}";
  
  # İlk kurulum için önerilen ayarlar
  # Bunlar sadece Preferences dosyası YOKSA yazılır
  initialPreferences = {
    # ========================================================================
    # Privacy & Security
    # ========================================================================
    webrtc = {
      ip_handling_policy = "disable_non_proxied_udp";
      multiple_routes_enabled = false;
      nonproxied_udp_enabled = false;
    };

    profile = {
      block_third_party_cookies = true;
      cookie_controls_mode = 1;
      default_content_setting_values = {
        cookies = 1;
      };
    };

    # ========================================================================
    # Search & Suggestions
    # ========================================================================
    search = {
      suggest_enabled = false;
    };

    spellcheck = {
      enabled = false;
    };

    # ========================================================================
    # Passwords & Autofill
    # ========================================================================
    credentials_enable_service = false;
    password_manager_enabled = false;

    # ========================================================================
    # DNS over HTTPS
    # ========================================================================
    dns_over_https = {
      mode = "secure";
      templates = "https://cloudflare-dns.com/dns-query";
    };

    # ========================================================================
    # SSL/TLS
    # ========================================================================
    ssl = {
      error_override_allowed = false;
    };

    # ========================================================================
    # Safe Browsing
    # ========================================================================
    safebrowsing = {
      enabled = true;
      enhanced = true;
    };

    # ========================================================================
    # Hardware Acceleration
    # ========================================================================
    hardware_acceleration_mode = {
      enabled = config.my.browser.brave.enableHardwareAcceleration;
    };

    # ========================================================================
    # Downloads
    # ========================================================================
    download = {
      prompt_for_download = true;
      directory_upgrade = true;
      default_directory = "\${HOME}/Downloads";
    };

    # ========================================================================
    # Appearance
    # ========================================================================
    browser = {
      theme = {
        color = -1; # Use system theme
      };
    };

    # ========================================================================
    # Brave Specific
    # ========================================================================
    brave = {
      brave_vpn = {
        show_button = false;
      };
      brave_wallet = {
        enabled = config.my.browser.brave.enableCrypto;
      };
      new_tab_page = {
        show_background_image = false;
        show_clock = true;
        show_stats = true;
        show_rewards = false;
      };
      rewards = {
        enabled = false;
      };
      shields = {
        enabled = true;
      };
    };
  };

in {
  config = lib.mkIf config.my.browser.brave.enable {
    
    # ========================================================================
    # Initial Setup Activation Script
    # ========================================================================
    # Bu script sadece ilk kurulumda çalışır
    # Preferences dosyası varsa DOKUNMAZ
    
    home.activation.braveInitialSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      PROFILE_DIR="$HOME/${profilePath}"
      PREFS_FILE="$PROFILE_DIR/Preferences"
      SETUP_MARKER="$PROFILE_DIR/.nixos-initial-setup-done"
      
      # Profile directory oluştur
      if [ ! -d "$PROFILE_DIR" ]; then
        $DRY_RUN_CMD mkdir -p "$PROFILE_DIR"
        echo "✓ Created Brave profile directory"
      fi
      
      # Sadece ilk kurulumda ayarları yaz
      if [ ! -f "$SETUP_MARKER" ]; then
        echo "==> Running initial Brave setup..."
        
        # Preferences dosyası yoksa oluştur
        if [ ! -f "$PREFS_FILE" ]; then
          echo "Creating initial Preferences..."
          $DRY_RUN_CMD cat > "$PREFS_FILE" << 'EOFPREFS'
${builtins.toJSON initialPreferences}
EOFPREFS
          echo "✓ Initial preferences created"
        else
          echo "ℹ Preferences file exists, skipping..."
        fi
        
        # Setup marker oluştur
        $DRY_RUN_CMD touch "$SETUP_MARKER"
        echo "✓ Initial setup completed"
        echo ""
        echo "Your Brave configuration is ready!"
        echo "You can now customize settings in Brave - they will be preserved."
      fi
    '';

    # ========================================================================
    # Setup Helper Script
    # ========================================================================
    
    home.file.".local/bin/brave-setup" = {
      text = ''
        #!/usr/bin/env bash
        # Brave Browser Setup Helper
        
        PROFILE_DIR="$HOME/${profilePath}"
        SETUP_MARKER="$PROFILE_DIR/.nixos-initial-setup-done"
        
        show_status() {
          echo "==> Brave Browser Setup Status"
          echo ""
          echo "Profile: ${config.my.browser.brave.profile}"
          echo "Profile Directory: $PROFILE_DIR"
          echo ""
          
          if [ -f "$SETUP_MARKER" ]; then
            echo "✓ Initial setup: COMPLETED"
          else
            echo "✗ Initial setup: NOT DONE"
          fi
          
          if [ -f "$PROFILE_DIR/Preferences" ]; then
            echo "✓ Preferences: EXISTS"
            echo "  Size: $(du -h "$PROFILE_DIR/Preferences" | cut -f1)"
            echo "  Modified: $(stat -c %y "$PROFILE_DIR/Preferences" | cut -d. -f1)"
          else
            echo "✗ Preferences: NOT FOUND"
          fi
          
          if [ -d "$PROFILE_DIR/Extensions" ]; then
            EXT_COUNT=$(ls -1 "$PROFILE_DIR/Extensions" | wc -l)
            echo "✓ Extensions: $EXT_COUNT installed"
          else
            echo "✗ Extensions: NOT INSTALLED"
          fi
          
          echo ""
        }
        
        reset_setup() {
          echo "==> Resetting Brave setup..."
          read -p "This will remove setup marker. Continue? [y/N] " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$SETUP_MARKER"
            echo "✓ Setup marker removed"
            echo "Run 'home-manager switch' to re-run initial setup"
          fi
        }
        
        reset_preferences() {
          echo "==> Resetting Brave preferences..."
          read -p "This will delete your Preferences file. Continue? [y/N] " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f "$PROFILE_DIR/Preferences" ]; then
              mv "$PROFILE_DIR/Preferences" "$PROFILE_DIR/Preferences.backup.$(date +%Y%m%d_%H%M%S)"
              echo "✓ Preferences backed up and removed"
              rm -f "$SETUP_MARKER"
              echo "✓ Setup marker removed"
              echo "Run 'home-manager switch' to recreate preferences"
            else
              echo "✗ No preferences file found"
            fi
          fi
        }
        
        backup_profile() {
          BACKUP_DIR="$HOME/.brave-backups"
          BACKUP_NAME="brave-profile-$(date +%Y%m%d_%H%M%S).tar.gz"
          
          mkdir -p "$BACKUP_DIR"
          
          echo "==> Creating backup..."
          tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$HOME" ".config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}"
          
          echo "✓ Backup created: $BACKUP_DIR/$BACKUP_NAME"
          echo "  Size: $(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)"
        }
        
        case "''${1:-}" in
          status)
            show_status
            ;;
          reset-setup)
            reset_setup
            ;;
          reset-prefs)
            reset_preferences
            ;;
          backup)
            backup_profile
            ;;
          *)
            echo "Brave Browser Setup Helper"
            echo ""
            echo "Usage: brave-setup <command>"
            echo ""
            echo "Commands:"
            echo "  status       - Show setup status"
            echo "  reset-setup  - Reset setup marker (re-run initial setup)"
            echo "  reset-prefs  - Reset preferences to defaults"
            echo "  backup       - Create profile backup"
            echo ""
            show_status
            ;;
        esac
      '';
      executable = true;
    };

    # ========================================================================
    # README for Users
    # ========================================================================
    
    home.file.".config/BraveSoftware/README-NixOS.md" = {
      text = ''
        # Brave Browser on NixOS
        
        ## Configuration
        
        Your Brave browser is configured through NixOS home-manager.
        
        ### Important Locations
        
        - **Profile**: `${profilePath}`
        - **Preferences**: `${profilePath}/Preferences`
        - **Extensions**: `${profilePath}/Extensions`
        - **Cache**: `~/.cache/BraveSoftware`
        
        ### Your Settings Are Safe!
        
        ✅ Your browser settings and extensions are preserved
        ✅ Only initial defaults are set by NixOS
        ✅ You can customize everything in Brave normally
        
        ### Initial Setup
        
        On first installation, NixOS creates default preferences. After that:
        - Your changes in Brave settings are kept
        - Extensions you install/remove are preserved
        - Bookmarks and history are yours to manage
        
        ### Useful Commands
        
        ```bash
        # Check setup status
        brave-setup status
        
        # Reset to defaults (if needed)
        brave-setup reset-prefs
        
        # Create backup
        brave-setup backup
        
        # Install extensions
        brave-install-extensions
        
        # Apply theme
        brave-apply-theme
        ```
        
        ### Managed by NixOS
        
        The following are managed by your NixOS config:
        - ✅ Default browser associations
        - ✅ Launch flags (performance, Wayland, etc.)
        - ✅ Extension installation
        - ✅ Theme integration (if enabled)
        
        ### NOT Managed (Your Control)
        
        You have full control over:
        - ❌ Browser settings (privacy, search, appearance)
        - ❌ Extension settings
        - ❌ Bookmarks and history
        - ❌ Passwords and autofill
        - ❌ Profile data
        
        ### Troubleshooting
        
        **Extensions not loading?**
        ```bash
        brave-install-extensions
        ```
        
        **Settings reset after update?**
        Check if you have `force = true` in your config. Remove it.
        
        **Want fresh start?**
        ```bash
        brave-setup reset-prefs
        home-manager switch
        ```
        
        ## More Info
        
        - [Brave Browser](https://brave.com)
        - [NixOS Home Manager](https://github.com/nix-community/home-manager)
        - Your config: `~/.config/home-manager/modules/home/brave/`
      '';
    };

    # ========================================================================
    # Shell Aliases
    # ========================================================================
    
    home.shellAliases = {
      brave-setup = "brave-setup";
      brave-status = "brave-setup status";
      brave-backup = "brave-setup backup";
    };

  };
}
