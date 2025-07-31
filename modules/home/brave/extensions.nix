# modules/home/brave/extensions.nix
# ==============================================================================
# Brave Browser Extensions Configuration
# ==============================================================================
# This configuration manages Brave browser extensions through NixOS
# Extensions are automatically installed and managed declaratively
# Now includes Catppuccin theme integration
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:
{
  config = lib.mkIf config.my.browser.brave.enable {
    programs.chromium = {
      extensions = [
        # Çeviri Araçları
        { id = "aapbdbdomjkkjkaonfhkkikfgjllcleb"; } # Google Translate
        { id = "cofdbpoegempjloogbagkncekinflcnj"; } # DeepL: translate and write with AI
        { id = "ibplnjkanclpjokhdolnendpplpjiace"; } # Simple Translate
        
        # Güvenlik & Gizlilik
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
        
        # Navigasyon & Prodüktivite
        { id = "gfbliohnnapiefjpjlpjnehglfpaknnc"; } # Surfingkeys
        { id = "eekailopagacbcdloonjhbiecobagjci"; } # Go Back With Backspace
        { id = "inglelmldhjcljkomheneakjkpadclhf"; } # Keep Awake
        { id = "kdejdkdjdoabfihpcjmgjebcpfbhepmh"; } # Copy Link Address
        { id = "kgfcmiijchdkbknmjnojfngnapkibkdh"; } # Picture-in-Picture Viewer
        { id = "mbcjcnomlakhkechnbhmfjhnnllpbmlh"; } # Tab Pinner (Keyboard Shortcuts)
        
        # Medya
        { id = "lmjnegcaeklhafolokijcfjliaokphfk"; } # Video DownloadHelper
        { id = "ponfpcnoihfmfllpaingbgckeeldkhle"; } # Enhancer for YouTube™
        
        # Sistem Entegrasyonu
        { id = "gphhapmejobijbbhgpjhcjognlahblep"; } # GNOME Shell integration
        
        # ========================================================================
        # TEMA - Catppuccin (theme.nix dosyasından dinamik olarak eklenir)
        # ========================================================================
        # Not: Catppuccin tema extension'ı theme.nix'te merkezi konfigürasyona
        # göre dinamik olarak ekleniyor
        
        # Dark Reader ve Stylus da theme.nix'te ekleniyor
        
        # Kripto Cüzdanları
        { id = "acmacodkjbdgmoleebolmdjonilkdbch"; } # Rabby Wallet
        { id = "anokgmphncpekkhclmingpimjmcooifb"; } # Compass Wallet for Sei
        { id = "bfnaelmomeimhlpmgjnjophhpkkoljpa"; } # Phantom
        { id = "bhhhlbepdkbapadjdnnojkbgioiodbic"; } # Solflare Wallet
        { id = "dlcobpjiigpikoobohmabehhmhfoodbb"; } # Ready Wallet (Formerly Argent)
        { id = "dmkamcknogkgcdfhhbddcghachkejeap"; } # Keplr
        { id = "enabgbdfcbaehmbigakijjabdpdnimlg"; } # Manta Wallet
        { id = "nebnhfamliijlghikdgcigoebonmoibm"; } # Leo Wallet
        { id = "ojggmchlghnjlapmfbnjholfjkiidbch"; } # Venom Wallet
        { id = "ppbibelpcjmhbdihakflkdcoccbgbkpo"; } # UniSat Wallet
        
        # Diğer
        { id = "njbclohenpagagafbmdipcdoogfpnfhp"; } # Ethereum Gas Prices
      ];
    };
  };
}

