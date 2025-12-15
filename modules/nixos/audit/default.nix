# modules/nixos/audit/default.nix
# ==============================================================================
# NixOS auditd configuration: kernel audit, logging, and retention policy.
# Central place to enable auditing and tune rules per host.
# Avoid scattered audit settings by keeping them defined here.
# ==============================================================================

{ pkgs, ... }:
{
  # NOTE:
  # On this host/kernel, audit control operations (AUDIT_SET) are not supported:
  # `auditctl -b/-e/-f/-r` fails with netlink error `EOPNOTSUPP`.
  #
  # The NixOS `security.audit.enable = true` module loads rules via `auditctl -R`,
  # which includes `-b/-f/-r/-e` lines and causes `audit-rules-nixos.service` to fail.
  # That failure aborts `nixos-rebuild switch`.
  #
  # Workaround:
  # - Keep kernel auditing enabled via cmdline (audit=1).
  # - Do NOT attempt to load kernel audit rules via auditctl.
  #
  # If/when the kernel supports AUDIT_SET again, you can switch back to:
  #   security.audit.enable = true;

  security.audit.enable = false;

  # Enable auditing early in boot (without loading rules).
  boot.kernelParams = [
    "audit=1"
    # Backlog limit must be set at boot on this kernel.
    "audit_backlog_limit=8192"
  ];

  environment.systemPackages = [ pkgs.audit ];

  environment.shellAliases = {
    audit-summary = "sudo aureport --summary";
    audit-failed  = "sudo aureport --failed";
    audit-search  = "sudo ausearch -i";
    audit-auth    = "sudo ausearch -m USER_LOGIN";
  };
}
