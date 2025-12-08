# modules/nixos/dms-greeter/default.nix
# ==============================================================================
# DMS Greeter (greetd) integration using DankMaterialShell aesthetics.
# Imports upstream module, disables GDM, and configures greetd command.
# ==============================================================================
{ lib, config, inputs, ... }:
let
  cfg = config.my.greeter.dms or { enable = false; };
  user = config.my.user.name or "kenan";
in {
  imports = [ inputs.dankMaterialShell.nixosModules.greeter ];

  options.my.greeter.dms = {
    enable = lib.mkEnableOption "DMS Greeter via greetd";

    compositor = lib.mkOption {
      type = lib.types.enum [ "hyprland" "niri" "sway" "mangowc" ];
      default = "hyprland";
      description = "Compositor used by dms-greeter.";
    };

    layout = lib.mkOption {
      type = lib.types.str;
      default = "tr";
      description = "Keyboard layout passed to greetd (XKB_DEFAULT_LAYOUT).";
    };

    variant = lib.mkOption {
      type = lib.types.str;
      default = "f";
      description = "Keyboard layout variant passed to greetd (XKB_DEFAULT_VARIANT).";
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
        path = "/var/log/dms-greeter.log";
      };
    };

    # Ensure greetd uses requested keyboard layout when invoking the greeter
    services.greetd.settings.default_session = lib.mkDefault {
      user = "greeter";
      command = "env XKB_DEFAULT_LAYOUT=${cfg.layout} XKB_DEFAULT_VARIANT=${cfg.variant} dms-greeter --command ${cfg.compositor}";
    };
  };
}
