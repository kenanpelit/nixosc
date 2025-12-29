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
  username = config.home.username;
  btEnabled = config.my.user.bt.enable or false;
  scriptsEnabled = config.my.user.scripts.enable or false;
  
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
    #cyan = "#74c7ec";
    cyan = "#00BCD4";
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
    niriSet = "${config.home.profileDirectory}/bin/niri-set";
    clipse = "${pkgs.clipse}/bin/clipse";
    niriusd = "${pkgs.nirius}/bin/niriusd";
    nirius  = "${pkgs.nirius}/bin/nirius";
    niriuswitcher = "${pkgs.niriswitcher}/bin/niriswitcher";
    nsticky = "${inputs.nsticky.packages.${pkgs.stdenv.hostPlatform.system}.nsticky}/bin/nsticky";
  };

  # ---------------------------------------------------------------------------
  # Imports
  # ---------------------------------------------------------------------------
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
  imports = [
    inputs.niri.homeModules.niri
  ];

  options.my.desktop.niri = {
    enable = lib.mkEnableOption "Niri compositor (Wayland) configuration";

    initDelaySeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3;
      description = "Delay (in seconds) before running niri-init after session start.";
    };

    btAutoConnectDelaySeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5;
      description = "Delay (in seconds) before running Bluetooth auto-connect in Niri sessions.";
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
    programs.niri.package = pkgs.niri-unstable;
    
    # Use programs.niri.config for build-time validation!
    # We concatenate all parts into one big KDL string to avoid 'include' issues during validation.
    programs.niri.config = lib.concatStringsSep "\n" [
      settingsConfig.main
      (if cfg.enableHardwareConfig then cfg.hardwareConfig else "")
      settingsConfig.layout
      
      # Bindings must be inside a SINGLE `binds {}` block.
      "binds {"
      bindsConfig.core
      bindsConfig.nirius
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
      ];
      After = [ "dbus.service" ];
    };

    # Bootstrap: fast and observable (oneshot).
    # Keep this unit short-running; move slow/flaky tasks (like BT audio routing)
    # into separate services/timers so startup doesn't appear "stuck".
    systemd.user.services.niri-init = {
      Unit = {
        Description = "Niri bootstrap (monitors + audio + layout)";
        Wants = [ "pipewire.service" "wireplumber.service" ];
        After = [ "niri-session.target" "pipewire.service" "wireplumber.service" ];
        PartOf = [ "niri-session.target" ];
      };
      Service = {
        Type = "oneshot";
        TimeoutStartSec = 60;
        RemainAfterExit = true;
        Environment = [
          "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
        ];
        ExecStart = "${pkgs.bash}/bin/bash -lc 'sleep ${toString cfg.initDelaySeconds}; for ((i=0;i<120;i++)); do /etc/profiles/per-user/${username}/bin/niri msg version >/dev/null 2>&1 && break; sleep 0.1; done; /etc/profiles/per-user/${username}/bin/niri-set init'";
        ExecStartPost = "${pkgs.bash}/bin/bash -lc 'command -v notify-send >/dev/null 2>&1 && notify-send -t 2500 \"Niri\" \"Bootstrap tamamlandı\" || true'";
      };
      Install = {
        WantedBy = [ "niri-session.target" ];
      };
    };

    # Bluetooth auto-connect: run later via timer; never block the init unit.
    systemd.user.services.niri-bt-autoconnect = lib.mkIf (btEnabled && scriptsEnabled) {
      Unit = {
        Description = "Niri Bluetooth auto-connect";
        Wants = [ "pipewire.service" "wireplumber.service" ];
        After = [ "niri-session.target" "pipewire.service" "wireplumber.service" "niri-init.service" ];
        PartOf = [ "niri-session.target" ];
      };
      Service = {
        Type = "oneshot";
        TimeoutStartSec = "${toString config.my.user.bt.autoToggle.timeoutSeconds}s";
        Environment = [
          "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/%u/bin"
        ];
        ExecStart = "${pkgs.bash}/bin/bash -lc '/etc/profiles/per-user/${username}/bin/bluetooth_toggle --connect'";
        Restart = "on-failure";
        RestartSec = 10;
      };
    };

    systemd.user.timers.niri-bt-autoconnect = lib.mkIf (btEnabled && scriptsEnabled) {
      Unit = {
        Description = "Niri Bluetooth auto-connect (delayed)";
        After = [ "niri-session.target" ];
        PartOf = [ "niri-session.target" ];
      };
      Timer = {
        OnActiveSec = "${toString cfg.btAutoConnectDelaySeconds}s";
        AccuracySec = "5s";
        Unit = "niri-bt-autoconnect.service";
      };
      Install = {
        WantedBy = [ "niri-session.target" ];
      };
    };

    systemd.user.services.niri-nsticky = {
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

    systemd.user.services.niri-niriusd = lib.mkIf cfg.enableNirius {
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

    systemd.user.services.niri-niriswitcher = lib.mkIf cfg.enableNiriswitcher {
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
