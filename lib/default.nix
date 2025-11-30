# lib/default.nix
# ==============================================================================
# NixOS Configuration Library & Helper Functions
# ==============================================================================
#
# Module:      lib
# Purpose:     Abstracts system generation logic from flake.nix
# Author:      Kenan Pelit
# Created:     2025-11-29
#
# Description:
#   This file contains reusable helper functions and metadata definitions
#   used to construct NixOS systems and Home Manager configurations.
#   Separating this logic ensures flake.nix remains declarative and clean.
#
# Exports:
#   - hostsMeta: Host definitions and roles (physical/vm)
#   - mkSystem:  Builder function for NixOS system configurations
#   - mkHome:    Builder function for standalone Home Manager configurations
#
# ==============================================================================

{ inputs, nixpkgs, home-manager, ... }:
let
  inherit (nixpkgs) lib;

  # Host Metadata
  hostsMeta = {
    hay = {
      hostRole       = "physical";
      isPhysicalHost = true;
      isVirtualHost  = false;
    };
    vhay = {
      hostRole       = "vm";
      isPhysicalHost = false;
      isVirtualHost  = true;
    };
  };
in
{
  inherit hostsMeta;

  # System Builder
  mkSystem = { system, host, modules, overlays, nixpkgsConfig, username, specialArgs ? {} }:
    let
      hostMeta = hostsMeta.${host} or {
        hostRole       = "unknown";
        isPhysicalHost = false;
        isVirtualHost  = false;
      };
    in
    lib.nixosSystem {
      inherit system;
      modules = [
        # Platform configuration
        { nixpkgs.hostPlatform = system; }

        # Apply overlays and nixpkgs config
        {
          nixpkgs.overlays = overlays;
          nixpkgs.config   = nixpkgsConfig;
        }

        # Theming modules
        inputs.catppuccin.nixosModules.catppuccin

        # Home-manager as NixOS module (integrated mode)
        inputs.home-manager.nixosModules.home-manager

        # Empty system packages (managed elsewhere)
        { environment.systemPackages = []; }

        # Ensure insecure packages are allowed
        {
          nixpkgs.config.permittedInsecurePackages = 
            nixpkgsConfig.permittedInsecurePackages;
        }
      ] ++ modules;

      specialArgs = specialArgs // {
        inherit inputs username host system;
        inherit (hostMeta) hostRole isPhysicalHost isVirtualHost;
      };
    };

  # Home Manager Configuration Builder
  mkHome = { host, username, pkgs, homeModules, specialArgs ? {} }:
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = specialArgs // { inherit inputs username host; };
      modules = homeModules ++ [
        {
          home = {
            inherit username;
            homeDirectory = "/home/${username}";
            stateVersion = "25.11";
          };
        }
      ];
    };
}