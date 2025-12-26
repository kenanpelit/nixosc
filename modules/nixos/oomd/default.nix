# modules/nixos/oomd/default.nix
# ==============================================================================
# systemd-oomd configuration (memory pressure based OOM killer).
# Helps keep the desktop responsive under heavy memory pressure.
# ==============================================================================

{ lib, config, ... }:

let
  cfg = config.my.oomd;
in
{
  options.my.oomd = {
    enable = lib.mkEnableOption "systemd-oomd (memory pressure protection)";
  };

  config = lib.mkIf cfg.enable {
    systemd.oomd = {
      enable = true;
      enableSystemSlice = true;
      enableUserSlices = true;
    };
  };
}

