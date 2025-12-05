# ==============================================================================
#  NixOS Configuration Flake - Snowfall Edition
# ==============================================================================
#
#  Author:  Kenan Pelit
#  Repo:    https://github.com/kenanpelit/nixosc
#  License: MIT
#  Date:    2025-12-06
#
# ------------------------------------------------------------------------------
#  ARCHITECTURE
# ------------------------------------------------------------------------------
#
#  Snowfall Lib v4 layout, with NixOS + Home Manager under one flake.
#
#  Structure (workspace-write sandbox friendly):
#    ├── systems/              # Host configs per arch (hay, vhay, …)
#    ├── homes/                # Home Manager profiles (e.g. kenan@hay)
#    ├── modules/
#    │   ├── nixos/            # System-level modules (services, hardware)
#    │   └── home/             # User-level modules (HM apps/services)
#    ├── overlays/             # Nixpkgs overlays
#    ├── secrets/              # sops-nix secrets (age key in ~/.config/sops/age)
#    ├── assets/               # Encrypted dotfiles, mpv/tmux bundles, etc.
#    └── wallpapers/           # Theming assets
#
# ------------------------------------------------------------------------------
#  USAGE
# ------------------------------------------------------------------------------
#
#  Build & Switch:
#    $ ./install.sh install <host>        # system + home for host
#    $ nixos-rebuild switch --flake .#hay # direct call
#    $ home-manager switch --flake .#kenan@hay # home only
#
#  Update Inputs:
#    $ ./install.sh update
#
# ==============================================================================

{
  description = "Kenan's NixOS Configuration - Modern, Modular, Snowfall-based";

  inputs = {
    # ==========================================================================
    # Core Dependencies
    # ==========================================================================
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================================
    # System Components
    # ==========================================================================
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================================
    # Desktop Environment (Hyprland)
    # ==========================================================================
    hyprland = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hyprwm/hyprland/3cf0280b11f370c11e6839275e547779a33f4a19"; # 1203 - Updated commit
#      url = "github:hyprwm/hyprland/f82a8630d7a51dab4cc70924f500bf70e723db12"; # 1202 - Updated commit
#      url = "github:hyprwm/hyprland/bb963fb00263bac78a0c633d1d0d02ae4763222c";
    };

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyprland = {
      url = "github:hyprland-community/pyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================================
    # Theming
    # ==========================================================================
    catppuccin.url = "github:catppuccin/nix";
    distro-grub-themes.url = "github:AdisonCavani/distro-grub-themes";

    # ==========================================================================
    # Development Tools
    # ==========================================================================
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    statix = {
      url = "github:nerdypepper/statix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
    };

    deadnix = {
      url = "github:astro/deadnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dsearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ==========================================================================
    # Applications
    # ==========================================================================
    walker.url = "github:abenz1267/walker/v2.11.3";
    
    elephant = {
      url = "github:abenz1267/elephant/v2.16.1";
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

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    
    spicetify-nix = {
      url = "github:gerg-l/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nix-search-tv.url = "github:3timeslazy/nix-search-tv";

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };
  };

  outputs = inputs:
    let
      lib = inputs.nixpkgs.lib;
    in
    lib.removeAttrs
      (inputs.snowfall-lib.mkFlake {
        inherit inputs;
        src = ./.;

        snowfall = {
          namespace = "my"; # Custom namespace for internal modules
          
          # Default paths are used:
          # modules/nixos -> System modules
          # modules/home  -> (Not used, we use modules/user-modules manually)
        };

        # Global Nixpkgs configuration
        channels-config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "electron-36.9.5"
            "ventoy-1.1.07"
            "libsoup-2.74.3"
          ];
        };

        # Overlays applied to all systems
        overlays = with inputs; [
          nur.overlays.default
        ];

        # Modules automatically added to all NixOS systems
        systems.modules.nixos = with inputs; [
          home-manager.nixosModules.home-manager
          dankMaterialShell.nixosModules.dankMaterialShell
          catppuccin.nixosModules.catppuccin
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
        ];

        # Special arguments available to all modules
        systems.specialArgs = {
          username = "kenan";
        };

              outputs-builder = channels: {
                formatter = inputs.alejandra.packages.${channels.nixpkgs.stdenv.hostPlatform.system}.default;
                
                checks = {
                  statix = channels.nixpkgs.runCommand "statix-check" {
                    nativeBuildInputs = [ inputs.statix.packages.${channels.nixpkgs.stdenv.hostPlatform.system}.default ];
                  } ''
                    statix check ${./.}
                    touch $out
                  '';
                };

                devShells.default = channels.nixpkgs.mkShell {
                  packages = [
                    inputs.alejandra.packages.${channels.nixpkgs.stdenv.hostPlatform.system}.default
                    inputs.statix.packages.${channels.nixpkgs.stdenv.hostPlatform.system}.default
                    inputs.deadnix.packages.${channels.nixpkgs.stdenv.hostPlatform.system}.default
                  ];
                };
              };      })
      [ "snowfall" ];
}
