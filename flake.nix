# ==============================================================================
#  NixOS Configuration Flake Suite - nixosc v4.2.0
# ==============================================================================
#
#  Author:  Kenan Pelit
#  Repo:    https://github.com/kenanpelit/nixosc
#  License: MIT
#  Date:    2025-11-15
#
# ------------------------------------------------------------------------------
#  ARCHITECTURE OVERVIEW
# ------------------------------------------------------------------------------
#
#  INPUTS (External Dependencies)
#      │
#      ├─ nixpkgs ─────────┐
#      ├─ home-manager ────┤
#      ├─ hyprland ────────┤
#      └─ themes & tools ──┘
#              │
#              ▼
#  UNIFIED OVERLAY LAYER
#      • overlaysCommon       → Applied everywhere
#      • nixpkgsConfigCommon  → Central config
#              │
#      ┌───────┴────────┐
#      │                │
#      ▼                ▼
#  NIXOS SYSTEMS    HOME-MANAGER
#    • hay            • kenan@hay
#    • vhay           • kenan@vhay
#
#  Integrated Mode   Standalone Mode
#  nixos-rebuild     home-manager
#
# ------------------------------------------------------------------------------
#  KEY FEATURES
# ------------------------------------------------------------------------------
#
#  ✓ Unified Overlay Management    Single source of truth
#  ✓ Dual Home-Manager Modes        NixOS module + standalone
#  ✓ Central Configuration          No divergence
#  ✓ Modular Architecture           Host-aware, theme-enabled
#  ✓ Reproducible Builds            Pinned dependencies
#
# ==============================================================================

{
  description = "Kenan's NixOS Configuration - Full-stack system and home management";

  # ============================================================================
  #  INPUTS - External Dependencies
  # ============================================================================

  inputs = {
    
    # --------------------------------------------------------------------------
    #  CORE SYSTEM COMPONENTS
    # --------------------------------------------------------------------------
    
    nixpkgs = { 
      url = "github:NixOS/nixpkgs/nixos-unstable"; 
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    #  PACKAGE REPOSITORIES & EXTENSIONS
    # --------------------------------------------------------------------------
    
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    #  THEMING & AESTHETICS
    # --------------------------------------------------------------------------
    
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    #  HYPRLAND ECOSYSTEM
    # --------------------------------------------------------------------------
    
    hyprland = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hyprwm/hyprland/e584a8bade2617899d69ae6f83011d0c1d2a9df7"; # 1122 - Updated commit
#      url = "github:hyprwm/hyprland/b5a2ef77b7876798d33502f8de006f9c478c12db"; # 1121 - Updated commit
#      url = "github:hyprwm/hyprland/c249a9f4b8940d7356b756dc639f9cb18713e088"; # 1121 - Updated commit
#      url = "github:hyprwm/hyprland/f9d1da66678dbe645408aa8c6919d7debf88245d"; # 1120 - Updated commit
#      url = "github:hyprwm/hyprland/fbb31503f1b69402eeda81ba75a547c862c88bf2"; # 1119 - Updated commit
#      url = "github:hyprwm/hyprland/9f02dca8de5489689a7e31a2dfbf068c5dd3d282"; # 1119 - Updated Commits
    };
    
    # Hyprland dependencies
    hyprlang            = { url = "github:hyprwm/hyprlang";                      inputs.nixpkgs.follows = "nixpkgs"; };
    hyprutils           = { url = "github:hyprwm/hyprutils";                     inputs.nixpkgs.follows = "nixpkgs"; };
    hyprland-protocols  = { url = "github:hyprwm/hyprland-protocols";            inputs.nixpkgs.follows = "nixpkgs"; };
    xdph                = { url = "github:hyprwm/xdg-desktop-portal-hyprland";   inputs.nixpkgs.follows = "nixpkgs"; };
    hyprwayland-scanner = { url = "github:hyprwm/hyprwayland-scanner";           inputs.nixpkgs.follows = "nixpkgs"; };
    hyprcursor          = { url = "github:hyprwm/hyprcursor";                    inputs.nixpkgs.follows = "nixpkgs"; };
    hyprgraphics        = { url = "github:hyprwm/hyprgraphics";                  inputs.nixpkgs.follows = "nixpkgs"; };
    hyprland-qtutils    = { url = "github:hyprwm/hyprland-qtutils";              inputs.nixpkgs.follows = "nixpkgs"; };
    hyprland-plugins    = { url = "github:hyprwm/hyprland-plugins";              inputs.nixpkgs.follows = "nixpkgs"; };
    hypr-contrib        = { url = "github:hyprwm/contrib";                       inputs.nixpkgs.follows = "nixpkgs"; };
    hyprpicker          = { url = "github:hyprwm/hyprpicker";                    inputs.nixpkgs.follows = "nixpkgs"; };
    hyprmag             = { url = "github:SIMULATAN/hyprmag";                    inputs.nixpkgs.follows = "nixpkgs"; };

    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    #  DEVELOPMENT TOOLS
    # --------------------------------------------------------------------------
    
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems = {
      url = "github:nix-systems/default-linux";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    alejandra = { 
      url = "github:kamadorueda/alejandra"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };

    # --------------------------------------------------------------------------
    #  APPLICATIONS & INTEGRATIONS
    # --------------------------------------------------------------------------
    
    walker = {
      url = "github:abenz1267/walker/v2.11.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    elephant = {
      url = "github:abenz1267/elephant/v2.16.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  
    spicetify-nix = { 
      url = "github:gerg-l/spicetify-nix"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
    
    nix-flatpak = { 
      url = "github:gmodena/nix-flatpak"; 
    };
    
    zen-browser = { 
      url = "github:0xc000022070/zen-browser-flake"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
    
    browser-previews = { 
      url = "github:nix-community/browser-previews"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
    
    cachix-pkgs = { 
      url = "github:cachix/cachix"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };

    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    #  DATA SOURCES (Non-flake)
    # --------------------------------------------------------------------------
    
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  # ============================================================================
  #  OUTPUTS - System Configurations & Packages
  # ============================================================================
  
  outputs = { 
    nixpkgs, 
    self, 
    home-manager, 
    sops-nix, 
    distro-grub-themes, 
    poetry2nix, 
    systems, 
    pyprland,
    hyprland, 
    ... 
  }@inputs:
    let
      # ------------------------------------------------------------------------
      #  CONFIGURATION CONSTANTS
      # ------------------------------------------------------------------------
      
      username = "kenan";
      system   = "x86_64-linux";
      
      # Unified overlay list - applied consistently everywhere
      overlaysCommon = [
        inputs.nur.overlays.default
      ];
 
      # Central nixpkgs configuration
      nixpkgsConfigCommon = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "electron-36.9.5"
          "ventoy-1.1.07"
          "libsoup-2.74.3"
        ];
      };

      # Primary package set with overlays and config
      pkgs = import nixpkgs {
        inherit system;
        overlays = overlaysCommon;
        config   = nixpkgsConfigCommon;
      };

      lib = nixpkgs.lib;

      # ------------------------------------------------------------------------
      #  SYSTEM BUILDER FUNCTION
      # ------------------------------------------------------------------------
      
      mkSystem = { system, host, modules }:
        lib.nixosSystem {
          modules = [
            # Platform configuration
            { nixpkgs.hostPlatform = system; }

            # Apply overlays and nixpkgs config
            {
              nixpkgs.overlays = overlaysCommon;
              nixpkgs.config   = nixpkgsConfigCommon;
            }

            # Theming modules
            inputs.distro-grub-themes.nixosModules.${system}.default
            inputs.catppuccin.nixosModules.catppuccin

            # Home-manager as NixOS module (integrated mode)
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs   = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs username host; };
                users.${username} = {
                  imports = [
                    inputs.catppuccin.homeModules.catppuccin
                    ./modules/home
                  ];
                };
              };
            }

            # Empty system packages (managed elsewhere)
            { environment.systemPackages = []; }

            # Ensure insecure packages are allowed
            {
              nixpkgs.config.permittedInsecurePackages = 
                nixpkgsConfigCommon.permittedInsecurePackages;
            }
          ] ++ modules;

          specialArgs = { inherit self inputs username host system; };
        };

      # ------------------------------------------------------------------------
      #  HOME-MANAGER CONFIGURATION BUILDER
      # ------------------------------------------------------------------------
      
      mkHomeConfiguration = { host }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          extraSpecialArgs = { inherit inputs username host; };
          modules = [
            inputs.catppuccin.homeModules.catppuccin
            ./modules/home
            {
              home = {
                username = username;
                homeDirectory = "/home/${username}";
                stateVersion = "25.11";
              };
            }
          ];
        };

      # ------------------------------------------------------------------------
      #  POETRY2NIX SETUP
      # ------------------------------------------------------------------------
      
      inherit (inputs.poetry2nix.lib) mkPoetry2Nix;
      eachSystem = lib.genAttrs (import systems);

      # Per-system package sets with overlays
      pkgsFor = eachSystem (sys:
        import nixpkgs {
          localSystem = sys;
          overlays    = overlaysCommon;
          config      = nixpkgsConfigCommon;
        }
      );
    in
    {
      # ------------------------------------------------------------------------
      #  NIXOS SYSTEM CONFIGURATIONS
      # ------------------------------------------------------------------------
      
      nixosConfigurations = {
        hay = mkSystem { 
          inherit system; 
          host = "hay"; 
          modules = [ ./hosts/hay ]; 
        };
        
        vhay = mkSystem { 
          inherit system; 
          host = "vhay"; 
          modules = [ ./hosts/vhay ]; 
        };
      };

      # ------------------------------------------------------------------------
      #  HOME-MANAGER STANDALONE CONFIGURATIONS
      #
      #  Usage: home-manager switch --flake .#kenan@HOST
      # ------------------------------------------------------------------------
      
      homeConfigurations = {
        "kenan@hay" = mkHomeConfiguration { host = "hay"; };
        "kenan@vhay" = mkHomeConfiguration { host = "vhay"; };
      };

      # ------------------------------------------------------------------------
      #  EXPORTED PACKAGES
      # ------------------------------------------------------------------------
      
      packages = eachSystem (sys:
        let 
          inherit (mkPoetry2Nix { pkgs = pkgsFor.${sys}; }) mkPoetryApplication;
        in {
          pyprland = mkPoetryApplication {
            projectDir  = nixpkgs.lib.cleanSource "${pyprland}";
            checkGroups = [];
          };
        }
      );

      # ------------------------------------------------------------------------
      #  DEVELOPMENT SHELLS
      # ------------------------------------------------------------------------
      
      devShells = eachSystem (sys:
        let 
          inherit (mkPoetry2Nix { pkgs = pkgsFor.${sys}; }) mkPoetryEnv;
        in {
          pyprland = pkgsFor.${sys}.mkShellNoCC {
            packages = with pkgsFor.${sys}; [
              (mkPoetryEnv { projectDir = "${pyprland}"; })
              poetry
            ];
          };
        }
      );
    };

  # ============================================================================
  #  BINARY CACHE CONFIGURATION
  # ============================================================================
  
  nixConfig = {
    extra-substituters = [
      "https://hyprland-community.cachix.org"
      "https://cosmic.cachix.org"
    ];
    
    extra-trusted-public-keys = [
      "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSUnmE="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    ];
  };
}
