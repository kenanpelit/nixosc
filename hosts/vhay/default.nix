{ pkgs, config, lib, inputs, username, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./../../modules/core
  ];
  
  # SSH Service
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # Home Manager Configuration
  home-manager.users.${username} = {
    home.stateVersion = "24.11";
    home.packages = with pkgs; [
      git
      zsh
      zoxide
      ncurses
      terminfo
    ];
  };
}
