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
  # - Do NOT attempt to load kernel audit rules via auditctl.
  # - Also disable kernel auditing entirely to avoid noisy kernel spam like:
  #     `audit: error in audit_log_subj_ctx`
  #
  # If/when the kernel supports AUDIT_SET again and you actually need audit logs,
  # you can switch back to:
  #   security.audit.enable = true;
  #   boot.kernelParams = [ "audit=1" "audit_backlog_limit=8192" ];
  #
  security.audit.enable = false;

  # Disable auditing in early boot.
  boot.kernelParams = [
    "audit=0"
  ];

  environment.systemPackages = [ pkgs.audit ];

  environment.shellAliases = {
    audit-summary = "sudo aureport --summary";
    audit-failed  = "sudo aureport --failed";
    audit-search  = "sudo ausearch -i";
    audit-auth    = "sudo ausearch -m USER_LOGIN";
  };
}
