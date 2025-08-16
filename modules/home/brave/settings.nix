# modules/home/brave/settings.nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.my.browser.brave.enable {
    # Brave preferences
    home.file.".config/BraveSoftware/Brave-Browser/${config.my.browser.brave.profile}/Preferences".text = lib.mkIf config.my.browser.brave.manageSettings builtins.toJSON {
      "browser" = {
        "show_home_button" = true;
        "check_default_browser" = false;
      };
      "profile" = {
        "default_content_setting_values" = {
          "notifications" = 2; # Block
          "geolocation" = 2;   # Block
          "media_stream" = 2;  # Block camera/mic
        };
      };
      "brave" = {
        "new_tab_page" = {
          "show_background_image" = false;
          "show_sponsored_images" = false;
        };
      };
    };
  };
}

