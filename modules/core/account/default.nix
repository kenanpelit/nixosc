# modules/core/account/default.nix
# ==============================================================================
# User Account and Authentication Configuration
# ==============================================================================
# This configuration manages user account settings including:
# - User account options and privileges 
# - Group memberships and shell configuration
# - Sudo access rules
# - GNOME Keyring and credential storage
# - Authentication service integration
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, lib, username, config, ... }: 
{
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
        "audio"           # Audio device access
        "video"           # Video device access
        "storage"         # Storage device access
        "libvirtd"        # Virtualization
        "kvm"             # KVM virtualization
      ];
      shell = pkgs.zsh;
      uid = config.my.user.uid;
    };
    
    # Sudo Configuration
    security.sudo.wheelNeedsPassword = false;
    
    # Credential Storage Services
    services = {
      gnome.gnome-keyring.enable = true;
      dbus = {
        enable = true;
        packages = [ pkgs.gcr ];
      };
    };
    
    # Authentication Environment
    environment.sessionVariables = {
      GCR_PKCS11_MODULE = "${pkgs.gcr}/lib/pkcs11/gcr-pkcs11.so";
      GCR_PROVIDER_PRIORITY = "1";
    };
  };
}

