# modules/nixos/system/default.nix
# ==============================================================================
# NixOS core system defaults: state version, base services, global options.
# Central home for settings shared by all host configs.
# Extend this file for cross-host system behaviour instead of duplicating.
# ==============================================================================

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
    services.spice-vdagentd.enable = lib.mkIf config.my.host.isVirtualHost true;

    programs.zsh.enable = true;
  };
}
