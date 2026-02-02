# modules/nixos/security/default.nix
# ==============================================================================
# NixOS security policy (consolidated)
# ------------------------------------------------------------------------------
# Central place for system security posture:
# - Firewall + nftables defaults + helper aliases
# - AppArmor enablement + helper aliases
# - Polkit enablement
# - fail2ban service enablement + helper aliases
# - audit policy (currently disabled; see notes)
#
# Consolidated from:
#   modules/nixos/{firewall,apparmor,polkit,fail2ban,audit}
# ==============================================================================

{ lib, pkgs, config, ... }:

let
  inherit (lib) mkDefault mkOption optional types;

  cfg = config.my.firewall;

  transmissionWebPort  = 9091;
  transmissionPeerPort = 51413;
  customServicePort    = 1401;
in
{
  options.my.firewall = {
    allowTransmissionPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Open Transmission web/peer ports when the service is enabled.";
    };

    allowCustomServicePort = mkOption {
      type = types.bool;
      default = false;
      description = "Open TCP port 1401 for custom service usage.";
    };
  };

  config = {
    # -------------------------------------------------------------------------
    # Polkit
    # -------------------------------------------------------------------------
    security.polkit.enable = mkDefault true;

    # -------------------------------------------------------------------------
    # AppArmor
    # -------------------------------------------------------------------------
    security.apparmor.enable = true;

    # -------------------------------------------------------------------------
    # fail2ban
    # -------------------------------------------------------------------------
    services.fail2ban.enable = true;

    # -------------------------------------------------------------------------
    # Audit (disabled)
    # -------------------------------------------------------------------------
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
    security.audit.enable = false;

    # Disable auditing in early boot.
    boot.kernelParams = [
      "audit=0"
    ];

    environment.systemPackages = [
      pkgs.audit
    ];

    # -------------------------------------------------------------------------
    # Firewall + nftables (policy defaults)
    # -------------------------------------------------------------------------
    networking.firewall = {
      enable = mkDefault true;
      allowPing = false;
      logReversePathDrops = true;
      allowedTCPPorts =
        [ 22 ] # SSH
        ++ (optional cfg.allowTransmissionPorts transmissionWebPort)
        ++ (optional cfg.allowCustomServicePort customServicePort);
      allowedUDPPorts =
        optional cfg.allowTransmissionPorts transmissionPeerPort;
    };

    # Use native nftables routing instead of iptables
    networking.nftables.enable = true;

    # -------------------------------------------------------------------------
    # CLI helpers
    # -------------------------------------------------------------------------
    environment.shellAliases = {
      # AppArmor
      aa-status   = "sudo aa-status";
      aa-enforce  = "sudo aa-enforce";
      aa-complain = "sudo aa-complain";

      # fail2ban
      f2b-status      = "sudo fail2ban-client status";
      f2b-status-ssh  = "sudo fail2ban-client status sshd";
      f2b-banned      = "sudo fail2ban-client get sshd banned";
      f2b-unban       = "sudo fail2ban-client set sshd unbanip";

      # audit
      audit-summary = "sudo aureport --summary";
      audit-failed  = "sudo aureport --failed";
      audit-search  = "sudo ausearch -i";
      audit-auth    = "sudo ausearch -m USER_LOGIN";

      # firewall / nftables
      fw-list         = "sudo nft list ruleset";
      fw-list-filter  = "sudo nft list table inet filter";
      fw-list-nat     = "sudo nft list table inet nat";
      fw-list-input   = "sudo nft list chain inet filter input";
      fw-list-forward = "sudo nft list chain inet filter forward";

      fw-stats          = "sudo nft -a -s list ruleset";
      fw-counters       = "sudo nft list ruleset | grep -E 'counter|packets'";
      fw-reset-counters = "sudo nft reset counters table inet filter";

      fw-monitor      = "sudo nft monitor";
      fw-dropped      = "sudo journalctl -k | grep 'nft-drop'";
      fw-dropped-live = "sudo journalctl -kf | grep 'nft-drop'";

      fw-connections     = "sudo conntrack -L";
      fw-connections-ssh = "sudo conntrack -L | grep -E 'tcp.*22'";
      fw-flush-conntrack = "sudo conntrack -F";
    };
  };
}

