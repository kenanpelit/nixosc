
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
      exts.pass-otp
      (exts.pass-audit.overrideAttrs (_: { doCheck = false; }))
      exts.pass-update
    ]);

    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.pass";
      PASSWORD_STORE_CLIP_TIME = "45";
      PASSWORD_STORE_GENERATED_LENGTH = "20";
    };
  };

  # =============================================================================
  # Secret Service Integration
  # =============================================================================
  # NOT: GNOME ortamında secrets D-Bus adını gnome-keyring tutacak.
  #      Bu yüzden pass-secret-service’i zorla kapatıyoruz.
  services.pass-secret-service.enable = lib.mkForce false;

  # İstersen GNOME dışında bir profile’da şartlı açmak için:
  # services.pass-secret-service = lib.mkIf (config.xsession.windowManager.i3.enable or false) {
  #   enable = true;
  #   storePath = "${config.home.homeDirectory}/.pass";
  # };
}
