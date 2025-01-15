{ config, pkgs, lib, ... }:
{
  services.fusuma = {
    enable = true;
    package = pkgs.fusuma;
    extraPackages = with pkgs; [
      coreutils
    ];
    settings = {
      threshold = {
        swipe = 0.7;
        pinch = 0.3;
      };
      interval = {
        swipe = 0.6;
        pinch = 1.0;
      };
      swipe = {
        "3" = {
          right = {
            sendkey = "LEFTCTRL+TAB";
            threshold = 0.6;
          };
          left = {
            sendkey = "LEFTCTRL+LEFTSHIFT+TAB";
            threshold = 0.6;
          };
        };
      };
    };
  };
}
