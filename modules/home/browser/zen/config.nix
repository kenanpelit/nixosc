# modules/home/browser/zen/config.nix
# ==============================================================================
# Zen Browser Configuration
# ==============================================================================
# This configuration file sets up Zen Browser with multiple profiles for different
# use cases. Each profile has its own avatar and settings. The browser is set
# as the default handler for web protocols.
# 
# Key Features:
# - Multiple isolated profiles (CompecTA, Proxy, Whats, Discord, etc.)
# - Custom avatar paths for each profile
# - Default profile set to Kenp
# - System-wide default browser registration
# ==============================================================================

{ inputs, pkgs, host, lib, ... }:
let
 system = pkgs.system;
in
{
 # =============================================================================
 # Package Installation
 # Install Zen Browser from flake inputs
 # =============================================================================
 home.packages = with pkgs; [
   inputs.zen-browser.packages.${system}.default
 ];

 # =============================================================================
 # Default Browser Configuration
 # Register Zen Browser as the default handler for web protocols
 # =============================================================================
 xdg.mimeApps = {
   enable = true;
   defaultApplications = {
     "default-web-browser" = ["zen-browser.desktop"];
     "text/html" = ["zen-browser.desktop"];
     "x-scheme-handler/http" = ["zen-browser.desktop"];
     "x-scheme-handler/https" = ["zen-browser.desktop"];
     "x-scheme-handler/about" = ["zen-browser.desktop"];
     "x-scheme-handler/unknown" = ["zen-browser.desktop"];
     "application/xhtml+xml" = ["zen-browser.desktop"];
     "text/xml" = ["zen-browser.desktop"];
   };
 };

 # =============================================================================
 # Profile Configuration
 # Setup multiple profiles with custom avatars and settings
 # Profile List:
 # - CompecTA: Development and technical work
 # - Proxy: Protected browsing
 # - Whats: WhatsApp Web
 # - Discord: Discord Web
 # - Spotify: Music streaming
 # - NoVpn: Direct connection
 # - Kenp: Default profile
 # =============================================================================
 home.file.".zen/profiles.ini".text = ''
   [General]
   StartWithLastProfile=1
   Version=2

   [Profile0]
   Name=CompecTA
   IsRelative=1
   Path=CompecTA
   ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-7.svg

   [Profile1]
   Name=Proxy
   IsRelative=1
   Path=Proxy
   ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-43.svg

   [Profile2]
   Name=Whats
   IsRelative=1
   Path=Whats
   ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-89.svg

   [Profile3]
   Name=Discord
   IsRelative=1
   Path=Discord
   ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-73.svg

   [Profile4]
   Name=Spotify
   IsRelative=1
   Path=Spotify
   ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-31.svg

   [Profile5]
   Name=NoVpn
   IsRelative=1
   Path=NoVpn
   ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-62.svg

   [Profile6]
   Name=Kenp
   IsRelative=1
   Path=Kenp
   ZenAvatarPath=chrome://browser/content/zen-avatars/avatar-2.svg
   Default=1

   # Installation identifiers and locks
   [InstallKP77777777777]
   Default=Kenp
   Locked=1

   [InstallKP99999999999]
   Default=Kenp
   Locked=1
 '';
}
