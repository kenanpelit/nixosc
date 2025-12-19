# modules/home/niri/default.nix
# ==============================================================================
# Niri Compositor Configuration - Optimized for DankMaterialShell (DMS)
#
# Design goals:
# - Keep Niri config modular (KDL snippets under ~/.config/niri/dms/)
# - Avoid duplicate keybinds inside a single `binds {}` block (hard error).
#
# Refactored:
# - Logic split into binds.nix, rules.nix, settings.nix
# ==============================================================================
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.my.desktop.niri;
  
  # ---------------------------------------------------------------------------
  # Theme & Palette
  # ---------------------------------------------------------------------------
  catppuccin =
    if config ? catppuccin
    then config.catppuccin
    else { flavor = "mocha"; accent = "mauve"; };
  flavor = catppuccin.flavor or "mocha";
  accent = catppuccin.accent or "mauve";
  gtkTheme = "catppuccin-${flavor}-${accent}-standard+normal";
  cursorTheme = "catppuccin-${flavor}-dark-cursors";
  iconTheme =
    if config ? gtk && config.gtk ? iconTheme && config.gtk.iconTheme ? name
    then config.gtk.iconTheme.name
    else "a-candy-beauty-icon-theme";

  palette = {
    cyan = "#74c7ec";
    sky = "#89dceb";
    mauve = "#cba6f7";
    red = "#f38ba8";

    surface0 = "#313244";
    surface1 = "#45475a";

    skyA80 = "#89dceb80";
    mauveA80 = "#cba6f780";
    mauveFF = "#cba6f7ff";
    redFF = "#f38ba8ff";
  };

  # ---------------------------------------------------------------------------
  # Binary Paths & Features
  # ---------------------------------------------------------------------------
  enableNiriusBinds = true;

  bins = {
    kitty = "${pkgs.kitty}/bin/kitty";
    dms = "${config.home.profileDirectory}/bin/dms";
    niriLock = "${config.home.profileDirectory}/bin/niri-lock";
    clipse = "${pkgs.clipse}/bin/clipse";
    niriusd = "${pkgs.nirius}/bin/niriusd";
    nirius  = "${pkgs.nirius}/bin/nirius";
    niriuswitcher = "${pkgs.niriswitcher}/bin/niriswitcher";
    nsticky = "${inputs.nsticky.packages.${pkgs.stdenv.hostPlatform.system}.nsticky}/bin/nsticky";
  };

  # ---------------------------------------------------------------------------
  # Imports
  # ---------------------------------------------------------------------------
  # inputs.niri.homeModules.niri is now imported globally via flake.nix sharedModules
  imports = [
  ];

  bindsConfig = import ./binds.nix {
    inherit lib pkgs bins enableNiriusBinds;
  };

  rulesConfig = import ./rules.nix {
    inherit lib config pkgs;
  };

  settingsConfig = import ./settings.nix {
    inherit lib config pkgs palette gtkTheme cursorTheme iconTheme;
  };

in
{
  options.my.desktop.niri = {
    enable = lib.mkEnableOption "Niri compositor (Wayland) configuration";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.niri-unstable;
      description = "Niri compositor package";
    };

    enableNirius = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install nirius daemon and CLI helpers";
    };

    enableNiriswitcher = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install niriswitcher application switcher";
    };

    enableHardwareConfig = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable static output/workspace pinning (host-specific)";
    };

    enableGamingVrrRules = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable VRR window rules for common game launchers (gamescope/steam)";
    };

    hardwareConfig = lib.mkOption {
      type = lib.types.lines;
      default = settingsConfig.hardwareDefault;
      description = "Niri KDL snippet for outputs/workspaces";
    };
  };

  config = lib.mkIf cfg.enable {
    # Niri module from flake handles package installation via `programs.niri.package`
    programs.niri.enable = true;
    programs.niri.package = cfg.package;
    
    # Use programs.niri.config for build-time validation!
    # We concatenate all parts into one big KDL string to avoid 'include' issues during validation.
    programs.niri.config = lib.concatStringsSep "\n" [
      settingsConfig.main
      (if cfg.enableHardwareConfig then cfg.hardwareConfig else "")
      settingsConfig.layout
      
      # Bindings must be inside a SINGLE `binds {}` block.
      "binds {"
      bindsConfig.core
      bindsConfig.dms
      bindsConfig.apps
      bindsConfig.mpv
      bindsConfig.workspaces
      bindsConfig.monitors
      "}"

      rulesConfig.rules
      settingsConfig.animations
      settingsConfig.gestures
      settingsConfig.recentWindows
      settingsConfig.colors
    ];

    home.packages =
      lib.optional cfg.enableNirius pkgs.nirius
      ++ lib.optional cfg.enableNiriswitcher pkgs.niriswitcher
      ++ [
        pkgs.clipse
        inputs.nsticky.packages.${pkgs.stdenv.hostPlatform.system}.nsticky
      ]
      ++ lib.optional (builtins.hasAttr "xwayland-satellite" pkgs) pkgs."xwayland-satellite";

    # Helper file for niri-arrange-windows script (still needs to be a file)
    xdg.configFile."niri/dms/workspace-rules.tsv".text = rulesConfig.arrangeRulesTsv;
    
    # Deprecated placeholder (kept to avoid stale references)
    xdg.configFile."niri/dms/alttab.kdl".text = "";

    # -------------------------------------------------------------------------
    # Systemd --user integration for Niri sessions
    # -------------------------------------------------------------------------

    systemd.user.targets.niri-session.Unit = {
      Description = "Niri session (user services)";
      Wants = [
        "xdg-desktop-autostart.target"
        "dms.service"
      ];
      After = [ "dbus.service" "dms.service" ];
    };

    systemd.user.services.niri-init = {
      Unit = {
        Description = "Niri session bootstrap (monitors + audio + layout)";
        After = [ "niri-session.target" "dms.service" ];
        PartOf = [ "niri-session.target" ];
      };
      Service = {
        Type = "oneshot";
        TimeoutStartSec = 15;
        ExecStart = "${pkgs.bash}/bin/bash -lc 'for ((i=0;i<120;i++)); do niri msg version >/dev/null 2>&1 && break; sleep 0.1; done; niri-init'";
      };
      Install = {
        WantedBy = [ "niri-session.target" ];
      };
    };

    systemd.user.services.nsticky = {
      Unit = {
        Description = "nsticky daemon (niri)";
        After = [ "niri-session.target" ];
        PartOf = [ "niri-session.target" ];
      };
      Service = {
        ExecStart = "${bins.nsticky}";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {
        WantedBy = [ "niri-session.target" ];
      };
    };

    systemd.user.services.niriusd = lib.mkIf cfg.enableNirius {
      Unit = {
        Description = "nirius daemon (niri)";
        After = [ "niri-session.target" ];
        PartOf = [ "niri-session.target" ];
      };
      Service = {
        ExecStart = "${bins.niriusd}";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {
        WantedBy = [ "niri-session.target" ];
      };
    };

    systemd.user.services.niriswitcher = lib.mkIf cfg.enableNiriswitcher {
      Unit = {
        Description = "niriswitcher (niri)";
        After = [ "niri-session.target" ];
        PartOf = [ "niri-session.target" ];
      };
      Service = {
        ExecStart = "${bins.niriuswitcher}";
        Restart = "on-failure";
        RestartSec = 1;
      };
      Install = {
        WantedBy = [ "niri-session.target" ];
      };
    };
  };
}
