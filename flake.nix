# ==============================================================================
# NixOS System Configuration Flake
# ==============================================================================
#
# Project: NixOS Configuration Suite (nixosc)
# Version: 4.0.0
# Date:    2025-09-13
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
#      → TODO: Remove once dependencies stop calling buildGo123Module
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
#   - Use `nix flake update` to update all inputs, or `nix flake lock --update-input <name>`
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
    # Emergency rollback template (uncomment to pin to specific revision):
    # nixpkgs.url = "github:NixOS/nixpkgs/b5d4232";

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
    # All Hyprland-related packages pinned for stability and compatibility
    
    # Core Hyprland compositor (pinned to specific commit for stability)
    hyprland = {
      inputs.nixpkgs.follows = "nixpkgs";
      # Previous stable: github:hyprwm/hyprland/46174f78b374b6cea669c48880877a8bdcf7802f
      url = "github:hyprwm/hyprland/9e74d0aea7614eaf238ef07261129026572337e7"; # 0915 - Updated Commits
#      url = "github:hyprwm/hyprland/559024c3314e4b1180b10b80fce4e9f20bad14c8"; # 0915 - Updated Commits
#      url = "github:hyprwm/hyprland/adbf7c8663cfbc91fca78d3504fa8f73ce4bd23a"; # 2025-09-13 stable
    };
    
    # Hyprland dependencies and utilities
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

    # Hyprland Python plugin framework for extensibility
    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    # Development Tools & Build Systems
    # --------------------------------------------------------------------------
    
    # Poetry2nix - Build Python applications from poetry.lock
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Multi-system support for Linux architectures
    systems = {
      url = "github:nix-systems/default-linux";
    };

    # Compatibility layer for non-flake Nix tooling
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # --------------------------------------------------------------------------
    # Applications & Integrations
    # --------------------------------------------------------------------------
    
    # Code formatter for Nix
    alejandra = { 
      url = "github:kamadorueda/alejandra/3.1.0"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
    
    # Spotify customization framework
    spicetify-nix = { 
      url = "github:gerg-l/spicetify-nix"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
    
    # Flatpak integration for NixOS
    nix-flatpak = { 
      url = "github:gmodena/nix-flatpak"; 
    };
    
    # Alternative browsers
    zen-browser = { 
      url = "github:0xc000022070/zen-browser-flake"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
    
    browser-previews = { 
      url = "github:nix-community/browser-previews"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
    
    # Cachix binary cache tools
    cachix-pkgs = { 
      url = "github:cachix/cachix"; 
      inputs.nixpkgs.follows = "nixpkgs"; 
    };

    # --------------------------------------------------------------------------
    # Data Sources (Non-flake inputs)
    # --------------------------------------------------------------------------
    
    # Yazi file manager plugins (raw source, used as data)
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };

    # Nix package search tool (may use its own nixpkgs)
    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --------------------------------------------------------------------------
    # Optional/Experimental (Currently Disabled)
    # --------------------------------------------------------------------------
    
    # COSMIC desktop environment (keep for future testing)
    # nixos-cosmic = {
    #   url = "github:lilyinstarlight/nixos-cosmic";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  # ============================================================================
  # OUTPUTS - System Configurations & Packages
  # ============================================================================
  # This section defines what this flake produces: NixOS configurations,
  # packages, and development shells. Everything is built with consistent
  # overlays and configuration.
  
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
    catppuccin, 
    ... 
  }@inputs:
    let
      # ------------------------------------------------------------------------
      # Global Configuration Variables
      # ------------------------------------------------------------------------
      
      username = "kenan";        # Primary user account
      system   = "x86_64-linux"; # Target architecture
      
      # ------------------------------------------------------------------------
      # Overlay Configuration - Single Source of Truth
      # ------------------------------------------------------------------------
      # These overlays are applied consistently everywhere to avoid
      # "works in one place, breaks in another" issues.
      
      overlaysCommon = [
        # NUR overlay (Community packages)
        # Note: NUR changed its API; correct usage is inputs.nur.overlays.default
        inputs.nur.overlays.default

        # Temporary compatibility shim for buildGo123Module
        # Background: nixpkgs removed buildGo123Module when Go 1.23 reached EOL
        # This delegates to buildGoModule with Go 1.25 for backward compatibility
        # TODO: Remove once all external dependencies are updated
        (final: prev: {
          buildGo123Module = args:
            prev.buildGoModule (args // { go = prev.go_1_25; });
        })

        # TigerVNC build fix
        # Provides autoreconf tooling for nested autoreconf calls
        # without forcing autoreconfPhase at repository root
        (final: prev: {
          tigervnc = prev.tigervnc.overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
              prev.autoconf
              prev.automake
              prev.libtool
            ];
          });
        })

        # Qt5 to Qt6 migration overlay
        # globalprotect-openconnect Qt6 fix
        (final: prev: {
          globalprotect-openconnect = prev.globalprotect-openconnect.override {
            qtbase = final.qt6.qtbase;
            qtwebsockets = final.qt6.qtwebsockets;
            qtwebengine = final.qt6.qtwebengine;
          };
        })
      ];

      # ------------------------------------------------------------------------
      # Nixpkgs Configuration - Applied Everywhere
      # ------------------------------------------------------------------------
      # Central configuration ensures consistent behavior across all contexts
      
      nixpkgsConfigCommon = {
        allowUnfree = true;
        
        # Security exceptions (use sparingly and document reasons)
        # TODO: Audit and remove these as soon as alternatives are available
        permittedInsecurePackages = [
          "ventoy-1.1.07"       # Binary blobs for multiboot USB creation
          "libsoup-2.74.3"      # EOL GTK dependency - phase out when possible
          #"qtwebengine-5.15.19" # Legacy QtWebEngine - migrate when viable
        ];
      };

      # ------------------------------------------------------------------------
      # Package Set Creation
      # ------------------------------------------------------------------------
      
      # Top-level package set for ad-hoc usage and scripting
      # Note: nixosSystem uses its own unless explicitly passed
      pkgs = import nixpkgs {
        inherit system;
        overlays = overlaysCommon;
        config   = nixpkgsConfigCommon;
      };

      # Convenience shorthand for nixpkgs library functions
      lib = nixpkgs.lib;

      # ------------------------------------------------------------------------
      # System Builder Function (DRY Pattern)
      # ------------------------------------------------------------------------
      # Constructs a NixOS system with consistent configuration injection
      
      mkSystem = { system, host, modules }:
        lib.nixosSystem {
          inherit system;

          modules = [
            # Step 1: Inject overlays and config into the NixOS module system
            {
              nixpkgs.overlays = overlaysCommon;
              nixpkgs.config   = nixpkgsConfigCommon;
            }

            # Step 2: System-wide theming modules
            inputs.distro-grub-themes.nixosModules.${system}.default  # GRUB themes
            inputs.catppuccin.nixosModules.catppuccin                # Catppuccin theme

            # Step 3: Home-manager integration with shared package universe
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs   = true;  # Reuse NixOS pkgs for consistency
                useUserPackages = true;  # Install to /etc/profiles
                extraSpecialArgs = { inherit inputs username host; };
                users.${username} = {
                  imports = [
                    inputs.catppuccin.homeModules.catppuccin
                    ./modules/home
                  ];
                };
              };
            }

            # Step 4: Optional global packages from external flakes
            # Warning: These may use their own nixpkgs and ignore our overlays
            {
              environment.systemPackages = [
                # inputs.nix-search-tv.packages.${system}.default
                # inputs.walker.packages.${system}.default
              ];
            }

            # Step 5: Safety net - mirror insecure package permissions
            {
              nixpkgs.config.permittedInsecurePackages = 
                nixpkgsConfigCommon.permittedInsecurePackages;
            }
          ] ++ modules;

          # Pass useful context to all modules
          specialArgs = { inherit self inputs username host system; };
        };

      # ------------------------------------------------------------------------
      # Poetry2nix Helper Functions
      # ------------------------------------------------------------------------
      
      inherit (inputs.poetry2nix.lib) mkPoetry2Nix;

      # ------------------------------------------------------------------------
      # Multi-system Support Infrastructure
      # ------------------------------------------------------------------------
      
      # Generate attributes for each supported system
      eachSystem = lib.genAttrs (import systems);

      # Per-system package sets with consistent configuration
      pkgsFor = eachSystem (sys:
        import nixpkgs {
          localSystem = sys;
          overlays    = overlaysCommon;
          config      = nixpkgsConfigCommon;
        }
      );
    in
    {
      # ========================================================================
      # NixOS Host Configurations
      # ========================================================================
      # Define your machines here. Add new hosts by creating a new entry
      # with the appropriate host-specific module.
      
      nixosConfigurations = {
        # Physical machine configuration
        hay = mkSystem { 
          inherit system; 
          host = "hay"; 
          modules = [ ./hosts/hay ]; 
        };
        
        # Virtual machine configuration
        vhay = mkSystem { 
          inherit system; 
          host = "vhay"; 
          modules = [ ./hosts/vhay ]; 
        };
      };

      # ========================================================================
      # Packages (Multi-system)
      # ========================================================================
      # Custom packages built by this flake
      # Usage: nix build .#pyprland
      
      packages = eachSystem (sys:
        let 
          inherit (mkPoetry2Nix { pkgs = pkgsFor.${sys}; }) mkPoetryApplication;
        in {
          # Pyprland - Hyprland Python plugin framework
          pyprland = mkPoetryApplication {
            projectDir  = nixpkgs.lib.cleanSource "${pyprland}";
            checkGroups = []; # Skip optional test dependencies for faster builds
          };
        }
      );

      # ========================================================================
      # Development Shells
      # ========================================================================
      # Reproducible development environments
      # Usage: nix develop .#pyprland
      
      devShells = eachSystem (sys:
        let 
          inherit (mkPoetry2Nix { pkgs = pkgsFor.${sys}; }) mkPoetryEnv;
        in {
          # Pyprland development environment with Poetry
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
  # These settings tell Nix where to look for pre-built binaries
  # to avoid unnecessary compilation.
  
  nixConfig = {
    # Additional binary caches
    extra-substituters = [
      "https://hyprland-community.cachix.org"
      # "https://cosmic.cachix.org"  # Uncomment when using COSMIC
    ];
    
    # Public keys for cache verification
    extra-trusted-public-keys = [
      "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSUnmE="
      # "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    ];
  };
}
