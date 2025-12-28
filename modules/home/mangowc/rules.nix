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

    # Daily layout (tags/workspaces)
    #
    # NOTE: Mango window rules support regex. In Nix multiline strings we do NOT
    # need to double-escape backslashes, so use `\.` (not `\\.`).

    # Terminal / session anchor
    windowrule=appid:^(TmuxKenp|Tmux)$,tags:2,force_maximize:1

    # Chat / comms
    windowrule=appid:^(discord|WebCord)$,tags:5,force_maximize:1
    windowrule=appid:^ferdium$,tags:9,force_maximize:1
    windowrule=appid:^com\.rtosta\.zapzap$,tags:9,force_maximize:1
    windowrule=appid:^org\.telegram\.desktop$,tags:6,force_maximize:1

    # Music / media
    windowrule=appid:^(spotify|Spotify|com\.spotify\.Client)$,tags:8
    windowrule=appid:^audacious$,tags:5
    windowrule=appid:^vlc$,tags:6

    # Downloads / secrets
    windowrule=appid:^transmission$,tags:7
    windowrule=appid:^org\.keepassxc\.KeePassXC$,tags:7

    # Work / daily apps
    windowrule=appid:^Kenp$,tags:1,force_maximize:1
    windowrule=appid:^Ai$,tags:3,force_maximize:1
    windowrule=appid:^CompecTA$,tags:4,force_maximize:1
    windowrule=appid:^brave-youtube\.com__-Default$,tags:7,force_maximize:1
    windowrule=appid:^remote-viewer$,tags:6,force_maximize:1

    # Utility: make these float by default (Niri parity-ish)
    windowrule=appid:^(org\.pulseaudio\.pavucontrol|pavucontrol)$,isfloating:1
    windowrule=appid:^nm-connection-editor$,isfloating:1
    windowrule=appid:^blueman-manager$,isfloating:1
    windowrule=appid:^polkit-gnome-authentication-agent-1$,isfloating:1
    windowrule=appid:^clipse$,isfloating:1
  '';
}
