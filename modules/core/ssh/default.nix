# modules/core/ssh/default.nix
# ==============================================================================
# SSH Configuration
# ==============================================================================
{ pkgs, lib, ... }: {
  # =============================================================================
  # SSH Client Configuration
  # =============================================================================
  programs.ssh = {
    startAgent = false;         # Using GPG agent instead
    enableAskPassword = false;  # Disable GUI password prompt
    
    # Connection Settings
    extraConfig = ''
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 2
    '';
  };

  # =============================================================================
  # Environment Configuration
  # =============================================================================
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
