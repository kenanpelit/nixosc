# modules/core/security/default.nix
# ==============================================================================
# Security Configuration
# ==============================================================================
# This configuration file manages all security-related settings including:
# - Core system security settings
# - GNOME Keyring integration
# - GnuPG configuration
# - Host blocking (hBlock)
#
# Key components:
# - PAM and sudo configuration
# - GNOME Keyring credential storage
# - GnuPG agent and SSH support 
# - System-wide ad and malware domain blocking
#
# Author: Kenan Pelit
# ==============================================================================

{ ... }:
{
  imports = [
    ./pam
    ./keyring
    ./hblock
    ./sops
  ];
}
