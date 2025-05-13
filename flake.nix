# ==============================================================================
#
#   NixOS System Configuration Flake
#   Project: NixOS Configuration Suite (nixosc)
#   Version: 3.0.0
#   Date: 2025-05-12
#   Author: Kenan Pelit
#   Repository: https://github.com/kenanpelit/nixosc
#
#   Description: Comprehensive NixOS system configuration management suite
#   This flake defines the complete NixOS system configuration, including:
#   - Package management and overlays
#   - User environment (via home-manager) 
#   - System services and settings
#   - Hardware-specific configurations
#   - VPN-aware workspace session management
#   - Automated backup and restoration tools
#   - Dynamic admin script generation
#
#   Features:
#   - Modular configuration structure
#   - Hybrid workspace session management
#   - Automated backup systems
#   - VPN-aware application launching
#   - Custom admin tooling generation
#   - Home-manager integration
#   - Hardware-specific optimizations
#
#   License: MIT
#
# ==============================================================================
{
  description = "Kenan's NixOS Configuration";
 
  # ============================================================================
  # INPUT SOURCES AND DEPENDENCIES
  # ============================================================================
  # Each input represents a source for packages, modules, or configurations
  # Dependencies are pinned in flake.lock for reproducibility
  inputs = {
    # === Core System Packages ===
    # Main Nixpkgs repository (unstable channel for latest packages)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    # === User Environment Management ===
    # Home-manager for user-specific configurations  
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";  # Use the same nixpkgs as above for compatibility
    };
    
    # Community package repository (NUR) for additional user-contributed packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";  # Ensure version compatibility
    };
    
    # === Security and Secrets Management ===
    # SOPS for encrypted secrets in the configuration
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # === GRUB Theme ===
    # Custom themes for the GRUB bootloader
    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
   
    # === Desktop Environment - Hyprland Ecosystem ===
    # Core Hyprland Wayland compositor - pinned to specific commit for stability
    hyprland = {
      url = "github:hyprwm/hyprland/da3583fd5e86044d02af9fcfac84724e02545336"; # 0513 - 6107 Commits
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- Hyprland Dependencies and Extensions ---
    # Language parsing library for Hyprland configuration
    hyprlang = {
      url = "github:hyprwm/hyprlang";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    # Utility libraries for Hyprland
    hyprutils = {
      url = "github:hyprwm/hyprutils";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    # Wayland protocol definitions specific to Hyprland
    hyprland-protocols = {
      url = "github:hyprwm/hyprland-protocols";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    # XDG Desktop Portal implementation for Hyprland (application integration)
    xdph = {
      url = "github:hyprwm/xdg-desktop-portal-hyprland";
      inputs = {
        hyprland-protocols.follows = "hyprland-protocols";
        hyprlang.follows = "hyprlang";
        hyprutils.follows = "hyprutils";
        hyprwayland-scanner.follows = "hyprwayland-scanner";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    # Hyprland cursor library for custom cursors
    hyprcursor = {
      url = "github:hyprwm/hyprcursor";
      inputs = {
        hyprlang.follows = "hyprlang";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    # Wayland protocol scanner for Hyprland
    hyprwayland-scanner = {
      url = "github:hyprwm/hyprwayland-scanner";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    # Graphics library for Hyprland
    hyprgraphics = {
      url = "github:hyprwm/hyprgraphics";
      inputs = {
        hyprutils.follows = "hyprutils";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    # Qt integration for Hyprland
    hyprland-qtutils = {
      url = "github:hyprwm/hyprland-qtutils";
      inputs = {
        hyprlang.follows = "hyprlang";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    # --- Hyprland Plugins and Extensions ---
    # Official Hyprland plugins collection
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    
    # Additional community utilities for Hyprland
    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Color picker utility for Hyprland
    hyprpicker = {
      url = "github:hyprwm/hyprpicker";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Screen magnifier for Hyprland
    hyprmag = {
      url = "github:SIMULATAN/hyprmag";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # === Hyprland Python Plugin Framework ===
    # PyPrland - Python plugin system enabling scriptable extensions
    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Poetry2nix for Python dependency management
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Systems definitions for multi-platform support
    systems = {
      url = "github:nix-systems/default-linux";
    };
    
    # Flake compatibility layer for non-flake users
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    
    # === Development Tools ===
    # Nix code formatter and linter
    alejandra = {
      url = "github:kamadorueda/alejandra/3.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # === Application Customization ===
    # Spotify customization framework
    spicetify-nix = {
      url = "github:gerg-l/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # === System Integration and Tools ===
    # Flatpak integration for additional software support
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
    };
    
    # Enhanced browser configuration framework
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Chrome browser preview packages
    browser-previews = {
      url = "github:nix-community/browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Binary cache management tools
    cachix-pkgs = {
      url = "github:cachix/cachix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # === Terminal and File Management ===
    # Terminal file manager plugins (raw source)
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;  # Raw source, not a Nix flake
    };
    
    # === Package Search Tools ===
    # Interactive package search utility with TUI
    nix-search-tv = {
      url = "github:3timeslazy/nix-search-tv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # === Application Launcher & Tools ===
    # Fast application launcher for Wayland
    walker = {
      url = "github:abenz1267/walker/v0.12.21";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === COSMIC Desktop Environment ===
    # COSMIC desktop for NixOS
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs"; # Use the same nixpkgs as above
    };
  };
 
  # ============================================================================
  # SYSTEM CONFIGURATION OUTPUTS
  # ============================================================================
  outputs = { nixpkgs, self, home-manager, sops-nix, distro-grub-themes, poetry2nix, systems, pyprland, 
              hyprland, hyprlang, hyprutils, hyprland-protocols, xdph, hyprcursor, nixos-cosmic, ... }@inputs:
    let
      # === Global Variables ===
      username = "kenan";        # Primary user account
      system = "x86_64-linux";   # System architecture
      
      # Configure nixpkgs with system-wide settings
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;    # Enable proprietary software
          permittedInsecurePackages = [
            # Allow specific insecure packages with known issues
            "ventoy-1.1.05"      # USB multi-boot tool with binary blobs
          ];
        };
      };
      
      # Import nixpkgs library for helper functions
      lib = nixpkgs.lib;
      
      # === System Configuration Helper ===
      # Function to create a complete NixOS system configuration
      mkSystem = { system, host, modules }: 
        nixpkgs.lib.nixosSystem {
          inherit system;
          
          # Add default and machine-specific modules
          modules = [
            # GRUB theme module for all systems
            distro-grub-themes.nixosModules.${system}.default
            
            # Home-manager integration
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;       # Use global pkgs instance
                useUserPackages = true;     # Install packages to /etc/profiles
                extraSpecialArgs = {
                  inherit inputs username host;
                };
              };
            }
            
            # COSMIC Desktop Environment module
            inputs.nixos-cosmic.nixosModules.default
            
            # Cachix binary cache for COSMIC
            {
              nix.settings = {
                substituters = [ 
                  "https://cosmic.cachix.org/" 
                ];
                trusted-public-keys = [ 
                  "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" 
                ];
              };
            }
            
            # Global system packages
            {
              environment.systemPackages = [
                inputs.nix-search-tv.packages.${system}.default
                inputs.walker.packages.${system}.default
              ];
            }
            
            # Security exceptions for specific packages
            # This ensures insecure packages are permitted across the entire system
            {
              nixpkgs.config.permittedInsecurePackages = [ "ventoy-1.1.05" ];
            }
          ] ++ modules;  # Add machine-specific modules
          
          # Pass additional arguments to all modules
          specialArgs = {
            inherit self inputs username host system;
          };
        };
        
      # Setup for PyPrland packages
      inherit (inputs.poetry2nix.lib) mkPoetry2Nix;
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      pkgsFor = eachSystem (sys: import nixpkgs {localSystem = sys;});
    in
    {
      # === Machine Configurations ===
      nixosConfigurations = {
        # Personal laptop configuration
        hay = mkSystem {
          inherit system;
          host = "hay";
          modules = [ ./hosts/hay ];
        };
        
        # Development VM configuration
        vhay = mkSystem {
          inherit system;
          host = "vhay";
          modules = [ ./hosts/vhay ];
        };
      };
      
      # === PyPrland packages and shells ===
      # Make PyPrland available as a package
      packages = eachSystem (sys: let
        inherit (mkPoetry2Nix {pkgs = pkgsFor.${sys};}) mkPoetryApplication;
      in {
        pyprland = mkPoetryApplication {
          projectDir = nixpkgs.lib.cleanSource "${pyprland}";
          checkGroups = [];
        };
      });
      
      # Development shells for PyPrland
      devShells = eachSystem (sys: let
        inherit (mkPoetry2Nix {pkgs = pkgsFor.${sys};}) mkPoetryEnv;
      in {
        pyprland = pkgsFor.${sys}.mkShellNoCC {
          packages = with pkgsFor.${sys}; [
            (mkPoetryEnv {projectDir = "${pyprland}";})
            poetry
          ];
        };
      });
      
      # Additional outputs can be defined here:
      # - Development shells
      # - Custom packages
      # - NixOS modules
      # - Home-manager modules
    };
    
    # ============================================================================
    # BINARY CACHE CONFIGURATION
    # ============================================================================
    # Improve build times by using pre-built binaries from Cachix
    nixConfig = {
      extra-substituters = [
        "https://hyprland-community.cachix.org"
        "https://cosmic.cachix.org/"
      ];
      extra-trusted-public-keys = [
        "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSUnmE="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      ];
    };
}

