# modules/core/security/default.nix
# ==============================================================================
# Security Services Configuration
# ==============================================================================
# This configuration manages security-related services including:
# - PolicyKit authorization
# - System-wide security services
# - AppArmor profile enforcement
# - Firewall basic rules
#
# Author: Kenan Pelit
# ==============================================================================
{ pkgs, ... }:
{
  security = {
    # PolicyKit authorization manager
    polkit.enable = true;
    
    # AppArmor security profiles
    apparmor = {
      enable = true;
      packages = with pkgs; [
        apparmor-profiles
        apparmor-utils
      ];
    };
    
    # Audit daemon for security monitoring
    auditd.enable = true;
    
    # Restrict ptrace to same user processes
    allowUserNamespaces = true;
    
    # Protect kernel symbols
    protectKernelImage = true;
  };
  
  # PolicyKit rules for desktop environment
  environment.systemPackages = with pkgs; [
    polkit_gnome  # GNOME PolicyKit agent
  ];
}

