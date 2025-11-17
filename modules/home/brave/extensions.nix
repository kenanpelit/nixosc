# modules/home/brave/extensions.nix
# ==============================================================================
# Brave Browser Extensions Configuration
# ==============================================================================
# This configuration manages Brave browser extensions through NixOS
# Extensions are automatically installed and managed declaratively
# Now includes Catppuccin theme integration and conditional crypto wallets
#
# Author: Kenan Pelit
# ==============================================================================
{ inputs, pkgs, config, lib, ... }:
{
  config = lib.mkIf config.my.browser.brave.enable {
    programs.chromium = {
      extensions = [
        # ======================================================================
        # Translation Tools
        # ======================================================================
        { id = "aapbdbdomjkkjkaonfhkkikfgjllcleb"; } # Google Translate
        { id = "cofdbpoegempjloogbagkncekinflcnj"; } # DeepL: translate and write with AI
        { id = "ibplnjkanclpjokhdolnendpplpjiace"; } # Simple Translate

        # ======================================================================
        # Security & Privacy
        # ======================================================================
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite
        { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; } # Privacy Badger

        # ======================================================================
        # Navigation & Productivity
        # ======================================================================
        { id = "gfbliohnnapiefjpjlpjnehglfpaknnc"; } # Surfingkeys
        { id = "eekailopagacbcdloonjhbiecobagjci"; } # Go Back With Backspace
        { id = "inglelmldhjcljkomheneakjkpadclhf"; } # Keep Awake
        { id = "kdejdkdjdoabfihpcjmgjebcpfbhepmh"; } # Copy Link Address
        { id = "kgfcmiijchdkbknmjnojfngnapkibkdh"; } # Picture-in-Picture Viewer
        { id = "mbcjcnomlakhkechnbhmfjhnnllpbmlh"; } # Tab Pinner (Keyboard Shortcuts)
        #{ id = "llimhhconnjiflfimocjggfjdlmlhblm"; } # Reader Mode

        # ======================================================================
        # Media
        # ======================================================================
        { id = "lmjnegcaeklhafolokijcfjliaokphfk"; } # Video DownloadHelper
        { id = "ponfpcnoihfmfllpaingbgckeeldkhle"; } # Enhancer for YouTube™

        # ======================================================================
        # System Integration
        # ======================================================================
        { id = "gphhapmejobijbbhgpjhcjognlahblep"; } # GNOME Shell integration

        # ======================================================================
        # Other
        # ======================================================================
        { id = "njbclohenpagagafbmdipcdoogfpnfhp"; } # Ethereum Gas Prices
      ]
      # ========================================================================
      # Conditional Crypto Wallet Extensions
      # ========================================================================
      # Only loaded when enableCrypto option is true
      ++ lib.optionals config.my.browser.brave.enableCrypto [
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
      ];
    };
  };
}
