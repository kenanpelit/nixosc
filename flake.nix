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
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";  # Main nixpkgs repository (unstable channel)
    nur.url = "github:nix-community/NUR";                 # Nix User Repository - community packages
    home-manager = {                                      # User environment management
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";                # Use the same nixpkgs as above
    };

    # Hyprland-related inputs
    hyprland = {                                         # Hyprland Wayland compositor
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;                                 # Include all submodules
    };
    hypr-contrib.url = "github:hyprwm/contrib";          # Additional Hyprland utilities
    hyprpicker.url = "github:hyprwm/hyprpicker";        # Color picker for Hyprland
    hyprmag.url = "github:SIMULATAN/hyprmag";           # Hyprland magnifier

    # Additional tools and utilities
    alejandra.url = "github:kamadorueda/alejandra/3.0.0"; # Nix code formatter
    nix-gaming.url = "github:fufexan/nix-gaming";        # Gaming-related packages
    spicetify-nix = {                                    # Spotify customization
      url = "github:gerg-l/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";     # Flatpak integration
    zen-browser.url = "github:0xc000022070/zen-browser-flake"; # Browser configuration

    # Terminal and file management
    ghostty = {                                          # Terminal emulator
      url = "github:ghostty-org/ghostty";
    };
    yazi-plugins = {                                     # Yazi file manager plugins
      url = "github:yazi-rs/plugins";
      flake = false;                                     # Not a flake, just source files
    };
  };

  # System configuration and outputs
  outputs = { nixpkgs, self, ... }@inputs:
    let
      # Common configuration variables
      username = "kenan";                                # Main user username
      system = "x86_64-linux";                          # System architecture
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;                      # Allow proprietary software
      };
      lib = nixpkgs.lib;                                # Nixpkgs library functions
    in
    {
      # NixOS system configurations for different machines
      nixosConfigurations = {
        # Laptop configuration
        laptop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/laptop ];                 # Laptop-specific configuration
          specialArgs = {
            host = "laptop";
            inherit self inputs username;                # Pass common variables
          };
        };

        # Virtual Machine configuration
        vm = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/vm ];                     # VM-specific configuration
          specialArgs = {
            host = "vm";
            inherit self inputs username;
          };
        };
      };
    };
}
