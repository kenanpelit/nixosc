# modules/home/hyprland/default.nix
# ==============================================================================
# Home module for Hyprland user config: binds, env, plugins, extras.
# Manages compositor settings via Home Manager instead of loose dotfiles.
#
# Refactored for better modularity:
# - binds.nix, rules.nix, settings.nix, variables.nix
# ==============================================================================

{ lib, config, pkgs, ... }:
let
  cfg = config.my.desktop.hyprland;
  hmLib = lib.hm or config.lib;
  dag = hmLib.dag or config.lib.dag;

  defaultHyprlandPackage =
    if pkgs ? unstable && pkgs.unstable ? hyprland
    then pkgs.unstable.hyprland
    else pkgs.hyprland;

  defaultHyprscrollingPackage =
    if pkgs ? unstable && lib.hasAttrByPath [ "hyprlandPlugins" "hyprscrolling" ] pkgs.unstable
    then pkgs.unstable.hyprlandPlugins.hyprscrolling
    else if lib.hasAttrByPath [ "hyprlandPlugins" "hyprscrolling" ] pkgs
    then pkgs.hyprlandPlugins.hyprscrolling
    else null;

  defaultHyprexpoPackage =
    if pkgs ? unstable && lib.hasAttrByPath [ "hyprlandPlugins" "hyprexpo" ] pkgs.unstable
    then pkgs.unstable.hyprlandPlugins.hyprexpo
    else if lib.hasAttrByPath [ "hyprlandPlugins" "hyprexpo" ] pkgs
    then pkgs.hyprlandPlugins.hyprexpo
    else null;
  
  # Import modular configurations
  vars = import ./variables.nix { inherit config lib; };

  bins = {
    hyprSet = "${config.home.profileDirectory}/bin/hypr-set";
    screenshot = "${config.home.profileDirectory}/bin/screenshot";
    bluetoothToggle = "${config.home.profileDirectory}/bin/bluetooth_toggle";
    oscHereHypr = "${config.home.profileDirectory}/bin/osc-here-hypr";
  };
  
  settings = import ./settings.nix {
    inherit lib bins;
    inherit cfg;
    inherit (vars) mkColor colors activeBorder inactiveBorder inactiveGroupBorder cursorName cursorSize;
  };
  
  binds = import ./binds.nix { 
    inherit lib;
    inherit (vars) themeName;
    inherit bins;
  };
  
  rules = import ./rules.nix { };

in
{
  options.my.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultHyprlandPackage;
      defaultText = lib.literalExpression "pkgs.unstable.hyprland or pkgs.hyprland";
      description = "Hyprland package used by Home Manager.";
    };

    hyprscrollingPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = defaultHyprscrollingPackage;
      defaultText = lib.literalExpression "pkgs.unstable.hyprlandPlugins.hyprscrolling or pkgs.hyprlandPlugins.hyprscrolling";
      description = "Package for Hyprscrolling plugin.";
    };

    hyprexpoPackage = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = defaultHyprexpoPackage;
      defaultText = lib.literalExpression "pkgs.unstable.hyprlandPlugins.hyprexpo or pkgs.hyprlandPlugins.hyprexpo";
      description = "Package for Hyprexpo plugin.";
    };

    bootstrapDelaySeconds = lib.mkOption {
      type = lib.types.ints.between 0 30;
      default = 1;
      description = "Delay before `hypr-set init` runs in the Hyprland bootstrap service.";
    };

    inputNoAccel = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable pointer acceleration (`force_no_accel=1`, `accel_profile=flat`).";
    };

    renderDirectScanout = lib.mkOption {
      type = lib.types.bool;
      default = config.my.host.isPhysicalHost or false;
      defaultText = "config.my.host.isPhysicalHost";
      description = "Enable `render.direct_scanout` (can break overlays/screencast on some systems).";
    };

    useStaticMonitors = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use fixed monitor/workspace mapping (DP-3 top, eDP-1 bottom) instead of dynamic fallback.";
    };

    staticPrimaryMonitorDesc = lib.mkOption {
      type = lib.types.str;
      default = "DP-3";
      description = "Primary monitor identifier used when `useStaticMonitors=true`.";
    };

    staticSecondaryMonitorDesc = lib.mkOption {
      type = lib.types.str;
      default = "eDP-1";
      description = "Secondary monitor identifier used when `useStaticMonitors=true`.";
    };

    enableVerboseWlrLogs = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable verbose wlroots logs (`HYPRLAND_LOG_WLR=1`).";
    };

    disableRealtimeScheduling = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Set `HYPRLAND_NO_RT=1` for compatibility-first behavior.";
    };

    disableSdNotify = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set `HYPRLAND_NO_SD_NOTIFY=1`.";
    };

    suppressWatchdogWarning = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Set `HYPRLAND_NO_WATCHDOG_WARNING=1`.";
    };

    enablePyprlandExtendedPlugins = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable extended pyprland plugin set (expose/magnify/layout_center).";
    };
  };

  # Submodules are internally gated; import unconditionally
  imports = [
    # ---------------------------------------------------------------------------
    # Core Modules
    # ---------------------------------------------------------------------------
    # ---------------------------------------------------------------------------
    # Basic Configuration
    # ---------------------------------------------------------------------------
    ./hyprland.nix   # Main Hyprland configuration (systemd, package)
    ./hyprscrolling.nix # Hyprland plugin: scrolling layout
    ./hyprexpo.nix   # Hyprland plugin: workspace overview
    # ./config.nix   # REMOVED: Replaced by modular files below
    
    # ---------------------------------------------------------------------------
    # Extensions & Components 
    # ---------------------------------------------------------------------------
    # Idle/lock are handled by Stasis + DMS (see modules/home/stasis, modules/home/dms).
    ./pyprland.nix   # Python plugins
    ./keyring.nix    # Keyring
  ];

  config = lib.mkIf cfg.enable {
    wayland.windowManager.hyprland = {
      settings = {
        # Environment Variables
        env = vars.envVars;

        # Source external configs managed by DMS (runtime-generated).
        # These must be normal writable files (not Nix-store symlinks).
        source = [
          "./dms/outputs.conf"
          "./dms/cursor.conf"
        ];

        # Core Settings
        inherit (settings) 
          exec-once monitor workspace input gestures general 
          cursor group decoration animations misc dwindle master;

        # Binds (from settings.nix for general bind settings)
        binds = settings.binds;

        # Key Bindings
        bind = binds.bind;
        bindl = binds.bindl;
        bindm = binds.bindm;

        # Window & Layer Rules
        windowrule = 
          rules.coreRules ++ 
          rules.mediaRules ++ 
          rules.communicationRules ++ 
          rules.systemRules ++ 
          rules.workspaceRules ++ 
          rules.uiRules ++ 
          rules.dialogRules ++ 
          rules.miscRules;
        
        # Explicit empty gesture list (from original config)
        gesture = [ ];
      };

      extraConfig = binds.extraConfig;
    };

    # DMS writes Hyprland snippets at runtime (cursor.conf, outputs.conf, …).
    # Ensure they exist as regular writable files so DMS can `cat >` them.
    home.activation.hyprlandDmsRuntimeFiles = dag.entryAfter [ "writeBoundary" ] ''
      set -eu

      DMS_DIR=${lib.escapeShellArg "${config.xdg.configHome}/hypr/dms"}
      mkdir -p "$DMS_DIR"

      ensure_writable_file() {
        local f="$1"

        if [ -L "$f" ]; then
          rm -f "$f"
        elif [ -e "$f" ] && [ ! -f "$f" ]; then
          rm -rf "$f"
        fi

        if [ ! -f "$f" ]; then
          : >"$f"
        fi
      }

      ensure_writable_file "$DMS_DIR/cursor.conf"
      ensure_writable_file "$DMS_DIR/outputs.conf"
    '';
  };
}
