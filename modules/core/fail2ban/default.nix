# modules/core/security/fail2ban/default.nix
# fail2ban basic enablement.

{ ... }: { services.fail2ban.enable = true; }
