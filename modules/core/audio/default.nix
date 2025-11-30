# modules/core/audio/default.nix
# PipeWire audio stack.

{ lib, config, pkgs, ... }:

let cfg = config.my.display;
in {
  config = lib.mkIf cfg.enableAudio {
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
