# modules/nixos/audit/default.nix
# ==============================================================================
# NixOS auditd configuration: kernel audit, logging, and retention policy.
# Central place to enable auditing and tune rules per host.
# Avoid scattered audit settings by keeping them defined here.
# ==============================================================================

{ pkgs, ... }:
{
  security.audit.enable = true;
  # Prevent kauditd backlog overflow by enlarging the queue
  security.audit.rules = [ "-b 8192" ];
  boot.kernelParams = [ "audit_backlog_limit=8192" ];

  environment.systemPackages = [ pkgs.audit ];

  environment.shellAliases = {
    audit-summary = "sudo aureport --summary";
    audit-failed  = "sudo aureport --failed";
    audit-search  = "sudo ausearch -i";
    audit-auth    = "sudo ausearch -m USER_LOGIN";
  };
}
