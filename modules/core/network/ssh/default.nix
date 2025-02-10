# modules/core/network/ssh/default.nix
# ==============================================================================
# SSH Configuration
# ==============================================================================
# This configuration manages SSH settings including:
# - SSH agent configuration
# - Connection settings
# - Environment variables and aliases
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:
{
  programs.ssh = {
    startAgent = false;         # Using GPG agent instead
    enableAskPassword = false;  # Disable GUI password prompt
    
    # Connection Settings
    extraConfig = ''
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 2
        ProxyCommand ${pkgs.assh}/bin/assh connect --port=%p %h
    '';
  };
  environment = {
    # Variables
    variables = {
      ASSH_CONFIG = "$HOME/.ssh/assh.yml";
    };
    # Shell Aliases
    shellAliases = {
      assh = "${pkgs.assh}/bin/assh";
      sshconfig = "${pkgs.assh}/bin/assh config build > ~/.ssh/config";
    };
  };
}
