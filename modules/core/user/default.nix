# modules/core/user/default.nix
# ==============================================================================
# User Configuration and Home Manager Integration
# ==============================================================================
{ pkgs, inputs, username, host, lib, config, ... }:
let
  inherit (lib) mkOption types;
in
{
  # =============================================================================
  # User Options
  # =============================================================================
  options.my.user = {
    name = mkOption {
      type = types.str;
      default = username;
      description = "The name of the primary user account";
    };
    uid = mkOption {
      type = types.int;
      default = 1000;
      description = "The user's UID";
    };
  };

  config = {
    # =============================================================================
    # Home Manager Configuration
    # =============================================================================
    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;
      backupFileExtension = "backup";
      extraSpecialArgs = { inherit inputs username host; };
      
      users.${username} = {
        imports = [ ./../../home ];
        home = {
          username = "${username}";
          homeDirectory = "/home/${username}";
          stateVersion = "24.11";
        };
      };
    };
    
    # =============================================================================
    # User Account Configuration
    # =============================================================================
    users.users.${username} = {
      isNormalUser = true;
      description = "${username}";
      extraGroups = [
        "networkmanager"  # Network management
        "wheel"          # Sudo access
        "input"          # Input devices
      ];
      shell = pkgs.zsh;
      uid = 1000;
    };

    # =============================================================================
    # Nix Permissions
    # =============================================================================
    nix.settings.allowed-users = [ "${username}" ];
  };
}
