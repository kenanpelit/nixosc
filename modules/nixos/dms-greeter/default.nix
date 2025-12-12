# modules/nixos/dms-greeter/default.nix
# ==============================================================================
# NixOS integration for DankMaterialShell greeter service.
# Handles system service enablement and greeter assets in one place.
# Adjust greeter behaviour here instead of host-specific tweaks.
# ==============================================================================

{ lib, config, inputs, pkgs, ... }:
let
  cfg = config.my.greeter.dms or { enable = false; };
  user = config.my.user.name or "kenan";
  compositorCmd =
    if cfg.compositor == "hyprland"
    then "${pkgs.hyprland}/bin/start-hyprland"
    else cfg.compositor;
in {
  imports = [ inputs.dankMaterialShell.nixosModules.greeter ];

  options.my.greeter.dms = {
    enable = lib.mkEnableOption "DMS Greeter via greetd";

    compositor = lib.mkOption {
      type = lib.types.str;
      default = "hyprland";
      description = "Compositor command/name passed to dms-greeter (e.g., hyprland, start-hyprland).";
    };

    layout = lib.mkOption {
      type = lib.types.str;
      default = "tr";
      description = "Keyboard layout passed to greetd (XKB_DEFAULT_LAYOUT).";
    };

    variant = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Keyboard layout variant passed to greetd (XKB_DEFAULT_VARIANT). Leave empty to skip.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Prefer greetd over GDM
    services.displayManager.gdm.enable = lib.mkForce false;
    services.greetd.enable = true;

    programs.dankMaterialShell.greeter = {
      enable = true;
      compositor.name = cfg.compositor;
      configHome = "/home/${user}";
      logs = {
        save = true;
        path = "/var/log/greeter/dms-greeter.log";
      };
    };

    # Ensure greetd uses requested keyboard layout when invoking the greeter
    services.greetd.settings.default_session = lib.mkDefault {
      user = "greeter";
      command = "env XKB_DEFAULT_LAYOUT=${cfg.layout} dms-greeter --command ${compositorCmd}";
    };

    # Ensure log directory exists and is writable by greeter user
    systemd.tmpfiles.rules = [
      "d /var/log/greeter 0755 greeter greeter -"
      "f /var/log/greeter/dms-greeter.log 0664 greeter greeter -"
    ];
  };
}
