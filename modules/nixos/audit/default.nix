# modules/nixos/audit/default.nix
# ==============================================================================
# NixOS auditd configuration: kernel audit, logging, and retention policy.
# Central place to enable auditing and tune rules per host.
# Avoid scattered audit settings by keeping them defined here.
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
