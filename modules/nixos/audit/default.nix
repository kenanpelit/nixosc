# modules/core/audit/default.nix
# ==============================================================================
# System Audit Logging
# ==============================================================================
# Enables the Linux Audit framework for security monitoring.
# - Enables security.audit
# - Installs audit tools package
# - Provides shell aliases for report generation
#
# ==============================================================================

{ pkgs, ... }:
{
  security.audit.enable = true;

  environment.systemPackages = [ pkgs.audit ];

  environment.shellAliases = {
    audit-summary = "sudo aureport --summary";
    audit-failed  = "sudo aureport --failed";
    audit-search  = "sudo ausearch -i";
    audit-auth    = "sudo ausearch -m USER_LOGIN";
  };
}
