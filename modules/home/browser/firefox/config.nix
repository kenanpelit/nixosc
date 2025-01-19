# ==============================================================================
# Firefox Core Configuration
# ==============================================================================
# modules/home/browser/firefox/config.nix
{ config, lib, myLib, pkgs, username, ... }:

myLib.utilMods.mkDesktopModule config "firefox" {
  hm.xdg.mimeApps = let
    defaultApplications = {
      "default-web-browser" = ["firefox.desktop"];
      "text/html" = ["firefox.desktop"];
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
      "x-scheme-handler/about" = ["firefox.desktop"];
      "x-scheme-handler/unknown" = ["firefox.desktop"];
      "application/xhtml+xml" = ["firefox.desktop"];
      "text/xml" = ["firefox.desktop"];
    };
  in
    lib.mkIf (config.variables.defaultBrowser == "firefox") {
      enable = true;
      inherit defaultApplications;
      associations.added = defaultApplications;
    };

  hm.programs.firefox = {
    enable = true;
    nativeMessagingHosts = with pkgs; [fx-cast-bridge];
    
    profiles."${username}" = {
      extensions = import ./extensions.nix {inherit pkgs;};

      search = {
        force = true;
        default = "Ecosia";
        engines = import ./search.nix {inherit lib pkgs;};
      };

      settings = {
        # File Picker Settings
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        
        # Browser Behavior
        "browser.disableResetPrompt" = true;
        "browser.download.panel.shown" = true;
        "browser.download.useDownloadDir" = true;
        "browser.shell.checkDefaultBrowser" = true;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "browser.startup.homepage" = "https://google.com";
        "browser.bookmarks.showMobileBookmarks" = true;
        
        # Privacy & Security
        "dom.security.https_only_mode" = true;
        "privacy.trackingprotection.enabled" = true;
        "signon.rememberSignons" = false;
        
        # Sponsored Content
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        
        # Account Integration
        "identity.fxaccounts.enabled" = true;
        
        # Pinned Sites
        "browser.newtabpage.pinned" = lib.singleton {
          title = "NixOS";
          url = "https://nixos.org";
        };
        
        # UI Customization State
        "browser.uiCustomization.state" = ''
          {"placements": ... }
        '';
      };
    };
  };
}
