{ config, lib, pkgs, inputs, username, ... }:
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFile = "${config.home.homeDirectory}/.nixosc/secrets/home-secrets.enc.yaml";
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    validateSopsFiles = false;

    secrets = {
      github_token = {
        path = "${config.home.homeDirectory}/.config/github/token";
        mode = "0600";
      };
      nix_conf = {
        path = "${config.home.homeDirectory}/.config/nix/nix.conf";
        mode = "0600";
      };
      gist_token = {
        path = "${config.home.homeDirectory}/.gist";
        mode = "0600";
      };
    };
  };

  # Dizinleri oluştur
  home.activation.createDirs = lib.hm.dag.entryBefore ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/.config/sops/age"
    mkdir -p "${config.home.homeDirectory}/.config/github"
    mkdir -p "${config.home.homeDirectory}/.config/nix"
  '';
}

