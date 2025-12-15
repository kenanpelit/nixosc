# modules/home/brave/initial-setup.nix
# ==============================================================================
# Brave initial setup (one-shot): seed a sane Preferences file if missing.
# Runs only on first install per profile; never overwrites existing prefs.
# ==============================================================================

{ config, pkgs, lib, ... }:

let
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;
  profilePath = ".config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}";

  # Initial preferences applied only when Preferences does NOT exist.
  initialPreferences = {
    # -------------------------------------------------------------------------
    # Privacy & Security
    # -------------------------------------------------------------------------
    webrtc = {
      ip_handling_policy    = "disable_non_proxied_udp";
      multiple_routes_enabled = false;
      nonproxied_udp_enabled  = false;
    };

    profile = {
      block_third_party_cookies = true;
      cookie_controls_mode      = 1;
      default_content_setting_values = {
        cookies = 1;
      };
    };

    # -------------------------------------------------------------------------
    # Search & Suggestions
    # -------------------------------------------------------------------------
    search = {
      suggest_enabled = false;
    };

    spellcheck = {
      enabled = false;
    };

    # -------------------------------------------------------------------------
    # Passwords & Autofill
    # -------------------------------------------------------------------------
    credentials_enable_service = false;
    password_manager_enabled   = false;

    # -------------------------------------------------------------------------
    # DNS over HTTPS
    # -------------------------------------------------------------------------
    dns_over_https = {
      mode      = "secure";
      templates = "https://cloudflare-dns.com/dns-query";
    };

    # -------------------------------------------------------------------------
    # SSL/TLS
    # -------------------------------------------------------------------------
    ssl = {
      error_override_allowed = false;
    };

    # -------------------------------------------------------------------------
    # Safe Browsing
    # -------------------------------------------------------------------------
    safebrowsing = {
      enabled  = true;
      enhanced = true;
    };

    # -------------------------------------------------------------------------
    # Hardware Acceleration
    # -------------------------------------------------------------------------
    hardware_acceleration_mode = {
      enabled = config.my.browser.brave.enableHardwareAcceleration;
    };

    # -------------------------------------------------------------------------
    # Downloads
    # -------------------------------------------------------------------------
    download = {
      prompt_for_download  = true;
      directory_upgrade    = true;
      # Use $HOME at runtime, not expanded here
      default_directory    = "\${HOME}/Downloads";
    };

    # -------------------------------------------------------------------------
    # Appearance
    # -------------------------------------------------------------------------
    browser = {
      theme = {
        color = -1; # Use system theme
      };
    };

    # -------------------------------------------------------------------------
    # Brave specific settings
    # -------------------------------------------------------------------------
    brave = {
      brave_vpn = {
        show_button = false;
      };
      brave_wallet = {
        enabled = config.my.browser.brave.enableCrypto;
      };
      new_tab_page = {
        show_background_image = false;
        show_clock            = true;
        show_stats            = true;
        show_rewards          = false;
      };
      rewards = {
        enabled = false;
      };
      shields = {
        enabled = true;
      };
    };
  };

in
{
  config = lib.mkIf config.my.browser.brave.enable {

    # -------------------------------------------------------------------------
    # Initial setup activation script
    # -------------------------------------------------------------------------
    # - Creates profile directory if needed
    # - Writes Preferences only if:
    #   * .nixos-initial-setup-done marker does NOT exist AND
    #   * Preferences does NOT exist
    # - After first run, user's changes are respected

    home.activation.braveInitialSetup = dag.entryAfter [ "writeBoundary" ] ''
      PROFILE_DIR="$HOME/${profilePath}"
      PREFS_FILE="$PROFILE_DIR/Preferences"
      SETUP_MARKER="$PROFILE_DIR/.nixos-initial-setup-done"

      # Ensure profile directory exists
      if [ ! -d "$PROFILE_DIR" ]; then
        $DRY_RUN_CMD mkdir -p "$PROFILE_DIR"
        echo "✓ Created Brave profile directory: $PROFILE_DIR"
      fi

      # Only run on first setup
      if [ ! -f "$SETUP_MARKER" ]; then
        echo "==> Running initial Brave setup for profile '${config.my.browser.brave.profile}'..."

        # Create Preferences only if it does not exist
        if [ ! -f "$PREFS_FILE" ]; then
          echo "Creating initial Preferences..."
          $DRY_RUN_CMD cat > "$PREFS_FILE" << 'EOFPREFS'
${builtins.toJSON initialPreferences}
EOFPREFS
          echo "✓ Initial preferences created"
        else
          echo "ℹ Preferences file already exists, skipping initial preferences..."
        fi

        # Mark setup as done
        $DRY_RUN_CMD touch "$SETUP_MARKER"
        echo "✓ Initial setup completed (marker created)"
        echo
        echo "Your Brave configuration is ready."
        echo "You can now customize settings directly in Brave."
      fi
    '';

    # -------------------------------------------------------------------------
    # Setup helper script (status / reset / backup)
    # -------------------------------------------------------------------------

    home.file.".local/bin/brave-setup" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Brave Browser Setup Helper (NixOS / Home Manager)

        PROFILE_DIR="$HOME/${profilePath}"
        SETUP_MARKER="$PROFILE_DIR/.nixos-initial-setup-done"

        show_status() {
          echo "==> Brave Browser Setup Status"
          echo
          echo "Profile: ${config.my.browser.brave.profile}"
          echo "Profile directory: $PROFILE_DIR"
          echo

          if [ -f "$SETUP_MARKER" ]; then
            echo "✓ Initial setup: COMPLETED"
          else
            echo "✗ Initial setup: NOT DONE"
          fi

          if [ -f "$PROFILE_DIR/Preferences" ]; then
            echo "✓ Preferences: EXISTS"
            echo "  Size: $(du -h "$PROFILE_DIR/Preferences" 2>/dev/null | cut -f1)"
            if command -v stat >/dev/null 2>&1; then
              echo "  Modified: $(stat -c %y "$PROFILE_DIR/Preferences" 2>/dev/null | cut -d. -f1)"
            fi
          else
            echo "✗ Preferences: NOT FOUND"
          fi

          if [ -d "$PROFILE_DIR/Extensions" ]; then
            EXT_COUNT=$(ls -1 "$PROFILE_DIR/Extensions" 2>/dev/null | wc -l)
            echo "✓ Extensions: $EXT_COUNT installed"
          else
            echo "✗ Extensions: NOT INSTALLED"
          fi

          echo
        }

        reset_setup() {
          echo "==> Resetting Brave setup marker..."
          read -p "This will remove the setup marker. Continue? [y/N] " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$SETUP_MARKER"
            echo "✓ Setup marker removed"
            echo "Run 'home-manager switch' to re-run initial setup."
          else
            echo "Aborted."
          fi
        }

        reset_preferences() {
          echo "==> Resetting Brave Preferences..."
          read -p "This will delete your Preferences file. Continue? [y/N] " -n 1 -r
          echo
          if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -f "$PROFILE_DIR/Preferences" ]; then
              mv "$PROFILE_DIR/Preferences" "$PROFILE_DIR/Preferences.backup.$(date +%Y%m%d_%H%M%S)"
              echo "✓ Preferences backed up and removed"
              rm -f "$SETUP_MARKER"
              echo "✓ Setup marker removed"
              echo "Run 'home-manager switch' to recreate Preferences from defaults."
            else
              echo "✗ No Preferences file found"
            fi
          else
            echo "Aborted."
          fi
        }

        backup_profile() {
          BACKUP_DIR="$HOME/.brave-backups"
          BACKUP_NAME="brave-profile-$(date +%Y%m%d_%H%M%S).tar.gz"

          mkdir -p "$BACKUP_DIR"

          echo "==> Creating Brave profile backup..."
          tar -czf "$BACKUP_DIR/$BACKUP_NAME" -C "$HOME" ".config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}"

          echo "✓ Backup created: $BACKUP_DIR/$BACKUP_NAME"
          echo "  Size: $(du -h "$BACKUP_DIR/$BACKUP_NAME" 2>/dev/null | cut -f1)"
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
            echo
            echo "Usage: brave-setup <command>"
            echo
            echo "Commands:"
            echo "  status       - Show setup status"
            echo "  reset-setup  - Reset setup marker (re-run initial setup on next HM switch)"
            echo "  reset-prefs  - Remove Preferences and reset to defaults"
            echo "  backup       - Create a compressed profile backup"
            echo
            show_status
            ;;
        esac
      '';
    };

    # -------------------------------------------------------------------------
    # README for users
    # -------------------------------------------------------------------------

    home.file.".config/BraveSoftware/README-NixOS.md" = {
      text = ''
        # Brave Browser on NixOS (Home Manager)

        ## Configuration model

        Your Brave browser is configured through NixOS Home Manager with the
        following principles:

        - Only initial defaults are written automatically
        - Your ongoing settings and data stay under your control
        - You can always override or reset via helper scripts

        ## Important locations

        - Profile: `${profilePath}`
        - Preferences: `${profilePath}/Preferences`
        - Extensions: `${profilePath}/Extensions`
        - Cache: `~/.cache/BraveSoftware`

        ## What is managed by NixOS

        - Default browser associations (xdg mime apps)
        - Launch flags (performance, Wayland, VA-API, etc.)
        - Optional extension configuration (managed_preferences)
        - Optional theme integration (Catppuccin, Stylus CSS)

        ## What is NOT continuously managed

        - Browser settings (privacy, search, appearance)
        - Extension configuration details
        - Bookmarks and history
        - Passwords and autofill
        - Profile data in general

        Once initial setup is done, Home Manager does not overwrite your
        Preferences file unless you explicitly reset it.

        ## Useful commands

        ```bash
        # Setup & status
        brave-setup status
        brave-setup reset-prefs
        brave-setup backup

        # Extensions
        brave-install-extensions
        brave-ext-list
        brave-ext-clean

        # Theme (if enabled)
        brave-apply-theme
        ```

        ## Reset flow

        If something feels broken and you want a clean slate:

        ```bash
        brave-setup reset-prefs
        home-manager switch
        ```

        This will:
        - Backup and remove your existing Preferences
        - Remove the initial setup marker
        - Recreate default preferences on next Home Manager activation
      '';
    };

    # -------------------------------------------------------------------------
    # Convenience aliases for setup
    # -------------------------------------------------------------------------

    home.shellAliases = {
      brave-setup  = "brave-setup";
      brave-status = "brave-setup status";
      brave-backup = "brave-setup backup";
    };
  };
}
