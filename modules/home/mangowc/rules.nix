# modules/home/mangowc/rules.nix
# ==============================================================================
# MangoWC window rules (config.conf snippet)
#
# Syntax:
#   windowrule=appid:<regex>,tags:<n>,force_maximize:<0|1>,...
# ==============================================================================
{ lib, ... }:

{
  rules = ''
    # ==============================================================================
    # Window rules
    # ==============================================================================

    # ZapZap (WhatsApp)
    windowrule=appid:com\\.rtosta\\.zapzap,tags:9,force_maximize:1

    # Telegram Desktop
    windowrule=appid:org\\.telegram\\.desktop,tags:6,force_maximize:1
  '';
}

