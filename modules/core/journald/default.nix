{ config, lib, pkgs, ... }:

{
  services.journald = {
    extraConfig = ''
      SystemMaxUse=5G
      SystemMaxFileSize=500M
      MaxRetentionSec=1month
    '';
  };
}
