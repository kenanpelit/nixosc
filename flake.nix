# ==============================================================================
# NixOS System Configuration Flake
# Author: Kenan Pelit
# Description: Main configuration file for NixOS system setup
#
# This flake defines the complete NixOS system configuration, including:
# - Package management and overlays
# - User environment (via home-manager)
# - System services and settings
# - Hardware-specific configurations
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
    
    # Community package repository
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";  # Ensure version compatibility
    };
    
    # === Desktop Environment - Hyprland Ecosystem ===
    # Core Hyprland compositor
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Essential Hyprland plugins and extensions
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";  # Ensure version compatibility
    };
    
    # Additional Hyprland utilities
    hypr-contrib.url = "github:hyprwm/contrib";          # Core utilities and scripts
    hyprpicker.url = "github:hyprwm/hyprpicker";        # Color picker for theming
    hyprmag.url = "github:SIMULATAN/hyprmag";           # Screen magnification tool
    
    # === Development Tools ===
    alejandra.url = "github:kamadorueda/alejandra/3.0.0"; # Nix code formatter and linter
    nix-gaming.url = "github:fufexan/nix-gaming";        # Gaming optimizations and tools
    
    # === Application Customization ===
    # Spotify customization framework
    spicetify-nix = {
      url = "github:gerg-l/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";  # Maintain package compatibility
    };
    
    # === System Integration and Tools ===
    nix-flatpak.url = "github:gmodena/nix-flatpak";     # Flatpak integration
    zen-browser.url = "github:0xc000022070/zen-browser-flake"; # Enhanced browser setup
    cachix-pkgs.url = "github:cachix/cachix";            # Binary cache management
    
    # === Terminal and File Management ===
    # Modern GPU-accelerated terminal emulator
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    
    # Terminal file manager plugins
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;  # Raw source, not a Nix flake
    };
  };
  
  # System outputs and configurations
  outputs = { nixpkgs, self, home-manager, ... }@inputs:
    let
      # === Global Variables ===
      username = "kenan";        # Primary user account
      system = "x86_64-linux";   # System architecture
      
      # Configure nixpkgs with system-wide settings
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;  # Enable proprietary software
      };
      
      # Import nixpkgs library for helper functions
      lib = nixpkgs.lib;
      
      # === System Configuration Helper ===
      # Function to create a complete NixOS system configuration
      # Parameters:
      # - system: Architecture (e.g., x86_64-linux)
      # - host: Machine-specific identifier
      # - modules: Additional configuration modules
      mkSystem = { system, host, modules }: 
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            # Home-manager integration
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;      # Use system packages
                useUserPackages = true;     # Enable user packages
                extraSpecialArgs = { inherit inputs username host; };
              };
            }
          ] ++ modules;
          # Pass additional arguments to all modules
          specialArgs = {
            inherit self inputs username host;
          };
        };
    in
    {
      # === Machine Configurations ===
      nixosConfigurations = {
        # Personal laptop configuration
        hay = mkSystem {
          inherit system;
          host = "hay";
          modules = [ ./hosts/hay ];  # Laptop-specific settings
        };
        
        # Development VM configuration
        vhay = mkSystem {
          inherit system;
          host = "vhay";
          modules = [ ./hosts/vhay ];  # VM-specific settings
        };
      };
    };
}
