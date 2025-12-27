# modules/home/mangowc/default.nix
# ==============================================================================
# MangoWC (mango) Home Manager configuration
#
# This wraps upstream `wayland.windowManager.mango` module (from the mango
# flake) and generates a single `~/.config/mango/config.conf` from modular
# snippets (settings/binds/rules/monitors), similar to modules/home/niri.
# ==============================================================================
{ lib, pkgs, config, inputs, osConfig ? null, ... }:

let
  cfg = config.my.desktop.mangowc;
  system = pkgs.stdenv.hostPlatform.system;

  upstreamKeyboard =
    if osConfig != null && osConfig ? my && osConfig.my ? display && osConfig.my.display ? keyboard
    then osConfig.my.display.keyboard
    else null;

  keyboard = {
    layout =
      if cfg.keyboard.layout != null
      then cfg.keyboard.layout
      else if upstreamKeyboard != null
      then upstreamKeyboard.layout
      else "tr";
    variant =
      if cfg.keyboard.variant != null
      then cfg.keyboard.variant
      else if upstreamKeyboard != null
      then upstreamKeyboard.variant
      else "f";
    options =
      if cfg.keyboard.options != null
      then cfg.keyboard.options
      else if upstreamKeyboard != null
      then upstreamKeyboard.options
      else [ "ctrl:nocaps" ];
  };

  bins = {
    terminal = "${pkgs.kitty}/bin/kitty";
    clipse = "${pkgs.clipse}/bin/clipse";
    bluetoothToggle = "${config.home.profileDirectory}/bin/bluetooth_toggle";
    startKkenp = "${config.home.profileDirectory}/bin/start-kkenp";
    dms = "${config.home.profileDirectory}/bin/dms";
    wmWorkspace = "${config.home.profileDirectory}/bin/wm-workspace";
    semsumo = "${config.home.profileDirectory}/bin/semsumo";
    mangoSet = "${config.home.profileDirectory}/bin/mango-set";
  };

  settingsConfig = import ./settings.nix {
    inherit lib keyboard bins;
  };

  bindsConfig = import ./binds.nix {
    inherit lib bins;
    fusumaEnabled = config.my.user.fusuma.enable or false;
  };

  rulesConfig = import ./rules.nix { inherit lib; };
  monitorsConfig = import ./monitors.nix { inherit lib; };

in
{
  options.my.desktop.mangowc = {
    enable = lib.mkEnableOption "MangoWC (mango) compositor config";

    package = lib.mkOption {
      type = lib.types.package;
      default = inputs.mango.packages.${system}.mango;
      description = "Which mango package to use.";
    };

    enableHardwareConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable host-specific monitor/workspace rules snippet.";
    };

    hardwareConfig = lib.mkOption {
      type = lib.types.lines;
      default = monitorsConfig.hardwareDefault;
      description = "Extra Mango config lines for monitor rules (monitorrule=...).";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra Mango config lines appended at the end.";
    };

    keyboard = {
      layout = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "XKB layout (falls back to `my.display.keyboard.layout` when available).";
      };
      variant = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "XKB variant (falls back to `my.display.keyboard.variant` when available).";
      };
      options = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = "XKB options list (falls back to `my.display.keyboard.options` when available).";
      };
    };
  };

  imports = [
    inputs.mango.hmModules.mango
  ];

  config = lib.mkIf cfg.enable {
    wayland.windowManager.mango = {
      enable = true;
      package = cfg.package;
      settings = lib.concatStringsSep "\n" (
        [
          settingsConfig.main
          bindsConfig.core
          rulesConfig.rules
        ]
        ++ lib.optional cfg.enableHardwareConfig cfg.hardwareConfig
        ++ lib.optional (cfg.extraConfig != "") cfg.extraConfig
      );
    };

    # -------------------------------------------------------------------------
    # Systemd --user integration for Mango sessions
    #
    # This target is started by `mango-set session-start` from Mango's `exec-once`.
    # Services like DMS/Fusuma are bound to this target for compositor-only startup.
    # -------------------------------------------------------------------------
    systemd.user.targets.mango-session.Unit = {
      Wants = [
        "xdg-desktop-autostart.target"
        "dms.service"
      ];
      After = [ "dbus.service" ];
    };

    # Bootstrap: keep it short-running; don't block Mango startup.
    systemd.user.services.mango-init = {
      Unit = {
        Description = "Mango bootstrap (audio + layout)";
        Wants = [ "pipewire.service" "wireplumber.service" ];
        After = [ "mango-session.target" "pipewire.service" "wireplumber.service" ];
        PartOf = [ "mango-session.target" ];
      };
      Service = {
        Type = "oneshot";
        TimeoutStartSec = 60;
        RemainAfterExit = true;
        Environment = [
          "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
        ];
        ExecStart = "${pkgs.bash}/bin/bash -lc '/etc/profiles/per-user/%u/bin/mango-set init'";
      };
      Install = {
        WantedBy = [ "mango-session.target" ];
      };
    };
  };
}
