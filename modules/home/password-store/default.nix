# modules/home/password-store/default.nix
# ==============================================================================
# Password Store Configuration
# ==============================================================================
{ config, lib, pkgs, ... }:
{
  # =============================================================================
  # Pass CLI Configuration
  # =============================================================================
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp    # OTP support
      (exts.pass-audit.overrideAttrs (old: {
        doCheck = false;  # Skip tests to avoid build failures
      }))
      exts.pass-update # Password updating
    ]);
    # ---------------------------------------------------------------------------
    # Core Settings
    # ---------------------------------------------------------------------------
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.pass";
      PASSWORD_STORE_CLIP_TIME = "45";
      PASSWORD_STORE_GENERATED_LENGTH = "20";
    };
  };
  # =============================================================================
  # Secret Service Integration
  # =============================================================================
  services.pass-secret-service = {
    enable = true;
    storePath = "${config.home.homeDirectory}/.pass";
  };
}
