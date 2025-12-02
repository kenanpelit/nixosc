# modules/core/audio/default.nix
# ==============================================================================
# Audio Configuration
# ==============================================================================
# Configures the PipeWire audio stack.
# - Enables PipeWire service
# - Enables ALSA, PulseAudio, and JACK compatibility
# - Enables 32-bit ALSA support
#
# ==============================================================================

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
