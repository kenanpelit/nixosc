# modules/core/networking/default.nix
# ==============================================================================
# Networking Configuration
# ==============================================================================
# Configures network management and SSH client settings.
# - NetworkManager enablement
# - SSH client hardening and ASSH integration
# - Shell aliases for SSH management
#
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
