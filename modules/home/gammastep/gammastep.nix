{ config, lib, pkgs, ... }:
{
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = 41.0;  # İstanbul için
    longitude = 28.9; # İstanbul için
    temperature = {
      day = 4500;
      night = 3700;
    };
    settings = {
      general = {
        brightness-day = 1.0;
        brightness-night = 0.8;
      };
    };
  };
}
