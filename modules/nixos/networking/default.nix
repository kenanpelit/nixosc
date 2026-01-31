# modules/nixos/networking/default.nix
# ==============================================================================
# NixOS networking base: NetworkManager, hostname, hosts file, DHCP/DNS hooks.
# Keep core network defaults here for consistency across machines.
# Adjust connectivity policy in this module instead of per-host tweaks.
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  enableAssh = config.my.networking.assh.enable or false;
in
{
  options.my.networking = {
    assh.enable = lib.mkEnableOption "ASSH integration (optional SSH ProxyCommand wrapper)";
  };

  config = lib.mkMerge [
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
        '';
      };

      environment.shellAliases = {
        sshtest = "ssh -o ConnectTimeout=5 -o BatchMode=yes";
      };
    }

    (lib.mkIf enableAssh {
      environment.systemPackages = with pkgs; [ assh ];

      environment.shellAliases = {
        assh      = "${pkgs.assh}/bin/assh";
        sshconfig = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
      };

      environment.variables.ASSH_CONFIG = "$HOME/.ssh/assh.yml";

      programs.ssh.extraConfig = ''
        # ASSH proxy (only when a config exists, to avoid breaking plain SSH)
        Match exec "test -f ~/.ssh/assh.yml && command -v assh >/dev/null 2>&1"
          ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
      '';
    })
  ];
}
