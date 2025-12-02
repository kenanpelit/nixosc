# modules/core/system/default.nix
# ==============================================================================
# Core System Metadata & Defaults
# ==============================================================================
# Defines custom host metadata options and applies global system defaults.
# - Host Role (physical/vm)
# - Global service enablement (upower, spice-vdagentd)
# - Global shell enablement (zsh)
#
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
    services.upower.enable = true;
    services.spice-vdagentd.enable = lib.mkIf config.my.host.isVirtualHost true;

    programs.zsh.enable = true;
  };
}
