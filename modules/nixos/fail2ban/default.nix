# modules/nixos/fail2ban/default.nix
# ------------------------------------------------------------------------------
# NixOS module for fail2ban (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

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
