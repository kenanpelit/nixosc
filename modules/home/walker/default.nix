# modules/home/walker/default.nix
#
# Home Manager module for Walker - A fast application launcher for Wayland
#
# Walker is a keyboard-driven application launcher with fuzzy search capabilities,
# designed for modern Wayland compositors. It works together with Elephant backend
# to provide quick access to applications, files, custom menus, and more.
#
# Features:
#   - Fast fuzzy and exact search with configurable algorithms
#   - Multiple providers (applications, files, clipboard, calculator, websearch)
#   - Custom menus with static or dynamic (Lua) content
#   - Themeable UI with GTK4 and CSS support
#   - Flexible keybindings and multi-action support
#   - Page navigation with configurable jump size (v2.7.2+)
#   - Low resource usage and quick startup times
#
# Architecture:
#   Walker (Frontend - GTK4 UI) ←→ Elephant (Backend - Provider engine)
#
# Version Information:
#   - Recommended: v2.7.2+ (from GitHub flake input)
#   - Nixpkgs version: 0.12.21 (outdated, not recommended)
#
# Usage:
#   # Automatically enabled when imported in modules/home/default.nix
#   # To disable: programs.walker.enable = false;
#   
#   # To configure:
#   programs.walker = {
#     runAsService = true;  # Run as systemd service (recommended)
#     settings = {
#       force_keyboard_focus = true;
#       theme = "catppuccin";
#       page_jump_size = 10;  # v2.7.2: Page Up/Down navigation
#       providers = {
#         default = ["desktopapplications" "calc" "runner"];
#         prefixes = [
#           { prefix = ">"; provider = "runner"; }
#         ];
#       };
#     };
#   };
#
# References:
#   - Walker (Frontend): https://github.com/abenz1267/walker
#   - Elephant (Backend): https://github.com/abenz1267/elephant
#   - GTK4 Theming: https://docs.gtk.org/gtk4/
#   - Latest Release: https://github.com/abenz1267/walker/releases

{ config, lib, pkgs, inputs, ... }:

let
  inherit (lib) 
    mkEnableOption 
    mkOption 
    mkIf 
    types 
    literalExpression
    mdDoc
    mkDefault;
    
  cfg = config.programs.walker;
  
  # TOML format generator for type-safe configuration
  tomlFormat = pkgs.formats.toml { };
  
  # Get elephant package
  elephantPkg = if inputs ? elephant 
                then inputs.elephant.packages.${pkgs.system}.elephant-with-providers
                else throw "Elephant backend is required but not found in flake inputs";
  
in
{
  options.programs.walker = {
    # Enable by default when module is imported
    # Can be disabled with: programs.walker.enable = false;
    enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = mdDoc ''
        Whether to enable Walker application launcher.
        
        Enabled by default when the module is imported.
        Set to `false` to disable if needed.
      '';
    };

    runAsService = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = mdDoc ''
        Whether to run Walker and Elephant as systemd user services.
        
        When enabled:
        - Elephant backend runs automatically on login
        - Walker runs as a D-Bus activated service for faster startup
        - Services restart automatically on failure
        
        Recommended: `true` for best performance and reliability.
        
        Manual control:
        ```bash
        systemctl --user status elephant walker
        systemctl --user restart elephant walker
        ```
      '';
    };

    package = mkOption {
      type = types.package;
      # Default to GitHub flake input if available, fallback to nixpkgs
      default = if inputs ? walker 
                then inputs.walker.packages.${pkgs.system}.default 
                else pkgs.walker;
      defaultText = literalExpression "inputs.walker.packages.\${pkgs.system}.default";
      description = mdDoc ''
        Walker package to use.
        
        **Recommended**: Use the flake input for latest version (v2.7.2+)
        
        Add to your flake.nix:
        ```nix
        inputs.walker = {
          url = "github:abenz1267/walker/v2.7.2";
          inputs.nixpkgs.follows = "nixpkgs";
        };
        ```
        
        **Note**: nixpkgs version (0.12.21) is significantly outdated and
        missing many features. Using the flake input is strongly recommended.
      '';
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          # General behavior
          force_keyboard_focus = true;
          theme = "catppuccin";
          page_jump_size = 10;
          
          # Providers
          providers = {
            default = ["desktopapplications" "calc" "runner" "websearch"];
            empty = ["desktopapplications"];
            
            # Prefix shortcuts
            prefixes = [
              { prefix = ">"; provider = "runner"; }
              { prefix = "/"; provider = "files"; }
              { prefix = "="; provider = "calc"; }
              { prefix = "?"; provider = "websearch"; }
              { prefix = ":"; provider = "clipboard"; }
            ];
          };
          
          # Global keybindings
          close = ["Escape"];
          next = ["Down" "ctrl n" "ctrl j"];
          previous = ["Up" "ctrl p" "ctrl k"];
        }
      '';
      description = mdDoc ''
        Configuration written to {file}`$XDG_CONFIG_HOME/walker/config.toml`.
        
        For complete documentation, see the module's comprehensive examples
        or visit: <https://github.com/abenz1267/walker>
      '';
    };
  };

  config = mkIf cfg.enable {
    # Install Walker and Elephant packages
    home.packages = [ 
      cfg.package
      elephantPkg
    ];

    # Elephant provider directory with automatic provider installation
    # Providers MUST be in ~/.config/elephant/providers/ (documented requirement)
    home.file.".config/elephant/providers" = {
      source = "${elephantPkg}/lib/elephant/providers";
      recursive = true;
    };

    # Elephant systemd service with proper configuration
    # Note: We create our own service file instead of using 'elephant service enable'
    # because that creates a service with relative path that doesn't work in systemd
    systemd.user.services.elephant = mkIf cfg.runAsService {
      Unit = {
        Description = "Elephant - Backend provider for Walker";
        Documentation = "https://github.com/abenz1267/elephant";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${elephantPkg}/bin/elephant";
        Restart = "on-failure";
        RestartSec = 5;
        TimeoutStopSec = 10;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # Walker systemd service - Frontend launcher
    systemd.user.services.walker = mkIf cfg.runAsService {
      Unit = {
        Description = "Walker - Application launcher";
        Documentation = "https://github.com/abenz1267/walker";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" "elephant.service" ];
        # Walker REQUIRES Elephant to be running
        Requires = [ "elephant.service" ];
      };

      Service = {
        Type = "dbus";
        BusName = "io.github.abenz1267.walker";
        ExecStart = "${cfg.package}/bin/walker --gapplication-service";
        Restart = "on-failure";
        RestartSec = 3;
        # Ensure clean shutdown
        TimeoutStopSec = 10;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # Generate configuration file
    xdg.configFile."walker/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "walker-config.toml" cfg.settings;
    };

    # D-Bus service file for Walker (REQUIRED for --gapplication-service)
    # This allows Walker to be D-Bus activated
    xdg.dataFile."dbus-1/services/io.github.abenz1267.walker.service".text = ''
      [D-BUS Service]
      Name=io.github.abenz1267.walker
      Exec=${cfg.package}/bin/walker --gapplication-service
      SystemdService=walker.service
    '';
    
    # Note: Walker uses bus name 'io.github.abenz1267.walker'
    # Alternative bus name 'dev.benz.walker' is legacy and not needed
    
    # Usage instructions via activation script
    home.activation.walkerInfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      ${pkgs.coreutils}/bin/cat << 'EOF'
      
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      Walker Application Launcher
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      
      ${if cfg.runAsService then ''
      ✓ Running as systemd service (recommended)
      
      Service Management:
        systemctl --user status elephant walker
        systemctl --user restart elephant walker
        systemctl --user stop elephant walker
        
      Launch Walker:
        walker                                    # Standard launch
        nc -U /run/user/$UID/walker/walker.sock  # Fast socket launch
      '' else ''
      ⚠ Not running as service
      
      Manual Start:
        elephant service &  # Start backend first
        walker              # Then start frontend
      ''}
      
      Configuration:
        ~/.config/walker/config.toml              # Main config
        ~/.config/elephant/menus/                 # Custom menus
        
      Documentation:
        Walker:   https://github.com/abenz1267/walker
        Elephant: https://github.com/abenz1267/elephant
        
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      EOF
    '';
  };
}

