# ==============================================================================
# NixOS System Configuration Flake
# ==============================================================================
#
# Project: NixOS Configuration Suite (nixosc)
# Version: 4.1.0
# Date:    2025-10-01
# Author:  Kenan Pelit
# Repo:    https://github.com/kenanpelit/nixosc
# License: MIT
#
# Overview:
#   - Full-stack NixOS configuration (system + home-manager)
#   - Modular, host-aware, theme-enabled, and battery-included
#   - Single source of truth for overlays & nixpkgs configuration
#   - Reproducible builds with pinned dependencies via flake.lock
#
# Architecture & Design Principles:
#   
#   1. Unified Overlay Management:
#      One overlay list (overlaysCommon) is consistently injected into:
#      • Top-level pkgs (import nixpkgs …)
#      • nixosSystem via a tiny module (nixpkgs.overlays = overlaysCommon)
#      • pkgsFor (packages/devShells multi-system world)
#      → This eliminates the "works here, breaks there" class of overlay bugs
#
#   2. Temporary Compatibility Bridge:
#      buildGo123Module → buildGoModule (Go 1.25)
#      → Why: nixpkgs removed buildGo123Module (Go 1.23 is EOL)
#      → Some external flakes still call it; this shim keeps builds green
#      → TODO: Remove once all external dependencies are updated
#
#   3. Central Configuration:
#      Single nixpkgs config (allowUnfree + permittedInsecurePackages)
#      → Declared once, reused everywhere to avoid divergence
#      → Ensures consistent behavior across all contexts
#
# Important Notes:
#   - External flakes often build with their own nixpkgs; your overlays may not
#     affect them. If a package fails inside a foreign flake, pin or patch that
#     flake instead of trying to overlay it here.
#   - Use `nix flake update` to update all inputs, or `nix flake lock --update-input <n>`
#     to update specific inputs.
#
# ==============================================================================

{
  description = "Kenan's NixOS Configuration";

  # ============================================================================
  # INPUTS - External Dependencies
  # ============================================================================
  # All dependencies are pinned through flake.lock for reproducibility.
  # We use `follows = "nixpkgs"` where practical to ensure ABI alignment
  # and reduce closure size.
  
  inputs = {
    # --------------------------------------------------------------------------
    # Core Dependencies
    # --------------------------------------------------------------------------
    
    # Primary package collection (nixos-unstable for fresh software)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # User environment management with declarative configuration
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    # Package Repositories & Extensions
    # --------------------------------------------------------------------------
    
    # Nix User Repository - Community-maintained packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secret management with SOPS (encrypted secrets in git)
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    # Theming & Aesthetics
    # --------------------------------------------------------------------------
    
    # Catppuccin theme framework for consistent theming
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # GRUB bootloader themes for visual customization
    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    # Hyprland Ecosystem (Wayland Compositor)
    # --------------------------------------------------------------------------
    
    hyprland = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hyprwm/hyprland/8e9add2afda58d233a75e4c5ce8503b24fa59ceb"; # 1031 - Updated Commits
#      url = "github:hyprwm/hyprland/309c3c78485781a28ad9f5bef48b09ecb3b81473"; # 1028 - Updated Commits
#      url = "github:hyprwm/hyprland/560c53d87dedf7df8185eb370cfbf3575826e85c"; # 1027 - Updated Commits
#      url = "github:hyprwm/hyprland/748d2f656ee4952090eb4ce8702ee05c82d228cb"; # 1026 - Updated Commits
#      url = "github:hyprwm/hyprland/da04afa44e7545771b08f8e0defd2cd1810f1613"; # 1025 - Updated Commits
#      url = "github:hyprwm/hyprland/aa5a239ac92a6bd6947cce2ca3911606df392cb6"; # 1024 - Updated Commits
    };
    
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
    # Development Tools & Build Systems
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

    # --------------------------------------------------------------------------
    # Applications & Integrations
    # --------------------------------------------------------------------------
    
    alejandra = { 
      url = "github:kamadorueda/alejandra"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
    
    # Walker - Wayland application launcher
    walker = {
      url = "github:abenz1267/walker/v2.8.1";
      #url = "github:abenz1267/walker/v2.7.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Elephant - Backend provider for Walker (with all providers)
    elephant = {
      url = "github:abenz1267/elephant";
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

    # --------------------------------------------------------------------------
    # Data Sources (Non-flake inputs)
    # --------------------------------------------------------------------------
    
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };

    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # ============================================================================
  # OUTPUTS - System Configurations & Packages
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
    hyprlang, 
    hyprutils, 
    hyprland-protocols, 
    xdph, 
    hyprcursor,
    walker,
    elephant,
    ... 
  }@inputs:
    let
      username = "kenan";
      system   = "x86_64-linux";
      
      overlaysCommon = [
        inputs.nur.overlays.default
      ];
 
      nixpkgsConfigCommon = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "ventoy-1.1.07"
          "libsoup-2.74.3"
        ];
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = overlaysCommon;
        config   = nixpkgsConfigCommon;
      };

      lib = nixpkgs.lib;

      mkSystem = { system, host, modules }:
        lib.nixosSystem {
          inherit system;

          modules = [
            {
              nixpkgs.overlays = overlaysCommon;
              nixpkgs.config   = nixpkgsConfigCommon;
            }

            inputs.distro-grub-themes.nixosModules.${system}.default
            inputs.catppuccin.nixosModules.catppuccin

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

            {
              environment.systemPackages = [];
            }

            {
              nixpkgs.config.permittedInsecurePackages = 
                nixpkgsConfigCommon.permittedInsecurePackages;
            }
          ] ++ modules;

          specialArgs = { inherit self inputs username host system; };
        };

      inherit (inputs.poetry2nix.lib) mkPoetry2Nix;

      eachSystem = lib.genAttrs (import systems);

      pkgsFor = eachSystem (sys:
        import nixpkgs {
          localSystem = sys;
          overlays    = overlaysCommon;
          config      = nixpkgsConfigCommon;
        }
      );
    in
    {
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

