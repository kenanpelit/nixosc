# modules/home/mangowc/monitors.nix
# ==============================================================================
# MangoWC monitor rules (config.conf snippet)
#
# MangoWC requires 11 fields:
#   monitorrule=<name>,<mfact>,<nmaster>,<layout>,<rr>,<scale>,<x>,<y>,<w>,<h>,<refresh>
#
# You can list output names in a Mango session with:
#   mmsg -O
#
# Ref: https://github.com/DreamMaoMao/mango/wiki/
# ==============================================================================
{ lib, ... }:

{
  hardwareDefault = ''
    # ==============================================================================
    # Monitor rules
    # ==============================================================================
    # NOTE: Adjust output names/sizes/refresh to your actual setup.
    #       List outputs in a Mango session: `mmsg -O`

    monitorrule=DP-3,0.55,1,tile,0,1.0,0,0,2560,1440,165
    monitorrule=eDP-1,0.55,1,tile,0,1.0,2560,0,1920,1080,60
  '';
}
