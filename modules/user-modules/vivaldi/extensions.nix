# modules/home/vivaldi/extensions.nix
# ==============================================================================
# Vivaldi Browser Extensions Configuration
# ==============================================================================

{ inputs, pkgs, config, lib, ... }:

{
  config = lib.mkIf (config.my.browser.vivaldi.enable && config.my.browser.vivaldi.useChromiumWrapper) {
    # Only provision extensions when the Chromium wrapper is enabled for Vivaldi
    programs.chromium = {
      extensions = [
        # Translation tools
        { id = "aapbdbdomjkkjkaonfhkkikfgjllcleb"; } # Google Translate
        { id = "cofdbpoegempjloogbagkncekinflcnj"; } # DeepL: translate and write with AI
        { id = "ibplnjkanclpjokhdolnendpplpjiace"; } # Simple Translate

        # Security & privacy
        { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; } # uBlock Origin Lite

        # Navigation & productivity
        { id = "gfbliohnnapiefjpjlpjnehglfpaknnc"; } # Surfingkeys
        { id = "eekailopagacbcdloonjhbiecobagjci"; } # Go Back With Backspace
        { id = "inglelmldhjcljkomheneakjkpadclhf"; } # Keep Awake
        { id = "kdejdkdjdoabfihpcjmgjebcpfbhepmh"; } # Copy Link Address
        { id = "kgfcmiijchdkbknmjnojfngnapkibkdh"; } # Picture-in-Picture Viewer
        { id = "mbcjcnomlakhkechnbhmfjhnnllpbmlh"; } # Tab Pinner (Keyboard Shortcuts)

        # Media
        { id = "lmjnegcaeklhafolokijcfjliaokphfk"; } # Video DownloadHelper
        { id = "ponfpcnoihfmfllpaingbgckeeldkhle"; } # Enhancer for YouTube™

        # GNOME integration
        { id = "gphhapmejobijbbhgpjhcjognlahblep"; } # GNOME Shell integration

        # Crypto wallets
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

        # Other
        { id = "njbclohenpagagafbmdipcdoogfpnfhp"; } # Ethereum Gas Prices
      ];
    };
  };
}
