# modules/nixos/networking/default.nix
# ------------------------------------------------------------------------------
# NixOS module for networking (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

{ lib, pkgs, ... }:

{
  networking = {
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    wireless.enable = false;
  };

  programs.ssh = {
    startAgent        = false;
    enableAskPassword = false;

    extraConfig = ''
      Host *
        # Connection keep-alive
        ServerAliveInterval 60
        ServerAliveCountMax 3
        TCPKeepAlive yes

        # Fail fast
        ConnectTimeout 30

        # ASSH proxy
        ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
    '';
  };

  environment = {
    systemPackages = with pkgs; [ assh ];

    shellAliases = {
      assh       = "${pkgs.assh}/bin/assh";
      sshconfig  = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
      sshtest    = "ssh -o ConnectTimeout=5 -o BatchMode=yes";
    };

    variables = {
      ASSH_CONFIG = "$HOME/.ssh/assh.yml";
    };
  };
}
