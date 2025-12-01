# modules/core/fail2ban/default.nix
# ==============================================================================
# Fail2ban Intrusion Prevention
# ==============================================================================
# Configures fail2ban service and shell aliases for monitoring.
# - Enable fail2ban service
# - Shell aliases for status and ban management
#
# ==============================================================================

{ ... }:
{
  services.fail2ban.enable = true;

  environment.shellAliases = {
    f2b-status      = "sudo fail2ban-client status";
    f2b-status-ssh  = "sudo fail2ban-client status sshd";
    f2b-banned      = "sudo fail2ban-client get sshd banned";
    f2b-unban       = "sudo fail2ban-client set sshd unbanip";
  };
}
