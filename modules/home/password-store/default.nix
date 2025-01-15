# home.nix ya da benzeri konfigürasyon dosyasında:
{ config, lib, pkgs, ... }:
{
  programs.password-store = {
    enable = true;
    package = pkgs.pass.withExtensions (exts: [
      exts.pass-otp
      exts.pass-audit
      exts.pass-update
    ]);
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.pass";
      PASSWORD_STORE_CLIP_TIME = "45";
      PASSWORD_STORE_GENERATED_LENGTH = "20";
    };
  };

  services.pass-secret-service = {
    enable = true;
    storePath = "${config.home.homeDirectory}/.pass";
  };
}
