# modules/core/system/default.nix
# Host metadata and imports for system submodules.

{ lib, config, hostRole ? "unknown", isPhysicalHost ? false, isVirtualHost ? false, ... }:

let
  hostname          = config.networking.hostName or "";
  isPhysicalMachine = isPhysicalHost;
  isVirtualMachine  = isVirtualHost;
in
{
  options = {
    my.host = {
      role = lib.mkOption {
        type = lib.types.str;
        default = hostRole;
        description = "Host role identifier.";
      };
      isPhysicalHost = lib.mkOption {
        type = lib.types.bool;
        default = isPhysicalMachine;
        description = "Flag for physical host.";
      };
      isVirtualHost = lib.mkOption {
        type = lib.types.bool;
        default = isVirtualMachine;
        description = "Flag for virtual host.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        default = hostname;
        description = "Resolved hostname.";
      };
    };
  };

  config = {
    my.host = {
      role           = hostRole;
      isPhysicalHost = isPhysicalMachine;
      isVirtualHost  = isVirtualMachine;
      name           = hostname;
    };

    services.upower.enable = true;
    services.spice-vdagentd.enable = lib.mkIf isVirtualMachine true;
  };
}
