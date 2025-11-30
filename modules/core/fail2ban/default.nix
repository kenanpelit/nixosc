# modules/core/security/fail2ban/default.nix
# fail2ban basic enablement.

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
