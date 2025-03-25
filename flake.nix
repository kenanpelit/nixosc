# ==============================================================================
#
#   NixOS System Configuration Flake
#   Project: NixOS Configuration Suite (nixosc)
#   Version: 2.0.0
#   Date: 2024-03-25
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
 description = "Kenan's nixos configuration";
 
 # Define all external dependencies and inputs
 # Each input represents a source for packages, modules, or configurations
 inputs = {
   # === Core System Packages ===
   # Main repository for most packages
   nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
   
   # === User Environment Management ===
   # Home-manager for user-specific configurations  
   home-manager = {
     url = "github:nix-community/home-manager";
     inputs.nixpkgs.follows = "nixpkgs";  # Use the same nixpkgs as above
   };
   
   # Community package repository for additional software
   nur = {
     url = "github:nix-community/NUR";
     inputs.nixpkgs.follows = "nixpkgs";  # Ensure version compatibility
   };
   
   # === Security and Secrets Management ===
   # For managing sensitive configuration data
   sops-nix = {
     url = "github:Mic92/sops-nix";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   # === GRUB Theme ===
   # Custom GRUB bootloader themes
   distro-grub-themes = {
     url = "github:AdisonCavani/distro-grub-themes";
     inputs.nixpkgs.follows = "nixpkgs";
   };
 
   # === Desktop Environment - Hyprland Ecosystem ===
   # Core Hyprland compositor
   hyprland = {
     #url = "github:hyprwm/hyprland/9171db1984415a8553ee707bc2f558eb1ae06e7e"; # 0317
     url = "github:hyprwm/hyprland";  # Latest version without pinning
     inputs.nixpkgs.follows = "nixpkgs";
   };

   # Hyprland language parsing library
   hyprlang = {
     url = "github:hyprwm/hyprlang";
     inputs = {
       nixpkgs.follows = "nixpkgs";
       systems.follows = "systems";
     };
   };

   # Hyprland utility libraries
   hyprutils = {
     url = "github:hyprwm/hyprutils";
     inputs = {
       nixpkgs.follows = "nixpkgs";
       systems.follows = "systems";
     };
   };

   # Wayland protocol definitions for Hyprland
   hyprland-protocols = {
     url = "github:hyprwm/hyprland-protocols";
     inputs = {
       nixpkgs.follows = "nixpkgs";
       systems.follows = "systems";
     };
   };

   # XDG Desktop Portal implementation for Hyprland
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

   # Hyprland cursor library
   hyprcursor = {
     url = "github:hyprwm/hyprcursor";
     inputs = {
       hyprlang.follows = "hyprlang";
       nixpkgs.follows = "nixpkgs";
       systems.follows = "systems";
     };
   };

   # Hyprland Wayland protocol scanner
   hyprwayland-scanner = {
     url = "github:hyprwm/hyprwayland-scanner";
     inputs = {
       nixpkgs.follows = "nixpkgs";
       systems.follows = "systems";
     };
   };

   # Hyprland graphics library
   hyprgraphics = {
     url = "github:hyprwm/hyprgraphics";
     inputs = {
       hyprutils.follows = "hyprutils";
       nixpkgs.follows = "nixpkgs";
       systems.follows = "systems";
     };
   };

   # Hyprland Qt integration
   hyprland-qtutils = {
     url = "github:hyprwm/hyprland-qtutils";
     inputs = {
       hyprlang.follows = "hyprlang";
       nixpkgs.follows = "nixpkgs";
       systems.follows = "systems";
     };
   };

   # Essential Hyprland plugins
   hyprland-plugins = {
     url = "github:hyprwm/hyprland-plugins";
     inputs.hyprland.follows = "hyprland";
   };
   
   # Additional Hyprland utilities and tools
   hypr-contrib = {
     url = "github:hyprwm/contrib";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   hyprpicker = {
     url = "github:hyprwm/hyprpicker";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   hyprmag = {
     url = "github:SIMULATAN/hyprmag";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   # === Hyprland Python Plugin Framework ===
   # PyPrland - Python plugin system for Hyprland
   pyprland = {
     url = "github:hyprland-community/pyprland";  # Updated to latest version
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   # PyPrland dependencies
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
   
   # Enhanced browser configuration
   zen-browser = {
     url = "github:0xc000022070/zen-browser-flake";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   
   # Chrome
   browser-previews = {
     url = "github:nix-community/browser-previews";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   # Binary cache management
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
   # Interactive package search utility
   nix-search-tv = {
     url = "github:3timeslazy/nix-search-tv";
     inputs.nixpkgs.follows = "nixpkgs";
   };
   # === Application Launcher & Tools ===
   walker = {
     url = "github:abenz1267/walker";  # Updated to latest version
     inputs.nixpkgs.follows = "nixpkgs";
   };
 };
 
 # System outputs and configurations
 outputs = { nixpkgs, self, home-manager, sops-nix, distro-grub-themes, poetry2nix, systems, pyprland, 
             hyprland, hyprlang, hyprutils, hyprland-protocols, xdph, hyprcursor, ... }@inputs:
   let
     # === Global Variables ===
     username = "kenan";        # Primary user account
     system = "x86_64-linux";   # System architecture
     
     # Configure nixpkgs with system-wide settings
     pkgs = import nixpkgs {
       inherit system;
       config = {
         allowUnfree = true;  # Enable proprietary software
         permittedInsecurePackages = [
           # Add any required insecure packages here
           # "example-package-1.0.0"
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
               useGlobalPkgs = true;
               useUserPackages = true;
               extraSpecialArgs = {
                 inherit inputs username host;
               };
             };
           }
           {
            environment.systemPackages = [
             inputs.nix-search-tv.packages.${system}.default
             inputs.walker.packages.${system}.default
            ];
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
     packages = eachSystem (sys: let
       inherit (mkPoetry2Nix {pkgs = pkgsFor.${sys};}) mkPoetryApplication;
     in {
       pyprland = mkPoetryApplication {
         projectDir = nixpkgs.lib.cleanSource "${pyprland}";
         checkGroups = [];
       };
     });
     
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
     
     # You can add additional outputs here, such as:
     # - Development shells
     # - Custom packages
     # - NixOS modules
     # - Home-manager modules
   };
   
   # Additional configuration for binary cache
   nixConfig = {
     extra-substituters = [
       "https://hyprland-community.cachix.org"
     ];
     extra-trusted-public-keys = [
       "hyprland-community.cachix.org-1:5dTHY+TjAJjnQs23X+vwMQG4va7j+zmvkTKoYuSUnmE="
     ];
   };
}

