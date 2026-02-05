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
