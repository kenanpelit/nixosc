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
#   programs.walker = {
#     enable = true;
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
    mdDoc;
    
  cfg = config.programs.walker;
  
  # TOML format generator for type-safe configuration
  tomlFormat = pkgs.formats.toml { };
  
  # Helper type for provider prefixes
  prefixType = types.submodule {
    options = {
      prefix = mkOption {
        type = types.str;
        example = ">";
        description = mdDoc "Prefix character to trigger this provider";
      };
      provider = mkOption {
        type = types.str;
        example = "runner";
        description = mdDoc "Provider name to activate";
      };
    };
  };
  
  # Helper type for action bindings
  actionType = types.submodule {
    options = {
      action = mkOption {
        type = types.str;
        example = "run";
        description = mdDoc "Action identifier";
      };
      bind = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Return";
        description = mdDoc "Keybinding for this action (default: Return)";
      };
      label = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "Run in terminal";
        description = mdDoc "Display label (defaults to action name)";
      };
      default = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether this is the default action";
      };
      after = mkOption {
        type = types.nullOr (types.enum [
          "KeepOpen" 
          "Close" 
          "Nothing" 
          "Reload" 
          "ClearReload" 
          "AsyncClearReload" 
          "AsyncReload"
        ]);
        default = null;
        example = "Close";
        description = mdDoc "Behavior after action execution (default: Close)";
      };
    };
  };
  
in
{
  options.programs.walker = {
    enable = mkEnableOption (mdDoc "Walker application launcher");

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
          # ====================================================================
          # General Behavior
          # ====================================================================
          
          # Force keyboard focus to stay in Walker
          force_keyboard_focus = true;
          
          # Invoking Walker while it's already open will close it
          close_when_open = true;
          
          # Clicking outside the main box will close Walker
          click_to_close = true;
          
          # Wrap selection at the end of the list
          selection_wrap = false;
          
          # Disable mouse interaction (except drag & drop from preview)
          disable_mouse = false;
          
          # Enable debug printing for troubleshooting
          debug = false;
          
          # Theme to use (must exist in ~/.config/walker/themes/)
          theme = "catppuccin";
          
          # ====================================================================
          # Search Configuration
          # ====================================================================
          
          # Delimiter for passing arguments to Elephant backend
          # Usage: "query#arg" sends "arg" as argument to the provider
          global_argument_delimiter = "#";
          
          # Prefix for exact search (disables fuzzy matching)
          # Usage: "'query" performs exact match instead of fuzzy search
          exact_search_prefix = "'";
          
          # ====================================================================
          # Navigation (v2.7.2+)
          # ====================================================================
          
          # Number of items to jump when using Page Up/Down
          # Default: 10
          page_jump_size = 10;
          
          # ====================================================================
          # Window Positioning (Wayland Layer Shell)
          # ====================================================================
          
          shell = {
            # Anchor window to screen edges
            # These determine where the window appears on screen
            anchor_top = true;
            anchor_bottom = false;
            anchor_left = false;
            anchor_right = false;
          };
          
          # ====================================================================
          # Placeholder Text
          # ====================================================================
          
          # Customize placeholder text per provider or globally
          placeholders = {
            # Default placeholders for all providers
            default = {
              input = "Search...";
              list = "No Results";
            };
            
            # Provider-specific placeholders
            desktopapplications = {
              input = "Launch Application";
              list = "No Applications Found";
            };
          };
          
          # ====================================================================
          # Provider Configuration
          # ====================================================================
          
          providers = {
            # Providers queried by default when searching
            # Note: v2.7.1 removed "menus" from defaults - add manually if needed
            default = [
              "desktopapplications"  # Desktop applications (.desktop files)
              "calc"                 # Calculator
              "runner"               # Shell command execution
              "websearch"            # Web search engines
            ];
            
            # Providers shown when input is empty
            empty = ["desktopapplications"];
            
            # Providers that display file previews
            previews = ["files" "menus"];
            
            # Global maximum results across all providers
            max_results = 50;
            
            # Per-provider result limits
            # Allows fine-tuning results per provider
            max_results_provider = {
              desktopapplications = 10;
              files = 20;
              runner = 15;
            };
            
            # Prefix shortcuts for direct provider access
            # Type the prefix to query only that provider
            prefixes = [
              { prefix = ">"; provider = "runner"; }
              { prefix = "/"; provider = "files"; }
              { prefix = "?"; provider = "websearch"; }
              { prefix = "="; provider = "calc"; }
            ];
            
            # Named provider sets
            # Launch with: walker -s <set_name>
            # Overrides the default provider configuration
            sets = {
              # Example: Productivity-focused set
              productivity = {
                default = ["desktopapplications" "files" "clipboard"];
                empty = ["desktopapplications"];
              };
              
              # Example: System management set
              system = {
                default = ["runner" "menus:system"];
                empty = ["menus:system"];
              };
            };
            
            # Action keybindings per provider
            # Configure multiple actions per provider
            actions = {
              # Runner provider actions
              runner = [
                { 
                  action = "run";
                  default = true;
                  bind = "Return";
                  after = "Close";
                }
                { 
                  action = "runterminal";
                  label = "Run in Terminal";
                  bind = "shift Return";
                  after = "Close";
                }
              ];
              
              # Fallback actions for multiple providers
              # These apply to providers that support these actions
              fallback = [
                { 
                  action = "menus:open";
                  label = "Open";
                  after = "Nothing";
                }
                { 
                  action = "erase_history";
                  label = "Clear History";
                  bind = "ctrl h";
                  after = "AsyncReload";
                }
              ];
            };
          };
          
          # ====================================================================
          # Global Keybindings
          # ====================================================================
          
          # Close Walker
          close = ["Escape"];
          
          # Navigate to next item (multiple bindings supported)
          next = ["Down" "ctrl n" "ctrl j"];
          
          # Navigate to previous item
          previous = ["Up" "ctrl p" "ctrl k"];
          
          # Toggle exact search mode
          toggle_exact = ["ctrl e"];
          
          # Resume last query
          resume_last_query = ["ctrl r"];
          
          # Quick activate (activate without closing)
          quick_activate = ["ctrl Return"];
          
          # Page navigation (v2.7.2+)
          # Jump by page_jump_size items
          page_up = ["Page_Up"];
          page_down = ["Page_Down"];
        }
      '';
      description = mdDoc ''
        Configuration written to {file}`$XDG_CONFIG_HOME/walker/config.toml`.
        
        Walker uses TOML format for configuration. The configuration controls:
        
        - **General behavior**: Focus, closing, mouse interaction
        - **Providers**: Which search backends to use (apps, files, calculator, etc.)
        - **Keybindings**: Global shortcuts and per-provider actions
        - **Theming**: GTK4 theme selection
        - **Custom menus**: Via Elephant backend integration
        - **Navigation**: Page jumping and selection wrapping (v2.7.2+)
        
        ## Key Concepts
        
        ### Providers
        Walker queries different "providers" for results:
        
        - **desktopapplications**: Desktop apps from .desktop files
        - **runner**: Shell command execution
        - **files**: File system search
        - **calc**: Calculator with math expression support
        - **clipboard**: Clipboard history manager
        - **websearch**: Web search engines
        - **menus:<name>**: Custom static or dynamic menus
        
        ### Provider Sets
        Create named configurations with `providers.sets.<name>` and launch
        with `walker -s <name>` to override the default provider list.
        
        Example: `walker -s productivity` uses only productivity-focused providers.
        
        ### Prefixes
        Type a prefix character (e.g., `>`) to directly target a specific provider,
        bypassing the default provider list and searching only that provider.
        
        Example: `> firefox` searches only the runner provider.
        
        ### Actions
        Each provider can have multiple actions with different keybindings.
        For example, the runner provider can "run" (Return) or "run in terminal"
        (Shift+Return).
        
        Configure keybindings in `providers.actions.<provider>`.
        
        ### Action Behaviors (after)
        
        - **KeepOpen**: Activate item and select next (useful for batch operations)
        - **Close**: Close Walker after activation (default)
        - **Nothing**: Just activate, don't change UI state
        - **Reload**: Reload with current query
        - **ClearReload**: Clear query and reload
        - **AsyncClearReload**: Backend triggers reload after clearing
        - **AsyncReload**: Backend triggers reload with current query
        
        ### Special Actions
        
        - **provider:<name>**: Switch to a given provider
        - **set:<name>**: Switch to a given provider set
        
        ### Custom Menus
        
        Walker integrates with Elephant backend to provide custom menus:
        
        **Static Menus** (TOML):
        ```toml
        name = "bookmarks"
        icon = "bookmark"
        action = "xdg-open %VALUE%"
        
        [[entries]]
        text = "GitHub"
        value = "https://github.com"
        ```
        
        **Dynamic Menus** (Lua):
        ```lua
        function GetEntries()
          local entries = {}
          -- Generate entries dynamically
          return entries
        end
        ```
        
        Place custom menus in `~/.config/elephant/menus/`.
        Reference them as `menus:<name>` in provider configuration.
        
        Run `elephant generatedoc` for complete provider documentation.
        
        ## Recent Changes
        
        ### v2.7.2 (Latest)
        
        - Added Page Up/Down navigation with configurable jump size
        - Fixed uuctl force-closing twice on ESC
        
        ### v2.7.1
        
        - Moved custom menus out of default provider list
        - Add `"menus"` to `providers.default` manually if needed
        
        ## Theme Structure
        
        Custom themes are placed in `~/.config/walker/themes/<theme>/`:
        
        - **style.css**: GTK4 CSS styling (hot-reloadable, no restart needed)
        - **layout.xml**: Main window layout (requires restart)
        - **keybind.xml**: Keybinding display (requires restart)
        - **preview.xml**: Preview pane layout (requires restart)
        - **item_<provider>.xml**: Per-provider item template (requires restart)
        
        Reference default theme for examples:
        <https://github.com/abenz1267/walker/tree/master/resources/themes/default>
        
        ## Targeting Custom Menus
        
        List all available providers including custom menus:
        ```bash
        elephant listproviders
        ```
        
        Output format: `<Pretty Name>;<Actual Name>`
        ```
        Bookmarks;menus:bookmarks
        System;menus:system
        ```
        
        Use the actual name (e.g., `menus:bookmarks`) when referencing in configuration.
        
        ## Complete Documentation
        
        - Walker: <https://github.com/abenz1267/walker>
        - Elephant: <https://github.com/abenz1267/elephant>
        - GTK4 Theming: <https://docs.gtk.org/gtk4/>
        - Provider docs: Run `elephant generatedoc`
      '';
    };
  };

  config = mkIf cfg.enable {
    # Install Walker package
    home.packages = [ cfg.package ];

    # Generate configuration file only if settings are provided
    # This prevents creating unnecessary empty config files
    xdg.configFile."walker/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "walker-config.toml" cfg.settings;
    };
    
    # Note: Walker expects Elephant backend to be available in PATH
    # Elephant is typically included with Walker or installed separately
    
    # Custom themes should be placed in ~/.config/walker/themes/<theme>/
    # Theme structure:
    #   - style.css           (GTK4 CSS - hot-reloadable)
    #   - layout.xml          (Main window - requires restart)
    #   - keybind.xml         (Keybindings - requires restart)
    #   - preview.xml         (Preview pane - requires restart)
    #   - item_<provider>.xml (Item templates - requires restart)
    
    # Custom menus (Elephant) should be placed in:
    #   ~/.config/elephant/menus/<name>.toml    (Static menus)
    #   ~/.config/elephant/scripts/<name>.lua   (Dynamic menus)
  };
}

