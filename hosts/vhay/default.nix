{ pkgs, config, lib, inputs, username, ... }:
{
  # -------------------------------------------------------
  # Configuration Files
  # -------------------------------------------------------
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];

  # -------------------------------------------------------
  # Bootloader Configuration
  # -------------------------------------------------------
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub = {
      enable = true;
      version = 2;
      devices = [ "/dev/vda" ];
      useOSProber = false;
    };
  };

  # -------------------------------------------------------
  # SSH Service
  # -------------------------------------------------------
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # -------------------------------------------------------
  # Home Manager Configuration
  # -------------------------------------------------------
  home-manager.users.${username} = {
    home.stateVersion = "24.11";
    home.packages = with pkgs; [
      git
      neovim
      zsh
      ripgrep
      fd
    ];
  };
}

