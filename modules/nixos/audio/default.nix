# modules/nixos/audio/default.nix
# ==============================================================================
# NixOS audio stack: PipeWire core with ALSA/Pulse/JACK shims and 32-bit support.
# Central place to toggle sound services and compatibility layers per host.
# Keep sound policy here instead of scattering overrides across modules.
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
