#modules/core/security/default.nix
{ pkgs, ... }:
{
  security = {
    rtkit.enable = true;
    sudo.enable = true;
    pam.services = {
      swaylock = {
        enableGnomeKeyring = true;
      };
      hyprlock = {
        enableGnomeKeyring = true;
      };
      login.enableGnomeKeyring = true;
    };
  };

  # GNOME Keyring servisi
  services.gnome = {
    gnome-keyring.enable = true;
  };
}
