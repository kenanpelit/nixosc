# modules/core/nix/settings/default.nix
# ==============================================================================
# Nix Settings Configuration
# ==============================================================================
# This configuration manages core Nix settings including:
# - User permissions
# - Store optimization
# - System features
# - Experimental features
#
# Author: Kenan Pelit
# ==============================================================================

{ username, ... }:
{
  nix = {
    settings = {
      # System Users
      allowed-users = [ "${username}" ];
      trusted-users = [ "${username}" ];
      
      # Store Configuration
      auto-optimise-store = true;
      keep-outputs = true;
      keep-derivations = true;
      sandbox = true;
      
      # Features
      system-features = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    };
    
    # Experimental Features
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}
