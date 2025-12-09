# modules/nixos/system/default.nix
# ------------------------------------------------------------------------------
# NixOS module for system (system-wide stack).
# Provides host defaults and service toggles declared in this file.
# Keeps machine-wide settings centralized under modules/nixos.
# Extend or override options here instead of ad-hoc host tweaks.
# ------------------------------------------------------------------------------

{ lib, config, ... }:

{
  options = {
    my.host = {
      role = lib.mkOption {
        type = lib.types.str;
        default = "unknown";
        description = "Host role identifier.";
      };
      isPhysicalHost = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Flag for physical host.";
      };
      isVirtualHost = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Flag for virtual host.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName;
        description = "Resolved hostname.";
      };
    };
  };

  config = {
    services.upower.enable = true;
    services.spice-vdagentd.enable = lib.mkIf config.my.host.isVirtualHost true;

    programs.zsh.enable = true;
  };
}
