# modules/home/hyprland/default.nix
# ==============================================================================
# Home module for Hyprland user config: binds, env, plugins, extras.
# Manages compositor settings via Home Manager instead of loose dotfiles.
#
# Refactored for better modularity:
# - binds.nix, rules.nix, settings.nix, variables.nix
# ==============================================================================

{ inputs, lib, config, pkgs, ... }:
let
  cfg = config.my.desktop.hyprland;
  
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
    # Base Hyprland home-manager module
    inputs.hyprland.homeManagerModules.default
    
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

        # Source external configs (DMS Cursor)
        source = [ "./dms/cursor.conf" ];

        # Core Settings
        inherit (settings) 
          exec-once monitor workspace input gestures general 
          cursor group decoration animations misc dwindle master;

        # Binds (from settings.nix for general bind settings)
        binds = settings.binds;

        # Key Bindings
        bind = binds.bind;
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
    
    # Placeholder for DMS cursor config
    xdg.configFile."hypr/dms/cursor.conf".text = "";
  };
}
