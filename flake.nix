# ==============================================================================
# NixOS System Configuration Flake
# Author: Kenan
# Description: Main configuration file for NixOS system setup
# ==============================================================================
{
  description = "Kenan's nixos configuration";
  # Input sources - where we get our packages and modules from
  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";  # Main nixpkgs repository
    
    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix User Repository
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland and related packages
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
    };
    hypr-contrib.url = "github:hyprwm/contrib";          # Additional Hyprland utilities
    hyprpicker.url = "github:hyprwm/hyprpicker";        # Color picker
    hyprmag.url = "github:SIMULATAN/hyprmag";           # Magnifier

    # Development and utilities
    alejandra.url = "github:kamadorueda/alejandra/3.0.0"; # Nix formatter
    nix-gaming.url = "github:fufexan/nix-gaming";        # Gaming packages
    spicetify-nix = {                                    # Spotify customization
      url = "github:gerg-l/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System integration
    nix-flatpak.url = "github:gmodena/nix-flatpak";     # Flatpak support
    zen-browser.url = "github:0xc000022070/zen-browser-flake"; # Browser config

    # Cachix support
    cachix-pkgs.url = "github:cachix/cachix";

    # Terminal and file management
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  # System configuration and outputs
  outputs = { nixpkgs, self, home-manager, ... }@inputs:
    let
      # Common configuration variables
      username = "kenan";
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;  # Allow proprietary software
      };
      lib = nixpkgs.lib;

      # Helper function to create system configurations
      mkSystem = { system, host, modules }: 
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            # Base home-manager configuration
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = { inherit inputs username host; };
              };
            }
          ] ++ modules;
          specialArgs = {
            inherit self inputs username host;
          };
        };
    in
    {
      # NixOS system configurations for different machines
      nixosConfigurations = {
        # Laptop configuration (hay)
        hay = mkSystem {
          inherit system;
          host = "hay";
          modules = [ ./hosts/hay ];
        };

        # Virtual Machine configuration (vhay)
        vhay = mkSystem {
          inherit system;
          host = "vhay";
          modules = [ ./hosts/vhay ];
        };
      };
    };
}

