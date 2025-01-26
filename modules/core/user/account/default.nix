# modules/core/user/account/default.nix
# ==============================================================================
# User Account Configuration
# ==============================================================================
# This configuration manages user account settings including:
# - User account options and privileges 
# - Group memberships
# - Shell configuration
# - Sudo access rules
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, lib, username, config, ... }: {
 options.my.user = {
   name = lib.mkOption {
     type = lib.types.str;
     default = username;
     description = "The name of the primary user account";
   };
   uid = lib.mkOption {
     type = lib.types.int;
     default = 1000;
     description = "The user's UID";
   };
 };
 
 config = {
   # Primary user account configuration
   users.users.${username} = {
     isNormalUser = true;
     description = "${username}";
     extraGroups = [
       "networkmanager"  # Network management permissions
       "wheel"           # Sudo access
       "input"           # Input device access
     ];
     shell = pkgs.zsh;
     uid = config.my.user.uid;
   };
   
   # Passwordless sudo configuration
   security.sudo.extraRules = [{
     users = [ username ];
     commands = [{
       command = "ALL";     # Allow all commands
       options = [ "NOPASSWD" ];  # No password required
     }];
   }];
 };
}

