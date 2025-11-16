# ==============================================================================
# NixOS System Configuration Flake
# ==============================================================================
#
# Project: NixOS Configuration Suite (nixosc)
# Version: 4.2.0
# Date:    2025-11-15
# Author:  Kenan Pelit
# Repo:    https://github.com/kenanpelit/nixosc
# License: MIT
#
# Overview:
#   - Full-stack NixOS configuration (system + home-manager)
#   - Modular, host-aware, theme-enabled, and battery-included
#   - Single source of truth for overlays & nixpkgs configuration
#   - Reproducible builds with pinned dependencies via flake.lock
#   - Dual home-manager modes: NixOS module + standalone
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
#   2. Dual Home-Manager Configuration:
#      • NixOS Module Mode: Integrated with system, atomic updates
#        Usage: sudo nixos-rebuild switch --flake .#hay
#      • Standalone Mode: Independent user environment management
#        Usage: home-manager switch --flake .#kenan@hay
#      Both modes share the same ./modules/home configuration
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
#   - stateVersion "25.11" tracks nixos-unstable compatibility
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
      url = "github:hyprwm/hyprland/d52639fdfaedd520515a8f46e00d9b8881d40819"; # 1116 - Updated Commits
#      url = "github:hyprwm/hyprland/43527d363472b52f17dd9f9f4f87ec25cbf8a399"; # 1114 - Updated Commits
#      url = "github:hyprwm/hyprland/64ee8f8a72d62069a6bef45ca05bef1d0d412e1f"; # 1113 - Updated Commits
#      url = "github:hyprwm/hyprland/0b1d690676589503f0addece30e936a240733699"; # 1110 - Updated Commits
#      url = "github:hyprwm/hyprland/522edc87126a48f3ce4891747b6a92a22385b1e7"; # 1108 - Updated Commits
#      url = "github:hyprwm/hyprland/f56ec180d3a03a5aa978391249ff8f40f949fb73"; # 1107 - Updated Commits
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
      url = "github:abenz1267/walker/v2.8.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Elephant - Backend provider for Walker (with all providers)
    elephant = {
      url = "github:abenz1267/elephant/v2.13.2";
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
      # ==========================================================================
      # Configuration Constants
      # ==========================================================================
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

      # ==========================================================================
      # System Builder Function
      # ==========================================================================
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
            {
              environment.systemPackages = [];
            }

            # Ensure insecure packages are allowed
            {
              nixpkgs.config.permittedInsecurePackages = 
                nixpkgsConfigCommon.permittedInsecurePackages;
            }
          ] ++ modules;

          specialArgs = { inherit self inputs username host system; };
        };

      # ==========================================================================
      # Home-Manager Configuration Builder
      # ==========================================================================
      mkHomeConfiguration = { host }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgs;
          extraSpecialArgs = { 
            inherit inputs username host; 
          };
          modules = [
            # Catppuccin theming
            inputs.catppuccin.homeModules.catppuccin
            
            # Main home configuration
            ./modules/home
            
            # Required home-manager settings for standalone mode
            {
              home = {
                username = username;
                homeDirectory = "/home/${username}";
                stateVersion = "25.11";
              };
            }
          ];
        };

      # ==========================================================================
      # Poetry2nix Setup
      # ==========================================================================
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
      # ==========================================================================
      # NixOS System Configurations
      # ==========================================================================
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

      # ==========================================================================
      # Home-Manager Standalone Configurations
      # ==========================================================================
      # These allow using `home-manager switch --flake .#kenan@HOST`
      # Provides user-level package management without sudo
      homeConfigurations = {
        "kenan@hay" = mkHomeConfiguration { host = "hay"; };
        "kenan@vhay" = mkHomeConfiguration { host = "vhay"; };
      };

      # ==========================================================================
      # Exported Packages
      # ==========================================================================
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

      # ==========================================================================
      # Development Shells
      # ==========================================================================
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
  # Binary Cache Configuration
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

