# modules/home/brave/extensions.nix
# ==============================================================================
# Brave extensions wiring: writes managed_preferences.json and a helper script
# (brave-install-extensions) to seed/patch extensions from the Chrome Web Store.
# Managed prefs are recommended, not forced, so users can remove them.
# ==============================================================================

{ inputs, pkgs, config, lib, ... }:

let
  # Chrome Web Store update URL
  chromeWebStoreUrl = "https://clients2.google.com/service/update2/crx";

  # Core extensions (ID + name)
  coreExtensions = [
    # Translation
    { id = "aapbdbdomjkkjkaonfhkkikfgjllcleb"; name = "Google Translate"; }
    { id = "cofdbpoegempjloogbagkncekinflcnj"; name = "DeepL Translator"; }
    { id = "ibplnjkanclpjokhdolnendpplpjiace"; name = "Simple Translate"; }

    # Security & Privacy
    { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; name = "uBlock Origin Lite"; }
    { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; name = "Privacy Badger"; }

    # Navigation & Productivity
    { id = "gfbliohnnapiefjpjlpjnehglfpaknnc"; name = "Surfingkeys"; }
    { id = "eekailopagacbcdloonjhbiecobagjci"; name = "Go Back With Backspace"; }
    { id = "inglelmldhjcljkomheneakjkpadclhf"; name = "Keep Awake"; }
    { id = "kdejdkdjdoabfihpcjmgjebcpfbhepmh"; name = "Copy Link Address"; }
    { id = "kgfcmiijchdkbknmjnojfngnapkibkdh"; name = "Picture-in-Picture"; }
    { id = "mbcjcnomlakhkechnbhmfjhnnllpbmlh"; name = "Tab Pinner"; }

    # Media
    { id = "lmjnegcaeklhafolokijcfjliaokphfk"; name = "Video DownloadHelper"; }
    { id = "ponfpcnoihfmfllpaingbgckeeldkhle"; name = "Enhancer for YouTube"; }

    # System Integration
    { id = "gphhapmejobijbbhgpjhcjognlahblep"; name = "GNOME Shell Integration"; }

    # Example: Ethereum tools etc.
    { id = "njbclohenpagagafbmdipcdoogfpnfhp"; name = "Ethereum Gas Prices"; }
  ];

  # Crypto extensions (optional)
  cryptoExtensions = [
    { id = "acmacodkjbdgmoleebolmdjonilkdbch"; name = "Rabby Wallet"; }
    { id = "anokgmphncpekkhclmingpimjmcooifb"; name = "Compass Wallet"; }
    { id = "bfnaelmomeimhlpmgjnjophhpkkoljpa"; name = "Phantom"; }
    { id = "bhhhlbepdkbapadjdnnojkbgioiodbic"; name = "Solflare"; }
    { id = "dlcobpjiigpikoobohmabehhmhfoodbb"; name = "Ready Wallet"; }
    { id = "dmkamcknogkgcdfhhbddcghachkejeap"; name = "Keplr"; }
    { id = "enabgbdfcbaehmbigakijjabdpdnimlg"; name = "Manta Wallet"; }
    { id = "nebnhfamliijlghikdgcigoebonmoibm"; name = "Leo Wallet"; }
    { id = "ojggmchlghnjlapmfbnjholfjkiidbch"; name = "Venom Wallet"; }
    { id = "ppbibelpcjmhbdihakflkdcoccbgbkpo"; name = "UniSat Wallet"; }
  ];

  # Merge all extensions depending on crypto toggle
  allExtensions =
    coreExtensions
    ++ (if config.my.browser.brave.enableCrypto then cryptoExtensions else []);

  # Format for ExtensionInstallForcelist: "id;update_url"
  extensionInstallList = map (ext: "${ext.id};${chromeWebStoreUrl}") allExtensions;

  # Extension settings map for policies and Preferences patching
  extensionSettings = lib.listToAttrs (map (ext: {
    name = ext.id;
    value = {
      installation_mode = "force_installed";
      update_url        = chromeWebStoreUrl;
    };
  }) allExtensions);

  # Profile-relative path (same logic as in default.nix)
  braveConfigDir = ".config/BraveSoftware/Brave-Browser";
  profilePath    = "${braveConfigDir}/${config.my.browser.brave.profile}";

in
{
  config = lib.mkIf (config.my.browser.brave.enable && config.my.browser.brave.manageExtensions) {

    # -------------------------------------------------------------------------
    # Brave managed preferences (per-profile, under $HOME)
    # -------------------------------------------------------------------------
    # NOTE:
    # - This is NOT /etc-based policy like on non-Nix Linux distributions.
    # - On NixOS + Home Manager we place managed_preferences.json inside the
    #   profile directory under $HOME and let Brave pick it up from there.

    home.file."${profilePath}/managed_preferences.json" = {
      text = builtins.toJSON {
        ExtensionInstallForcelist = extensionInstallList;
        ExtensionSettings         = extensionSettings;
      };
    };

    # -------------------------------------------------------------------------
    # Manual extension installation script
    # -------------------------------------------------------------------------
    # This script:
    # - Kills Brave if it is running
    # - Ensures the profile directory exists
    # - Uses jq to inject `.extensions.settings` into Preferences
    # - Creates a minimal Preferences file if it does not exist
    #
    # Home Manager does NOT touch Preferences directly; only this script does,
    # and only when you manually run it.

    home.file.".local/bin/brave-install-extensions" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        # Brave Extensions Force Installer (NixOS / Home Manager)

        PROFILE_DIR="$HOME/${profilePath}"
        PREFS_FILE="$PROFILE_DIR/Preferences"

        echo "==> Force installing Brave extensions"
        echo "Profile directory: $PROFILE_DIR"
        echo

        # Stop Brave if running
        if pgrep -x brave >/dev/null 2>&1; then
          echo "⚠ Brave is running. Closing it..."
          pkill brave || true
          sleep 2
        fi

        # Ensure profile directory exists
        mkdir -p "$PROFILE_DIR"

        # If Preferences exists, patch it via jq; otherwise create minimal JSON
        if [ -f "$PREFS_FILE" ]; then
          echo "Backing up existing Preferences..."
          cp "$PREFS_FILE" "$PREFS_FILE.backup.$(date +%Y%m%d_%H%M%S)"

          echo "Injecting extension settings into Preferences..."
          ${pkgs.jq}/bin/jq \
            --argjson ext '${builtins.toJSON extensionSettings}' \
            '.extensions.settings = $ext' \
            "$PREFS_FILE" > "$PREFS_FILE.tmp"

          mv "$PREFS_FILE.tmp" "$PREFS_FILE"
          echo "✓ Preferences updated"
        else
          echo "Creating new Preferences file with extension settings..."
          cat > "$PREFS_FILE" << 'EOFPREFS'
${builtins.toJSON {
  extensions = {
    settings = extensionSettings;
  };
}}
EOFPREFS
          echo "✓ Preferences created"
        fi

        echo
        echo "Extensions configured (policy + Preferences):"
        ${lib.concatMapStringsSep "\n" (ext: ''echo "  • ${ext.name} (${ext.id})"'') allExtensions}
        echo
        echo "Next steps:"
        echo "  1. Start Brave (brave or brave-launcher)"
        echo "  2. Visit brave://extensions/"
        echo "  3. Verify that extensions are installed and enabled"
      '';
    };

    # -------------------------------------------------------------------------
    # Shell aliases for extensions
    # -------------------------------------------------------------------------

    home.shellAliases = {
      brave-extensions  = "brave-install-extensions";
      brave-ext-list    = "ls -la ~/.config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}/Extensions/ 2>/dev/null || echo 'No Extensions directory found'";
      brave-ext-clean   = "rm -rf ~/.config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}/Extensions/";
    };
  };
}
