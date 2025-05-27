# modules/core/user/home/default.nix
# ==============================================================================
# Home Manager Configuration
# ==============================================================================
# This configuration manages home environment including:
# - Home Manager settings
# - User environment setup
#
# Author: Kenan Pelit
# ==============================================================================

{ inputs, username, host, ... }:
{
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs username host; };
    
    users.${username} = {
      imports = [ ./../../../home ];  # Path düzeltildi
      home = {
        username = "${username}";
        homeDirectory = "/home/${username}";
        stateVersion = "25.11";
      };
    };
  };
}

