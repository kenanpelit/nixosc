# modules/core/user/account/default.nix
# ==============================================================================
# User Account Configuration
# ==============================================================================
# This configuration manages user account settings including:
# - User options and definitions
# - Group memberships
# - Shell configuration
#
# Author: Kenan Pelit
# ==============================================================================

{ pkgs, lib, username, config, ... }:
let
  inherit (lib) mkOption types;
in
{
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
    users.users.${username} = {
      isNormalUser = true;
      description = "${username}";
      extraGroups = [
        "networkmanager"  # Network management
        "wheel"           # Sudo access
        "input"           # Input devices
      ];
      shell = pkgs.zsh;
      uid = config.my.user.uid;
    };
  };
}
