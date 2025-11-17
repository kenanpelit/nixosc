# modules/home/brave/extensions.nix
# ==============================================================================
# Brave Browser Extensions Configuration - Fixed Version
# ==============================================================================
# Bu konfigürasyon extensions'ları Chrome Web Store'dan otomatik yükler
# 
# NASIL ÇALIŞIR:
# - ExtensionInstallForcelist kullanarak extensions otomatik yüklenir
# - Kullanıcı extensions'ları disable edebilir ama silemez
# - Her başlatmada kontrol edilir ve eksikse yüklenir
#
# ÖNEMLİ:
# - Extension ID'ler Chrome Web Store'dan alınır
# - Update URL otomatik eklenir
# - Sync yapılmaz, local installation
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:

let
  # Chrome Web Store update URL
  chromeWebStoreUrl = "https://clients2.google.com/service/update2/crx";
  
  # Extension listesi (ID ve açıklama ile)
  coreExtensions = [
    # Translation
    { id = "aapbdbdomjkkjkaonfhkkikfgjllcleb"; name = "Google Translate"; }
    { id = "cofdbpoegempjloogbagkncekinflcnj"; name = "DeepL"; }
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
    
    # Other
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

  # Tüm extensions'ları birleştir
  allExtensions = coreExtensions ++ 
    (if config.my.browser.brave.enableCrypto then cryptoExtensions else []);

  # Extension install string oluştur (ID;update_url formatında)
  extensionInstallList = map (ext: "${ext.id};${chromeWebStoreUrl}") allExtensions;

  # Extension settings JSON
  extensionSettings = lib.listToAttrs (map (ext: {
    name = ext.id;
    value = {
      installation_mode = "force_installed";
      update_url = chromeWebStoreUrl;
    };
  }) allExtensions);

in {
  config = lib.mkIf (config.my.browser.brave.enable && config.my.browser.brave.manageExtensions) {
    
    # ========================================================================
    # Brave Managed Policies - Extensions
    # ========================================================================
    # Brave için tek çalışan yöntem: Managed policies JSON dosyası
    
    home.file.".config/BraveSoftware/Brave-Browser/managed_preferences.json" = {
      text = builtins.toJSON {
        ExtensionInstallForcelist = extensionInstallList;
      };
    };
    
    # Alternative: User policies (daha esnek)
    home.file.".config/BraveSoftware/Brave-Browser/Preferences.json" = {
      text = builtins.toJSON {
        extensions = {
          settings = extensionSettings;
        };
      };
    };
    
    # ========================================================================
    # Extension Installation Script (Manuel trigger için)
    # ========================================================================
    
    home.file.".local/bin/brave-install-extensions" = {
      text = ''
        #!/usr/bin/env bash
        # Brave Extensions Force Installer
        
        PROFILE_DIR="$HOME/.config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}"
        PREFS_FILE="$PROFILE_DIR/Preferences"
        
        echo "==> Force installing Brave Extensions..."
        echo "Profile: ${config.my.browser.brave.profile}"
        echo ""
        
        # Brave'i kapat
        if pgrep -x brave > /dev/null; then
          echo "⚠ Brave is running. Closing it..."
          pkill brave
          sleep 2
        fi
        
        # Profile directory oluştur
        mkdir -p "$PROFILE_DIR"
        
        # Preferences dosyasını güncelle
        if [ -f "$PREFS_FILE" ]; then
          echo "Backing up existing Preferences..."
          cp "$PREFS_FILE" "$PREFS_FILE.backup"
          
          # Extensions section'ı ekle/güncelle
          ${pkgs.jq}/bin/jq '.extensions.settings = ${builtins.toJSON extensionSettings}' "$PREFS_FILE" > "$PREFS_FILE.tmp"
          mv "$PREFS_FILE.tmp" "$PREFS_FILE"
          echo "✓ Updated Preferences with extensions"
        else
          echo "Creating new Preferences with extensions..."
          cat > "$PREFS_FILE" << 'EOF'
${builtins.toJSON {
  extensions = {
    settings = extensionSettings;
  };
}}
EOF
          echo "✓ Created Preferences"
        fi
        
        echo ""
        echo "Extensions to be installed:"
        ${lib.concatMapStringsSep "\n" (ext: ''echo "  • ${ext.name} (${ext.id})"'') allExtensions}
        echo ""
        echo "✓ Configuration updated"
        echo ""
        echo "Next steps:"
        echo "1. Start Brave: brave"
        echo "2. Check: brave://extensions/"
        echo "3. Extensions should auto-install from Chrome Web Store"
      '';
      executable = true;
    };

    # ========================================================================
    # Shell Aliases
    # ========================================================================
    
    home.shellAliases = {
      # Extension yönetimi
      brave-extensions = "brave-install-extensions";
      brave-ext-list = "ls -la ~/.config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}/Extensions/";
      brave-ext-clean = "rm -rf ~/.config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}/Extensions/";
    };

  };
}
