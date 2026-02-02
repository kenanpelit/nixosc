{ lib, config, ... }:

let
  isHay = (config.networking.hostName or null) == "hay";
in
{
  config = lib.mkIf isHay {
    # Host-local policy knobs that should stay in NixOS (not Home Manager).
    my.power.stack = lib.mkDefault "ppd";

    # ThinkPad E14 Gen 6 (Meteor Lake): enable ThinkPad ACPI module explicitly.
    # (Safe; avoids forcing it on non-ThinkPad machines.)
    my.kernel.thinkpad.enable = lib.mkDefault true;

    # DNS adblock (Blocky) - optional aggressive Google/YouTube blocking.
    my.dns.blocky.noGoogle.enable = lib.mkDefault true;
  };
}
