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
      url = "github:hyprwm/hyprland/a5b7c91329313503e8864761f24ef43fb630f35c"; # 1208 - Updated commit
#      url = "github:hyprwm/hyprland/c26e91f074a1ffa5a7ef7fc0da247bcecada50ea"; # 1207 - Updated commit
      #      url = "github:hyprwm/hyprland/f8d5aad1a1f61e1b6443c27394a38c8c54d39e9e"; # 1207 - Updated commit
      #      url = "github:hyprwm/hyprland/222dbe99d0d2d8a61f3b3202f8ef1794b0b081b7"; # 1206 - Updated commit
      #      url = "github:hyprwm/hyprland/6a1daff5f30ea71e6d678554aa59fc5670864d24"; # 1205 - Updated commit
      #      url = "github:hyprwm/hyprland/3cf0280b11f370c11e6839275e547779a33f4a19"; # 1203 - Updated commit
    };

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ax-shell = {
      url = "github:poogas/Ax-Shell";
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
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.dgop.follows = "dgop";
      url = "github:AvengeMedia/DankMaterialShell/c570e20308ef4714a6c591a2da2f7989455da021"; # 1208 - Updated commit
#      url = "github:AvengeMedia/DankMaterialShell/308c8c3ea77300c463ba4ece1a41ec9a3f2e5701"; # 1207 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/511cb938060f3c5d6302ff5d02cff4d6c22ccfb4"; # 1207 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/2ddc448150b0576afe528ae5700ac031f94c9547"; # 1206 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/52d5e21fc4299aad7dad96482f6c4cd215e1e06c"; # 1205 - Updated commit
      #      url = "github:AvengeMedia/DankMaterialShell/6d0c56554fba353db582893540f39c53935b6460"; # 1205 - Updated commit
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

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
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
          (final: prev: let system = prev.stdenv.hostPlatform.system; ax = inputs.ax-shell.packages.${system}; in {
            ax-shell = ax.default;
            ax-send  = ax.ax-send or ax.default;
          })
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

              outputs-builder = channels: let
                system = channels.nixpkgs.stdenv.hostPlatform.system;
                alejandra = inputs.alejandra.packages.${system}.default;
                statix = inputs.statix.packages.${system}.default;
                deadnix = inputs.deadnix.packages.${system}.default;
                treefmt = channels.nixpkgs.treefmt;
              in {
                formatter = alejandra;
                
                checks = {
                  statix = channels.nixpkgs.runCommand "statix-check" {
                    nativeBuildInputs = [ statix ];
                  } ''
                    statix check ${./.}
                    touch $out
                  '';

                  deadnix = channels.nixpkgs.runCommand "deadnix-check" {
                    nativeBuildInputs = [ deadnix ];
                  } ''
                    deadnix --fail ${./.}
                    touch $out
                  '';

                  treefmt = channels.nixpkgs.runCommand "treefmt-check" {
                    nativeBuildInputs = [ treefmt ];
                  } ''
                    treefmt --fail-on-change --clear-cache --check ${./.}
                    touch $out
                  '';

                  nixos-hay = inputs.self.nixosConfigurations.hay.config.system.build.toplevel;
                  nixos-vhay = inputs.self.nixosConfigurations.vhay.config.system.build.toplevel;
                  home-kenan-hay = inputs.self.homeConfigurations."kenan@hay".activationPackage;
                };

                devShells.default = channels.nixpkgs.mkShell {
                  packages = [
                    alejandra
                    statix
                    deadnix
                  ];
                };
              };      })
      [ "snowfall" ];
}
