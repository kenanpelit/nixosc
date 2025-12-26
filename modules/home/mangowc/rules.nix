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

    # Semsumo daily layout (workspace/tag assignment)
    windowrule=appid:TmuxKenp,tags:2,force_maximize:1
    windowrule=appid:Kenp,tags:1,force_maximize:1
    windowrule=appid:Ai,tags:3,force_maximize:1
    windowrule=appid:CompecTA,tags:4,force_maximize:1
    windowrule=appid:WebCord,tags:5,force_maximize:1
    windowrule=appid:brave-youtube\\.com__-Default,tags:7,force_maximize:1
    windowrule=appid:Spotify,tags:8,force_maximize:1
    windowrule=appid:ferdium,tags:9,force_maximize:1

    # ZapZap (WhatsApp)
    windowrule=appid:com\\.rtosta\\.zapzap,tags:9,force_maximize:1

    # Telegram Desktop
    windowrule=appid:org\\.telegram\\.desktop,tags:6,force_maximize:1
  '';
}
