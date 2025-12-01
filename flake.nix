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
      #url = "github:NixOS/nixpkgs/nixos-unstable"; 
      url = "github:NixOS/nixpkgs/nixos-25.11";
    };

    home-manager = {
      #url = "github:nix-community/home-manager";
      url = "github:nix-community/home-manager/release-25.11";
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
      url = "github:hyprwm/hyprland/bb963fb00263bac78a0c633d1d0d02ae4763222c"; # 1201 - Updated commit
#      url = "github:hyprwm/hyprland/f11cf6f1de708b6b3811788e8ff7984ff05a9546"; # 1130 - Updated commit
#      url = "github:hyprwm/hyprland/379ee99c681d45626604ad0253527438960ed374"; # 1127 - Updated commit
#      url = "github:hyprwm/hyprland/2b0fd417d32278159d0ca1d23fb997588c37995b"; # 1124 - Updated commit
#      url = "github:hyprwm/hyprland/e584a8bade2617899d69ae6f83011d0c1d2a9df7"; # 1122 - Updated commit
#      url = "github:hyprwm/hyprland/b5a2ef77b7876798d33502f8de006f9c478c12db"; # 1121 - Updated commit
    };
    
    # Hyprland extras actually used elsewhere
    hypr-contrib = { 
      url = "github:hyprwm/contrib"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };

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
      url = "github:abenz1267/walker/v2.11.3";
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
      
      # Import custom library
      mylib = import ./lib { inherit inputs nixpkgs home-manager; };

      # Unified overlay list - applied consistently everywhere
      overlaysCommon = [
        inputs.nur.overlays.default
        (final: prev: {
          maple-mono = import ./modules/home/maple { lib = final.lib; pkgs = final; };
        })
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

      cacheSubstituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://nix-gaming.cachix.org"
        "https://hyprland-community.cachix.org"
        "https://cosmic.cachix.org"
      ];

      cachePublicKeys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSUnmE="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      ];

      # Primary package set with overlays and config
      pkgs = import nixpkgs {
        inherit system;
        overlays = overlaysCommon;
        config   = nixpkgsConfigCommon;
      };

      lib = nixpkgs.lib;

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
      #  EXPORTED OVERLAYS
      # ------------------------------------------------------------------------
      
      overlays = {
        nur = inputs.nur.overlays.default;
        default = final: prev: {
          # Add custom overlays here
        };
      };

      # ------------------------------------------------------------------------
      #  NIXOS SYSTEM CONFIGURATIONS
      # ------------------------------------------------------------------------
      
      nixosConfigurations = {
        hay = mylib.mkSystem { 
          inherit system username; 
          host = "hay"; 
          modules = [ ./hosts/hay ]; 
          overlays = overlaysCommon;
          nixpkgsConfig = nixpkgsConfigCommon;
          specialArgs = { inherit cacheSubstituters cachePublicKeys; };
        };
        
        vhay = mylib.mkSystem { 
          inherit system username; 
          host = "vhay"; 
          modules = [ ./hosts/vhay ]; 
          overlays = overlaysCommon;
          nixpkgsConfig = nixpkgsConfigCommon;
          specialArgs = { inherit cacheSubstituters cachePublicKeys; };
        };
      };

      # ------------------------------------------------------------------------
      #  HOME-MANAGER STANDALONE CONFIGURATIONS
      #
      #  Usage: home-manager switch --flake .#kenan@HOST
      # ------------------------------------------------------------------------
      
      homeConfigurations = {
        "kenan@hay" = mylib.mkHome { 
          inherit username pkgs; 
          host = "hay"; 
          homeModules = [ ./modules/home ];
        };
        "kenan@vhay" = mylib.mkHome { 
          inherit username pkgs; 
          host = "vhay"; 
          homeModules = [ ./modules/home ];
        };
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

      # ----------------------------------------------------------------------
      #  BINARY CACHE CONFIGURATION
      # ----------------------------------------------------------------------
      nixConfig = {
        extra-substituters        = cacheSubstituters;
        extra-trusted-public-keys = cachePublicKeys;
      };
    };
}
