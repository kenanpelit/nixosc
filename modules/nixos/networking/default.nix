# modules/nixos/networking/default.nix
# ==============================================================================
# NixOS networking base: NetworkManager, hostname, hosts file, DHCP/DNS hooks.
# Keep core network defaults here for consistency across machines.
# Adjust connectivity policy in this module instead of per-host tweaks.
# ==============================================================================

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
