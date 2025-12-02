# modules/home/zen/default.nix
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
# - Custom .desktop files for Zen Browser and Zen Beta
# ==============================================================================
{ inputs, pkgs, lib, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
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
  # MIME Configuration
  # Register file associations and default applications
  # =============================================================================
  xdg.mimeApps = {
    enable = true;
    
    # Default applications
    #defaultApplications = {
    #  # Browser related - all three options with browser as default
    #  "default-web-browser" = ["zen-browser.desktop" "zen-beta.desktop" "zen.desktop"];
    #  "text/html" = ["zen-browser.desktop" "zen-beta.desktop" "zen.desktop"];
    #  "x-scheme-handler/http" = ["zen-browser.desktop" "zen-beta.desktop" "zen.desktop"];
    #  "x-scheme-handler/https" = ["zen-browser.desktop" "zen-beta.desktop" "zen.desktop"];
    #  "x-scheme-handler/about" = ["zen-browser.desktop" "zen-beta.desktop" "zen.desktop"];
    #  "x-scheme-handler/unknown" = ["zen-browser.desktop" "zen-beta.desktop" "zen.desktop"];
    #  "application/xhtml+xml" = ["zen-browser.desktop" "zen-beta.desktop" "zen.desktop"];
    #  "text/xml" = ["zen-browser.desktop" "zen-beta.desktop" "zen.desktop"];
    #};
  };

  # =============================================================================
  # Custom .desktop Files
  # Create custom Zen Browser, Zen Beta, and Zen .desktop files
  # =============================================================================
  xdg.desktopEntries = {
    # Main Zen Browser .desktop file
    zen-browser = {
      name = "Zen Browser";
      genericName = "Web Browser";
      exec = "zen-browser --name zen-browser %U";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml" 
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      icon = "zen-browser";
      startupNotify = true;
      # startupWMClass = "zen-browser"; # Bu satırı kaldırdım
      actions = {
        "new-private-window" = {
          name = "New Private Window";
          exec = "zen-browser --private-window %U";
        };
        "new-window" = {
          name = "New Window";
          exec = "zen-browser --new-window %U";
        };
        "profile-manager-window" = {
          name = "Profile Manager";
          exec = "zen-browser --ProfileManager";
        };
      };
    };
    
    # Zen Beta Browser .desktop file
    zen-beta = {
      name = "Zen Browser (Beta)";
      genericName = "Web Browser";
      exec = "zen-beta --name zen-beta %U";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml" 
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      icon = "zen-beta";
      startupNotify = true;
      # startupWMClass = "zen-beta"; # Bu satırı kaldırdım
      actions = {
        "new-private-window" = {
          name = "New Private Window";
          exec = "zen-beta --private-window %U";
        };
        "new-window" = {
          name = "New Window";
          exec = "zen-beta --new-window %U";
        };
        "profile-manager-window" = {
          name = "Profile Manager";
          exec = "zen-beta --ProfileManager";
        };
      };
    };
    
    # Standard Zen .desktop file
    zen = {
      name = "Zen Browser";
      genericName = "Web Browser";
      exec = "zen --name zen %U";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml" 
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      icon = "zen";
      startupNotify = true;
      # startupWMClass = "zen"; # Bu satırı kaldırdım
      actions = {
        "new-private-window" = {
          name = "New Private Window";
          exec = "zen --private-window %U";
        };
        "new-window" = {
          name = "New Window";
          exec = "zen --new-window %U";
        };
        "profile-manager-window" = {
          name = "Profile Manager";
          exec = "zen --ProfileManager";
        };
      };
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
