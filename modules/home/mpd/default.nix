{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    mpc-cli
    rmpc
  ];

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
        mixer_type "software"
      }
      
      restore_paused "yes"
      auto_update "yes"
      
      audio_buffer_size "4096"
    '';
  };
}
