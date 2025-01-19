# modules/home/security/default.nix
# ==============================================================================
# Security Configuration
# ==============================================================================
# This module manages security tools including:
#
# Components:
# - Encryption:
#   - GnuPG: OpenPGP implementation
#   - SOPS: Secrets management
# - Password Management:
#   - Password Store: Command line password manager
#
# Author: Kenan Pelit
# ==============================================================================
{ config, lib, pkgs, ... }:

{
 imports = [
   ./gnupg
   ./password-store
   ./sops
 ];
}
