# modules/home/brave/policies.nix
{ config, lib, ... }:
{
  config = lib.mkIf config.my.browser.brave.enable {
    programs.chromium.policies = {
      # Güvenlik politikaları
      "AutofillAddressEnabled" = false;
      "AutofillCreditCardEnabled" = false;
      "PasswordManagerEnabled" = false;
      "SyncDisabled" = !config.my.browser.brave.enableSync or true;
      "SpellcheckEnabled" = true;
      "SpellcheckLanguage" = [ "en-US" "tr-TR" ];
      
      # Gizlilik
      "DefaultSearchProviderSearchURL" = "https://search.brave.com/search?q={searchTerms}";
      "MetricsReportingEnabled" = false;
      "SearchSuggestEnabled" = false;
      "DefaultCookiesSetting" = 1; # Allow cookies
      "DefaultNotificationsSetting" = 2; # Block notifications
      
      # Performans
      "BackgroundModeEnabled" = false;
      "HardwareAccelerationModeEnabled" = config.my.browser.brave.enableHardwareAcceleration;
      
      # Updates
      "ComponentUpdatesEnabled" = false;
      "ExtensionInstallBlocklist" = ["*"]; # Block random extension installs
    };
  };
}

